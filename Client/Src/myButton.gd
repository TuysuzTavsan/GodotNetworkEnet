extends Button
class_name MyButton

@onready var m_pressedPlayer : AudioStreamPlayer = $Pressed
@onready var m_hoveredPlayer : AudioStreamPlayer = $Hovered

#Custom button to play ui sounds.

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)

func _mouse_entered() -> void:
	if(not disabled):
		m_hoveredPlayer.play()

func _pressed() -> void:
	m_pressedPlayer.play()