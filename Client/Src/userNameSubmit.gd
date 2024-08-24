extends Control
class_name UserNameSubmitPanel

@onready var m_lineEdit : LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var m_connectButton : Button = $MarginContainer/VBoxContainer/ConnectButton

var m_connectingPanelScene : PackedScene = load("res://Scenes/ConnectingPanel.tscn")

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func _onConnectPressed() -> void:
	var connectingPanel : ConnectingPanel = m_connectingPanelScene.instantiate() as ConnectingPanel
	var userName : String = m_lineEdit.text
	connectingPanel.mInit(userName) #Store it on connectingPannel
	add_child(connectingPanel) #Will make the tree paused and will call _onConnectionResult when the attemp is resulted.

func _onTextSubmitted(_new_text:String) -> void:
	_onConnectPressed()

func _onCancelPressed() -> void:
	queue_free()

func _onTextChanged(new_text:String) -> void:
	if(new_text.length() <= 0):
		m_connectButton.disabled = true
	else:
		m_connectButton.disabled = false
