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
	pass

func _exit_tree() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(abs(m_player.velocity.x) < 0.1 ):
		m_changeState.call(Player.STATES.IDLE)