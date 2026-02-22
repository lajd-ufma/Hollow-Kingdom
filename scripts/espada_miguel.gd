extends Node2D

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@export var speed = 600
var is_ativada:= false

func _process(delta: float) -> void:
	if !GameManager.can_move: return
	
	if !is_ativada:
		$Path2D/PathFollow2D/espada_miguel_body/AnimatedSprite2D.frame = 1
		is_ativada = true
	path_follow_2d.progress += speed * delta
