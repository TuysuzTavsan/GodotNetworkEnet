extends Node2D
class_name Spawner

#Generic spawner class to spawn heart and bullets around the map.
#Will only operate on server.

@export var m_sceneToSpawn : PackedScene
@export var m_random : bool = false
@export_range(5,30) var m_timePeriod : int = 15

@onready var m_marker : Marker2D = $Marker2D
@onready var m_timer : Timer = $Timer

var m_spawnedNode = null

const M_MINIMUM_TIME : int = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#If this is not server do not start timer.
	if(get_tree().get_multiplayer().is_server()):
		_mStartTimer()

func _onTimeOut() -> void:
	#Keep in mind this timer will only work on server.
	if(get_tree().get_multiplayer().is_server()):
		_mSpawn.rpc()
		m_timer.stop()


#only server can control spawn.
@rpc("authority", "call_local", "reliable", 1)
func _mSpawn() -> void:
	var spawnedNode : Node2D = m_sceneToSpawn.instantiate() as Node2D
	spawnedNode.position = m_marker.position
	add_child(spawnedNode)

	if(get_tree().get_multiplayer().is_server()):
		spawnedNode.tree_exited.connect(_onSpawnedNodeTreeExited)


func _onSpawnedNodeTreeExited() -> void:
	#Stop the pause since spawned scene is gone. We need to respawn on timeout.
	#start timer on only server.
	if(get_tree().get_multiplayer().is_server()):
		_mStartTimer()


func _mStartTimer() -> void:
	if(get_tree().get_multiplayer().is_server()):
		if(m_random):
			var randomTime : int = randi_range(M_MINIMUM_TIME, m_timePeriod)
			m_timer.start(randomTime)
		else:
			m_timer.start(m_timePeriod)
