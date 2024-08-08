extends Node
class_name Host


var m_server : ENetConnection = ENetConnection.new()
const M_MAX_CLIENTS : int = 1024
const M_MAX_CHANNELS : int = 1
const M_ADDRESS : String = "127.0.0.1"
const M_PORT : int = 9999

var m_clients : Array[Client] = []


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
			Logger.mLogInfo("Received packet form client: " + _mGetClient(peer).m_name + ".")
			var packetIn : PacketIn = PacketIn.new(peer.get_packet(), _mGetClient(peer))
			_mProcessPakcet(packetIn)



func _mProcessPakcet(packetIn : PacketIn) -> void:
	pass



func _mEraseClient(packetPeer : ENetPacketPeer) -> void:
	Logger.mLogInfo("Erasing client.")
	m_clients.erase(_mGetClient(packetPeer))

func _mAddClient(packetPeer : ENetPacketPeer) -> void:
	Logger.mLogInfo("Adding new client.")
	m_clients.push_back(Client.new(packetPeer))

#Get client which is mapped to packetPeer. Will return null if cant find specified client.
func _mGetClient(packetPeer : ENetPacketPeer) -> Client:
	for client : Client in m_clients:
		if(client.m_eNetPeer == packetPeer):
			return client
	
	Logger.mLogError("Can not find specified packetPeer in m_clients.")
	return null


################################# PRIVATE FUNCTIONS #########################################
