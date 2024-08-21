extends PlayerState
class_name  PlayerJump

#JumpState of the player.
#Keep in mind that states only exist on local player and server.

func _ready() -> void:
	m_player._mChangeAnimation("jump")