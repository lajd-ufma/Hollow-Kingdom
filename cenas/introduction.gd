extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.timeline_ended.connect(_next_scene)
	DialogsManager.start_dialog("introdução")

func _next_scene():
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://cenas/levels/level_01.tscn")
