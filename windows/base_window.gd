extends PanelContainer
class_name BaseWindow

signal window_shown(_bool: bool)
signal window_maximized(_bool: bool)
signal _done_confirm(_bool: bool)

#@export var window_title : String = "My Window"
@export var movable : bool = true
@export var resizable : bool = true
@export var exclusive : bool = true
@export var allow_off_click : bool = true
@export var allow_click_through : bool = false
@export var show_maximize_button : bool = true
@export var show_close_button : bool = true
@export var show_focus_highlight : bool = true
@export_enum("minimize", "fade_out") var minimize_style: String = "minimize"
@export var focus_border_color : Color = Color.SLATE_BLUE
@export var panel_color : Color = Color.DARK_SLATE_BLUE
@export var panel_corner_radius : int = 10
@export var minimize_location_node : Control
@export var panel_style_override: StyleBoxFlat
@export var start_maximized: bool = false
@export var header: bool = true

var focus_border : Control
var menu_bar_size : int = 0
var maximized : bool = false
var window_title : String :
	set(_new_value):
		var node: Label = get_node_or_null("%WindowTitle")
		if node:
			node.text = _new_value
	get:
		var node: Label = get_node_or_null("%WindowTitle")
		if node:
			return node.text
		else:
			return ""

var _tween : Tween
var _hiding : bool = false


@onready var previous_size : Vector2 = size
@onready var previous_position : Vector2 = global_position
@onready var unmaximize_size : Vector2 = size
@onready var unmaximize_position : Vector2 = global_position
var resize_container: MarginContainer

func _ready() -> void:
	var panel_theme := StyleBoxFlat.new()
	if panel_style_override:
		panel_theme = panel_style_override
		focus_border_color = panel_style_override.bg_color * 0.9
	else:
		panel_theme.bg_color = panel_color
		panel_theme.corner_radius_top_left = panel_corner_radius
		panel_theme.corner_radius_top_right = panel_corner_radius
		panel_theme.corner_radius_bottom_right = panel_corner_radius
		panel_theme.corner_radius_bottom_left = panel_corner_radius
		panel_theme.corner_detail = 4
	add_theme_stylebox_override("panel", panel_theme)
	
	var inner_panel_theme := StyleBoxFlat.new()
	inner_panel_theme.bg_color = Color(.1, .1, .1, .6)
	inner_panel_theme.corner_radius_top_left = panel_corner_radius
	inner_panel_theme.corner_radius_top_right = panel_corner_radius
	inner_panel_theme.corner_radius_bottom_right = panel_corner_radius
	inner_panel_theme.corner_radius_bottom_left = panel_corner_radius
	%MainContainer.add_theme_stylebox_override("panel", inner_panel_theme)
	
	var _menu_panel_node : Control = get_node_or_null("/root/Main/Menu/MenuPanel")
	if _menu_panel_node:
		menu_bar_size = _menu_panel_node.size.y
	
	add_focus_mode(%MaximizeButton)
	add_focus_mode(%CloseButton)
	add_focus_mode(%MainContainer)
	
	if exclusive:
		%Background.show()
	
	if allow_click_through:
		%Background.mouse_filter = MOUSE_FILTER_IGNORE
	
	# Title
	# --------
	var regex := RegEx.new()
	regex.compile("([A-Z][a-z]+)|(\\d+)")
	var results := []
	for result in regex.search_all(name):
		results.push_back(result.get_start())
	if len(results) > 0:
		var title = name
		for i in range(len(results)-1, -1, -1):
			if results[i] == 0:
				continue
			title = title.insert(results[i], " ")
		%WindowTitle.text = title
	else:
		%WindowTitle.text = name
	
	%MaximizeButton.visible = show_maximize_button
	%CloseButton.visible = show_close_button
	
	if not header:
		%HeaderContainer.queue_free()
	
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if show_focus_highlight:
		
		#focus_mode = FocusMode.FOCUS_CLICK
		# Border
		# ---------
		var focus_border_theme : StyleBoxFlat = panel_theme.duplicate()
		focus_border_theme.bg_color = focus_border_color
		
		focus_border = Panel.new()
		focus_border.anchor_left = Anchor.ANCHOR_BEGIN
		focus_border.anchor_top = Anchor.ANCHOR_BEGIN
		focus_border.anchor_right = Anchor.ANCHOR_END
		focus_border.anchor_bottom = Anchor.ANCHOR_END
		focus_border.offset_left = -5
		focus_border.offset_top = -5
		focus_border.offset_right = 5
		focus_border.offset_bottom = 5
		focus_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_border.visible = false
		focus_border.name = "BorderColor"
		focus_border.add_theme_stylebox_override("panel", focus_border_theme)
		
		var border_container := Control.new()
		border_container.add_child(focus_border)
		border_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_container.show_behind_parent = true
		border_container.name = "Border"
		add_child(border_container)
		move_child(border_container, 0)
	
	if resizable:
		# Edges
		# --------
		var left_edge := ResizeEdge.new()
		var right_edge := ResizeEdge.new()
		var top_edge := ResizeEdge.new()
		var bottom_edge := ResizeEdge.new()
		
		left_edge.name = "Left"
		right_edge.name = "Right"
		top_edge.name = "Top"
		bottom_edge.name = "Bottom"
		
		left_edge.target = self
		right_edge.target = self
		top_edge.target = self
		bottom_edge.target = self
		
		left_edge.menu_bar_size = menu_bar_size
		right_edge.menu_bar_size = menu_bar_size
		top_edge.menu_bar_size = menu_bar_size
		bottom_edge.menu_bar_size = menu_bar_size
		
		left_edge.custom_minimum_size.x = 3
		right_edge.custom_minimum_size.x = 3
		top_edge.custom_minimum_size.y = 3
		bottom_edge.custom_minimum_size.y = 3
		
		left_edge.mouse_default_cursor_shape = CURSOR_HSIZE
		right_edge.mouse_default_cursor_shape = CURSOR_HSIZE
		top_edge.mouse_default_cursor_shape = CURSOR_VSIZE
		bottom_edge.mouse_default_cursor_shape = CURSOR_VSIZE
		
		left_edge.size_flags_horizontal = SIZE_SHRINK_BEGIN
		right_edge.size_flags_horizontal = SIZE_SHRINK_END
		top_edge.size_flags_vertical = SIZE_SHRINK_BEGIN
		bottom_edge.size_flags_vertical = SIZE_SHRINK_END
		
		left_edge.focus_mode = Control.FOCUS_CLICK
		right_edge.focus_mode = Control.FOCUS_CLICK
		top_edge.focus_mode = Control.FOCUS_CLICK
		bottom_edge.focus_mode = Control.FOCUS_CLICK
		
		left_edge.focus_entered.connect(func () -> void: grab_focus())
		right_edge.focus_entered.connect(func () -> void: grab_focus())
		top_edge.focus_entered.connect(func () -> void: grab_focus())
		bottom_edge.focus_entered.connect(func () -> void: grab_focus())
		
		
		# Corners
		# ---------
		var top_left_corner := ResizeEdge.new()
		var top_right_corner := ResizeEdge.new()
		var bottom_right_corner := ResizeEdge.new()
		var bottom_left_corner := ResizeEdge.new()
		
		top_left_corner.name = "TopLeft"
		top_right_corner.name = "TopRight"
		bottom_right_corner.name = "BottomRight"
		bottom_left_corner.name = "BottomLeft"
		
		top_left_corner.target = self
		top_right_corner.target = self
		bottom_right_corner.target = self
		bottom_left_corner.target = self
		
		top_left_corner.menu_bar_size = menu_bar_size
		top_right_corner.menu_bar_size = menu_bar_size
		bottom_right_corner.menu_bar_size = menu_bar_size
		bottom_left_corner.menu_bar_size = menu_bar_size
		
		top_left_corner.custom_minimum_size = Vector2(6,6)
		top_right_corner.custom_minimum_size = Vector2(6,6)
		bottom_right_corner.custom_minimum_size = Vector2(6,6)
		bottom_left_corner.custom_minimum_size = Vector2(6,6)
		
		top_left_corner.mouse_default_cursor_shape = CURSOR_FDIAGSIZE
		top_right_corner.mouse_default_cursor_shape = CURSOR_BDIAGSIZE
		bottom_right_corner.mouse_default_cursor_shape = CURSOR_FDIAGSIZE
		bottom_left_corner.mouse_default_cursor_shape = CURSOR_BDIAGSIZE
		
		top_left_corner.size_flags_horizontal = SIZE_SHRINK_BEGIN
		top_left_corner.size_flags_vertical = SIZE_SHRINK_BEGIN
		top_right_corner.size_flags_horizontal = SIZE_SHRINK_END
		top_right_corner.size_flags_vertical = SIZE_SHRINK_BEGIN
		bottom_right_corner.size_flags_horizontal = SIZE_SHRINK_END
		bottom_right_corner.size_flags_vertical = SIZE_SHRINK_END
		bottom_left_corner.size_flags_horizontal = SIZE_SHRINK_BEGIN
		bottom_left_corner.size_flags_vertical = SIZE_SHRINK_END
		
		top_left_corner.focus_mode = Control.FOCUS_CLICK
		top_right_corner.focus_mode = Control.FOCUS_CLICK
		bottom_right_corner.focus_mode = Control.FOCUS_CLICK
		bottom_left_corner.focus_mode = Control.FOCUS_CLICK
		
		top_left_corner.focus_entered.connect(func () -> void: grab_focus())
		top_right_corner.focus_entered.connect(func () -> void: grab_focus())
		bottom_right_corner.focus_entered.connect(func () -> void: grab_focus())
		bottom_left_corner.focus_entered.connect(func () -> void: grab_focus())
		
		resize_container = MarginContainer.new()
		resize_container.name = "ResizeControls"
		resize_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resize_container.add_child(left_edge)
		resize_container.add_child(right_edge)
		resize_container.add_child(top_edge)
		resize_container.add_child(bottom_edge)
		resize_container.add_child(top_left_corner)
		resize_container.add_child(top_right_corner)
		resize_container.add_child(bottom_right_corner)
		resize_container.add_child(bottom_left_corner)
		add_child(resize_container)
		move_child(resize_container, 3 if show_focus_highlight else 2)
	
	# Bugfix: Positions aren't properly set if we don't wait a frame
	await get_tree().process_frame
	if start_maximized:
		await toggle_maximize()
	if not visible:
		match minimize_style:
			"minimize":
				_hide()
			"fade_out":
				_fade_out()


func _on_minimize_button_pressed() -> void:
	_hide()


func _on_maximize_button_pressed() -> void:
	toggle_maximize()


func _on_close_button_pressed() -> void:
	#reset()
	toggle()


func toggle(_bool: Variant = null) -> void:
	if typeof(_bool) == TYPE_BOOL:
		if _bool == visible:
			if visible:
				grab_focus()
			return
		if _bool == true:
			match minimize_style:
				"minimize":
					_show()
				"fade_out":
					_fade_in()
		else:
			match minimize_style:
				"minimize":
					_hide()
				"fade_out":
					_fade_out()
	else:
		if visible:
			match minimize_style:
				"minimize":
					_hide()
				"fade_out":
					_fade_out()
		else:
			match minimize_style:
				"minimize":
					_show()
				"fade_out":
					_fade_in()


func _hide() -> void:
	if _hiding:
		_hiding = false
		_show()
		return
	if _tween and _tween.is_running():
		_tween.kill()
	else:
		previous_size = size
		previous_position = global_position
	_hiding = true
	var minimized_position := Vector2.ZERO
	if minimize_location_node:
		minimized_position = minimize_location_node.global_position
	_tween = create_tween()
	_tween.tween_property(self, "size", Vector2(0,0), 0.2)
	_tween.parallel().tween_property(self, "global_position", minimized_position, 0.2)
	_tween.parallel().tween_property(self, "modulate:a", 0, 0.2)
	if exclusive:
		_tween.tween_property(%Background, "visible", false, 0)
	_tween.tween_callback(self.hide)
	_tween.tween_property(self, "_hiding", false, 0.0)
	window_shown.emit(false)


func _show() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	show()
	_tween = create_tween()
	_tween.tween_property(self, "size", previous_size, 0.2)
	_tween.parallel().tween_property(self, "global_position", previous_position, 0.2)
	_tween.parallel().tween_property(self, "modulate:a", 1, 0.2)
	if exclusive:
		_tween.parallel().tween_property(%Background, "visible", true, 0)
	window_shown.emit(true)
	grab_focus()


func _fade_in() -> void:
	if _tween and _tween.is_running():
		return
	show()
	_tween = create_tween()
	_tween.parallel().tween_property(self, "modulate:a", 1, 0.2)
	if exclusive:
		_tween.parallel().tween_property(%Background, "visible", true, 0)
	window_shown.emit(true)
	grab_focus()


func _fade_out() -> void:
	if _tween and _tween.is_running():
		await _tween.finished
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0, 0.2)
	if exclusive:
		_tween.tween_property(%Background, "visible", false, 0)
	_tween.tween_callback(self.hide)
	window_shown.emit(false)
	await _tween.finished


func reset() -> void:
	hide()


func _on_focus_entered() -> void:
	if get_parent() == get_tree().get_root():
		return
	get_parent().move_child(self, -1)
	if show_focus_highlight:
		focus_border.show()


func _on_focus_exited() -> void:
	if show_focus_highlight:
		focus_border.hide()


func add_focus_mode(node: Control) -> void:
	node.focus_entered.connect(_on_focus_entered)
	node.focus_exited.connect(_on_focus_exited)
	for child in node.get_children(true):
		if child.is_class("Control"):
			add_focus_mode(child)


func toggle_maximize() -> void:
	maximized = not maximized
	var tween : Tween = create_tween()
	if maximized:
		grab_focus()
		focus_neighbor_bottom = "."
		focus_neighbor_top = "."
		focus_neighbor_left = "."
		focus_neighbor_right = "."
		focus_next = "."
		focus_previous = "."
		unmaximize_size = size
		unmaximize_position = global_position
		tween.tween_property(self, "size:x", get_viewport().content_scale_size.x, 0.2)
		tween.set_parallel()
		tween.tween_property(self, "size:y", get_viewport().content_scale_size.y-menu_bar_size, 0.2)
		tween.tween_property(self, "global_position:x", 0, 0.2)
		tween.tween_property(self, "global_position:y", menu_bar_size, 0.2)
		for child: Control in resize_container.get_children():
			child.disable()
	
	else:
		focus_neighbor_bottom = ""
		focus_neighbor_top = ""
		focus_neighbor_left = ""
		focus_neighbor_right = ""
		focus_next = ""
		focus_previous = ""
		tween.tween_property(self, "size", unmaximize_size, 0.2)
		tween.set_parallel()
		tween.tween_property(self, "global_position", unmaximize_position, 0.2)
		for child: Control in resize_container.get_children():
			child.enable()
	await tween.finished
	window_maximized.emit(maximized)

func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and allow_off_click:
		match minimize_style:
			"minimize":
				_hide()
			"fade_out":
				_fade_out()
		_done_confirm.emit(false)


func _on_header_container_gui_input(event: InputEvent) -> void:
	if show_maximize_button and event is InputEventMouseButton and event.button_index == 1 and event.double_click:
		_on_maximize_button_pressed()
	if movable and event is InputEventMouseMotion and event.button_mask == 1:
		global_position += event.relative
		if global_position.x < 0:
			global_position.x = 0
		if global_position.y < menu_bar_size:
			global_position.y = menu_bar_size
		if global_position.x + size.x > get_viewport().content_scale_size.x:
			global_position.x = get_viewport().content_scale_size.x - size.x
		if global_position.y + size.y > get_viewport().content_scale_size.y:
			global_position.y = get_viewport().content_scale_size.y - size.y
