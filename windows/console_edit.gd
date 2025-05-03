extends LineEdit


signal previous
signal next


func _gui_input(event: InputEvent) -> void:
	#super._gui_input(event)
	if event is InputEventKey and event.pressed and event.keycode == KEY_UP:
		previous.emit()
		get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_DOWN:
		next.emit()
		get_viewport().set_input_as_handled()
