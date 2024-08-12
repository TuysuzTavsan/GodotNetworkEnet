extends Node2D
class_name Battlefield

var m_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var m_address : String = "127.0.0.1"
var m_port : int = 9999

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_onPeerConnected)
	multiplayer.peer_disconnected.connect(_onPeerDisconnected)
	multiplayer.connected_to_server.connect(_onConnectedServer)
	multiplayer.server_disconnected.connect(_onServerDisconnected)
	multiplayer.connection_failed.connect(_onConnectionFailed)

	var result = m_peer.create_client(m_address, m_port, 2)
	if(result != OK):
		Logger.mLogError("Can not create peer. Aborting application.")
		get_tree().quit(-1)
	
	Logger.mLogInfo("Creted peer successfully.")
	multiplayer.multiplayer_peer = m_peer

func _onPeerConnected(id : int) -> void:
	pass

func _onPeerDisconnected(id : int) -> void:
	pass

func _onConnectedServer() -> void:
	pass

func _onServerDisconnected() -> void:
	pass

func _onConnectionFailed() -> void:
	pass