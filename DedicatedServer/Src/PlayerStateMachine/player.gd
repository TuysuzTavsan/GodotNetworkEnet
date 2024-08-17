extends CharacterBody2D
class_name Player

#State machine that will handle player.
#This script is the main handler of the states.

var m_state : PlayerState = null
@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer
@onready var m_animatedSprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var m_inputSyncer : InputSyncer = $InputSyncer

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
var m_netType : Net.Type = Net.Type.UNSPECIFIED
var m_gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var m_frame : int = 0

func _ready() -> void:
	m_netType = Net.mGetNetworkType(self)
	if(m_netType == Net.Type.SERVER):
		m_inputSyncer._m_reliableInputReceived.connect(_onReliableInputReceived)
		m_inputSyncer._m_unreliableInputReceived.connect(_onUnreliableInputReceived)
	
	if(m_netType == Net.Type.PUPPET):
		m_animatedSprite.top_level = true
		m_animatedSprite.position = position

func _physics_process(delta: float) -> void:

	if(not is_on_floor()):
		velocity.y += delta * m_gravity

	if(m_netType == Net.Type.LOCAL):
		#We need to apply inputs to movement.
		var latestInputs : InputContainer = m_inputSyncer.mGetLatestInputs() as InputContainer
		var xDirection : float = latestInputs.mGetxAxisDirection() as float
		velocity.x = xDirection * M_SPEED
		m_frame += 1

	move_and_slide()

	if(m_netType == Net.Type.SERVER):
		_mUpdatePos.rpc(position, velocity, m_frame)
	
	if(m_netType == Net.Type.PUPPET):
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


#Function that will be used for only server. Because local players send their inputs to the server only.
func _onReliableInputReceived(inputContainer : InputContainer, frame : int) -> void:
	pass
	

#Function that will be used for only server. Because local players send their inputs to the server only.
func _onUnreliableInputReceived(inputContainer : InputContainer, frame : int) -> void:
	#This function only operates on the server.
	if(frame <= m_frame):
		Logger.mLogWarning("Received frame is older then current frame. Ignoring input.")
		return
	
	var frameDiff : int = frame - m_frame

	#Try to predict players state from latest input.
	for i : int in range(0, frameDiff, 1):
		var xDir = inputContainer.mGetxAxisDirection()
		velocity.x = xDir * M_SPEED

		move_and_slide()
	
	m_frame = frame

	#Send feedback to the local player and puppet from server.
	_mUpdatePos.rpc(position, velocity, m_frame)


@rpc("any_peer", "call_remote", "unreliable", 0)
func _mUpdatePos(pos : Vector2, vel : Vector2, frame : int) -> void:
	#For a puppet player this is all we can do. We have to trust latest snapshat from the server.
	position = pos
	velocity = vel
	if(m_netType != Net.Type.LOCAL):
		return
	
	#For local player, we have inputs that server doesnt have yet.
	#We can use these to simulate up to the current frame.

	var frameDiff : int = m_frame - frame

	if(frameDiff < 0):
		print("error shouldnt be able to receive future frame.")
		return
	
	if(frameDiff >= m_inputSyncer.M_RING_BUFFER_SIZE):
		#Latency is greater than we expect.
		#drop old inputs.
		print("server sent states from very past.")
		print("simulating possible amount of inputs.")
		frameDiff = m_inputSyncer.M_RING_BUFFER_SIZE - 1

	#Re-simulate up to current frame.
	
	var inputBuffer : RingBuffer = m_inputSyncer.mGetUnreliableInputBuffer() as RingBuffer
	for i : int in range(frameDiff, 0, -1):
		var inputContainer : InputContainer = inputBuffer.mGetwOffset(i) as InputContainer
		var inputX : float = inputContainer.mGetxAxisDirection()

		if(inputX):
			velocity.x = inputX * M_SPEED
			move_and_slide()

@rpc("authority", "call_local", "reliable", 1)
func _mSyncDirection(isLeft : bool) -> void:
	m_animatedSprite.flip_h = isLeft

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnimation(animName : String) -> void:
	m_animPlayer.play(animName)
