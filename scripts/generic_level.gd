extends Node2D

@export var next_scene:PackedScene
signal matou_boss



func _ready() -> void:
	matou_boss.connect(_on_matou_boss)
	$portal.monitoring = false
	$arrow_to_next_scene.visible = false
	

func _on_matou_boss():
	$portal.monitoring = true
	$arrow_to_next_scene.visible = true
	$arrow_to_next_scene/AnimationPlayer.play("next")

func _on_portal_body_entered(_body: Node2D) -> void:
	if next_scene:
		call_deferred("change_scene")
	else:
		print("Próxima cena não foi carregada.")

func change_scene():
	get_tree().change_scene_to_packed(next_scene)
