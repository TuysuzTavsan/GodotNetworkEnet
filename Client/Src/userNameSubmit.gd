extends Control
class_name UserNameSubmitPanel

@onready var m_lineEdit : LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var m_connectButton : Button = $MarginContainer/VBoxContainer/ConnectButton

signal _m_UserNameSubmitted(name : String)

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func _onConnectPressed() -> void:
	_m_UserNameSubmitted.emit(m_lineEdit.text)
	queue_free()

func _onTextSubmitted(_new_text:String) -> void:
	_onConnectPressed()

func _onCancelPressed() -> void:
	queue_free()

func _onTextChanged(new_text:String) -> void:
	if(new_text.length() <= 0):
		m_connectButton.disabled = true
	else:
		m_connectButton.disabled = false
