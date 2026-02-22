extends Area2D

@export var rotation_speed: float = 720.0 # graus por segundo

@export var damage_sword: int = 2
func _process(delta):
	rotation_degrees += rotation_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if body.has_signal("tomou_dano"):
			body.emit_signal("tomou_dano", damage_sword) # Replace with function body.
