extends Control
class_name CreateLobbyPanel

@onready var m_maxPlayersOptionButton : OptionButton = $MarginContainer/VBoxContainer/HBoxContainer2/MaxPlayersOption
@onready var m_lobbyNameLineEdit : LineEdit = $MarginContainer/VBoxContainer/LobbyNameEdit
@onready var m_createButton : Button = $MarginContainer/VBoxContainer/HBoxContainer/CreateButton

var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_lobbyScene : PackedScene = load("res://Scenes/Lobby.tscn")
var m_informationPanelScene : PackedScene = load("res://Scenes/InformationPanel.tscn")

var m_lobbyName : String = "DefaultLobbyName"

func _enter_tree() -> void:
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.NEW_LOBBY_FEEDBACK, self)

func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.NEW_LOBBY_FEEDBACK:
			match packetIn.m_data as int:
				0: #Lobby name is taken by another lobby.
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					popUp.mInit("Lobby name is taken. Choose another name.")
					queue_free()
					get_parent().add_child(popUp)
				1: #created lobby successfully.
					var lobby : Lobby = m_lobbyScene.instantiate() as Lobby
					lobby.mInit(m_lobbyName, true)
					#Since this player created this lobby, player is the owner.
					get_parent().queue_free() #which will also queue free this node!!!!
					get_tree().root.add_child(lobby)             


func _onCancelPressed() -> void:
	queue_free()

func _onCreatePressed() -> void:
	m_createButton.disabled = true #We dont want clients to flood server with lobbyRequests.
	#It is either successfully lobby create attemp or unsuccessfull at this point.
	#Because we are sending reliable packets we wont be handling exceptions here for simplicity.
	#Todo queue free incase no reply from lobbyServer in specified seconds.

	var lobbyName : String = m_lobbyNameLineEdit.text
	var capacity : int = m_maxPlayersOptionButton.get_item_text(m_maxPlayersOptionButton.get_selected_id()) as int

	var dataToSend : Dictionary = {
		"lobbyName" : lobbyName,
		"capacity" : capacity
	}

	Client.mSendPacket(Msg.Type.NEW_LOBBY, dataToSend)
	var informationPanel : InformationPanel = m_informationPanelScene.instantiate() as InformationPanel
	informationPanel.mInit("Working on lobby request")
	m_lobbyName = m_lobbyNameLineEdit.text
	add_child(informationPanel)


func _mWaitServerFeedback(secondsToWait : int) -> void:
	await get_tree().create_timer(secondsToWait).timeout
	var popUp : PopUp = m_popUpScene.instantiate() as PopUp
	popUp.mInit("Cant create lobby. No response from server.")
	get_parent().add_child(popUp)
	queue_free()

func _onLobbyNameEditChanged(new_text:String) -> void:
	if(new_text.length() <= 0):
		m_createButton.disabled = true
	else:
		m_createButton.disabled = false


func _onLobbyNameSubmitted(_new_text:String) -> void:
	_onCreatePressed()
