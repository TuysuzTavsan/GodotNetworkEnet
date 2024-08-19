extends Node2D
class_name Heart

#A collectable item to replanish helath

@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if(get_tree().get_multiplayer().is_server()):
		m_animPlayer.animation_finished.connect(_onAnimFinished)

func _onAnimFinished(animName : String) -> void:
	if(animName == "taken"):
		_mFree.rpc()

func _onBodyEntered(body : Node2D) -> void:
	if(get_tree().get_multiplayer().is_server()):
		if body is Player:
			_mPlayAnim.rpc("taken")
			
@rpc("authority", "call_local", "reliable", 1)
func _mFree() -> void:
	queue_free()

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnim(animName : String) -> void:
	m_animPlayer.play(animName)
