extends Control

var m_lobbyMenuScene : PackedScene = load("res://Scenes/lobbyMenu.tscn")

func _onReturnPressed() -> void:
	var lobbyMenu = m_lobbyMenuScene.instantiate()
	get_parent().add_child(lobbyMenu)
	queue_free()
