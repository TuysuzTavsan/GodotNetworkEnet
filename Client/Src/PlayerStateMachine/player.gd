extends CharacterBody2D
class_name Player

#State machine that will handle player.
#This script is the main handler of the states.

var m_state : PlayerState = null

enum STATES {
	IDLE,
	RUN,
}

static var m_states : Dictionary = {
	STATES.IDLE : PlayerIdle,
	STATES.RUN : PlayerRun,
}

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _mChangeState(state : STATES, params : Dictionary = {}) -> void:
	if(m_state != null):
		m_state.queue_free()
		m_state = null
	
	m_state = m_states.get(state).new(params)
	assert(m_state, "Trying to change state no nonexisting state.")

	#initialize new state with owner = self, and callable reference to this function.
	m_state.mSetup(self, _mChangeState)
	add_child(m_state, true) #Always force readable name so rpc calls can work.