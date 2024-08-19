extends Node
class_name Battlefield

#Battlefield is the main node that will manage game on both client and dedicated server.
#For all @rpc calls to work, every rpc must exist on both projects.
#To keep things simple and understandable every script related to gameplay is actually same on server and client.
#Only real difference is how this nodes initialize itself and creates peer for high level networking.
#Other then that there is no difference in terms of script files. All scripts will have some logic depending on type.
#	type 1 : server
#	type 2 : localPlayer = Actual player
#	type 3 : puppetPlayer = copy of a playerState that exist on server.

#Everytime a player connects we will create player node with authority set to connected peer id.
#Server will also create same player node with authority set to connected peer id.
#Every client can only control player node which it owns.
#Every puppet player will be controlled by the server.
#So basicly the real game actually exists on the server.
#What client see is actually a copy of that game state. And client only have control over its player character.

const M_MAX_CLIENTS : int = 8
const M_MAX_CHANNELS : int = 2
var m_playerScene : PackedScene = load("res://Scenes/Player.tscn")
var m_players : Dictionary = {} # Key is id value is the player node.
var m_netType : Net.Type = Net.Type.UNSPECIFIED

@onready var m_spawnMarkersPivot : Node2D = $SpawnMarkers

func _ready() -> void:
	var args : Dictionary = _mFetchArguments()

	if(args.has("client")):
		_mCreateClient(args)
		m_netType = Net.Type.LOCAL
		return

	_mCreateServer(args)
	m_netType = Net.Type.SERVER

func _mCreateClient(args : Dictionary) -> void:
	multiplayer.connected_to_server.connect(_onConnectedServer)
	multiplayer.server_disconnected.connect(_onServerDisconnected)
	multiplayer.connection_failed.connect(_onConnectionFailed)

	var address : String = args.get("address") as String
	var port : int = args.get("port") as int

	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if(address == null):
		Logger.mLogError("Cant find address information on arguments. Aborting application")
		get_tree().quit(-1)

	if(port == null):
		Logger.mLogError("Cant find port information on arguments. Aborting application")
		get_tree().quit(-1)

	var result = peer.create_client(address, port, 2)
	if(result != OK):
		Logger.mLogError("Can not create client. Aborting application.")
		get_tree().quit(-1)
	
	Logger.mLogInfo("Created client successfully.")
	
	#This is same as get_tree().get_multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer = peer

#Create server with fetched arguments.
func _mCreateServer(args : Dictionary) -> void:

	var address : String = args.get("address") as String
	var port : int = args.get("port") as int
	var playerCount : int = args.get("playerCount") as int

	if(address == null):
		Logger.mLogError("Cant find address information on arguments. Aborting application")
		get_tree().quit(-1)

	if(port == null):
		Logger.mLogError("Cant find port information on arguments. Aborting application")
		get_tree().quit(-1)

	if(playerCount == null):
		Logger.mLogError("Cant find port playerCount on arguments. Aborting application")
		get_tree().quit(-1)

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

	
	return arguments


func _onPeerConnected(id : int) -> void:
	#Create existing players on new players client with authority set to 1 (server).
	if(m_players.size() > 0):
		_mAddExistingPlayers(id, m_players.keys())

	#Create a player for newly connected peer on every client.
	#This will create a player with authority set to id on dedicated server.
	_mAddNewPlayer.rpc(id) 
	if(m_netType == Net.Type.SERVER):
		_mSetPlayerPosition.rpc(id, _mGetRandomSpawnPosition())


func _onPeerDisconnected(id : int) -> void:
	#Remove disconnected player on every client and this server.
	_mRemovePlayer.rpc(id)

#Called when connected to server. We dont have to do anything here, since server will call required functions for client.
#This is here for convenience.
func _onConnectedServer() -> void:
	Logger.mLogInfo("Connected to server.")

#Called when disconnected from server.
#In normal scenerio server will control clients when the game ends, so if client disconnects before that, thats an error for sure.
func _onServerDisconnected() -> void:
	Logger.mLogError("Disconnected from server.")
	get_tree().quit(-1)

#Quit the application whenever connectionfails
func _onConnectionFailed() -> void:
	Logger.mLogError("Connection failed.")
	get_tree().quit(-1)

@rpc("authority", "call_local", "reliable", 1)
func _mSetPlayerPosition(id : int, pos : Vector2) -> void:
	var player : Player = m_players.get(id) as Player
	player.position = pos

@rpc("authority", "call_local", "reliable", 1)
func _mRemovePlayer(id : int) -> void:
	Logger.mLogInfo("removing peer: " + str(id) + ".")
	var player : Player = m_players.get(id) as Player
	m_players.erase(id)
	player.queue_free()

#This function will be called locally to create a player node that matching client is responsible from.
#This function will also be called remote to add already existing player on client. (for replication.)
#Dont get confused. Client will always set authority to 1.
@rpc("authority", "call_local", "reliable", 1)
func _mAddNewPlayer(id : int) -> void:
	Logger.mLogInfo("adding peer: " + str(id) + ".")
	
	var player : Player = m_playerScene.instantiate()

	#Set multiplayer authority to given id.
	if(m_netType == Net.Type.SERVER):
		player.set_multiplayer_authority(id)
	else:
		player.set_multiplayer_authority(id if multiplayer.get_unique_id() == id else 1)
		

	m_players[id] = player
	add_child(player, true) #Always force readable names so rpc works.

#Add existing players on client with id.
func _mAddExistingPlayers(clientId : int, arr : Array) -> void:
	for id in arr:
		_mAddNewPlayer.rpc_id(clientId, id)

func _mGetRandomSpawnPosition() -> Vector2:
	var childCount = m_spawnMarkersPivot.get_child_count()

	var randomNumber : int = randi_range(0, childCount - 1)

	return m_spawnMarkersPivot.get_child(randomNumber).position
