extends Node2D

@export var speed_path_follow: float = 200.0
@export var attack_cooldown_time: float = 3.0
@export var laser_damage: int = 1
@export var aiming_time: float = 0.5

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var body: CharacterBody2D = $Path2D/PathFollow2D/gabriel_body
@onready var hp: ProgressBar = $Path2D/PathFollow2D/hp
@onready var player: Node2D = $"../player"
@onready var ray_cast: RayCast2D = $Path2D/PathFollow2D/gabriel_body/RayCast2D
@onready var line_2d: Line2D = $Path2D/PathFollow2D/gabriel_body/Line2D
@onready var laser_material := line_2d.material
@onready var attack_timer: Timer = $AttackTimer

signal tomou_dano

var current_state = "moving"
var aiming_time_left = 2.0
var locked_direction: Vector2

func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)
	attack_timer.wait_time = attack_cooldown_time
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	line_2d.visible = false
	ray_cast.enabled = false

func _process(delta: float) -> void:
	match current_state:
		"moving":
			path_follow_2d.progress += speed_path_follow * delta
		
		"aiming":
			var aim_progress: float = clamp(1.0 - (aiming_time_left / aiming_time), 0.0, 1.0)
			laser_material.set_shader_parameter("progress", aim_progress)
			update_laser_visual()

		"firing":
			update_laser_visual()

func _on_attack_timer_timeout() -> void:
	if not is_instance_valid(player): return
	start_aiming()

# ------------------------------------------------------------
# ESTADO: AIMING
# ------------------------------------------------------------

func start_aiming() -> void:
	current_state = "aiming"

	aiming_time_left = aiming_time

	line_2d.visible = true
	ray_cast.enabled = true

	laser_material.set_shader_parameter("progress", 0.0)

	# trava a mira aqui
	var player_local_pos = body.to_local(player.global_position)
	locked_direction = player_local_pos.normalized() * 2000
	ray_cast.target_position = locked_direction

	update_laser_visual()

	aiming_delay()


func aiming_delay() -> void:
	await get_tree().create_timer(aiming_time).timeout
	start_firing()

func update_laser_direction():
	var player_local_pos = body.to_local(player.global_position)
	ray_cast.target_position = player_local_pos.normalized() * 2000

# ------------------------------------------------------------
# ESTADO: FIRING
# ------------------------------------------------------------

func start_firing():
	current_state = "firing"

	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.name == "player":
			collider.emit_signal("tomou_dano", laser_damage)

	# encerra disparo após pequena janela visual
	await get_tree().create_timer(0.2).timeout

	end_laser()

# ------------------------------------------------------------
# VISUAL DO LASER
# ------------------------------------------------------------

func update_laser_visual() -> void:
	var cast_point = ray_cast.target_position
	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		cast_point = body.to_local(ray_cast.get_collision_point())

	line_2d.points = [Vector2.ZERO, cast_point]

# ------------------------------------------------------------
# FINALIZAÇÃO
# ------------------------------------------------------------

func end_laser():
	line_2d.visible = false
	ray_cast.enabled = false
	current_state = "moving"
	attack_timer.start()

# ------------------------------------------------------------
# DANO
# ------------------------------------------------------------

func _on_tomou_dano(value):
	hp.value -= value
	
	var tween := get_tree().create_tween()
	tween.tween_property(body, "modulate", Color.RED, 0.1)
	tween.tween_property(body, "modulate", Color.WHITE, 0.1)
	
	if hp.value <= 0:
		queue_free()
