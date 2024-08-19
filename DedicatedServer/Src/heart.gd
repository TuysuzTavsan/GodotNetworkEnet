extends Node2D
class_name Heart

const M_REGEN_HEART : int = 1

#A collectable item to replanish helath

@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if(get_tree().get_multiplayer().is_server()):
		m_animPlayer.animation_finished.connect(_onAnimFinished)

func _onAnimFinished(animName : String) -> void:
	if(animName == "taken"):
		_mFree.rpc()

func _onBodyEntered(body : Node2D) -> void:
	
	if(body is not Player):
		return

	_mPlayAnim.rpc("taken")

	var player : Player = body as Player

	player.m_statusBar._mRegenerate(M_REGEN_HEART)
			
@rpc("authority", "call_local", "reliable", 1)
func _mFree() -> void:
	queue_free()

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnim(animName : String) -> void:
	m_animPlayer.play(animName)
