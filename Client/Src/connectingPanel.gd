extends Control
class_name ConnectingPanel

@onready var m_label : Label = $MarginContainer/Label

const M_ANIMATON_TIMER : float = 1.0
const M_MAX_DOTS : int = 3
var m_timerSum : float = 0.0
var m_textDotCount : int = 0
var m_userName : String = "DefaultUserName"
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_lobbyMenuScene : PackedScene = load("res://Scenes/lobbyMenu.tscn")

func mInit(userName : String) -> void:
	m_userName = userName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Wait for result...
	var result : bool = await Client.mConnectServer()

	#Process result.
	_onConnectAttemptResulted(result, m_userName)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_mAnimateConnectingString(delta)

func _onConnectAttemptResulted(result : bool, userName : String) -> void:
	var popUp : PopUp = m_popUpScene.instantiate() as PopUp
	if(result):
		popUp.mInit("Successfully connected to server.")
		add_child(popUp)

		#Send username to lobbyserver.
		Client.mSendPacket(Msg.Type.USER_INFO, userName)

		#Free all scenes from scene tree and change scene to lobbyMenu.
		get_parent().get_parent().queue_free()
		var lobbyMenu = m_lobbyMenuScene.instantiate()
		get_tree().root.add_child(lobbyMenu)

	else:
		popUp.mInit("Failed to connect server.")
		get_parent().get_parent().add_child(popUp) #Add it as mainMenu child.
		get_parent().queue_free()

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
