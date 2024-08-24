extends Control
class_name GameStartingPanel

const M_MAX_LIFETIME : int = 10
var m_remainingLaunchTime : float = -1.0

@onready var m_label : Label = $MarginContainer/Label
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_battleFieldScene : PackedScene = load("res://Scenes/Battlefield.tscn")
var m_isOwner : bool = false

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

#Called whenever subscribed packet type is received.
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
					var port : int = packetIn.m_data["port"] as int
					var battleField : Battlefield = m_battleFieldScene.instantiate()
					battleField.mInit(Client.m_ADRESS, port)
					get_parent().queue_free() #This will also queue free this.
					get_tree().root.add_child(battleField)
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
