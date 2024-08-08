extends Control
class_name ConnectingPanel

@onready var m_label : Label = $MarginContainer/Label

const M_ANIMATON_TIMER : float = 1.0
const M_MAX_DOTS : int = 3
var m_timerSum : float = 0.0
var m_textDotCount : int = 0
var m_userName : String = "DefaultUserName"

signal _m_connectionResulted(result : bool) #true if client connected to server false otherwise.

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func mInit(userName : String) -> void:
	m_userName = userName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var result : bool = await Client.mConnectServer()
	_m_connectionResulted.emit(result, m_userName)
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
