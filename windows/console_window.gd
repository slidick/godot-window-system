extends BaseWindow
class_name ConsoleWindow


var history : Array = []
var history_position : int = -1
var _is_ready : bool = false


func _ready() -> void:
	hide()
	super._ready()
	await get_parent().ready
	get_parent().move_child(self, -1)
	_is_ready = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		toggle()


func print(message: Variant) -> void:
	while not _is_ready:
		await get_tree().process_frame
	printl(message)
	print(message)


func prints(message: Variant) -> void:
	printd(message)


func printu(message: String) -> void:
	#printc(message, "User")
	print_console(message, "User: ")
	if history_position != -1:
		history_position = -1
		history.pop_back()
	history.append(message)
	_handle_command(message)


func _handle_command(command: String) -> void:
	pass


func printl(message: Variant) -> void:
	printc(str(message), "System")


func printd(message: Variant) -> void:
	printc(str(message), "Server")


func printo(message: Variant) -> void:
	printc(str(message), "Socket")


func printc(message: String, user: String) -> void:
	var time := Time.get_time_string_from_system()
	%ConsoleText.append_text("[%s] [color=white]%s[/color]: %s\n" % [time, user, message])
	%ConsoleEdit.clear()


func print_console(message: String, _prefix: String = "--> ", _suffix: String = "\n") -> void:
	%ConsoleText.append_text("%s%s%s" % [_prefix, message, _suffix])
	%ConsoleEdit.clear()


func _on_console_edit_text_submitted(message: String) -> void:
	printu(message)


func _on_console_edit_next() -> void:
	if history_position == -1:
		return
	if history_position <= len(history) - 2:
		history_position += 1
		%ConsoleEdit.clear()
		%ConsoleEdit.text = history[history_position]
		%ConsoleEdit.caret_column = len(%ConsoleEdit.text)


func _on_console_edit_previous() -> void:
	if history_position == -1 and len(history) > 0:
		history.append(%ConsoleEdit.text)
		history_position = len(history) - 2
		%ConsoleEdit.clear()
		%ConsoleEdit.text = history[history_position]
		%ConsoleEdit.caret_column = len(%ConsoleEdit.text)
	elif history_position != -1 and history_position == len(history) - 1:
		history.pop_back()
		history.append(%ConsoleEdit.text)
		history_position = len(history) - 2
		%ConsoleEdit.clear()
		%ConsoleEdit.text = history[history_position]
		%ConsoleEdit.caret_column = len(%ConsoleEdit.text)
	elif history_position != -1:
		if history_position > 0:
			history_position -= 1
		%ConsoleEdit.clear()
		%ConsoleEdit.text = history[history_position]
		%ConsoleEdit.caret_column = len(%ConsoleEdit.text)


func _on_clear_button_pressed() -> void:
	%ConsoleText.clear()
