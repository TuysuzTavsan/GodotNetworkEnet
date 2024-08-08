extends Control

var m_mainMenuScene : PackedScene = load("res://Scenes/MainMenu.tscn")

func _ready() -> void:
	Client.m_packetHandler.mSubscribe(Msg.Type.LOBBY_LIST, self)
	Client.m_packetHandler.mSubscribe(Msg.Type.NEW_LOBBY, self)

########################################## PUBLIC FUNCTIONS ##########################################

#This function will be called whenever Client singleton receives packet which msg Type matches this node subscribed to.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.LOBBY_LIST:
			pass
		Msg.Type.NEW_LOBBY:
			pass

########################################## PUBLIC FUNCTIONS ##########################################

func _onReturnPressed() -> void:
	var mainMenu = m_mainMenuScene.instantiate()
	queue_free()
	get_parent().add_child(mainMenu)

func _onRefreshPressed() -> void:
	Client.mSendPacket(Msg.Type.LOBBY_LIST) #Request lobby list from lobbyServer. 

func _onLobbyCreatePressed() -> void:
	pass