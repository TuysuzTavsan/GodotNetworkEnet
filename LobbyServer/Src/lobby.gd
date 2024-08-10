extends Node
class_name Lobby

#Lobby class will hold clients and manage lobby specific features.
#Will call _process frequently. (Thats why it derives Node instead of RefCounted.)

const M_LIFE_TIME = 300 #Lobby time out value in seconds.
var m_capacity = 4 # 4 as default.
var m_lifeTime : float = 0 #Lifetime in seconds since lobby created.
var m_clients : Array[Client] = []
var m_owner : Client = null
var m_name : String = ""
var m_isSealed : bool = false

signal _m_timeOut(lobby : Lobby)

func _init(lobbyName : String, lobbyOwner : Client, capacity : int) -> void:
	Logger.mLogInfo("Created lobby: " + lobbyName)
	m_name = lobbyName
	m_owner = lobbyOwner
	m_capacity = capacity
	m_clients.push_back(lobbyOwner)

func _exit_tree() -> void:
	Logger.mLogInfo("Deleting Lobby: " + m_name)
	for client : Client in m_clients:
		client.mSendMsg(Msg.Type.LEFT_LOBBY) #This will force clients to exit lobby.

func _process(delta: float) -> void:
	m_lifeTime += delta

	if(m_lifeTime > M_LIFE_TIME):
		_m_timeOut.emit(self)

###################################### PUBLIC FUNCTIONS ######################################

#Returns true if clients added to lobby successfully else false.
func mAddClient(client : Client) -> void:
	if(m_clients.size() < m_capacity):
		if(m_clients.size() == 0):
			var dataToSend : Dictionary = {
				"userName" : client.m_userName,
				"isHost" : true
			} 
			client.mSendMsg(Msg.Type.HOST_FEEDBACK, dataToSend)
			m_owner = client  
		m_clients.push_back(client)
		Logger.mLogInfo("Added client to lobby: " + m_name)
		client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, str(1)) #1 means success for join lobby feedback.

		var dictToSend : Dictionary = {
			"userName" : client.m_userName,
			"isHost" : false
		}

		_mBroadcastExceptSender(client, Msg.Type.JOIN_LOBBY_FEEDBACK, dictToSend)
		m_lifeTime = M_LIFE_TIME #Reset timeout value.
	else:
		Logger.mLogError("Cant add client to lobby: " + m_name)
		client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, str(2)) # 0 means capacity is full for feedback to join lobby.

func mRemoveClient(client : Client) -> void:
	if(m_clients.has(client)):
		m_clients.erase(client)

		#Change ownership of the lobby if required.
		if(client == m_owner):
			if(m_clients.size() > 0):
				m_owner = m_clients[0]
				Logger.mLogInfo("Owner of the lobby: " + m_name + " is now: " \
				+ m_owner.m_userName + ".")
				
				var sendDict : Dictionary = {
					"userName" : m_owner.m_userName,
					"isHost" : true
				}
				#Inform all players that host is changed.
				Logger.mLogInfo("Informing all players that owner of the lobby: " + m_name\
				+ " is changed.")
				_mBroadcast(Msg.Type.HOST_FEEDBACK, sendDict)
			else:
				Logger.mLogInfo("Lobby: " + m_name + " is now empty.")
				m_owner = null
		
		var dictToSend : Dictionary = {
			"userName" : client.m_userName
		}

		#Inform all players that a player left lobby.
		Logger.mLogInfo("Informing all players that client: " + client.m_userName\
		+ " left the lobby: " + m_name + ".")
		_mBroadcast(Msg.Type.LEFT_LOBBY_FEEDBACK, dictToSend) 

	else:
		Logger.mLogError("Cant find client " + client.m_userName + " to remove from lobby: "\
		+ m_name + ".")

func mProcessLobbyMessage(fromClient : Client, msg : String) -> void:

	var dictToSend : Dictionary = {
		"userName" : fromClient.m_userName,
		"msg" : msg
	}

	Logger.mLogInfo("Broadcasting msg from client: " + fromClient.m_userName\
	+ " to players in lobby: " + m_name + ".")
	_mBroadcastExceptSender(fromClient, Msg.Type.LOBBY_MESSAGE_FEEDBACK, dictToSend)

func mSendPlayerList(toClient : Client) -> void:

	var arrayToSend : Array[Dictionary] = []

	for client : Client in m_clients:
		var dictToSend = {
			"userName" : client.m_userName,
			"isHost" : client == m_owner
		}
		arrayToSend.push_back(dictToSend)
	
	Logger.mLogInfo("Sending player list in lobby: " + m_name\
	+ " to client: " + toClient.m_userName + ".")
	toClient.mSendMsg(Msg.Type.PLAYER_LIST_FEEDBACK, arrayToSend)

#Get lobby info as dictionary to send clients when they are searching lobbies.
func mGetLobbyInfo() -> Dictionary:
	var info : Dictionary = {
		"lobbyName" : m_name,
		"playerCount" : m_clients.size(),
		"capacity" : m_capacity,
		"isSealed" : m_isSealed
	}

	return info


################################## PRIVATE FUNCTIONS #############################

func _mBroadcastExceptSender(fromCLient : Client, type : Msg.Type, data) -> void:
	for client : Client in m_clients:
		if(client != fromCLient):
			client.mSendMsg(type, data)

func _mBroadcast(type : Msg.Type, data) -> void:
	for client : Client in m_clients:
		client.mSendMsg(type, data)

################################## PRIVATE FUNCTIONS #############################