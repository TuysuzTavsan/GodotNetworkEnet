extends PlayerState
class_name PlayerIdle

#IdleState of the player will listen any type of input and change state.

#Default _init function for PlayerState
func _init(_params : Dictionary = {}):
	pass

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass

func _ready() -> void:
	m_player._mPlayAnimation("idle") 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
