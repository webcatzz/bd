extends Node

var data: Dictionary = {}


func read() -> void:
	data = bytes_to_var(FileAccess.get_file_as_bytes("user://save.cfg"))


func write() -> void:
	var file: FileAccess = FileAccess.open("user://save.cfg", FileAccess.WRITE)
	file.store_var(data)
	file.close()
