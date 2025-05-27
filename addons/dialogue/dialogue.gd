class_name Dialogue
extends Resource

var threads: Dictionary[String, Line]
var line: Line


func load(file: String) -> void:
	var strs: PackedStringArray = FileAccess.get_file_as_string("res://dialogue/%s.txt" % file).split("\n", false)
	var line: Line
	
	for i: int in strs.size():
		if strs[i].begins_with("~"):
			line = Line.new()
			threads[strs[i].substr(2)] = line
		else:
			line.links.append(Line.new())
			line = line.links[0]


func parse(strs: PackedStringArray) -> void:
	for i: int in strs.size():
		if strs[i].begins_with("~"):
			line = Line.new()
			threads[strs[i].substr(2)] = line


func run(key: String) -> void:
	line = threads[key]
	next()


func next() -> Line:
	line = line.next()
	return line


class Line extends Resource:
	var text: String
	var links: Array[Line]
	var condition: Callable
	var is_choice: bool
	
	func next() -> Line:
		for line: Line in links:
			if not line.condition or line.condition.call():
				return line
		return null
