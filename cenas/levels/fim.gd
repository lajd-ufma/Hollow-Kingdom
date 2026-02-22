extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.timeline_ended.connect(terminou)
	DialogsManager.start_dialog("Deus")
func terminou():
	$generic_level.emit_signal("matou_boss")
