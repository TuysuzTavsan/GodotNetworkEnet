extends PlayerState
class_name  PlayerAttack

#AttackState of the player.
#Keep in mind that states only exist on local player and server.

var m_isCombined : bool = false #Flag to check if we need to combo attack animations.

#Default _init function for PlayerState
func _init(_params : Dictionary = {}):
	pass

func _ready() -> void:
	m_player._mChangeAnimation("attack1")
	m_player.m_animPlayer.animation_finished.connect(_onAnimFinished)

	if(m_player.m_netType == Net.Type.SERVER):
		set_physics_process(false)
		m_player.m_inputSyncer._m_reliableInputReceived.connect(_onReliableInput)

func _onAnimFinished(animName : String) -> void:
	match animName:
		"attack1":
			if(m_isCombined):
				m_isCombined = false
				m_player._mChangeAnimation("attack2")
			else:
				m_changeState.call(Player.STATES.IDLE)
		"attack2":
			if(m_isCombined):
				m_isCombined = false
				m_player._mChangeAnimation("attack3")
			else:
				m_changeState.call(Player.STATES.IDLE)
		"attack3":
				m_changeState.call(Player.STATES.IDLE)

#Will only be called on server.
func _onReliableInput(inputContainer : InputContainer, _frame : int) -> void:
	
	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.ATTACK:
				m_isCombined = true

func _physics_process(_delta: float) -> void:
	var inputContainer : InputContainer = m_player.m_inputSyncer.mGetLatestInputs() as InputContainer

	for input : INPUT.Type in inputContainer.m_events:
		match input:
			INPUT.Type.ATTACK:
				m_isCombined = true