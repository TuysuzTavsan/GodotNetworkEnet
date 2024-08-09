extends Control


@onready var m_lobbyListPivot : VBoxContainer = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

var m_mainMenuScene : PackedScene = load("res://Scenes/MainMenu.tscn")
var m_lobbyListItemScene : PackedScene = load("res://Scenes/LobbyListItem.tscn")
var m_createLobbyPanelScene : PackedScene = load("res://Scenes/CreateLobbyPanel.tscn")
var m_informationPanelScene : PackedScene = load("res://Scenes/InformationPanel.tscn")
var m_lobbyScene : PackedScene = load("res://Scenes/Lobby.tscn")
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")

var m_lobbyName : String = ""

signal _m_joinFeedbackReceived()

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_LIST_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.JOIN_LOBBY_FEEDBACK, self)
	Client.mSendPacket(Msg.Type.LOBBY_LIST) #Request lobby list from lobby server.

########################################## PUBLIC FUNCTIONS ##########################################

#This function will be called whenever Client singleton receives packet which msg Type matches this node subscribed to.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.LOBBY_LIST_FEEDBACK:
			_mUpdateLobbyList(packetIn.m_data)
		
		Msg.Type.JOIN_LOBBY_FEEDBACK:
			_m_joinFeedbackReceived.emit()
			match packetIn.m_data as int:
				0:
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					popUp.mInit("Cant find lobby.")
					add_child(popUp)
				1:
					var lobby : Lobby = m_lobbyScene.instantiate() as Lobby
					lobby.mInit(m_lobbyName, false)
					queue_free()
					get_parent().add_child(lobby)
				2:
					var popUp : PopUp = m_popUpScene.instantiate() as PopUp
					popUp.mInit("Lobby is full.")
					add_child(popUp)

########################################## PUBLIC FUNCTIONS ##########################################

func _mUpdateLobbyList(lobbyArr : Array) -> void:
	_mClearLobbyList()

	for lobbyDict : Dictionary in lobbyArr:
		var lobbyName : String = lobbyDict["lobbyName"] as String
		var playerCount : int = lobbyDict["playerCount"] as int
		var capacity : int = lobbyDict["capacity"] as int
		var isSealed : bool = lobbyDict["isSealed"] as bool

		var lobbyListItem : LobbyListItem = m_lobbyListItemScene.instantiate() as LobbyListItem
		lobbyListItem.mInit(lobbyName, playerCount, capacity, isSealed)
		lobbyListItem._m_JoinPressed.connect(_onJoinLobbyPressed)
		m_lobbyListPivot.add_child(lobbyListItem)

func _mClearLobbyList() -> void:
	for child in m_lobbyListPivot.get_children():
		child.queue_free()

func _onJoinLobbyPressed(lobbyListItem : LobbyListItem) -> void:
	get_tree().paused = true

	var dictToSend : Dictionary = {
		"lobbyName" : lobbyListItem.m_lobbyName
	}
	m_lobbyName = lobbyListItem.m_lobbyName

	Client.mSendPacket(Msg.Type.JOIN_LOBBY, dictToSend)
	var informatioPanel : InformationPanel = m_informationPanelScene.instantiate() as InformationPanel
	informatioPanel.mInit("Joining lobby.")
	add_child(informatioPanel)
	await  _m_joinFeedbackReceived
	informatioPanel.queue_free()
	get_tree().paused = false

func _onReturnPressed() -> void:
	var mainMenu = m_mainMenuScene.instantiate()
	queue_free()
	get_parent().add_child(mainMenu)

func _onRefreshPressed() -> void:
	Client.mSendPacket(Msg.Type.LOBBY_LIST) #Request lobby list from lobbyServer. 

func _onLobbyCreatePressed() -> void:
	var lobbyCreatePanel : CreateLobbyPanel = m_createLobbyPanelScene.instantiate() as CreateLobbyPanel
	add_child(lobbyCreatePanel)
