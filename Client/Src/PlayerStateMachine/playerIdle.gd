extends PlayerState
class_name PlayerIdle


#Additional parameters can be used to customize init function.
#Because Player.mChangeState will pass additional parameters to PlayerState.new(params)
func _init(_params : Dictionary = {}):
	pass

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
