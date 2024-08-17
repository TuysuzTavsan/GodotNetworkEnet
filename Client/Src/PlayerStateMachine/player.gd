extends CharacterBody2D
class_name Player

#State machine that will handle player.
#This script is the main handler of the states.

var m_state : PlayerState = null
@onready var m_animPlayer : AnimationPlayer = $AnimationPlayer
@onready var m_animatedSprite : AnimatedSprite2D = $AnimatedSprite2D

enum STATES {
	IDLE,
	RUN,
}

static var m_states : Dictionary = {
	STATES.IDLE : PlayerIdle,
	STATES.RUN : PlayerRun,
}

const M_RING_BUFFER_SIZE : int = 64
const M_SPEED = 300.0
const M_JUMP_VELOCITY = -400.0
const M_INTERPOLATIN_FACTOR : float = 10.0	
@onready var m_isAuthority : bool = get_multiplayer_authority() == get_tree().get_multiplayer().get_unique_id()
var m_gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass


func _mChangeState(state : STATES, params : Dictionary = {}) -> void:
	if(m_state != null):
		remove_child(m_state) #To force stop listening input from InputSyncer
		m_state.queue_free()
		m_state = null
	
	m_state = m_states.get(state).new(params)
	assert(m_state, "Trying to change state no nonexisting state.")

	#initialize new state with owner = self, and callable reference to this function.
	m_state.mSetup(self, _mChangeState)
	add_child(m_state, true) #Always force readable name so rpc calls can work.

@rpc("any_peer", "call_remote", "unreliable", 0)
func _mUpdatePos(pos : Vector2, vel : Vector2, frame : int) -> void:
	pass
		

@rpc("any_peer", "call_remote", "unreliable", 0)
func _mSendInput(inputVectorX : float, frame : int) -> void:
	pass

@rpc("authority", "call_local", "reliable", 1)
func _mSyncDirection(isLeft : bool) -> void:
	m_animatedSprite.flip_h = isLeft

@rpc("authority", "call_local", "reliable", 1)
func _mPlayAnimation(animName : String) -> void:
	m_animPlayer.play(animName)
