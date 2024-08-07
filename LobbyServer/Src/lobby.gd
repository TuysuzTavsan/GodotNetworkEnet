extends Node
class_name Lobby

#Lobby class will hold clients and manage lobby specific features.
#Will call _process frequently. (Thats why it derives Node instead of RefCounted.)

const M_LIFE_TIME = 300 #Lobby time out value in seconds.
const MAX_CLIENTS = 4 #Lobby capacity.
var m_lifeTime : float = 0 #Lifetime in seconds since lobby created.
var m_clients : Array[Client] = []
var m_owner : Client = null
var m_name : String = ""

func _init(lobbyName : String, lobbyOwner : Client) -> void:
	Logger.mLogInfo("Created lobby: " + lobbyName)
	m_name = lobbyName
	m_owner = lobbyOwner

func _exit_tree() -> void:
	Logger.mLogInfo("Deleting Lobby: " + m_name)
	for client : Client in m_clients:
		client.mSendMsg(Msg.Type.LEFT_LOBBY)

func _process(delta: float) -> void:
	m_lifeTime += delta

	if(m_lifeTime < M_LIFE_TIME):
		queue_free()

###################################### PUBLIC FUNCTIONS ######################################

#Returns true if clients added to lobby successfully else false.
func mAddClient(client : Client) -> bool:
	if(m_clients.size() < MAX_CLIENTS):
		m_clients.push_back(client)
		Logger.mLogInfo("Added client to lobby: " + m_name)
		return true
	else:
		Logger.mLogError("Cant add client to lobby: " + m_name)
		return false