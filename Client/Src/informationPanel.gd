extends Control
class_name InformationPanel

@onready var m_label : Label = $MarginContainer/Label

const M_ANIMATON_TIMER : float = 1.0
const M_MAX_DOTS : int = 3
var m_timerSum : float = 0.0
var m_textDotCount : int = 0
var m_msg : String = "DefaultUserName"

func mInit(msgToShow : String) -> void:
	m_msg = msgToShow

func _ready() -> void:
	m_label.text = m_msg

func _process(delta: float) -> void:
	_mAnimateConnectingString(delta)

func _mAnimateConnectingString(delta : float) -> void:
	m_timerSum += delta
	if(m_timerSum > M_ANIMATON_TIMER):
		m_timerSum = 0.0
		m_textDotCount += 1
		m_label.text = _mGetNextAnimString()

func _mGetNextAnimString() -> String:
	if(m_textDotCount > M_MAX_DOTS):
		m_textDotCount = 0
	
	var dotString : String = ""
	for i : int in range(0, m_textDotCount + 1, 1):
		dotString += "."

	return "Connecting" + dotString 