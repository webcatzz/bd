extends Control

const START_DIALOGUE := "# "
const END_DIALOGUE := "---"
const SWITCH_DIALOGUE := "=> "

const SWITCH_SPEAKER := "as "
const OPTION := "> "
const EXECUTE := "do "
const EVALUATE := "if "
#const EVALUTE := "else"

const INDENT := "\t"
const IGNORE := "x "

@export var filename: String
@export var key: String

var file: FileAccess
var speaker: String
var indent: int
var stack: PackedInt32Array

@onready var feed: RichTextLabel = $VBox/Feed
@onready var controls: TabContainer = $VBox/Controls
@onready var option_list: ItemList = $VBox/Controls/Options


# loop

func start() -> void:
	file = FileAccess.open("res://resources/dialogue/%s.txt" % filename, FileAccess.READ)
	if key:
		seek(key)
	else:
		step()


func seek(key: String) -> void:
	key = START_DIALOGUE + key
	reset_indent()
	file.seek(0)
	while true:
		if file.get_position() < file.get_length():
			var line: String = file.get_line()
			if line == key:
				break
		else:
			return
	step()


func step() -> void:
	var line: String = file.get_line().strip_edges(false, true)
	if line.is_empty():
		step()
		return
	# indentation
	var line_indent: int = get_indent(line)
	if line_indent > indent:
		step()
		return
	elif line_indent < indent:
		if stack.is_empty():
			indent = line_indent
		else:
			file.seek(stack[-1])
			stack.resize(stack.size() - 1)
			step()
			return
	line = line.strip_edges(true, false)
	# tokens
	if line.begins_with(SWITCH_SPEAKER):
		speaker = line.substr(SWITCH_SPEAKER.length())
		add_speaker_name(speaker)
		step()
	elif line.begins_with(OPTION):
		var options: Dictionary[String, int]
		var options_end: int
		while true:
			if not line.is_empty() and get_indent(line) == indent:
				line = line.substr(indent)
				if line.begins_with(OPTION):
					options[line.substr(OPTION.length())] = file.get_position()
				else:
					break
			options_end = file.get_position()
			line = file.get_line()
		stack.append(options_end)
		show_options(options)
	elif line.begins_with(EXECUTE):
		run(line.substr(EXECUTE.length()))
		step()
	elif line.begins_with(EVALUATE):
		if run(line.substr(EVALUATE.length())):
			indent += 1
		step()
	elif line.begins_with(SWITCH_DIALOGUE):
		seek(line.substr(SWITCH_DIALOGUE.length()))
	elif line.begins_with(END_DIALOGUE):
		end()
	elif line.begins_with(IGNORE):
		step()
	else:
		add_line(line)
		show_button()


func end() -> void:
	reset_indent()
	file.close()


# feed

func add_line(text: String) -> void:
	feed.text += text + "\n"


func add_speaker_name(text: String) -> void:
	add_line("\n[b]%s[/b]" % text)


# controls

func show_button() -> void:
	controls.current_tab = 0


func show_options(options: Dictionary[String, int]) -> void:
	option_list.item_activated.connect(_on_option_selected.bind(options), CONNECT_ONE_SHOT)
	for option: String in options:
		option_list.add_item(option)
	controls.current_tab = 1


func _on_control_changed() -> void:
	controls.get_current_tab_control().grab_focus()


func _on_option_selected(idx: int, options: Dictionary[String, int]) -> void:
	option_list.clear()
	var text: String = options.keys()[idx]
	add_speaker_name("YOU")
	add_line(text)
	file.seek(options[text])
	indent += 1
	step()


# helpers

func get_indent(line: String) -> int:
	var indent: int = 0
	while line[indent] == INDENT:
		indent += 1
	return indent


func reset_indent() -> void:
	indent = 0
	stack.clear()


func run(code: String) -> Variant:
	var expr := Expression.new()
	expr.parse(code)
	return expr.execute([], Save)
