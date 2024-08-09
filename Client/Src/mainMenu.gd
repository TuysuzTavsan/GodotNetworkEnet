extends Control

var m_userNameSubmitPanelScene : PackedScene = load("res://Scenes/UserNameSubmitPanel.tscn")

func _ready() -> void:
	if(Client.mIsConnected()):
		#We need to reset client to its fresh state.
		Client.mDisconnect()

func _onPlayPressed() -> void:
	var userNameSubmitPanel : UserNameSubmitPanel = m_userNameSubmitPanelScene.instantiate() as UserNameSubmitPanel
	add_child(userNameSubmitPanel) #Adding this as child will make the scene paused.
	#UserNameSubmitPanel will handle the rest.

func _onQuitPressed() -> void:
	get_tree().quit(0)