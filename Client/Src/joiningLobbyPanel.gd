extends MarginContainer
class_name JoiningLobbyPanel

@onready var m_label : Label = $MarginContainer/Label

const M_FEEDBACK_WAIT_TIME : int = 15 #Wait 15 seconds for feedback.
const M_ANIMATON_TIMER : float = 1.0
const M_MAX_DOTS : int = 3
const M_MSG : String = "Joining Lobby"
var m_timerSum : float = 0.0
var m_textDotCount : int = 0
var m_informationPanelScene : PackedScene = load("res://Scenes/InformationPanel.tscn")
var m_lobbyScene : PackedScene = load("res://Scenes/Lobby.tscn")
var m_lobbyNameToJoin : String = ""


func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func mInit(lobbyNameToJoin : String) -> void:
	m_lobbyNameToJoin = lobbyNameToJoin

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.JOIN_LOBBY_FEEDBACK, self)
	
	var dictToSend : Dictionary = {
		"lobbyName" : m_lobbyNameToJoin
	}

	Client.mSendPacket(Msg.Type.JOIN_LOBBY, dictToSend)
	_mWaitForFeedback(M_FEEDBACK_WAIT_TIME)


func _process(delta: float) -> void:
	_mAnimateConnectingString(delta)

#Called whenever subscribed packet type is received.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.JOIN_LOBBY_FEEDBACK:
			var result : int = packetIn.m_data as int
			match result:
				0:
					#Cant find lobby to join
					var informationPanel : InformationPanel = m_informationPanelScene.instantiate() as InformationPanel
					informationPanel.mInit("Cant find lobby to join.")
					get_parent().add_child(informationPanel)
					queue_free()
				1:
					#Successfully created lobby.
					#Clear scene tree and switch to lobby scene.
					var lobby : Lobby = m_lobbyScene.instantiate()
					lobby.mInit(packetIn.m_data["lobbyName"] as String, false)
					#Since we are joining, there is no way we are the owner of the lobby.

					get_parent().get_parent().queue_free()
					
					get_tree().root.add_child(lobby)
				2:
					#Lobby is full capacity.
					var informationPanel : InformationPanel = m_informationPanelScene.instantiate() as InformationPanel
					informationPanel.mInit("Lobby is full.")
					get_parent().add_child(informationPanel)
					queue_free()


func _mWaitForFeedback(timeInSeconds : int) -> void:
	await get_tree().create_timer(timeInSeconds).timeout
	
	#If this node still exists after waiting for timeInSeconds.
	#It means we dont get feedback from lobbyServer.
	#Queue free this node and show information to player.
	var informationPanel : InformationPanel = m_informationPanelScene.instantiate() as InformationPanel
	informationPanel.mInit("No response from lobbyServer.")
	get_parent().add_child(informationPanel)
	queue_free()

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