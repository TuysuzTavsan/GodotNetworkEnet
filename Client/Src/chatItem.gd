extends RichTextLabel
class_name ChatItem


var m_msg : String = ""

func mInit(msg : String) -> void:
	m_msg = msg

func _ready() -> void:
	text = m_msg