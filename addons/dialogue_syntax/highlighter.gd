@tool
extends EditorSyntaxHighlighter

var settings: EditorSettings = EditorInterface.get_editor_settings()


func _get_name() -> String:
	return "Dialogue"


func _get_supported_languages() -> PackedStringArray:
	return ["dialogue"]


func _get_line_syntax_highlighting(idx: int) -> Dictionary:
	var line: String = get_text_edit().get_line(idx)
	# indent
	var indent: int
	while line[indent] == "\t":
		indent += 1
	line = line.substr(indent)
	# tokens
	var map: Dictionary[int, Dictionary]
	if line.begins_with(Dialogue.SWITCH_SPEAKER):
		map_add_prefix(map, "keyword", "text", indent, Dialogue.SWITCH_SPEAKER.length())
	elif line.begins_with(Dialogue.OPTION):
		map_add_prefix(map, "control_flow_keyword", "text", indent, Dialogue.OPTION.length())
	elif line.begins_with(Dialogue.EXECUTE):
		map_add_prefix(map, "keyword", "text", indent, Dialogue.EXECUTE.length())
	elif line.begins_with(Dialogue.EVALUATE):
		map_add_prefix(map, "control_flow_keyword", "text", indent, Dialogue.EVALUATE.length())
	elif line.begins_with(Dialogue.SWITCH_DIALOGUE) or line.begins_with(Dialogue.START_DIALOGUE) or line.begins_with(Dialogue.END_DIALOGUE):
		map_add(map, "control_flow_keyword", indent)
	elif line.begins_with(Dialogue.IGNORE):
		map_add(map, "comment", indent)
	return map


func map_add(map: Dictionary[int, Dictionary], type: String, idx: int) -> void:
	map[idx] = {"color": settings.get_setting("text_editor/theme/highlighting/%s_color" % type)}


func map_add_prefix(map: Dictionary[int, Dictionary], prefix_type: String, body_type: String, start: int, prefix_length: int) -> void:
	map_add(map, prefix_type, start)
	map_add(map, body_type, start + prefix_length)
