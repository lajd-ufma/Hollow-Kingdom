extends Node2D

@export var next_scene:PackedScene
signal matou_boss



func _ready() -> void:
	$transition/CanvasLayer.visible = true
	$transition/AnimationPlayer.play("fade-in")
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
	$transition/AnimationPlayer.play("fade-out")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade-out":
		get_tree().change_scene_to_packed(next_scene)
