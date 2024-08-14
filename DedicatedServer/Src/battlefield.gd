extends Node
class_name Battlefield

#Singleton class that will manage important networking features.

const M_MAX_CLIENTS : int = 8
const M_MAX_CHANNELS : int = 2
var m_clientCount : int = -1
var m_clients = []

func _ready() -> void:
	# var args : Dictionary = _mFetchArguments()
	# _mCreateServer(args)

	# #Store client count.
	# m_clientCount = args.get("playerCount") as int
	
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip("127.0.0.1")
	var result = peer.create_server(9999, M_MAX_CHANNELS, M_MAX_CHANNELS)
	if(result != OK):
		Logger.mLogError("Cant create server on address: " + "127.0.0.1" + ":" + str(9999)\
			+ " aborting application.")
	
	Logger.mLogInfo("Created server on address: " + "127.0.0.1" + ":" + str(9999) + ".")
	#Set multiplayer peer
	multiplayer.multiplayer_peer = peer
	
	#bind signals.
	multiplayer.peer_connected.connect(_onPeerConnected)
	multiplayer.peer_disconnected.connect(_onPeerDisconnected)


#Create server with fetched arguments.
func _mCreateServer(args : Dictionary) -> void:

	var port = args.get("port")
	var address = args.get("address")

	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(address)
	var result = peer.create_server(port, M_MAX_CHANNELS, M_MAX_CHANNELS)
	if(result != OK):
		Logger.mLogError("Cant create server on address: " + address + ":" + str(port)\
			+ " aborting application.")
	
	Logger.mLogInfo("Created server on address: " + address + ":" + str(port) + ".")
	
	#Set multiplayer peer
	multiplayer.multiplayer_peer = peer
	
	#bind signals.
	multiplayer.peer_connected.connect(_onPeerConnected)
	multiplayer.peer_disconnected.connect(_onPeerDisconnected)

#Fetch arguments that must be given when launching dedicated server.
func _mFetchArguments() -> Dictionary:
	Logger.mLogInfo("Fetching starting arguments.")

	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.find("="):
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""

	#check if arguments are given.
	var port : int = arguments.get("port") as int
	var address : String = arguments.get("address") as String
	var playerCount : int = arguments.get("playerCount") as int
	
	if(not port):
		Logger.mLogError("Cant find start argument --port. Aborting application.")
		get_tree().quit(-1)

	if(not address):
		Logger.mLogError("Cant find start argument --address. Aborting application.")
		get_tree().quit(-1)

	if(not playerCount):
		Logger.mLogError("Cant find start argument --playerCount. Aborting application.")
		get_tree().quit(-1)
	
	return arguments

func _onPeerConnected(id : int) -> void:
	#Create a player for newly connected peer on every client.
	_mAddNewPlayer.rpc(id)

	#Create existing players on new players client.
	if(m_clients.size() > 0):
		_mAddExistingPlayers.rpc_id(id, m_clients)
	
	m_clients.push_back(id)

func _onPeerDisconnected(id : int) -> void:
	#Remove disconnected player on every client and this server.
	_mRemovePlayer.rpc(id)
	m_clients.erase(id)

@rpc("authority", "call_local", "reliable", 1)
func _mRemovePlayer(id : int) -> void:
	print("peer: " + str(id) + " removed.")

@rpc("authority", "call_local", "reliable", 1)
func _mAddNewPlayer(id : int) -> void:
	print("peer: " + str(id) + " added.")

@rpc("authority", "call_remote", "reliable", 1)
func _mAddExistingPlayers(_arr : Array) -> void:
	for id in _arr:
		print("Adding existing player with id: " + str(id))