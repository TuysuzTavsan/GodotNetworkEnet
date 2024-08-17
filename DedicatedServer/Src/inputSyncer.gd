extends Node
class_name InputSyncer

#Helper node to sync inputs.

const M_RING_BUFFER_SIZE : int = 256
var m_netType : Net.Type = Net.Type.UNSPECIFIED #Enum to improve code readability about ownership of network.
var m_frame : int = 0 #Current frame
var m_reliableInputBuffer : RingBuffer = RingBuffer.new(256)
var m_unreliableInputBuffer : RingBuffer = RingBuffer.new(256)
var m_latestInputs : InputContainer = InputContainer.new()
#Input buffer is needed on only local player.
#Whenever local player presses an input, it will also simulate it like it normally would on singleplayer.
#It will also send inputs to the server.
#Server will response updates to players state.
#Local player will always be ahead of server.
#Therefore whenever local player receives player state, it will instantly roll back to that state.
#And then will RE-SIMULATE actions starting from that point.
#We need this ringbuffer just for that.

signal _m_reliableInputReceived(inputContainer : InputContainer, frame : int)
signal _m_unreliableInputReceived(inputContainer : InputContainer, frame : int)

func _ready() -> void:
	m_netType = Net.mGetNetworkType(self)

	if(not m_netType == Net.Type.LOCAL):
		#No need to check for inputs if the player is not local.
		set_physics_process(false)

#We will poll inputs in physics process instead of process like we would on singlePlayer game.
#Physics process function local player will call.
func _physics_process(_delta: float) -> void:

	#Local players should store their inputs.
	var reliableInputContainer : InputContainer = InputContainer.new()
	var unreliableInputContainer : InputContainer = InputContainer.new()
	m_latestInputs.mClear()

	if(Input.is_action_just_pressed("jump")):
		reliableInputContainer.mPushBack(INPUT.Type.JUMP)
		m_latestInputs.mPushBack(INPUT.Type.JUMP)

	if(Input.is_action_pressed("moveRight")):
		unreliableInputContainer.mPushBack(INPUT.Type.MOVE_RIGHT)
		m_latestInputs.mPushBack(INPUT.Type.MOVE_RIGHT)
	
	if(Input.is_action_pressed("moveLeft")):
		unreliableInputContainer.mPushBack(INPUT.Type.MOVE_LEFT)
		m_latestInputs.mPushBack(INPUT.Type.MOVE_LEFT)
	
	if(Input.is_action_just_pressed("attack")):
		reliableInputContainer.mPushBack(INPUT.Type.ATTACK)
		m_latestInputs.mPushBack(INPUT.Type.ATTACK)
	
	if(Input.is_action_just_pressed("fire")):
		reliableInputContainer.mPushBack(INPUT.Type.FIRE)
		m_latestInputs.mPushBack(INPUT.Type.FIRE)

	#Send input containers.
	_mReliableSync.rpc_id(1, {"inputContainer" : reliableInputContainer.m_events}, m_frame)

	_mUnreliableSync.rpc_id(1, {"inputContainer" : unreliableInputContainer.m_events}, m_frame)

	#Store
	m_unreliableInputBuffer.mPushBack(unreliableInputContainer)
	m_reliableInputBuffer.mPushBack(reliableInputContainer)
	
	m_frame += 1

func mGetUnreliableInputBuffer() -> RingBuffer:
	return m_unreliableInputBuffer

func mGetLatestInputs() -> InputContainer:
	return m_latestInputs.duplicate()

################################### PRIVATE #############################

#Sync actions that needs reliable packet sending.
#Such as fire pistol, jump.
@rpc("authority", "call_remote", "reliable", 1)
func _mReliableSync(inputContainerAsDict : Dictionary, frame : int) -> void:

	var inputContainer : InputContainer = InputContainer.new()
	inputContainer.m_events = inputContainerAsDict["inputContainer"]
	#We dont send this rpc to puppet or local player but anyway.
	if(m_netType != Net.Type.SERVER):
		return
	
	_m_reliableInputReceived.emit(inputContainer, frame)

#Sync actions that doesnt need reliable sending.
#Such as basic movement.
@rpc("authority", "call_remote", "unreliable", 0)
func _mUnreliableSync(inputContainerAsDict : Dictionary, frame : int) -> void:

	var inputContainer : InputContainer = InputContainer.new()
	inputContainer.m_events = inputContainerAsDict["inputContainer"]
	#We dont send this rpc to puppet or local player but anyway.
	if(m_netType != Net.Type.SERVER):
		return

	_m_unreliableInputReceived.emit(inputContainer, frame)

################################### PRIVATE #############################
