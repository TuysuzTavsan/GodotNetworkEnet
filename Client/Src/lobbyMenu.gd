extends Control


@onready var m_lobbyListPivot : VBoxContainer = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/VScrollBar/LobbyListPivot

var m_mainMenuScene : PackedScene = load("res://Scenes/MainMenu.tscn")
var m_lobbyListItemScene : PackedScene = load("res://Scenes/LobbyListItem.tscn")
var m_createLobbyPanelScene : PackedScene = load("res://Scenes/CreateLobbyPanel.tscn")

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_LIST, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.NEW_LOBBY, self)
	Client.mSendPacket(Msg.Type.LOBBY_LIST) #Request lobby list from lobby server.

########################################## PUBLIC FUNCTIONS ##########################################

#This function will be called whenever Client singleton receives packet which msg Type matches this node subscribed to.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.LOBBY_LIST:
			_mUpdateLobbyList(packetIn.m_data)

		Msg.Type.NEW_LOBBY:
			pass

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
	pass

func _onReturnPressed() -> void:
	var mainMenu = m_mainMenuScene.instantiate()
	queue_free()
	get_parent().add_child(mainMenu)

func _onRefreshPressed() -> void:
	Client.mSendPacket(Msg.Type.LOBBY_LIST) #Request lobby list from lobbyServer. 

func _onLobbyCreatePressed() -> void:
	var lobbyCreatePanel = m_createLobbyPanelScene.instantiate()
	add_child(lobbyCreatePanel)