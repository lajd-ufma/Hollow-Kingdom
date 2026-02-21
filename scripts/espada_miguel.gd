extends Node2D

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@export var speed = 600
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	await get_tree().create_timer(3).timeout
	set_process(true)
	$Path2D/PathFollow2D/espada_miguel_body/AnimatedSprite2D.frame = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path_follow_2d.progress += speed * delta
