extends PlayerState
class_name PlayerFall


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	m_player._mChangeAnimation("fall")

	m_player.m_animPlayer.animation_finished.connect(_onAnimationFinished)
	
func _onAnimationFinished(animName : String) -> void:
	if(animName == "jump"):
		m_player._mChangeAnimation("fall")
	if(animName == "land"):
		m_changeState.call(Player.STATES.IDLE)

func _physics_process(_delta: float) -> void:
	if(m_player.is_on_floor()):
		m_player._mChangeAnimation("land")
