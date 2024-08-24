extends Control
class_name Lobby

@onready var m_chatLineEdit : LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/ChatLineEdit
@onready var m_sendButton : Button = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/SendButton
@onready var m_playerListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/ScrollContainer/PlayersPivot
@onready var m_chatListPivot : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/ChatPivot
@onready var m_lobbyNameLabel : Label = $MarginContainer/VBoxContainer/MarginContainer/LobbyNameLabel
@onready var m_startButton : Button = $MarginContainer/VBoxContainer/HBoxContainer2/StartButton
@onready var m_chatScrollContainer : ScrollContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer

var m_lobbyMenuScene : PackedScene = load("res://Scenes/lobbyMenu.tscn")
var m_playerListItemScene : PackedScene = load("res://Scenes/PlayerListItem.tscn")
var m_chatItemScene : PackedScene = load("res://Scenes/ChatItem.tscn")
var m_popUpScene : PackedScene = load("res://Scenes/PopUp.tscn")
var m_gameStartPanelScene : PackedScene = load("res://Scenes/GameStartingPanel.tscn")

var m_lobbyName : String = "DefaultLobbyName"
var m_isHost : bool = false

func mInit(lobbyName : String, isHost : bool) -> void:
	m_lobbyName = lobbyName
	m_isHost = isHost

func _ready() -> void:
	m_lobbyNameLabel.text = m_lobbyName
	_mAddPlayer(Client.m_userName, m_isHost, false)

	Client.m_packetHandler.mSubscribe(Msg.Type.PLAYER_LIST_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_MESSAGE_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.JOIN_LOBBY_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LEFT_LOBBY_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.START_GAME, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.READY_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.HOST_FEEDBACK, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.LEFT_LOBBY, self)

	#Request player list from server.
	Client.mSendPacket(Msg.Type.PLAYER_LIST)
	

########################################### PUBLIC FUNCTIONS ################################################

#Called whenever subscribed packet type is received.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.READY_FEEDBACK:
			_mUpdatePlayerReadyStatus(packetIn.m_data["userName"] as String, packetIn.m_data["isReady"] as bool)

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
			_mAddPlayer(packetIn.m_data["userName"] as String, false, false) 

		Msg.Type.HOST_FEEDBACK:
			#Means we are the host now.
			var playerName : String = packetIn.m_data["userName"] as String
			_mUpdateLobbyOwnership(playerName)
			_mChangeLobbyOwner(playerName)

		Msg.Type.START_GAME:
			#Means we need to instantiate gameStart panel.
			var gameStartPanel : GameStartingPanel = m_gameStartPanelScene.instantiate() as GameStartingPanel
			#Instantiate panel as regular player, not lobby owner.
			gameStartPanel.mInit(false, packetIn.m_data["inSeconds"] as float)
			add_child(gameStartPanel)
			


########################################### PUBLIC FUNCTIONS ################################################

func _mUpdatePlayerReadyStatus(playerName : String, isReady : bool) -> void:
	for playerListItem : PlayerListItem in m_playerListPivot.get_children():
		if(playerListItem.m_playerName == playerName):
			playerListItem.mUpdateReadyState(isReady)
			break
	
	_mUpdateCanGameStart()

func _mUpdateCanGameStart() -> void:
	if(not m_isHost):
		m_startButton.disabled = true
	else:
		var canStart : bool = true
		for playerListItem : PlayerListItem in m_playerListPivot.get_children():
			if(playerListItem.m_isReady == false):
				canStart = false
				break
		
		m_startButton.disabled = not canStart


func _mUpdateLobbyOwnership(newOwnerName : String) -> void:
	if(Client.m_userName == newOwnerName):
		m_isHost = true
		_mUpdateCanGameStart()

func _mChangeLobbyOwner(ownerName : String) -> void:
	if(Client.m_userName == ownerName):
		m_isHost = true
	
	for playerListItem : PlayerListItem in m_playerListPivot.get_children():
		if(playerListItem.m_playerName == ownerName):
			playerListItem.mUpdateLobbyOwnership(true)
		else:
			playerListItem.mUpdateLobbyOwnership(false)

	_mShowChatMsg(ownerName + " is the new lobby owner.")
	_mUpdateCanGameStart()


func _mUpdatePlayerList(playerArray : Array) -> void:
	_mClearPlayerList()
	for playerDict : Dictionary in playerArray:
		var playerName : String = playerDict["userName"] as String
		var isHost : bool = playerDict["isHost"] as bool
		var isReady : bool = playerDict["isReady"] as bool
		_mAddPlayer(playerName, isHost, isReady)

func _mAddMsgFromPlayer(playerName : String, msg : String) -> void:
	var chatItem : ChatItem = m_chatItemScene.instantiate() as ChatItem
	chatItem.mInit(playerName + ": " + msg) 
	m_chatListPivot.add_child(chatItem)

	#I dont know why, but 1 line of this wont work sometimes lol.
	await get_tree().process_frame
	await get_tree().process_frame

	m_chatScrollContainer.ensure_control_visible(chatItem)

func _mShowChatMsg(msg : String) -> void:
	var chatItem : ChatItem = m_chatItemScene.instantiate() as ChatItem
	chatItem.mInit(msg) 
	m_chatListPivot.add_child(chatItem)

	#I dont know why, but 1 line of this wont work sometimes lol.
	await get_tree().process_frame
	await get_tree().process_frame

	m_chatScrollContainer.ensure_control_visible(chatItem)


func _mAddPlayer(playerName : String, isHost : bool, isReady : bool) -> void:
	var playerListItem : PlayerListItem = m_playerListItemScene.instantiate() as PlayerListItem
	playerListItem.mInit(playerName, isHost, isReady)
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

func _onStartGamePressed() -> void:
	#gameStartingPanel will handle everything from here.
	var gameStartPanel : GameStartingPanel = m_gameStartPanelScene.instantiate() as GameStartingPanel
	gameStartPanel.mInit(true)
	add_child(gameStartPanel)
