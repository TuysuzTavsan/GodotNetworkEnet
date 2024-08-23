extends Node
class_name Lobby

#Lobby class will hold clients and manage lobby specific features.
#Lobby creation and deletion is under control of the Host.
#Lobbies will only emmit their deletion by _m_timeOut, host will destroy it.
#Everytime a client creates lobby, Host will create lobby and add this node as child. Host will also keep a reference to this node in Host.m_lobbies.
#Also check the timer nodes and their settings in Lobby.tscn to fully understand how it operates.

var m_clients : Array[Client] = [] #Clients that are in this lobby.
var m_owner : Client = null # Owner of this lobby. By Default it is the client who created this.
var m_name : String = "" # Name of this lobby.
var m_capacity = -1 # Capacity of this lobby.
var m_isSealed : bool = false #If its sealed it means players are in game and game is already started.
const M_TIMEOUT_SECS : int = 300 #Time value in seconds which this lobby will be destroyed upon timeOut. Needed when no player left in this lobby.
const M_GAMESERVER_LAUNCH_SECS : int = 5 #Time value in seconds which this lobby will launch game server upon timeOut.

@onready var m_lobbyTimer : Timer = $LobbyTimer #Fired when no player left in this lobby. Only resetted when a new client joins. Upon timeout this node will emmit _m_timeOut.
@onready var m_gameServerLaunchTimer : Timer = $GameServerLaunchTimer #Fired when owner client requests start game. on Timeout will launch dedicated server.

signal _m_timeOut(lobby : Lobby) #Signal to host, meaning this lobby is idle for some time and it can be freed.

#Every lobby needs a name, owner and capacity parameters set.
func mInit(lobbyName : String, lobbyOwner : Client, capacity : int) -> void:
	Logger.mLogInfo("Created lobby: " + lobbyName)
	m_name = lobbyName
	m_owner = lobbyOwner
	m_capacity = capacity
	m_clients.push_back(lobbyOwner)

#Upon exiting tree order every client to leave lobby.
func _exit_tree() -> void:
	Logger.mLogInfo("Deleting Lobby: " + m_name)
	for client : Client in m_clients:
		#Force clients to exit lobby.
		client.mSendMsg(Msg.Type.LEFT_LOBBY) 

###################################### PUBLIC FUNCTIONS ######################################

#Add a client to this lobby.
func mAddClient(client : Client) -> void:
	if(m_isSealed):
		Logger.mLogInfo("Cant add client: " + client.m_userName + " to sealed lobby: " + m_name + ".") 
		client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, 3) #3 means lobby is sealed.
		return

	if(m_clients.size() < m_capacity):

		#1 means success for join lobby feedback.
		client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, 1) 
		Logger.mLogInfo("Added client to lobby: " + m_name)
		client.m_isReady = false
		m_clients.push_back(client)

		#If the size is 1, joined client needs to be informed that its the lobby owner now.
		if(m_clients.size() == 1):
			#Make client owner of this lobby.
			client.mSendMsg(Msg.Type.HOST_FEEDBACK, {
				"userName" : client.m_userName,
				"isHost" : true
			})
			m_owner = client

			#Also stop the timeOut timer since there is a player in this lobby now.
			m_lobbyTimer.stop()
			return

		#Inform other players that a client just joined.
		_mBroadcastExceptSender(client, Msg.Type.JOIN_LOBBY_FEEDBACK, {
			"userName" : client.m_userName,
			"isHost" : false
		})

		return
	
	#Capacity is full
	#Inform player that capacity is full. (Code 2 means full capacity)
	Logger.mLogWarning("Lobby " + m_name + " is full. Sending feedback to client: " + client.m_userName + ".")
	client.mSendMsg(Msg.Type.JOIN_LOBBY_FEEDBACK, 2)

#Remove client from this lobby.
#Since Host will call this function only if this lobby has this client, we dont need to check for it.
func mRemoveClient(client : Client) -> void:
	_mCancelGameLaunchIfNeeded()

	#Erase and inform all players that a player left lobby.
	m_clients.erase(client)
	Logger.mLogInfo("Informing all players that client: " + client.m_userName\
		+ " left the lobby: " + m_name + ".")

	_mBroadcast(Msg.Type.LEFT_LOBBY_FEEDBACK, {
		"userName" : client.m_userName
	})

	#Change ownership of the lobby if required.
	if(client == m_owner):
		if(m_clients.size() > 0):
			m_owner = m_clients[0]
			Logger.mLogInfo("Owner of the lobby: " + m_name + " is now: " \
			+ m_owner.m_userName + ".")
			
			#Inform all players that host is changed.
			Logger.mLogInfo("Informing all players that owner of the lobby: " + m_name\
				+ " is changed.")
			_mBroadcast(Msg.Type.HOST_FEEDBACK, {
				"userName" : m_owner.m_userName,
				"isHost" : true
			})

		else:
			#No player exists in this lobby. Start the timeOut timer now.
			m_lobbyTimer.start(M_TIMEOUT_SECS)
			Logger.mLogInfo("Lobby: " + m_name + " is now empty.")
			m_owner = null

#Start the timer for the gameServerLaunch. Upon timeout it will handle sending GAME_START_FEEDBACK to clients.
func mStartGame(client : Client) -> void:
	if(m_isSealed):
		Logger.mLogError("Client: " + client.m_userName + " requested start game on lobby: " + m_name \
			+ "But its already sealed.")

		#Since this situation is not something we except to happen. We will ignore it.
		#Client will not check for this action anyway.
		#Its more like a protection.
		return

	if(client != m_owner):
		Logger.mLogError("Client: " + client.m_userName + " requested start game on lobby: " + m_name \
			+ "But its not the owner.")

		#Since this situation is not something we except to happen. We will ignore it.
		#Because we are sure clients cant send this request when they are not the owner.
		#Client will not check for this action anyway.
		#Its more like a protection.
		return
	
	Logger.mLogInfo("Lobby: " + m_name + " is starting launch process.")
	m_gameServerLaunchTimer.start(M_GAMESERVER_LAUNCH_SECS)
	m_isSealed = true

	#Send owner feedback.
	m_owner.mSendMsg(Msg.Type.START_GAME_FEEDBACK, {
		"code" : 3,
		"inSeconds" : m_gameServerLaunchTimer.time_left as float
	})

	#Send everyone except owner start game order.
	_mBroadcastExceptSender(m_owner, Msg.Type.START_GAME, {
		"inSeconds" : m_gameServerLaunchTimer.time_left as float,
	})

#Update client ready status and inform other players.
func mSetClientReadyStatus(client : Client, isReady : bool) -> void:
	#Cancel the game launch if its not ready
	if(not isReady):
		_mCancelGameLaunchIfNeeded()

	client.m_isReady = isReady

	_mBroadcast(Msg.Type.READY_FEEDBACK, {
		"userName" : client.m_userName,
		"isReady" : client.m_isReady
	})

#Broadcast the lobby msg to other clients in the lobby.
func mInputLobbyMessage(fromClient : Client, msg : String) -> void:
	#Log and broadcast lobby msg.
	Logger.mLogInfo("Broadcasting msg from client: " + fromClient.m_userName\
		+ " to players in lobby: " + m_name + ".")

	_mBroadcastExceptSender(fromClient, Msg.Type.LOBBY_MESSAGE_FEEDBACK, {
		"userName" : fromClient.m_userName,
		"msg" : msg
	})

#Send playerlist to client which requested.
func mSendPlayerList(toClient : Client) -> void:

	#Prepare player list.
	var arrayToSend : Array[Dictionary] = []
	for client : Client in m_clients:
		var dictToSend = {
			"userName" : client.m_userName,
			"isHost" : client == m_owner,
			"isReady" : client.m_isReady
		}
		arrayToSend.push_back(dictToSend)
	
	Logger.mLogInfo("Sending player list in lobby: " + m_name\
		+ " to client: " + toClient.m_userName + ".")

	#Send player list to client which requested.
	toClient.mSendMsg(Msg.Type.PLAYER_LIST_FEEDBACK, arrayToSend)

#Get lobby info as dictionary.
#Helper function to send lobbyList when clients are searching lobbies.
func mGetLobbyInfo() -> Dictionary:

	var info : Dictionary = {
		"lobbyName" : m_name,
		"playerCount" : m_clients.size(),
		"capacity" : m_capacity,
		"isSealed" : m_isSealed
	}

	return info


################################## PRIVATE FUNCTIONS #############################

#Cancel the gameLaunch if it is in process.
func _mCancelGameLaunchIfNeeded() -> void:
	if(m_isSealed):
		Logger.mLogInfo("Cancelling game launch process in lobby: " + m_name + ".")
		m_isSealed = false
		m_gameServerLaunchTimer.stop()
		_mBroadcast(Msg.Type.START_GAME_FEEDBACK, {
			"code" : 0, #0 means something interrupted the launch process.
			"port": 0,
			"inSeconds": 0
		})

func _mBroadcastExceptSender(fromCLient : Client, type : Msg.Type, data) -> void:
	for client : Client in m_clients:
		if(client != fromCLient):
			client.mSendMsg(type, data)

func _mBroadcast(type : Msg.Type, data) -> void:
	for client : Client in m_clients:
		client.mSendMsg(type, data)

################################## PRIVATE FUNCTIONS #############################

func _onGameServerLaunchTimer() -> void:
		
	var port : int = get_parent()._mGetAvailableRandomPort() as int

	if(port == -1):
		_mBroadcast(Msg.Type.START_GAME_FEEDBACK, {
			"code" : 2,
		})
		m_isSealed = false
		return
	
	Logger.mLogInfo("Launching game server for lobby: " + m_name + " on port: " \
		+ str(port) + " .")


	var packedStr = PackedStringArray(["--headless", "--", "--address=" + get_parent().M_ADDRESS, "--port=" + str(port), "--playerCount=" + str(m_capacity)])

	
	if(OS.create_process("C:\\Users\\Victus\\Desktop\\server\\gameServer.exe", packedStr, true) != -1):
		_mBroadcast(Msg.Type.START_GAME_FEEDBACK, {
			"code" : 1,
			"port" : port,
		})
	else:
		_mBroadcast(Msg.Type.START_GAME_FEEDBACK, {
			"code" : 2,
		})
		m_isSealed = false
	
	await get_tree().create_timer(10).timeout
	for client : Client in m_clients:
		client.m_eNetPeer.peer_disconnect_later()
	
	_m_timeOut.emit(self)



func _onLobbyTimeout() -> void:
	_m_timeOut.emit(self)
