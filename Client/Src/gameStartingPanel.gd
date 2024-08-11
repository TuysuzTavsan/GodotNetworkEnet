extends Control
class_name GameStartingPanel

const M_MAX_LIFETIME : int = 10
var m_remainingLaunchTime : float = -1.0

@onready var m_label : Label = $MarginContainer/Label
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_isOwner : bool = false

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func mInit(isLobbyOwner : bool, launchTime : float = 0.0) -> void:
	m_isOwner = isLobbyOwner
	m_remainingLaunchTime = launchTime

func _process(delta: float) -> void:
	m_remainingLaunchTime -= delta
	_mUpdateLabel()

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.START_GAME_FEEDBACK, self)
	
	if(m_isOwner):
		Client.mSendPacket(Msg.Type.START_GAME)
	
	_mWaitForTimeOut()
		

func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.START_GAME_FEEDBACK:
			match packetIn.m_data["code"] as int:
				0:
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					popUp.mInit("Error occured while trying to start game server.")
					get_parent().add_child(popUp)
					queue_free()
				1:
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					var port : int = packetIn.m_data["port"] as int
					popUp.mInit("Game server started successfully in port:" + str(port) + ".")
					get_parent().add_child(popUp)
					queue_free()
				2:
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					popUp.mInit("Server failed to launch.")
					get_parent().add_child(popUp)
					queue_free()
				3:
					m_remainingLaunchTime = packetIn.m_data["inSeconds"] as float	


func _mUpdateLabel() -> void:
	if(m_remainingLaunchTime > 0.0):
		m_label.text = "Game server will launch in " + str(m_remainingLaunchTime as int) + "."
	else:
		m_label.text = "Working on launch game server request."

func _mWaitForTimeOut() -> void:
	await get_tree().create_timer(M_MAX_LIFETIME).timeout

	var popUp : PopUp = m_popUpScene.instantiate() as PopUp
	popUp.mInit("Can not create game. No feedback from server.")
	get_parent().add_child(popUp)
	queue_free()