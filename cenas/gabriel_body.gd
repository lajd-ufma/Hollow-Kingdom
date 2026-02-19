extends CharacterBody2D

signal tomou_dano_request(value)

func tomou_dano(value):
	emit_signal("tomou_dano_request", value)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "player":
		body.emit_signal("tomou_dano", 3)
