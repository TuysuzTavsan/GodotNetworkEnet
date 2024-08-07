extends Control
class_name PopUp

@onready var m_label : Label = $MarginContainer/VBoxContainer/MarginContainer/Label
var m_msg : String = "PlaceHolderText"

func mInit(msg : String) -> void:
	m_msg = msg

func _ready() -> void:
	m_label.text = m_msg

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func _onOkPressed() -> void:
	queue_free()
