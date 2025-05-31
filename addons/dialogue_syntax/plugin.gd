@tool
extends EditorPlugin

var highlighter: EditorSyntaxHighlighter


func _enter_tree() -> void:
	highlighter = load("res://addons/dialogue_syntax/highlighter.gd").new()
	EditorInterface.get_script_editor().register_syntax_highlighter(highlighter)


func _exit_tree() -> void:
	EditorInterface.get_script_editor().unregister_syntax_highlighter(highlighter)
	highlighter = null
