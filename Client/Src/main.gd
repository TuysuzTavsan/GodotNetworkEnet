extends Node

var mainMenuScene : PackedScene = load("res://Scenes/MainMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mainMenu = mainMenuScene.instantiate()
	add_child(mainMenu)