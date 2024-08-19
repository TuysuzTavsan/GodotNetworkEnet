extends PlayerState
class_name  PlayerFire

#FireState of the player.	
#Keep in mind that states only exist on local player and server.

func _ready() -> void:
	m_player._mChangeAnimation("gunOut")
	m_player.m_animPlayer.animation_finished.connect(_onAnimFinished)

func _onAnimFinished(animName : String) -> void:
	match animName:
		"gunOut":
			m_player._mChangeAnimation("gunShoot")
		
		"gunShoot":
			m_player._mChangeAnimation("gunIn")
		
		"gunIn":
			m_changeState.call(Player.STATES.IDLE)