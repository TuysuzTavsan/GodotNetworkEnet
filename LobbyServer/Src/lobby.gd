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

func _exit_tree() -> void:
	Logger.mLogInfo("Deleting Lobby: " + m_name)
	for client : Client in m_clients:
		client.mSendMsg(Msg.Type.LEFT_LOBBY, str(3)) # 3 Means timeout for lobby as a feedback to client.

func _process(delta: float) -> void:
	m_lifeTime += delta

	if(m_lifeTime > M_LIFE_TIME):
		_m_timeOut.emit(self)

###################################### PUBLIC FUNCTIONS ######################################

#Returns true if clients added to lobby successfully else false.
func mAddClient(client : Client) -> void:
	if(m_clients.size() < m_capacity):
		m_clients.push_back(client)
		Logger.mLogInfo("Added client to lobby: " + m_name)
		client.mSendMsg(Msg.Type.JOIN_LOBBY, str(1)) #1 means success for join lobby feedback.
	else:
		Logger.mLogError("Cant add client to lobby: " + m_name)
		client.mSendMsg(Msg.Type.JOIN_LOBBY, str(2)) # 0 means capacity is full for feedback to join lobby.

func mRemoveClient(client : Client) -> void:
	if(m_clients.has(client)):
		m_clients.erase(client)
		client.mSendMsg(Msg.Type.LEFT_LOBBY, str(1)) # 1 means successfully left lobby for client.
		#client doesnt really need to check for left lobby messsage. But we will send it anyway.
	else:
		Logger.mLogError("Cant find client " + client.m_userName + " to remove from lobby.")

func mProcessLobbyMessage(fromClient : Client, msg : String) -> void:

	var dictToSend : Dictionary = {
		"userName" : fromClient.m_userName,
		"msg" : msg
	}

	_mBroadcastExceptSender(fromClient, Msg.Type.LOBBY_MESSAGE, dictToSend)

#Get lobby info as dictionary to send clients when they are searching lobbies.
func mGetLobbyInfo() -> Dictionary:
	var info : Dictionary = {
		"lobbyName" : m_name,
		"playerCount" : str(m_clients.size()),
		"capacity" : str(m_capacity),
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