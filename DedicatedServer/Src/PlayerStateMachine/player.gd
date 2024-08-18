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
	JUMP,
	ATTACK,
	FIRE,
}

static var m_states : Dictionary = {
	STATES.IDLE : PlayerIdle,
	STATES.RUN : PlayerRun,
	STATES.JUMP : PlayerJump,
	STATES.ATTACK : PlayerAttack,
	STATES.FIRE : PlayerFire
}

const M_RING_BUFFER_SIZE : int = 256
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
		_mChangeState(STATES.IDLE)
		return
	
	if(m_netType == Net.Type.PUPPET):
		m_animatedSprite.top_level = true
		m_animatedSprite.position = position
		return
	
	#Means local player.
	_mChangeState(STATES.IDLE)

func _physics_process(delta: float) -> void:

	if(not is_on_floor()):
		velocity.y += delta * m_gravity

	if(m_netType == Net.Type.LOCAL):
		#We need to apply inputs to movement.
		var latestInputs : InputContainer = m_inputSyncer.mGetLatestInputs() as InputContainer
		var xDirection : float = latestInputs.mGetxAxisDirection() as float

		_mChangeDirection(xDirection)

		if(is_on_floor()):
			if(latestInputs.mHas(INPUT.Type.JUMP)):
				velocity.y = delta * m_gravity

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
	#This function only operates on the server.
	if(frame <= m_frame):
		Logger.mLogWarning("Received frame is older then current frame. Ignoring input.")
		return

	#For reliableInputs all we check for movement specific is jump input.
	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.JUMP:
				
				#Apply jump force.
				#We can not simulate jump because of delta time issues.
				if(is_on_floor()):
					velocity.y = M_JUMP_VELOCITY		

			INPUT.Type.ATTACK:
				pass
			INPUT.Type.FIRE:
				pass

#Function that will be used for only server. Because local players send their inputs to the server only.
func _onUnreliableInputReceived(inputContainer : InputContainer, frame : int) -> void:
	#This function only operates on the server.
	if(frame <= m_frame):
		Logger.mLogWarning("Received frame is older then current frame. Ignoring input.")
		return
	
	var frameDiff : int = frame - m_frame

	#Try to predict players state from latest input.
	var xDir : float = inputContainer.mGetxAxisDirection() as float
	for i : int in range(0, frameDiff, 1):
		velocity.x = xDir * M_SPEED

		move_and_slide()
	
	m_frame = frame
	#Send feedback to the local player and puppet from server.

	_mChangeDirection(xDir)
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

@rpc("any_peer", "call_local", "reliable", 1)
func _mSyncDirection(isLeft : bool) -> void:
	m_animatedSprite.flip_h = isLeft

@rpc("any_peer", "call_local", "reliable", 1)
func _mPlayAnimation(animName : String) -> void:
	m_animPlayer.play(animName)

func _mChangeDirection(vectorX : float) -> void:
	if(vectorX != -1.0 and vectorX != 1.0):
		return

	if(m_netType == Net.Type.SERVER):
		_mSyncDirection(true if vectorX == -1.0 else false)
		_mSyncDirection.rpc(true if vectorX == -1.0 else false)
		return

	if(m_netType == Net.Type.LOCAL):
		m_animatedSprite.flip_h = true if vectorX == -1.0 else false
		return

func _mChangeAnimation(animName : String) -> void:
	if(m_netType == Net.Type.SERVER):
		_mPlayAnimation(animName)
		_mPlayAnimation.rpc(animName)

	elif(m_netType == Net.Type.LOCAL):
		m_animPlayer.play(animName)