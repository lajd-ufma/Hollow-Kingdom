extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogsManager.start_dialog("Miguel")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
