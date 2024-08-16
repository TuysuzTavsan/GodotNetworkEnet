extends PlayerState
class_name PlayerIdle

#IdleState of the player will listen any type of input and change state.

#Default _init function for PlayerState
func _init(_params : Dictionary = {}):
	pass

func _enter_tree() -> void:
	m_player.m_inputSyncer.mListenInput(InputSyncer.INPUT.ATTACK, self)
	m_player.m_inputSyncer.mListenInput(InputSyncer.INPUT.JUMP, self)
	m_player.m_inputSyncer.mListenInput(InputSyncer.INPUT.MOVE_LEFT, self)
	m_player.m_inputSyncer.mListenInput(InputSyncer.INPUT.MOVE_RIGHT, self)

func _exit_tree() -> void:
	m_player.m_inputSyncer.mStopListeningInput(InputSyncer.INPUT.ATTACK, self)
	m_player.m_inputSyncer.mStopListeningInput(InputSyncer.INPUT.JUMP, self)
	m_player.m_inputSyncer.mStopListeningInput(InputSyncer.INPUT.MOVE_LEFT, self)
	m_player.m_inputSyncer.mStopListeningInput(InputSyncer.INPUT.MOVE_RIGHT, self)

#generic function to listen input from InputSyncer.
func mOnInput(inputType : InputSyncer.INPUT) -> void:
	match inputType:
		InputSyncer.INPUT.ATTACK:
			pass
		InputSyncer.INPUT.JUMP:
			pass
		InputSyncer.INPUT.MOVE_LEFT:
			m_changeState.call(Player.STATES.RUN, {"isLeft" : true})
		InputSyncer.INPUT.MOVE_RIGHT:
			m_changeState.call(Player.STATES.RUN, {"isLeft" : false})

func _ready() -> void:
	m_player._mPlayAnimation("idle") 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
