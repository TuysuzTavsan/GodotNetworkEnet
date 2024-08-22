extends Control

var m_userNameSubmitPanelScene : PackedScene = load("res://Scenes/UserNameSubmitPanel.tscn")
@onready var m_volumeSlider : HSlider = $MarginContainer/VBoxContainer2/VBoxContainer2/HBoxContainer/HSlider

func _ready() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(m_volumeSlider.value))

	if(Client.mIsConnected()):
		#We need to reset client to its fresh state.
		Client.mDisconnect()

func _onPlayPressed() -> void:
	var userNameSubmitPanel : UserNameSubmitPanel = m_userNameSubmitPanelScene.instantiate() as UserNameSubmitPanel
	add_child(userNameSubmitPanel) #Adding this as child will make the scene paused.
	#UserNameSubmitPanel will handle the rest.

func _onQuitPressed() -> void:
	get_tree().quit(0)

func _onVolumeValChanged(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

