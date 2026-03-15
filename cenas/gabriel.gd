extends Node2D

# ============================================================
# CONFIGURAÇÕES GERAIS
# ============================================================

@export var speed_path_follow: float = 200.0
@export var attack_cooldown: float = 4.0


# ============================================================
# CONFIGURAÇÃO DA CHUVA DE RAIOS
# ============================================================

@export var rain_scene: PackedScene
@export var rain_bar_width: float = 40.0
@export var spacing_factor: float = 1.0
@export var rain_interval: float = 0.05
@export var rain_spawn_height: float = -200.0

# ============================================================
# CONFIGURAÇÃO — PENAS DE FOGO
# ============================================================

@export var feather_scene: PackedScene
@export var feather_spawn_interval: float = 0.12
@export var feather_attack_duration: float = 4.0
@export var feather_spawn_height: float = -220.0
@export var feather_horizontal_padding: float = 64.0

# ============================================================
# CONFIGURAÇÃO DO SLAM
# ============================================================

@export var ground_y: float = 540.0
@export var slam_speed: float = 1400.0
@export var shake_time: float = 2.0
@export var vulnerable_time: float = 3.0

@export var shockwave_scene: PackedScene


# ============================================================
# REFERÊNCIAS
# ============================================================

@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var pivot: Node2D = $Path2D/PathFollow2D/Pivot
@onready var attack_timer: Timer = $AttackTimer
@onready var gabriel_body = $Path2D/PathFollow2D/Pivot/gabriel_body
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/Pivot/gabriel_body/hitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $Path2D/PathFollow2D/Pivot/gabriel_body/AnimationPlayer
@onready var hp: ProgressBar = $Path2D/PathFollow2D/Pivot/hp
@onready var body: CharacterBody2D = $Path2D/PathFollow2D/Pivot/gabriel_body
@onready var collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/Pivot/gabriel_body/CollisionShape2D
@onready var audio_stream_player: AudioStreamPlayer = $Path2D/PathFollow2D/Pivot/gabriel_body/AudioStreamPlayer
@onready var sprite: Sprite2D = $Path2D/PathFollow2D/Pivot/gabriel_body/Sprite2D


# ============================================================
# ESTADO
# ============================================================

var original_parent: Node = null
var on_path: bool = true
var stored_progress: float = 0.0
var is_attacking := false
var can_move := true
var is_dead := false


func _ready():
	set_physics_process(false)
	body.tomou_dano.connect(_on_tomou_dano)
	randomize()

	path_follow.rotates = false
	path_follow.h_offset = 0
	path_follow.v_offset = 0

	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _physics_process(delta: float) -> void:
	body.velocity += body.get_gravity() * delta
	body.move_and_slide()

# ============================================================
# MOVIMENTO NORMAL DO BOSS
# ============================================================

func _process(delta):
	if !GameManager.can_move: return
	if can_move and on_path:
		path_follow.progress += speed_path_follow * delta

# ============================================================
# ESCOLHER ATAQUE
# ============================================================

func _on_attack_timer_timeout():

	if is_attacking or is_dead or !GameManager.can_move:
		return

	is_attacking = true
	attack_timer.stop()

	var attack_type = randi() % 3

	if attack_type == 0:
		await rain_attack_sequence()
	elif attack_type == 1:
		await slam_attack_sequence()
	else:
		await feather_attack_sequence()
	

	is_attacking = false
	attack_timer.start()


# ============================================================
# ATAQUE 1 — CHUVA DE RAIOS
# ============================================================

func rain_attack_sequence() -> void:

	if rain_scene == null:
		return

	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return

	var screen_width = get_viewport_rect().size.x
	var left = cam.global_position.x - (screen_width / 2.0)

	var spacing = rain_bar_width * spacing_factor
	var count = int(screen_width / spacing) + 2

	for i in range(count):

		var x_position = left + (i * spacing)
		spawn_rain_bar(x_position)

		await get_tree().create_timer(rain_interval).timeout


func spawn_rain_bar(x_position: float):

	var bar = rain_scene.instantiate()
	get_tree().current_scene.add_child(bar)

	bar.global_position = Vector2(x_position, rain_spawn_height)


# ============================================================
# ATAQUE 2 — SLAM
# ============================================================

func slam_attack_sequence() -> void:
	if is_dead: return
	can_move = false

	await move_to_visual_center()

	# guarda progresso no path
	stored_progress = path_follow.progress

	original_parent = pivot.get_parent()
	pivot.reparent(get_tree().current_scene, true)

	await shake_warning()
	await slam_down()

	spawn_shockwaves()

	await get_tree().create_timer(vulnerable_time).timeout

	await return_from_slam()

	pivot.reparent(original_parent, true)

	path_follow.progress = stored_progress
	pivot.position = Vector2.ZERO

	can_move = true

# ============================================================
# IR PRO CENTRO VISUAL DA TELA
# ============================================================

func move_to_visual_center() -> void:
	if is_dead: return
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return

	var target_x = cam.global_position.x
	var curve: Curve2D = $Path2D.curve
	var length: float = curve.get_baked_length()

	var best_progress := path_follow.progress
	var best_distance := INF

	for i in range(0, int(length), 8):

		var pos: Vector2 = curve.sample_baked(i)
		var dist: float = abs(pos.x - target_x)

		if dist < best_distance:
			best_distance = dist
			best_progress = i

	while abs(path_follow.progress - best_progress) > 4.0:
		path_follow.progress = lerp(path_follow.progress, best_progress, 0.08)
		await get_tree().process_frame


# ============================================================
# TREMER ANTES DE CAIR
# ============================================================

func shake_warning() -> void:
	animation_player.play("abrino_asa")
	var timer := 0.0
	var base_pos := pivot.global_position

	while timer < shake_time:

		timer += get_process_delta_time()

		pivot.global_position = base_pos + Vector2(
			randf_range(-6, 6),
			randf_range(-4, 4)
		)

		await get_tree().process_frame

	pivot.global_position = base_pos



# ============================================================
# DESCER RETO
# ============================================================

func slam_down() -> void:
	if is_dead: return
	hitbox_collision_shape_2d.disabled = false
	while pivot.global_position.y < ground_y and !is_dead:

		pivot.global_position.y += slam_speed * get_process_delta_time()

		await get_tree().process_frame
	audio_stream_player.play()
	pivot.global_position.y = ground_y
	hitbox_collision_shape_2d.disabled = true

# ============================================================
# VOLTAR PRO PATH SUAVEMENTE
# ============================================================

func return_from_slam() -> void:
	if is_dead: return
	var target_y: float = original_parent.global_position.y

	while abs(pivot.global_position.y - target_y) > 2.0 and !is_dead:
		pivot.global_position.y = lerp(pivot.global_position.y, target_y, 0.15)
		await get_tree().process_frame

# ============================================================
# ONDA SÍSMICA
# ============================================================

func spawn_shockwaves():
	if shockwave_scene == null or is_dead:
		return

	var left_wave = shockwave_scene.instantiate()
	var right_wave = shockwave_scene.instantiate()

	get_tree().current_scene.add_child(left_wave)
	get_tree().current_scene.add_child(right_wave)

	left_wave.global_position = pivot.global_position
	right_wave.global_position = pivot.global_position

	left_wave.direction = -1
	right_wave.direction = 1

# ============================================================
# ATAQUE 3 — PENAS DE FOGO
# ============================================================

func feather_attack_sequence() -> void:

	if feather_scene == null:
		return

	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return

	var elapsed := 0.0

	while elapsed < feather_attack_duration:

		spawn_single_feather(cam)

		await get_tree().create_timer(feather_spawn_interval).timeout
		elapsed += feather_spawn_interval

func spawn_single_feather(cam: Camera2D) -> void:

	var view_size = get_viewport_rect().size * cam.zoom

	var left_limit  = cam.global_position.x - (view_size.x / 2.0)
	var right_limit = cam.global_position.x + (view_size.x / 2.0)

	left_limit  += feather_horizontal_padding
	right_limit -= feather_horizontal_padding

	var random_x = randf_range(left_limit, right_limit)

	var feather = feather_scene.instantiate()
	get_tree().current_scene.add_child(feather)

	feather.global_position = Vector2(random_x, feather_spawn_height)

# ============================================================
# RECEBER DANO
# ============================================================

func _on_tomou_dano(value):

	hp.value -= value

	if hp.value <= 0:
		is_dead = true
		call_deferred("_morrer")
	else:
		sprite.modulate = Color(1.0, 0.315, 0.25, 1.0) # vermelho
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1) # normal
		var damage_tween := get_tree().create_tween()
		damage_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _morrer():
	can_move = false
	collision_shape_2d.disabled = true
	body.set_collision_layer_value(3, false)
	body.set_collision_mask_value(1, false)
	set_physics_process(true)
	hp.visible = false
	hitbox_collision_shape_2d.disabled = true
	speed_path_follow = 0 
	animation_player.play("morrendo")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"abrino_asa":
			animation_player.play("idle")
		"morrendo":
			await get_tree().create_timer(1).timeout
			if get_parent().has_signal("matou_boss"):
				get_parent().emit_signal("matou_boss")
			await get_tree().create_timer(1).timeout
			queue_free()
