extends Control

var lines: PackedStringArray
var line_idx: int


func run(file: String, key: String) -> void:
	lines = FileAccess.get_file_as_string("res://dialogue/%s.txt" % file).split("\n", false)
	line_idx = lines.find("~ " + key)


func next() -> void:
	line_idx += 1
	if lines[line_idx].begins_with("=>"):
		pass
