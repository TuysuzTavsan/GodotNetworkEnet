extends PlayerState
class_name  PlayerFire

#FireState of the player.	
#Keep in mind that states only exist on local player and server.

const M_FIRE_DAMAGE : int = 2

func _ready() -> void:
	m_player._mChangeAnimation("gunOut")
	m_player.m_animPlayer.animation_finished.connect(_onAnimFinished)

	if(m_player.m_netType != Net.Type.SERVER):
		set_physics_process(false)

#Only operates on server.
func _physics_process(_delta: float) -> void:
	if(m_player.m_rayCast.is_colliding()):
		var player : Player = m_player.m_rayCast.get_collider() as Player

		#Cast is not successfull its not player
		if(player == null):
			return

		player.m_statusBar._mLoseHeart(M_FIRE_DAMAGE)


		#Damage only one time, so we need to turn it back off
		m_player.m_rayCast.enabled = false

func _onAnimFinished(animName : String) -> void:
	match animName:
		"gunOut":
			m_player._mChangeAnimation("gunShoot")
		
		"gunShoot":
			m_player._mChangeAnimation("gunIn")
		
		"gunIn":
			m_changeState.call(Player.STATES.IDLE)
