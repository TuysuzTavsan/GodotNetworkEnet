extends Node
class_name InputSyncer

#Helper class to transfer input from client to server.
#Server will perform input locally and sync movement and state on the client as response.

#Whenever client that has authority on sends input, we forward these inputs to listeners.
#Only one listener can listen specific input type at a specific time period.
#Listener nodes must have a function called -> mOnInput(inputType : InputSyncer.INPUT) -> void:
#InputSyncer will call mOnInput as a forwarding mechanism.

var m_listeners : Dictionary = {} # key is INPUT- value is listener Node
var m_frame : int = 0


enum INPUT {
	UNSPECIFIED = 0,
	JUMP = 1,
	MOVE_LEFT = 2,
	MOVE_RIGHT = 3,
	ATTACK = 4,
	FIRE = 5,
}

#Check inputs and send them to the server.
func _process(_delta: float) -> void:
	var anyInput : bool = false

	if(Input.is_action_just_pressed("jump")):
		_mReliableSync.rpc_id(1, (INPUT.JUMP))
		anyInput = true
	
	if(Input.is_action_pressed("moveRight")):
		_mReliableSync.rpc_id(1, (INPUT.MOVE_RIGHT))
		anyInput = true
	
	if(Input.is_action_pressed("moveLeft")):
		_mReliableSync.rpc_id(1, (INPUT.MOVE_LEFT))
		anyInput = true
	
	if(Input.is_action_just_pressed("attack")):
		_mReliableSync.rpc_id(1, (INPUT.ATTACK))
		anyInput = true
	
	if(Input.is_action_just_pressed("fire")):
		_mReliableSync.rpc_id(1, (INPUT.FIRE))
		anyInput = true
	
	if(anyInput):
		m_frame += 1


func mListenInput(inputType : INPUT, listener : Node) -> void:
	assert(m_listeners.get(inputType) == null, "Cant listen input which someone else is listening to.")

	m_listeners[inputType] = listener

func mStopListeningInput(inputType : INPUT, listener : Node) -> void:
	assert(m_listeners.get(inputType) == listener, "Cant stop listening input which no one or given listener doesnt listen to.")

	m_listeners.erase(inputType)

################################### PRIVATE #############################

#Sync actions that needs reliable packet sending.
#Such as fire pistol, jump.
@rpc("authority", "call_remote", "reliable", 1)
func _mReliableSync(input : INPUT) -> void:

	var listener : Node = m_listeners.get(input)

	if(listener):
		listener.mOnInput(input)
		return
	
	Logger.mLogWarning("Received reliable input without any listener. Ignoring input.")

#Sync actions that doesnt need reliable sending.
#Such as basic movement.
@rpc("authority", "call_remote", "unreliable", 0)
func _mUnreliableSync(input : INPUT) -> void:
	
	var listener : Node = m_listeners.get(input)

	if(listener):
		listener.mOnInput(input)
		return
	
	Logger.mLogWarning("Received unreliable input without any listener. Ignoring input.")

################################### PRIVATE #############################
