extends PlayerState
class_name  PlayerDead

#AttackState of the player.
#Keep in mind that states only exist on local player and server.

func _ready() -> void:
	m_player.m_isDead = true
	m_player._mChangeAnimation("death")

	if(m_player.m_netType == Net.Type.SERVER):
		m_player.m_animPlayer.animation_finished.connect(_onAnimFinished)

#Will only be triggered on server.
func _onAnimFinished(animName : String) -> void:
	match animName:
		"death":
				#this will trigger respawn code on the server.
				#on the node battlefield.
				m_player._m_dead.emit(m_player)