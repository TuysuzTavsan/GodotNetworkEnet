extends Node2D
class_name StatusBar

var m_hearts : int = 3

@onready var m_heart1 : Node2D = $Hearth1
@onready var m_heart2 : Node2D = $Hearth2
@onready var m_heart3 : Node2D = $Hearth3

var m_player : Player = null

func _ready() -> void:
	#Authority for this node is always server.
	set_multiplayer_authority(1)
	m_player = get_parent() as Player

######################################## PUBLIC FUNCTIONS #######################################

#Will only be called on server from external nodes.
#This function will be called by accessing player node first.
#Called when this player collects some heart.
func _mRegenerate(heartCount : int) -> void:

	#Do not execute on puppet players
	if(m_player.m_netType == Net.Type.PUPPET):
		return

	var newHeartCount : int  = clampi(m_hearts + heartCount, 0, 3) as int

	if(multiplayer.is_server()):
		_mSetHealth.rpc(newHeartCount)
	else:
		_mSetHealth(newHeartCount)


#This function will be called by accessing player node first.
#Called when this player gets damaged.
func _mLoseHeart(heartCount : int) -> void:

	#Do not execute on puppet players
	if(m_player.m_netType == Net.Type.PUPPET):
		return

	var newHeartCount : int  = clampi(m_hearts - heartCount, 0, 3) as int

	if(get_tree().get_multiplayer().is_server()):
		_mSetHealth.rpc(newHeartCount)
	else:
		_mSetHealth(newHeartCount)

######################################## PUBLIC FUNCTIONS #######################################


func _mUpdateStatusVisual() -> void:
	match m_hearts:
		0:
			m_heart1.hide()
			m_heart2.hide()
			m_heart3.hide()
		1:
			m_heart1.show()
			m_heart2.hide()
			m_heart3.hide()
		2:
			m_heart1.show()
			m_heart2.show()
			m_heart3.hide()
		3:
			m_heart1.show()
			m_heart2.show()
			m_heart3.show()

@rpc("authority", "call_local", "reliable", 1)
func _mSetHealth(heartCount : int) -> void:
	m_hearts = heartCount
	_mUpdateStatusVisual()
	if(heartCount <= 0):
		m_player._mChangeState(Player.STATES.DEAD)


	
