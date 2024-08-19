extends PlayerState
class_name PlayerRun

var m_args : Dictionary = {}

#param will always have isLeft as argument.
func _init(params : Dictionary = {}):
	m_args = params
	
func _ready() -> void:
	m_player._mChangeAnimation("run")
	
	if(m_player.m_netType == Net.Type.SERVER):
		set_physics_process(false)
		m_player.m_inputSyncer._m_reliableInputReceived.connect(_onReliableInput)

#Will only be called on server.
func _onReliableInput(inputContainer : InputContainer, _frame : int) -> void:
	
	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.JUMP:
				m_changeState.call(Player.STATES.JUMP)

			INPUT.Type.ATTACK:
				m_changeState.call(Player.STATES.ATTACK)

			INPUT.Type.FIRE:
				m_changeState.call(Player.STATES.FIRE)

func _physics_process(_delta: float) -> void:
	var inputContainer : InputContainer = m_player.m_inputSyncer.mGetLatestInputs() as InputContainer

	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.JUMP:
				m_changeState.call(Player.STATES.JUMP)

			INPUT.Type.ATTACK:
				m_changeState.call(Player.STATES.ATTACK)

			INPUT.Type.FIRE:
				m_changeState.call(Player.STATES.FIRE)

func _process(_delta: float) -> void:
	if(abs(m_player.velocity.x) < 0.1):
		m_changeState.call(Player.STATES.IDLE)