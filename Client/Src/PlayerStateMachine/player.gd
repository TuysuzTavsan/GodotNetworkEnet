extends CharacterBody2D
class_name Player

#State machine that will handle player.
#This script is the main handler of the states.

var m_state : PlayerState = null
@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer
@onready var m_inputSyncer : InputSyncer = $InputSyncer
@onready var m_animatedSprite : AnimatedSprite2D = $AnimatedSprite2D

enum STATES {
	IDLE,
	RUN,
}

static var m_states : Dictionary = {
	STATES.IDLE : PlayerIdle,
	STATES.RUN : PlayerRun,
}

const M_RING_BUFFER_SIZE : int = 64
const M_SPEED = 300.0
const M_JUMP_VELOCITY = -400.0
const M_INTERPOLATIN_FACTOR : float = 10.0
@onready var m_isAuthority : bool = get_multiplayer_authority() == get_tree().get_multiplayer().get_unique_id()
var m_gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var m_inputBuffer : FrameBuffer = FrameBuffer.new(M_RING_BUFFER_SIZE)
var m_stateBuffer : FrameBuffer = FrameBuffer.new(M_RING_BUFFER_SIZE)
var m_frame : int = 0 #This will only be used on the local player.

func _ready() -> void:
	if(m_isAuthority):
		_mChangeState(STATES.IDLE) #Do not use states if this player is puppet.
	elif(not get_tree().get_multiplayer().is_server()):
		m_animatedSprite.top_level = true
		m_animatedSprite.position = position

func _physics_process(delta: float) -> void:
	if(m_isAuthority):
		#This is local player.
		#Simulate movement like normally would.
		#Send input to the server.
		#on other peers frame is = to recent received frame.
		m_frame += 1
		var xStrength : float = Input.get_axis("moveLeft", "moveRight")
		velocity.x = xStrength * M_SPEED
		m_inputBuffer.mPushBack(xStrength)
		_mSendInput.rpc_id(1, xStrength, m_frame)

		#Simulate normally.
		
		if (not is_on_floor()):
			velocity.y += delta * m_gravity
	
		move_and_slide()
		return

	elif(multiplayer.is_server()):
		#Server will send latest position to puppets.

		if (not is_on_floor()):
			velocity.y += delta * m_gravity
	
		move_and_slide()

		_mUpdatePos.rpc(position, velocity, m_frame)
		return
	
	#This is a puppet.
	if (not is_on_floor()):
		velocity.y += delta * m_gravity

	move_and_slide()
	m_animatedSprite.position = lerp(m_animatedSprite.position, position, delta * M_INTERPOLATIN_FACTOR)





func _mChangeState(state : STATES, params : Dictionary = {}) -> void:
	if(m_state != null):
		remove_child(m_state) #To force stop listening input from InputSyncer
		m_state.queue_free()
		m_state = null
	
	m_state = m_states.get(state).new(params)
	assert(m_state, "Trying to change state no nonexisting state.")

	#initialize new state with owner = self, and callable reference to this function.
	m_state.mSetup(self, _mChangeState)
	add_child(m_state, true) #Always force readable name so rpc calls can work.

@rpc("any_peer", "call_remote", "unreliable", 0)
func _mUpdatePos(pos : Vector2, vel : Vector2, frame : int) -> void:
	
	#For a puppet player this is all we can do. We have to trust latest snapshat from the server.
	position = pos
	velocity = vel
	if(not m_isAuthority):
		return
	
	#For local player, we have inputs that server doesnt have yet.
	#We can use these to simulate up to the current frame.

	var step : int = m_frame - frame

	if(step < 0):
		print("error shouldnt be able to receive future frame.")
		return
	
	if(step >= M_RING_BUFFER_SIZE):
		#Latency is greater than we expect.
		#drop old inputs.
		print("server sent states from past.")
		step = M_RING_BUFFER_SIZE - 1

	
	#Re-simulate up to current frame.
	
	for i : int in range(step, 0, -1):
		var inputX : float = m_inputBuffer.mGet(i)
		velocity.x = inputX * M_SPEED
		move_and_slide()
		

@rpc("any_peer", "call_remote", "unreliable", 0)
func _mSendInput(inputVectorX : float, frame : int) -> void:
	if(frame <= m_frame):
		print("received frame is older.")
		return

	#Re simulate physics to the given frame using new received inputs.
	var steps : int = frame - m_frame #Step difference between frame received and local frame.
	for i : int in range(0, steps, 1):
		velocity.x = inputVectorX * M_SPEED
		move_and_slide()

	m_frame = frame
	
	_mUpdatePos.rpc(position, velocity, m_frame)
	

@rpc("authority", "call_local", "reliable", 1)
func _mSyncDirection(isLeft : bool) -> void:
	m_animatedSprite.flip_h = isLeft

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnimation(animName : String) -> void:
	m_animPlayer.play(animName)
