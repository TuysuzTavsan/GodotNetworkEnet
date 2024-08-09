extends Node
class_name Host


var m_server : ENetConnection = ENetConnection.new()
const M_MAX_CLIENTS : int = 1024
const M_MAX_CHANNELS : int = 1
const M_ADDRESS : String = "127.0.0.1"
const M_PORT : int = 9999

var m_clients : Array[Client] = []
var m_lobbies : Array[Lobby] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	m_server.create_host_bound(M_ADDRESS, M_PORT, M_MAX_CLIENTS, M_MAX_CHANNELS)
	if(m_server == null):
		Logger.mLogError("Can not create server.")
		get_tree().quit(-1)
	else:
		Logger.mLogInfo("Created server on Address: " + M_ADDRESS + " on port:" + str(M_PORT) + " with max client: " + \
		str(M_MAX_CLIENTS) + ".")

func _exit_tree() -> void:
	Logger.mLogInfo("Destroying server.")
	m_server.destroy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_mPoll()

################################# PRIVATE FUNCTIONS #########################################

func _mPoll() -> void:
	var arr : Array = m_server.service()
	# Format: EventType - ENetPacketPeer - data - channel
	
	var eventType : ENetConnection.EventType = arr[0] 
	var peer : ENetPacketPeer = arr[1]
	var _channel : int = arr[3]
	
	match eventType:	#We dont process EVENT_CONNECT because we dont want any other connection than server.
		ENetConnection.EVENT_CONNECT:
			_mAddClient(peer)
			Logger.mLogInfo("New peer connected.")

		ENetConnection.EVENT_DISCONNECT:
			Logger.mLogInfo("Peer with name: " + _mGetClient(peer).m_userName + " disconnected.")
			_mEraseClient(peer)

		ENetConnection.EVENT_ERROR:
			Logger.mLogError("Error occured in host. Aborting application.")
			get_tree().quit(-1)

		ENetConnection.EVENT_RECEIVE:
			Logger.mLogInfo("Received packet form client: " + _mGetClient(peer).m_userName + ".")
			var packetIn : PacketIn = PacketIn.new(peer.get_packet(), _mGetClient(peer))
			_mProcessPacket(packetIn)

func _mProcessPacket(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.USER_INFO:
			_mSetClientName(packetIn.m_from, packetIn.m_data)

		Msg.Type.LOBBY_LIST:
			_mSendLobbyList(packetIn.m_from)

		Msg.Type.NEW_LOBBY:
			var lobbyName : String = packetIn.m_data["lobbyName"] as String
			var capacity : int = packetIn.m_data["capacity"] as int
			_mCreateNewLobby(packetIn.m_from, lobbyName, capacity)

		Msg.Type.JOIN_LOBBY:
			var lobbyName : String = packetIn.m_data["lobbyName"] as String
			_mAddClientToLobby(packetIn.m_from, lobbyName)

		Msg.Type.LEFT_LOBBY:
			_mHandleClientLeft(packetIn.m_from)
			
		Msg.Type.LOBBY_MESSAGE:
			Logger.mLogInfo("Received lobby message request from client: " + packetIn.m_from.m_userName + ".")
			_mProcessLobbyMsgRequest(packetIn.m_from, packetIn.m_data as String)

		Msg.Type.PLAYER_LIST:
			Logger.mLogInfo("Received player list request from client: " + packetIn.m_from.m_userName + ".")
			_mProcessPlayerListRequest(packetIn.m_from)

func _mHandleClientLeft(leftClient : Client) -> void:
	Logger.mLogInfo("Received left lobby from client: " + leftClient.m_userName + ".")
	var lobby : Lobby = _mFindLobbyByClient(leftClient)
	if(lobby):
		lobby.mRemoveClient(leftClient)
	else:
		Logger.mLogError("Cant find any lobby to remove client: " + leftClient.m_userName + ".")

func _mProcessPlayerListRequest(toClient : Client) -> void:
	var lobby : Lobby = _mFindLobbyByClient(toClient)
	if(lobby):
		lobby.mSendPlayerList(toClient)
	else:
		Logger.mLogWarning("Cant find lobby which client: " + toClient.m_userName\
		+ " is in.")

func _mProcessLobbyMsgRequest(fromClient : Client, msg : String) -> void:
	var lobby : Lobby = _mFindLobbyByClient(fromClient)
	if(lobby):
		lobby.mProcessLobbyMessage(fromClient, msg)
	else:
		Logger.mLogWarning("Lobby message request is received from client: "\
		+ fromClient.m_userName + ". Cant find any lobby that has client as player.")

func _mSetClientName(client : Client, userName : String) -> void:
	Logger.mLogInfo("Received username for client: " + userName)
	client.m_userName = userName

	var dictToSend : Dictionary = {
		"userName" : userName
	}

	Logger.mLogInfo("Sending username feedback to client: " + userName)
	client.mSendMsg(Msg.Type.USER_INFO_FEEDBACK, dictToSend)

func _mSendLobbyList(client : Client) -> void:
	Logger.mLogInfo("Received lobby list request from client: " + client.m_userName)

	var lobbyList : Array = []

	for lobby : Lobby in m_lobbies:
		lobbyList.push_back(lobby.mGetLobbyInfo())
	
	Logger.mLogInfo("Sending lobby list feedback to client: " + client.m_userName)
	client.mSendMsg(Msg.Type.LOBBY_LIST_FEEDBACK, lobbyList)

func _mCreateNewLobby(ownerClient : Client, lobbyName : String, capacity : int) -> void:
	Logger.mLogInfo("Received new lobby request from client: " + ownerClient.m_userName)

	if(_mIsLobbyExist(lobbyName)):
		#Cant create new lobby with same name.
		#0 means failed to create lobby, reason: name is already taken.
		Logger.mLogInfo("New lobby request from client : + ownerClient.m_userName" \
		+ " is failed, lobby name is already taken.")
		ownerClient.mSendMsg(Msg.Type.NEW_LOBBY_FEEDBACK, str(0)) 
	else:
		var lobby : Lobby = Lobby.new(lobbyName, ownerClient, capacity)
		lobby._m_timeOut.connect(_onLobbyTimeOut)
		m_lobbies.push_back(lobby)
		add_child(lobby)
		Logger.mLogInfo("New lobby with name: " + lobbyName + " is created.")
		
		#Send user that their lobby is created.
		Logger.mLogInfo("Sending client: " + ownerClient.m_userName + "successfull new lobby feedback.")
		ownerClient.mSendMsg(Msg.Type.NEW_LOBBY_FEEDBACK, str(1)) # 1 means success for lobby created feedback.

func _mAddClientToLobby(client : Client, lobbyName : String) -> void:
	Logger.mLogInfo("Received join lobby request from client: " + client.m_userName\
	+ " to lobby: " + lobbyName + ".")
	if(not _mIsLobbyExist(lobbyName)):
		Logger.mLogInfo("Sending failed join lobby feedback to client: " + client.m_userName\
		+ " reason: Cant find any lobby that matches the requested join lobby name.")
		client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, str(0)) # 0 means cant find lobby for lobby join feedback.
	else:
		var lobby : Lobby = _mGetLobby(lobbyName)
		lobby.mAddClient(client)

func _onLobbyTimeOut(lobby : Lobby) -> void:
	Logger.mLogInfo("Lobby " + lobby.m_name + " reached its lifetime. Destroying lobby...")
	m_lobbies.erase(lobby)
	lobby.queue_free()

func _mEraseClient(packetPeer : ENetPacketPeer) -> void:
	Logger.mLogInfo("Erasing client.")
	m_clients.erase(_mGetClient(packetPeer))

func _mAddClient(packetPeer : ENetPacketPeer) -> void:
	Logger.mLogInfo("Adding new client.")
	m_clients.push_back(Client.new(packetPeer))

func _mIsLobbyExist(lobbyName : String) -> bool:	
	for lobby : Lobby in m_lobbies:
		if(lobby.m_name == lobbyName):
			return true
		
	#No lobby with lobbyName exists.
	return false

func _mFindLobbyByClient(client : Client) -> Lobby:
	for lobby : Lobby in m_lobbies:
		if(lobby.m_clients.find(client) != -1):
			return lobby

	return null

func _mGetLobby(lobbyName : String) -> Lobby:
	for lobby : Lobby in m_lobbies:
		if(lobby.m_name == lobbyName):
			return lobby
	
	#Cant find matching lobby:
	Logger.mLogError("Cant find matching lobby with name: " + lobbyName + ".")
	return null

#Get client which is mapped to packetPeer. Will return null if cant find specified client.
func _mGetClient(packetPeer : ENetPacketPeer) -> Client:
	for client : Client in m_clients:
		if(client.m_eNetPeer == packetPeer):
			return client
	
	Logger.mLogError("Can not find specified packetPeer in m_clients.")
	return null


################################# PRIVATE FUNCTIONS #########################################
