extends CanvasLayer
class_name GameEscapeMenu

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_cancel")):
		queue_free()
		get_viewport().set_input_as_handled()

func _onReturnMainMenuPressed() -> void:
	multiplayer.multiplayer_peer = null
	Client.mReturnMainMenuFromBattle("Left Game.")

	