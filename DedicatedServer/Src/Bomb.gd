extends RigidBody2D
class_name Bomb

@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer
@onready var m_area : Area2D = $Area2D

const M_DAMAGE_HEART : int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(Net.mGetNetworkType(self) != Net.Type.SERVER):
		set_physics_process(false)
		set_process(false)
		return

	#We are on the server.
	m_animPlayer.animation_finished.connect(_onAnimFinished)

func _physics_process(_delta: float) -> void:
	_mSyncPos.rpc(position)

#Will only called on server.
func _onAnimFinished(animName : String) -> void:
	match animName:
		"fire":
			_mPlayAnimation.rpc("explode")
		"explode":
			_mFree.rpc()
			
@rpc("authority", "call_remote", "unreliable", 0)
func _mSyncPos(pos : Vector2) -> void:
	position = pos

@rpc("authority", "call_local", "reliable", 1)
func _mFree():
	queue_free()

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnimation(animName : String) -> void:
	m_animPlayer.play(animName)


func _onBodyEntered(body : Node2D) -> void:
	if(not get_tree().get_multiplayer().is_server()):
		return

	if(body is not Player):
		return

	var player : Player = body as Player

	player.m_statusBar._mLoseHeart(M_DAMAGE_HEART)
	

