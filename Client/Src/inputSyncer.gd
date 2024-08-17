extends Node
class_name InputSyncer

#Helper node to sync inputs.

const RING_BUFFER_SIZE : int = 256
var m_netType : Net.Type = Net.Type.UNSPECIFIED #Enum to improve code readability about ownership of network.
var m_frame : int = 0 #Current frame

#Input buffer is needed on only local player.
#Whenever local player presses an input, it will also simulate it like it normally would on singleplayer.
#It will also send inputs to the server.
#Server will response updates to players state.
#Local player will always be ahead of server.
#Therefore whenever local player receives player state, it will instantly roll back to that state.
#And then will RE-SIMULATE actions starting from that point.
#We need this ringbuffer just for that.
var m_inputBuffer : RingBuffer = RingBuffer.new(256)

signal _m_jumpReceived(frame : int)
signal _m_moveLeftReceived(frame : int)
signal _m_moveRightReceived(frame : int)
signal _m_attackReceived(frame : int)
signal _m_fireReceived(frame : int)

func _enter_tree() -> void:
	m_netType = Net.mGetNetworkType(self)
	print(m_netType)

	if(not m_netType == Net.Type.LOCAL):
		#No need to check for inputs if the player is not local.
		set_physics_process(false)

#We will poll inputs in physics process instead of process like we would on singlePlayer game.
#Physics process function local player will call.
func _physics_process(_delta: float) -> void:

	#Local players should store their inputs.
	var inputContainer : InputContainer = InputContainer.new()

	if(Input.is_action_just_pressed("jump")):
		_mReliableSync.rpc_id(1, (INPUT.Type.JUMP), m_frame)
		inputContainer.PushBack(INPUT.Type.JUMP)

	if(Input.is_action_pressed("moveRight")):
		_mReliableSync.rpc_id(1, (INPUT.Type.MOVE_RIGHT), m_frame)
		inputContainer.PushBack(INPUT.Type.MOVE_RIGHT)
	
	if(Input.is_action_pressed("moveLeft")):
		_mReliableSync.rpc_id(1, (INPUT.Type.MOVE_LEFT), m_frame)
		inputContainer.PushBack(INPUT.Type.MOVE_LEFT)
	
	if(Input.is_action_just_pressed("attack")):
		_mReliableSync.rpc_id(1, (INPUT.Type.ATTACK), m_frame)
		inputContainer.PushBack(INPUT.Type.ATTACK)
	
	if(Input.is_action_just_pressed("fire")):
		_mReliableSync.rpc_id(1, (INPUT.Type.FIRE), m_frame)
		inputContainer.PushBack(INPUT.Type.FIRE)

	#Store
	m_inputBuffer.PushBack(inputContainer)
	
	m_frame += 1

################################### PRIVATE #############################

#Sync actions that needs reliable packet sending.
#Such as fire pistol, jump.
@rpc("authority", "call_remote", "reliable", 1)
func _mReliableSync(input : INPUT.Type, frame : int) -> void:

	#We dont send this rpc to puppet or local player but anyway.
	if(m_netType != Net.Type.SERVER):
		return

	match input:
		INPUT.Type.JUMP:
			_m_jumpReceived.emit(frame)
		INPUT.Type.ATTACK:
			_m_attackReceived.emit(frame)
		INPUT.Type.FIRE:
			_m_fireReceived.emit(frame)

#Sync actions that doesnt need reliable sending.
#Such as basic movement.
@rpc("authority", "call_remote", "unreliable", 0)
func _mUnreliableSync(input : INPUT.Type, frame : int) -> void:

	#We dont send this rpc to puppet or local player but anyway.
	if(m_netType != Net.Type.SERVER):
		return

	match input:
		INPUT.Type.MOVE_RIGHT:
			_m_moveRightReceived.emit(frame)
		INPUT.Type.MOVE_LEFT:
			_m_moveLeftReceived.emit(frame)
################################### PRIVATE #############################
