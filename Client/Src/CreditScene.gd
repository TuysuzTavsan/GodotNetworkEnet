extends Control

var m_mainMenuScene : PackedScene = load("res://Scenes/MainMenu.tscn")

func _onReturnPressed() -> void:
	var mainMenu = m_mainMenuScene.instantiate()
	queue_free()
	get_parent().add_child(mainMenu)
