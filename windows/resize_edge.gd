extends Control
class_name ResizeEdge

var target : Control
var menu_bar_size : int = 0
var disabled: bool = false
var _cursor_shape: CursorShape = Control.CURSOR_ARROW

func _gui_input(event: InputEvent):	
	if disabled:
		return
	if event is InputEventMouseMotion and event.button_mask == 1:
		if name == "Right" or name == "BottomRight" or name == "TopRight":
			var prev_size_x = target.size.x
			target.size.x += event.relative.x
			if target.global_position.x + target.size.x > get_viewport().content_scale_size.x:
				target.size.x = prev_size_x
				target.global_position.x = get_viewport().content_scale_size.x - target.size.x
		
		if name == "Left" or name == "BottomLeft" or name == "TopLeft":
			var prev_size_x = target.size.x
			target.size.x -= event.relative.x
			target.position.x += (prev_size_x - target.size.x)
			if target.global_position.x <= 0:
				target.global_position.x = 0
				target.size.x = prev_size_x
		
		if name == "Bottom" or name == "BottomRight" or name == "BottomLeft":
			var prev_size_y = target.size.y
			target.size.y += event.relative.y
			if target.global_position.y + target.size.y > get_viewport().content_scale_size.y:
				target.size.y = prev_size_y
				target.global_position.y = get_viewport().content_scale_size.y - target.size.y
		
		if name == "Top" or name == "TopLeft" or name == "TopRight":
			var prev_size_y = target.size.y
			target.size.y -= event.relative.y
			target.position.y += (prev_size_y - target.size.y)
			if target.global_position.y < menu_bar_size:
				target.global_position.y = menu_bar_size
				target.size.y = prev_size_y

func disable() -> void:
	disabled = true
	_cursor_shape = mouse_default_cursor_shape
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func enable() -> void:
	disabled = false
	mouse_default_cursor_shape = _cursor_shape
