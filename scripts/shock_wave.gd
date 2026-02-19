extends Area2D

@export var speed := 600.0
var direction := 1
var damage: int = 3

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	position.x += speed * direction * delta

	if position.x > 2000 or position.x < -200:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if body.has_signal("tomou_dano"):
			body.emit_signal("tomou_dano", damage)
