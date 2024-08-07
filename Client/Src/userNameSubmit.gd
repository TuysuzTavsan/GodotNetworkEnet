extends Control
class_name UserNameSubmitPanel

@onready var m_lineEdit : LineEdit = $MarginContainer/VBoxContainer/LineEdit
signal _m_UserNameSubmitted(name : String)

func _exit_tree() -> void:
	get_tree().paused = false

func _onConnectPressed() -> void:
	_m_UserNameSubmitted.emit(m_lineEdit.text)
	queue_free()

func _onTextSubmitted(_new_text:String) -> void:
	_onConnectPressed()

func _onCancelPressed() -> void:
	queue_free()