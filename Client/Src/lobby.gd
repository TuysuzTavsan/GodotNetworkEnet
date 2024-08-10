extends Control
class_name Lobby

@onready var m_chatLineEdit : LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/ChatLineEdit
@onready var m_sendButton : Button = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/SendButton
@onready var m_playerListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/ScrollContainer/PlayersPivot
@onready var m_chatListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/ChatPivot
@onready var m_lobbyNameLabel : Label = $MarginContainer/VBoxContainer/MarginContainer/LobbyNameLabel

var m_lobbyMenuScene : PackedScene = load("res://Scenes/lobbyMenu.tscn")
var m_playerListItemScene : PackedScene = load("res://Scenes/PlayerListItem.tscn")
var m_chatItemScene : PackedScene = load("res://Scenes/ChatItem.tscn")
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")

var m_lobbyName : String = "DefaultLobbyName"
var m_isHost : bool = false

func mInit(lobbyName : String, isHost : bool) -> void:
	m_lobbyName = lobbyName
	m_isHost = isHost

func _ready() -> void:
	m_lobbyNameLabel.text = m_lobbyName
	_mAddPlayer(Client.m_userName, m_isHost)

	Client.m_packetHandler.mSubscribe(Msg.Type.PLAYER_LIST_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_MESSAGE_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.JOIN_LOBBY_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LEFT_LOBBY_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.HOST_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LEFT_LOBBY, self)

	#Request player list from server.
	Client.mSendPacket(Msg.Type.PLAYER_LIST) 
	

########################################### PUBLIC FUNCTIONS ################################################

func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.PLAYER_LIST_FEEDBACK:
			_mUpdatePlayerList(packetIn.m_data as Array)

		Msg.Type.LOBBY_MESSAGE_FEEDBACK:
			_mAddMsgFromPlayer(packetIn.m_data["userName"] as String, packetIn.m_data["msg"] as String)

		Msg.Type.LEFT_LOBBY_FEEDBACK:
			
			_mRemovePlayer(packetIn.m_data["userName"] as String)

		Msg.Type.LEFT_LOBBY:
			var lobbyMenu = m_lobbyMenuScene.instantiate()
			var popUp : PopUp = m_popUpScene.instantiate() as PopUp
			popUp.mInit("Lobby timeOut.")
			queue_free()
			get_parent().add_child(lobbyMenu)
			lobbyMenu.add_child(popUp)
 
		Msg.Type.JOIN_LOBBY_FEEDBACK:

			#Since it is new joined player its not owner of the lobby.
			_mAddPlayer(packetIn.m_data["userName"] as String, false) 

		Msg.Type.HOST_FEEDBACK:
			#Means we are the host now.
			var playerName : String = packetIn.m_data["userName"] as String
			_mUpdateLobbyOwnership(playerName)
			_mChangeLobbyOwner(playerName)
			


########################################### PUBLIC FUNCTIONS ################################################

func _mUpdateLobbyOwnership(newOwnerName : String) -> void:
	if(Client.m_userName == newOwnerName):
		pass
		#TODO update lobby owner specific buttons on the ui.

func _mChangeLobbyOwner(ownerName : String) -> void:
	if(Client.m_userName == ownerName):
		m_isHost = true
	
	for playerListItem : PlayerListItem in m_playerListPivot.get_children():
		if(playerListItem.m_playerName == ownerName):
			playerListItem.mUpdateLobbyOwnership(true)
		else:
			playerListItem.mUpdateLobbyOwnership(false)

	_mShowChatMsg(ownerName + " is the new lobby owner.")


func _mUpdatePlayerList(playerArray : Array) -> void:
	_mClearPlayerList()
	for playerDict : Dictionary in playerArray:
		var playerName : String = playerDict["userName"] as String
		var isHost : bool = playerDict["isHost"] as bool
		_mAddPlayer(playerName, isHost)

func _mAddMsgFromPlayer(playerName : String, msg : String) -> void:
	var chatItem : ChatItem = m_chatItemScene.instantiate() as ChatItem
	chatItem.mInit(playerName + ": " + msg) 
	m_chatListPivot.add_child(chatItem)
 
func _mShowChatMsg(msg : String) -> void:
	var chatItem : ChatItem = m_chatItemScene.instantiate() as ChatItem
	chatItem.mInit(msg) 
	m_chatListPivot.add_child(chatItem)

func _mAddPlayer(playerName : String, isHost : bool) -> void:
	var playerListItem : PlayerListItem = m_playerListItemScene.instantiate() as PlayerListItem
	playerListItem.mInit(playerName, isHost)
	m_playerListPivot.add_child(playerListItem)
	_mShowChatMsg(playerName + " is joined.")

func _mRemovePlayer(playerName : String) -> void:
	for playerListItem : PlayerListItem in m_playerListPivot.get_children():
		if(playerListItem.m_playerName == playerName):
			playerListItem.queue_free()
			_mShowChatMsg(playerName + " left lobby.")
			break

func _mClearPlayerList() -> void:
	for child in m_playerListPivot.get_children():
		child.queue_free()


func _onReturnPressed() -> void:
	var lobbyMenu = m_lobbyMenuScene.instantiate()
	Client.mSendPacket(Msg.Type.LEFT_LOBBY)
	get_parent().add_child(lobbyMenu)
	queue_free()

func _onChatSubmitted(new_text:String) -> void:
	m_chatLineEdit.text = ""
	_mShowChatMsg(Client.m_userName + ": " + new_text)
	_mSendChatMessage(new_text)

func _onChatLineEditChanged(new_text:String) -> void:
	if(new_text.length() >= 0 ):
		m_sendButton.disabled = false
	else:
		m_sendButton.disabled = true

func _onSendPressed() -> void:
	_mShowChatMsg(Client.m_userName + ": " + m_chatLineEdit.text)
	m_chatLineEdit.text = ""
	_mSendChatMessage(m_chatLineEdit.text)

func _mSendChatMessage(msg : String) -> void:
	Client.mSendPacket(Msg.Type.LOBBY_MESSAGE, msg)
