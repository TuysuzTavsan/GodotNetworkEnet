extends MarginContainer
class_name ChatItem

@onready var m_msgLabel : Label = $HBoxContainer/MsgLabel

var m_msg : String = ""

func mInit(msg : String) -> void:
	m_msg = msg

func _ready() -> void:
	m_msgLabel.text = m_msg