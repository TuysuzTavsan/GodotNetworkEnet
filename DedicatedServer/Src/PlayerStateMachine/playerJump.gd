extends PlayerState
class_name  PlayerJump

#JumpState of the player.
#Keep in mind that states only exist on local player and server.

func _ready() -> void:
	m_player._mChangeAnimation("jump")
	
	m_player.m_animPlayer.animation_finished.connect(_onAnimationFinished)
	
func _onAnimationFinished(animName : String) -> void:
	if(animName == "jump"):
		m_player._mChangeAnimation("fall")
	if(animName == "land"):
		m_changeState.call(Player.STATES.IDLE)

func _physics_process(_delta: float) -> void:
	if(m_player.is_on_floor()):
		m_player._mChangeAnimation("land")	