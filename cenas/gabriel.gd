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


# ============================================================
# ESTADO
# ============================================================

var original_parent: Node = null
var on_path: bool = true
var stored_progress: float = 0.0
var is_attacking := false
var can_move := true


# ============================================================
# READY
# ============================================================

func _ready():
	randomize()

	# 🔴 ESSENCIAL → impede o PathFollow de empurrar o boss pro lado
	path_follow.rotates = false
	path_follow.h_offset = 0
	path_follow.v_offset = 0

	gabriel_body.tomou_dano_request.connect(_on_tomou_dano)

	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()


# ============================================================
# MOVIMENTO NORMAL DO BOSS
# ============================================================

func _process(delta):
	if can_move and on_path:
		path_follow.progress += speed_path_follow * delta

# ============================================================
# ESCOLHER ATAQUE
# ============================================================

func _on_attack_timer_timeout():

	if is_attacking:
		return

	is_attacking = true
	attack_timer.stop()

	var attack_type = randi() % 2

	if attack_type == 0:
		await rain_attack_sequence()
	else:
		await slam_attack_sequence()

	is_attacking = false
	attack_timer.start()


# ============================================================
# ATAQUE 1 — CHUVA DE RAIOS (INALTERADO)
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
# ATAQUE 2 — SLAM (AGORA 100% ESTÁVEL)
# ============================================================

func slam_attack_sequence() -> void:

	can_move = false

	await move_to_visual_center()

	# guarda progresso no path
	stored_progress = path_follow.progress

	# 🔴 SOLTA DO PATH DO JEITO CERTO (SEM QUEBRAR POSIÇÃO)
	original_parent = pivot.get_parent()
	pivot.reparent(get_tree().current_scene, true) # <-- ESSA LINHA CONSERTA TUDO

	await shake_warning()
	await slam_down()

	spawn_shockwaves()

	await get_tree().create_timer(vulnerable_time).timeout

	await return_from_slam()

	# 🔵 VOLTA PRO PATH SEM TELEPORTAR
	pivot.reparent(original_parent, true)

	# reposiciona o PathFollow de volta onde estava
	path_follow.progress = stored_progress

	pivot.position = Vector2.ZERO

	can_move = true

	# solta do PathFollow (AGORA ele fica livre de verdade)
	original_parent = pivot.get_parent()

	# guarda posição mundial antes de soltar
	var saved_global := pivot.global_position

	original_parent.remove_child(pivot)
	get_tree().current_scene.add_child(pivot)

	# restaura posição mundial (impede ir pro 0,0)
	pivot.global_position = saved_global

	await shake_warning()
	await slam_down()

	spawn_shockwaves()

	await get_tree().create_timer(vulnerable_time).timeout

	await return_from_slam()

	# devolve pro trilho
	saved_global = pivot.global_position

	get_tree().current_scene.remove_child(pivot)
	original_parent.add_child(pivot)

	pivot.global_position = saved_global
	pivot.position = Vector2.ZERO

	path_follow.progress = stored_progress


	can_move = true


# ============================================================
# IR PRO CENTRO VISUAL DA TELA
# ============================================================

func move_to_visual_center() -> void:

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
# DESCER RETO (SEM INTERFERIR NO PATH)
# ============================================================

func slam_down() -> void:

	while pivot.global_position.y < ground_y:

		pivot.global_position.y += slam_speed * get_process_delta_time()

		await get_tree().process_frame

	pivot.global_position.y = ground_y




# ============================================================
# VOLTAR PRO PATH SUAVEMENTE
# ============================================================

func return_from_slam() -> void:

	var target_y: float = original_parent.global_position.y

	while abs(pivot.global_position.y - target_y) > 2.0:

		pivot.global_position.y = lerp(pivot.global_position.y, target_y, 0.15)

		await get_tree().process_frame




# ============================================================
# ONDA SÍSMICA
# ============================================================

func spawn_shockwaves():

	if shockwave_scene == null:
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
# RECEBER DANO
# ============================================================

func _on_tomou_dano(value):
	print("Gabriel tomou dano:", value)
