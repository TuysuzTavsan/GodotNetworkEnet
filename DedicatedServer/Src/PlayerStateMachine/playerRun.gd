extends PlayerState
class_name PlayerRun

var m_args : Dictionary = {}

#param will always have isLeft as argument.
func _init(params : Dictionary = {}):
	m_args = params

func _ready() -> void:
	m_player._mSyncDirection(m_args["isLeft"] as bool)
	m_player._mPlayAnimation("run")

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
			m_player.velocity += m_player.M_SPEED * Vector2.LEFT
			m_player._mSyncDirection.rpc(true)

		InputSyncer.INPUT.MOVE_RIGHT:
			m_player.velocity += m_player.M_SPEED * Vector2.RIGHT
			m_player._mSyncDirection.rpc(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(abs(m_player.velocity.x) < 0.1 ):
		m_changeState.call(Player.STATES.IDLE)