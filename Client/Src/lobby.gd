extends Control

@onready var m_chatLineEdit : LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/ChatLineEdit
@onready var m_sendButton : Button = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/SendButton
@onready var m_playerListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/ScrollContainer/PlayersPivot
@onready var m_chatListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/ChatPivot
@onready var m_lobbyNameLabel : Label = $MarginContainer/VBoxContainer/MarginContainer/LobbyNameLabel

var m_lobbyMenuScene : PackedScene = load("res://Scenes/lobbyMenu.tscn")
var m_playerListItemScene : PackedScene = load("res://Scenes/PlayerListItem.tscn")
var m_chatItemScene : PackedScene = load("res://Scenes/ChatItem.tscn")

var m_lobbyName : String = "DefaultLobbyName"
var m_isHost : bool = false

func mInit(lobbyName : String, isHost : bool) -> void:
	m_lobbyName = lobbyName
	m_isHost = isHost

func _ready() -> void:
	m_lobbyNameLabel.text = m_lobbyName
	_mAddPlayer(Client.m_userName, m_isHost)

	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_MESSAGE, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.JOIN_LOBBY, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LEFT_LOBBY, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.HOST, self)


########################################### PUBLIC FUNCTIONS ################################################

func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.LOBBY_MESSAGE:
			var fromPlayerName : String = packetIn.m_data["playerName"] as String
			var msg : String = packetIn.m_data["msg"] as String

			_mAddMsgFromPlayer(fromPlayerName, msg)

		Msg.Type.LEFT_LOBBY:
			
			_mRemovePlayer(packetIn.m_data["playerName"] as String)

		Msg.Type.JOIN_LOBBY:
			
			_mAddPlayer(packetIn.m_data["playerName"] as String, packetIn.m_data["isHost"] as bool)

		Msg.Type.HOST:
			pass

########################################### PUBLIC FUNCTIONS ################################################

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
	get_parent().add_child(lobbyMenu)
	queue_free()

func _onChatSubmitted(new_text:String) -> void:
	_mSendChatMessage(new_text)

func _onChatLineEditChanged(new_text:String) -> void:
	if(new_text.length() >= 0 ):
		m_sendButton.disabled = false
	else:
		m_sendButton.disabled = true

func _onSendPressed() -> void:
	_mSendChatMessage(m_chatLineEdit.text)
	m_chatLineEdit.text = ""

func _mSendChatMessage(msg : String) -> void:
	Client.mSendPacket(Msg.Type.LOBBY_MESSAGE, msg)