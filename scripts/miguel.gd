extends Node2D

# ============================================================
# MOVIMENTO
# ============================================================

var virtual_progress: float = 0.0
var path_length: float = 0.0

@export var speed: float = 100.0

# Centros do infinito onde ele pode parar
@export var stop_ratios: Array[float] = [0.23, 0.73]

var current_stop_index: int = 0

@export_range(0.0, 1.0, 0.01)
var return_ratio: float = 0.66

# ============================================================
# ATAQUES
# ============================================================

@export var attack_cooldown: float = 3.0
@export var shake_time: float = 1.2
@export var sweep_speed_multiplier: float = 1.4

signal grito


# ============================================================
# REFERÊNCIAS
# ============================================================

@onready var normal_path: Path2D = $"Path Normal Track"
@onready var sweep_path: Path2D = $"Path_Sweep"
@onready var path_follow: PathFollow2D = $"Path Normal Track/PathFollow2D"

@onready var attack_timer: Timer = Timer.new()


# ============================================================
# MÁQUINA DE ESTADOS
# ============================================================

enum BossState {
	WALKING,
	MOVING_TO_CENTER,
	SCREAMING,
	SWEEPING
}

var state: BossState = BossState.WALKING
var target_progress: float = 0.0
var queued_attack: String = ""
var using_sweep_path := false


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	randomize()

	add_child(attack_timer)
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_choose_attack)
	attack_timer.start()

	path_length = normal_path.curve.get_baked_length()
	virtual_progress = path_follow.progress


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	match state:

		BossState.WALKING:
			_move_forward(delta)

		BossState.MOVING_TO_CENTER:
			_move_to_center(delta)

		BossState.SCREAMING:
			pass

		BossState.SWEEPING:
			_do_sweep(delta)


# ============================================================
# ESCOLHE ATAQUE
# ============================================================

func _choose_attack() -> void:

	if state != BossState.WALKING:
		return

	var attack_type := randi() % 2

	if attack_type == 0:
		queued_attack = "SCREAM"
	else:
		queued_attack = "SWEEP"

	_go_to_center()


# ============================================================
# IR ATÉ O CENTRO DO INFINITO
# ============================================================

func _go_to_center() -> void:

	if stop_ratios.is_empty():
		return

	var stop_ratio: float = stop_ratios[current_stop_index]
	var stop_point: float = stop_ratio * path_length

	var lap: float = floor(virtual_progress / path_length)

	target_progress = lap * path_length + stop_point

	if target_progress <= virtual_progress:
		target_progress += path_length

	state = BossState.MOVING_TO_CENTER


func _move_to_center(delta: float) -> void:

	virtual_progress += speed * delta

	if virtual_progress >= target_progress:

		virtual_progress = target_progress
		path_follow.progress = fmod(virtual_progress, path_length)

		_arrived_at_center()
		return

	path_follow.progress = fmod(virtual_progress, path_length)


func _arrived_at_center() -> void:

	current_stop_index = (current_stop_index + 1) % stop_ratios.size()

	if queued_attack == "SCREAM":
		_start_scream()

	elif queued_attack == "SWEEP":
		_start_sweep()


# ============================================================
# ATAQUE — SCREAM
# ============================================================

func _start_scream() -> void:

	state = BossState.SCREAMING
	await scream_attack()
	state = BossState.WALKING


func scream_attack() -> void:

	var timer: float = 0.0
	var base_pos: Vector2 = global_position

	while timer < shake_time:

		timer += get_process_delta_time()

		global_position = base_pos + Vector2(
			randf_range(-6, 6),
			randf_range(-4, 4)
		)

		await get_tree().process_frame

	global_position = base_pos

	print("BOSS GRITOU")
	emit_signal("grito")


# ============================================================
# ATAQUE — SWEEP (TROCA DE PATH)
# ============================================================

func _start_sweep() -> void:

	state = BossState.SWEEPING
	using_sweep_path = true

	# move o PathFollow para o Path_Sweep
	path_follow.get_parent().remove_child(path_follow)
	sweep_path.add_child(path_follow)

	path_follow.progress = 0.0
	virtual_progress = 0.0

	path_length = sweep_path.curve.get_baked_length()


func _do_sweep(delta: float) -> void:

	var sweep_speed := speed * sweep_speed_multiplier
	virtual_progress += sweep_speed * delta

	if virtual_progress >= path_length:
		_finish_sweep()
		return

	path_follow.progress = virtual_progress


func _finish_sweep() -> void:

	using_sweep_path = false

	# Remove do Path_Sweep
	path_follow.get_parent().remove_child(path_follow)

	# Recoloca no Path normal
	normal_path.add_child(path_follow)

	# Atualiza comprimento do path normal
	path_length = normal_path.curve.get_baked_length()

	# ============================
	# AQUI ESTÁ A CORREÇÃO REAL
	# ============================

	# Calcula posição desejada (66% do infinito)
	var return_progress: float = return_ratio * path_length

	# Zera o virtual e reposiciona LIMPO
	virtual_progress = return_progress
	path_follow.progress = return_progress

	# ============================

	state = BossState.WALKING

	print("SWEEP TERMINOU → voltou pro infinito")


# ============================================================
# MOVIMENTO NORMAL (∞)
# ============================================================

func _move_forward(delta: float) -> void:

	virtual_progress += speed * delta
	path_follow.progress = fmod(virtual_progress, path_length)
