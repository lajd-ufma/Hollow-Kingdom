extends Node2D


@export var speed_path_follow: float = 300
@onready var path_2d: Path2D = $Path2D
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var body: CharacterBody2D = $Path2D/PathFollow2D/rafael_body
@onready var tween :Tween
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/rafael_body/hitbox/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var hp: ProgressBar = $Path2D/PathFollow2D/hp
@onready var rafael_spawn_point: Marker2D = $"../rafael_spawn_point"
@onready var player: CharacterBody2D = $"../player"


signal tomou_dano

var current_state := ""
var is_aiming := false

# Move Paths
var move_basica = preload("res://tres/rafael_paths/move_basica.tres")
var ataque_queda = preload("res://tres/rafael_paths/ataque_queda.tres")
var return_to_start = preload("res://tres/rafael_paths/return_to_start.tres")

func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)
	path_2d.curve = move_basica
	await get_tree().create_timer(3).timeout
	current_state = "moving"
	hitbox_collision_shape_2d.disabled = false
	timer.start()
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(body, "rotation_degrees", 360.0, 2.0).from(0.0)


func _process(delta):
	match current_state:
		"moving":
			path_follow_2d.progress += speed_path_follow * delta
		
		"aiming":
			if not is_aiming:
				is_aiming = true
				_start_aiming()

		"firing":
			hitbox_collision_shape_2d.disabled = false
			path_2d.curve = ataque_queda
			path_follow_2d.progress += speed_path_follow * 2 * delta

func _start_aiming() -> void:
	ataque_queda.remove_point(ataque_queda.point_count - 1)
	ataque_queda.remove_point(ataque_queda.point_count - 1)

	await get_tree().create_timer(1).timeout
	print(player.position)
	var local_target := path_2d.to_local(player.global_position)
	ataque_queda.add_point(Vector2(local_target.x, 100))
	ataque_queda.add_point(Vector2(local_target))

	await get_tree().create_timer(1).timeout

	path_follow_2d.progress = 0
	current_state = "firing"
	is_aiming = false
	
func _on_tomou_dano(value):
	print("rafael tomou dano")
	hp.value -= value
	if hp.value <= 0:
		queue_free()
	else:
		var tween:= get_tree().create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_timer_timeout() -> void:
	hitbox_collision_shape_2d.disabled = true
	path_follow_2d.progress = 0
	if current_state == "moving":
		current_state = "aiming"
	elif current_state == "firing":

		# Pega a posição atual correta dentro da curva
		var atual_posicao = path_follow_2d.position

		# Posição do spawn convertida corretamente
		var local_target_spawn = path_2d.to_local(rafael_spawn_point.global_position)

		# Cria curva de retorno limpa
		return_to_start.clear_points()
		return_to_start.add_point(atual_posicao)
		return_to_start.add_point(local_target_spawn)

		# Reseta path
		path_follow_2d.progress = 0
		path_2d.curve = return_to_start
		current_state = "moving"

	tween.stop()

func _on_hitbox_body_entered(body: Node2D) -> void:
	body.emit_signal("tomou_dano", 3)
