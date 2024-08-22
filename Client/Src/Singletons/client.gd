extends Node

#Client Singleton that will connect to server and manage network related events.
#Will handle packets via m_packetHandler and m_packetDispatcher.

const m_PORT : int = 9999
const m_ADRESS : String = "5.180.106.157"
const m_CHANNELS : int = 2
const m_MAX_CONNECTIONS : int = 1
const m_TIME_OUTSEC : int = 10

var m_client : ENetConnection = ENetConnection.new() #Self
var m_server : ENetPacketPeer = null #Connection object on ENet
var m_peerID : int = -1 #Id of this cliebt
var m_packetHandler : PacketHandler = PacketHandler.new()
var m_userName : String = "DefaultUserName"

signal _m_connected()
signal _m_connection_error()
signal _m_disconnected()

func _ready() -> void:
	#This is the only msgType Client will listen to. All other msg types will be listened from menus.
	m_packetHandler.mSubscribe(Msg.Type.USER_INFO_FEEDBACK, self)

	#Scenes often call pause to control msg flow to server. 
	#We dont want network to pause.
	process_mode = Node.PROCESS_MODE_ALWAYS 

	var error : Error = m_client.create_host(m_MAX_CONNECTIONS, m_CHANNELS)
	if(error == OK):
		Logger.mLogInfo("Created client successfully.")
	else:
		Logger.mLogError("Creating client failed! Code: " + str(error))
		get_tree().quit(-1)

func _exit_tree() -> void:
	Logger.mLogInfo("Destroying client.")
	if(m_client):
		m_client.destroy()

func _process(_delta):
	_mPoll()

###################################### PUBLIC FUNCTIONS START #####################################

#Generic mHandle function that will be called by m_packetHandler : PacketHandler,
# whenever a msg of type whic is subscribed to is received.
func mHandle(packetIn : PacketIn) -> void:
	match packetIn.m_msgType:
		Msg.Type.USER_INFO_FEEDBACK:
			Logger.mLogInfo("Username feedback received from server.")
			Logger.mLogInfo("Setting username to: " + (packetIn.m_data["userName"] as String))
			m_userName = packetIn.m_data["userName"] as String

#Disconnect client and create host to refresh its state
func mDisconnect() -> void:
	m_server = null
	m_client.destroy()

	_ready()

#This is a coroutine and must be called with await. True if connection attemp succeeds.
func mConnectServer() -> bool:
	m_server = m_client.connect_to_host(m_ADRESS, m_PORT, m_CHANNELS)

	var state : ENetPacketPeer.PeerState = await _mPollConnectionStatus(m_server, m_TIME_OUTSEC)

	if(state == ENetPacketPeer.STATE_CONNECTED):
		_m_connected.emit()
		return true
	else:
		return false

#Check if the client is connected to server.
func mIsConnected() -> bool:
	if(m_server):
		return m_server.get_state() == ENetPacketPeer.STATE_CONNECTED
	else:
		return false

#Get connectionState of the server connection. Will return disconnected if there isnt any connection or attempt.
func mGetConnectionState() -> ENetPacketPeer.PeerState:
	if(m_server):
		return m_server.get_state()
	else:
		return ENetPacketPeer.STATE_DISCONNECTED

func mSendPacket(msgType : Msg.Type, data = str(0)) -> void:

	var dictToSend : Dictionary = {
		"protocol" : msgType,
		"data" : data,
	}

	var result : int = m_server.send(0, JSON.stringify(dictToSend).to_utf8_buffer(), ENetPacketPeer.FLAG_RELIABLE)

	if(result == 0):
		Logger.mLogInfo("Packet sent successfully to server.")
	else:
		Logger.mLogError("Cant send packet to server.")

###################################### PUBLIC FUNCTIONS END #######################################

###################################### PRIVATE FUNCTIONS START ####################################


func _mPoll() -> void:
	var arr : Array = m_client.service()
	# Format: EventType - ENetPacketPeer - data - channel
	
	var eventType : ENetConnection.EventType = arr[0] 
	var peer : ENetPacketPeer = arr[1]
	var _channel : int = arr[3]
	
	match eventType:	#We dont process EVENT_CONNECT because we dont want any other connection than server.
		m_client.EVENT_DISCONNECT:
			_m_disconnected.emit()
			mDisconnect() #Will also set m_server to null which is usefull.
			_mReturnToMainMenuWithPopUp()
			
		m_client.EVENT_ERROR:
			Logger.mLogError("Error occured in Enet connection. Aborting application.")
			get_tree().quit(-1)

		m_client.EVENT_RECEIVE:
			var packet : PacketIn = PacketIn.new(peer.get_packet())
			m_packetHandler.mForwardPacket(packet)


#Poll a fresh connection attemp to server.
func _mPollConnectionStatus(connection : ENetPacketPeer, seconds : int) -> ENetPacketPeer.PeerState:
	var state : ENetPacketPeer.PeerState

	for second : int in range(0, seconds + 1, 1):
		await get_tree().create_timer(1).timeout
		if(connection):
			state = connection.get_state()
		else:
			return ENetPacketPeer.STATE_DISCONNECTED

		if(state == ENetPacketPeer.STATE_CONNECTED or state == ENetPacketPeer.STATE_DISCONNECTED):
			return state
	
	return state

func _mReturnToMainMenuWithPopUp(msgToShow : String = "Disconnected") -> void:
	for child in get_tree().root.get_children(): #Clean every node.
	
		#No need to return to main menu if client is in game.
		if(child is Battlefield):
			return

		if(child != self and child != MusicPlayer):
			child.queue_free()

	var mainMenu = load("res://Scenes/MainMenu.tscn").instantiate()
	var popUp : PopUp = load("res://Scenes/PopUp.tscn").instantiate() as PopUp
	popUp.mInit(msgToShow)
	get_tree().root.add_child(mainMenu)
	mainMenu.add_child(popUp)


###################################### PRIVATE FUNCTIONS END ######################################
