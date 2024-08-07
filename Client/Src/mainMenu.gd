extends Control

var m_userNameSubmitPanelScene : PackedScene = load("res://Scenes/UserNameSubmitPanel.tscn")
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_connectingPanelScene : PackedScene = load("res://Scenes/ConnectingPanel.tscn")

func _onPlayPressed() -> void:
	var userNameSubmitPanel : UserNameSubmitPanel = m_userNameSubmitPanelScene.instantiate() as UserNameSubmitPanel
	userNameSubmitPanel._m_UserNameSubmitted.connect(_onUserNameSubmitted)
	add_child(userNameSubmitPanel)
	get_tree().paused = true

func _onQuitPressed() -> void:
	get_tree().quit(0)


func _onUserNameSubmitted(_name : String) -> void:
	var connectingPanel : ConnectingPanel = m_connectingPanelScene.instantiate() as ConnectingPanel

	get_tree().paused = true
	add_child(connectingPanel)

	var result : bool = await Client.mConnectServer()

	get_tree().paused = false
	connectingPanel.queue_free()

	var popUp : PopUp = m_popUpScene.instantiate() as PopUp
	if(result):
		popUp.mInit("Successfully connected to server.")
		add_child(popUp)

		#TODO do something with userName.

	else:
		popUp.mInit("Failed to connect server.")
		add_child(popUp)
