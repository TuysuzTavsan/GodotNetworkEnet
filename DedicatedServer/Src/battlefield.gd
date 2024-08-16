extends Node
class_name Battlefield

#Battlefield is the main node that will manage game on both client and dedicated server.
#For all @rpc calls to work, every rpc must exist on both projects.
#Therefore there are a lot of similarities between client Battlefield script - dedicatedServer Battlefield script.
#Only real difference is how this nodes initialize itself and creates peer for high level networking.
#Everytime a player connects we will create player node with authority set to connected peer id.
#Server will also create same player node with authority set to connected peer id.
#Every client can only control player node which it owns.
#For every other player node they have locally, it will be controlled by the server.
#So basicly the real game is actually exists on the server.
#What client see is actually a copy of that game state. And client only have control over its player character.

const M_MAX_CLIENTS : int = 8
const M_MAX_CHANNELS : int = 2
var m_clientCount : int = -1
var m_playerScene : PackedScene = load("res://Scenes/Player.tscn")
var m_players : Dictionary = {} #Key=id, value is the Player node.


@onready var m_marker1 : Marker2D = $Marker2D
@onready var m_marker2 : Marker2D = $Marker2D2
@onready var m_marker3 : Marker2D = $Marker2D3
@onready var m_marker4 : Marker2D = $Marker2D4

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

func _mGetRandomSpawnPosition() -> Vector2:
	match randi_range(1, 4):
		1:
			return m_marker1.position
		2:
			return m_marker2.position
		3:
			return m_marker3.position
		4:
			return m_marker4.position
	
	return Vector2(0, 0)

func _onPeerConnected(id : int) -> void:
	#Create existing players on new players client with authority set to 1 (server).
	if(m_players.size() > 0):
		_mAddExistingPlayers(id, m_players.keys())

	#Create a player for newly connected peer on every client.
	_mAddNewPlayer.rpc(id) #This will create a player with authority set to id on dedicated server.
	_mSetPlayerPosition.rpc(id, _mGetRandomSpawnPosition())


func _onPeerDisconnected(id : int) -> void:
	#Remove disconnected player on every client and this server.
	_mRemovePlayer.rpc(id)


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
#This function body is different on the client project. Dont get confused. Client will always set authority to 1.
@rpc("authority", "call_local", "reliable", 1)
func _mAddNewPlayer(id : int) -> void:
	Logger.mLogInfo("adding peer: " + str(id) + ".")
	
	var player : Player = m_playerScene.instantiate()
	player.set_multiplayer_authority(id)
	m_players[id] = player
	add_child(player, true) #Always force readable names so rpc works.

#Add existing players on client with id.
func _mAddExistingPlayers(clientId : int, arr : Array) -> void:
	for id in arr:
		_mAddNewPlayer.rpc_id(clientId, id)