extends PlayerState
class_name PlayerIdle

#IdleState of the player.
#Keep in mind that states only exist on local player and server.

#Default _init function for PlayerState
func _init(_params : Dictionary = {}):
	pass

func _ready() -> void:
	m_player._mChangeAnimation("idle")

	if(m_player.m_netType == Net.Type.SERVER):
		set_physics_process(false)
		m_player.m_inputSyncer._m_reliableInputReceived.connect(_onReliableInput)
		m_player.m_inputSyncer._m_unreliableInputReceived.connect(_onUnreliableInput)


#Will only be called on server.
func _onReliableInput(inputContainer : InputContainer, _frame : int) -> void:
	
	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.JUMP:
				if(m_player.is_on_floor()):
					m_changeState.call(Player.STATES.JUMP)
			INPUT.Type.ATTACK:
				m_changeState.call(Player.STATES.ATTACK)
			INPUT.Type.FIRE:
				m_changeState.call(Player.STATES.FIRE)

#Will only be called on server.
func _onUnreliableInput(inputContainer : InputContainer, _frame : int) -> void:

	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.MOVE_RIGHT:
				m_changeState.call(Player.STATES.RUN, {"isLeft" : false})
			INPUT.Type.MOVE_LEFT:
				m_changeState.call(Player.STATES.RUN, {"isLeft" : true})

func _physics_process(_delta: float) -> void:
	var inputContainer : InputContainer = m_player.m_inputSyncer.mGetLatestInputs() as InputContainer

	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.MOVE_RIGHT:
				m_changeState.call(Player.STATES.RUN, {"isLeft" : false})
			INPUT.Type.MOVE_LEFT:
				m_changeState.call(Player.STATES.RUN, {"isLeft" : true})
			INPUT.Type.JUMP:
				if(m_player.is_on_floor()):
					m_changeState.call(Player.STATES.JUMP)
			INPUT.Type.ATTACK:
				m_changeState.call(Player.STATES.ATTACK)
			INPUT.Type.FIRE:
				m_changeState.call(Player.STATES.FIRE)
