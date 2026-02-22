extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.tocar_musica03()
	DialogsManager.start_dialog("Miguel")

func _exit_tree() -> void:
	MusicManager.final()
