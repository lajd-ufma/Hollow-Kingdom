extends Area2D

@export var fall_speed: float = 260.0
@export var sway_speed: float = 4.5
@export var max_amplitude: float = 70.0
@export var lifetime: float = 6.0

var base_x: float
var time := 0.0
var sway_seed: float
var damage:int=3

func _ready():
	# cada pena ganha um comportamento único
	sway_seed = randf_range(0.0, 100.0)

	# ⚠️ MUITO IMPORTANTE:
	# espera 1 frame pra garantir que o boss já posicionou ela
	await get_tree().process_frame

	base_x = global_position.x

	# autodestruição
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta):
	time += delta

	# cai reto
	global_position.y += fall_speed * delta

	# oscila independente
	var offset = sin(time * sway_speed + sway_seed) * max_amplitude
	global_position.x = base_x + offset

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if body.has_signal("tomou_dano"):
			body.emit_signal("tomou_dano", damage)
