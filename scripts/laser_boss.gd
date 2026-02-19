extends Area2D

@export var fall_speed: float = 1400.0
@export var horizontal_speed: float = 300
@export var damage: int = 2

@onready var ray: RayCast2D = $RayCast2D

var velocity: Vector2
var has_hit_ground: bool = false


func _ready():
	monitoring = true
	monitorable = true
	
	velocity = Vector2(horizontal_speed, fall_speed)


func _process(delta):

	if has_hit_ground:
		return

	global_position += velocity * delta

	if ray.is_colliding():
		hit_ground()


func hit_ground():
	has_hit_ground = true
	monitoring = false
	queue_free()

func _on_body_entered(body):
	if body.name == "player":
		if body.has_signal("tomou_dano"):
			body.emit_signal("tomou_dano", damage)
