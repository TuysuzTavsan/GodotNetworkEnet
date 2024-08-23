extends PlayerState
class_name  PlayerJump

#JumpState of the player.
#Keep in mind that states only exist on local player and server.

func _ready() -> void:
	m_player._mChangeAnimation("jump")

func _physics_process(_delta: float) -> void:
	if(m_player.velocity.y > 0):
		m_changeState.call(Player.STATES.FALL)