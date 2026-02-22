extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.tocar_musica02()
	DialogsManager.start_dialog("Gabriel")
