extends Node2D
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

var m_address : String = "127.0.0.1" #To playtest this scene with dedicated server running on background.
var m_port : int = 9999 #To playtest this scene with dedicated server running on background.

var m_playerScene : PackedScene = load("res://Scenes/Player.tscn")
var m_players : Dictionary = {} #Key=id, value is the Player node.


@onready var m_marker1 : Marker2D = $Marker2D
@onready var m_marker2 : Marker2D = $Marker2D2
@onready var m_marker3 : Marker2D = $Marker2D3
@onready var m_marker4 : Marker2D = $Marker2D4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(_onConnectedServer)
	multiplayer.server_disconnected.connect(_onServerDisconnected)
	multiplayer.connection_failed.connect(_onConnectionFailed)

	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result = peer.create_client(m_address, m_port, 2)
	if(result != OK):
		Logger.mLogError("Can not create peer. Aborting application.")
		get_tree().quit(-1)
	
	Logger.mLogInfo("Created peer successfully.")
	
	#This is same as get_tree().get_multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer = peer

#This function will be called before adding this node to the scene tree.
#Port and address will be provided from lobbyServer just after dedicated server is initialized.
func mInit(port : int, address : String) -> void:
	m_port = port
	m_address = address


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

#Create a local player which this client has authority over.
func _mAddLocalPlayer() -> void:
	var player : Player = m_playerScene.instnatiate()
	player.set_multiplayer_authority(multiplayer.get_unique_id())
	add_child(player)
	player.position = _mGetRandomSpawnPosition()
	

#Called when connected to server. We dont have to do anything here, since server will call required functions for client.
#This is here for convenience.
func _onConnectedServer() -> void:
	Logger.mLogInfo("Connected to server.")
	#Create the local player.
	_mAddLocalPlayer()

#Called when disconnected from server.
#In normal scenerio server will control clients when the game ends, so if client disconnects before that, thats an error for sure.
func _onServerDisconnected() -> void:
	Logger.mLogError("Disconnected from server.")
	get_tree().quit(-1)

#Quit the application whenever connectionfails
func _onConnectionFailed() -> void:
	Logger.mLogError("Connection failed.")
	get_tree().quit(-1)







#Function that will be called from server.
#Will remove player node that disconnected from server.
@rpc("authority", "call_local", "reliable", 1)
func _mRemovePlayer(id : int) -> void:
	Logger.mLogInfo("removing peer: " + str(id) + ".")
	var player : Player = m_players.get(id) as Player
	m_players.erase(player)
	player.queue_free()

#Function that will be called from server.
#Will add newly joined player.
@rpc("authority", "call_local", "reliable", 1)
func _mAddNewPlayer(id : int) -> void:
	Logger.mLogInfo("adding peer: " + str(id) + ".")
	
	var player : Player = m_playerScene.instantiate()
	player.set_multiplayer_authority(1) #Authority is always 1 because its the server.
	m_players[id] = player
	add_child(player, true) #Always force readable names so rpc works.

#Function that will be called from server.
#Will add existingPlayers before this client connected to server.
@rpc("authority", "call_remote", "reliable", 1)
func _mAddExistingPlayers(_arr : Array) -> void:
	Logger.mLogInfo("Adding existing players.")
	for id in _arr:
		_mAddNewPlayer(id)
