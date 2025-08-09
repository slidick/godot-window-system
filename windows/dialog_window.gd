extends BaseWindow
class_name DialogWindow

signal _done(_bool: bool, _value: String)

signal _done_multi(_bool: bool, _values: Array[String])

#var _allow_click_off : bool = true
var _dialog_open : bool = false

@onready var _default_size : Vector2 = self.size

func _ready() -> void:
	hide()
	super._ready()
	
	# Quirk: This automatically gets set to FOCUS_ALL when text selection is enabled.
	# But it's not required for text selection to work and we don't want the
	# focus highlight so we change it to FOCUS_NONE here
	%InfoLabel.focus_mode = FOCUS_NONE
	
	await get_parent().ready
	get_parent().move_child(self, -1)
	await get_tree().process_frame
	reset()


func reset() -> void:
	await _fade_out()
	self.offset_left = _default_size.x / 2.0 * -1
	self.offset_top = _default_size.y / 2.0 * -1
	self.offset_right = _default_size.x / 2.0 
	self.offset_bottom = _default_size.y / 2.0
	%InfoLabel.text = ""
	%ConfirmLabel.text = ""
	%DialogLabel.text = ""
	%DialogLineEdit.text = ""
	%ErrorLabel.text = ""
	%CancelButton.text = "Cancel"
	for child in %MultiContainer.get_children():
		child.queue_free()
	%ConfirmButton.show()
	%InfoLabel.hide()
	%ConfirmLabel.hide()
	%SingleContainer.hide()
	%MultiContainer.hide()
	%ErrorLabel.hide()
	_dialog_open = false


func set_panel_size(_size: Vector2) -> void:
	self.offset_left = _size.x / 2.0 * -1
	self.offset_top = _size.y / 2.0 * -1
	self.offset_right = _size.x / 2.0 
	self.offset_bottom = _size.y / 2.0


func confirm(_label_text: String, _title_text: String = "Confirm?", p_allow_click_off: bool = true, _size: Vector2 = Vector2(400,200)) -> bool:
	allow_off_click = p_allow_click_off
	set_panel_size(_size)
	self.window_title = _title_text
	%ConfirmLabel.text = _label_text
	%ConfirmLabel.show()
	_fade_in()
	%ConfirmButton.grab_focus()
	var results: bool = await _done_confirm
	await reset()
	return results


func information(_label_text: String, _title_text: String = "Info", p_allow_click_off: bool = true, _size : Vector2 = Vector2(900,800), _button_text: String = "Close", _horiz_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	#if _dialog_open:
		#return
	#_dialog_open = true
	allow_off_click = p_allow_click_off
	set_panel_size(_size)
	self.window_title = _title_text
	%InfoLabel.text = _label_text
	%ConfirmButton.hide()
	%CancelButton.text = _button_text
	%InfoLabel.show()
	%InfoLabel.horizontal_alignment = _horiz_alignment
	_fade_in()
	%CancelButton.grab_focus()
	await _done_confirm
	await reset()
	return


func input(_label_text: String, _title_text: String = "Input required!", _default_text: String = "", _error_text: String = "", p_allow_click_off: bool = true, _size: Vector2 = Vector2(600, 150)) -> Array:
	allow_off_click = p_allow_click_off
	set_panel_size(_size)
	%SingleContainer.show()
	%DialogLabel.text = _label_text
	self.window_title = _title_text
	%DialogLineEdit.text = _default_text
	if not _default_text.is_empty():
		%DialogLineEdit.select_all()
	if not _error_text.is_empty():
		%ErrorLabel.text = _error_text
		%ErrorLabel.show()
	_fade_in()
	%DialogLineEdit.grab_focus()
	var results: Array = await _done
	await reset()
	return results


func input_multiple(_label_texts: Array, _title_text: String, _default_texts: Array, _error_text: String = "", p_allow_click_off: bool = true, _size: Vector2 = Vector2(600, 150), _read_only := false) -> Array:
	if len(_label_texts) != len(_default_texts):
		return [false, "Inconsistent number of inputs"]
	allow_off_click = p_allow_click_off
	set_panel_size(_size)
	%MultiContainer.show()
	%SingleContainer.hide()
	%ConfirmLabel.hide()
	self.window_title = _title_text
	for child in %MultiContainer.get_children():
		child.queue_free()
	await get_tree().process_frame
	
	for i in range(len(_label_texts)):
		var _label_node := Label.new()
		_label_node.text = _label_texts[i]
		var _line_edit_node := LineEdit.new()
		if _read_only:
			_line_edit_node.editable = false
		_line_edit_node.text = str(_default_texts[i])
		if not _read_only and i == 0 and not _default_texts[i].is_empty():
			_line_edit_node.select_all()
		%MultiContainer.add_child(_label_node)
		%MultiContainer.add_child(_line_edit_node)
	
	%ErrorLabel.text = _error_text
	if not _error_text.is_empty():
		%ErrorLabel.show()
	_fade_in()
	%MultiContainer.get_child(1).grab_focus()
	var results: Array = await _done_multi
	await reset()
	return results


func _confirm() -> void:
	if %SingleContainer.visible:
		if %DialogLineEdit.text.is_empty():
			%ErrorLabel.text = "Input is empty"
			%ErrorLabel.show()
			return
		_done.emit(true, %DialogLineEdit.text)
	elif %MultiContainer.visible:
		var results := []
		for child in %MultiContainer.get_children():
			if child is LineEdit:
				results.append(child.text)
		_done_multi.emit(true, results)
	else:
		_done_confirm.emit(true)


func _cancel() -> void:
	if %SingleContainer.visible:
		_done.emit(false, "")
	elif %MultiContainer.visible:
		_done_multi.emit(false, "")
	else:
		_done_confirm.emit(false)


func _on_confirm_button_pressed() -> void:
	_confirm()


func _on_dialog_line_edit_text_submitted(_new_text: String) -> void:
	_confirm()


func _on_cancel_button_pressed() -> void:
	_cancel()


func _on_dialog_line_edit_text_changed(_new_text: String) -> void:
	%ErrorLabel.hide()
