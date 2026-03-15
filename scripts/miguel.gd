extends Node2D

# ============================================================
# MOVIMENTO
# ============================================================
@onready var hitbox: CollisionShape2D = $"Path Normal Track/PathFollow2D/damage_area_miguel/damage_colision_miguel"

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

signal scream_started
signal grito
signal tomou_dano


# ============================================================
# REFERÊNCIAS
# ============================================================

@onready var normal_path: Path2D = $"Path Normal Track"
@onready var sweep_path: Path2D = $"Path_Sweep"
@onready var path_follow: PathFollow2D = $"Path Normal Track/PathFollow2D"
@onready var anim: AnimationPlayer = $"Path Normal Track/PathFollow2D/miguel_body/AnimationPlayer"
@onready var attack_timer: Timer = Timer.new()
@onready var hp: ProgressBar = $"Path Normal Track/PathFollow2D/miguel_body/Sprite2D/hp"
@onready var body: CharacterBody2D = $"Path Normal Track/PathFollow2D/miguel_body"
@onready var collision_shape_2d: CollisionShape2D = $"Path Normal Track/PathFollow2D/miguel_body/CollisionShape2D"
@onready var damage_colision_miguel: CollisionShape2D = $"Path Normal Track/PathFollow2D/damage_area_miguel/damage_colision_miguel"
@onready var animation_player: AnimationPlayer = $"Path Normal Track/PathFollow2D/miguel_body/AnimationPlayer"
@onready var grito_sound: AudioStreamPlayer2D = $"Path Normal Track/PathFollow2D/miguel_body/grito_sound"
@onready var cpu_particles_2d: CPUParticles2D = $"Path Normal Track/PathFollow2D/miguel_body/CPUParticles2D"
@onready var sprite: Sprite2D = $"Path Normal Track/PathFollow2D/miguel_body/Sprite2D"


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
	set_physics_process(false)
	tomou_dano.connect(_on_tomou_dano)
	hitbox.disabled = true
	randomize()

	add_child(attack_timer)
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_choose_attack)
	attack_timer.start()

	path_length = normal_path.curve.get_baked_length()
	virtual_progress = path_follow.progress

func _physics_process(delta: float) -> void:
	body.velocity += body.get_gravity() * delta
	body.move_and_slide()

func _process(delta: float) -> void:
	if !GameManager.can_move: return

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
	grito_sound.play()
	cpu_particles_2d.emitting = true
	play_anim("scream")
	emit_signal("scream_started")
	await scream_attack()
	current_stop_index = (current_stop_index + 1) % stop_ratios.size()
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
	hitbox.disabled = false
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
	hitbox.disabled = true
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
	play_anim("idle")
	virtual_progress += speed * delta
	path_follow.progress = fmod(virtual_progress, path_length)

func play_anim(name: String) -> void:

	if anim == null:
		return

	if anim.current_animation != name:
		anim.play(name)
		
# =====================================================
# SISTEMA DE DANO
# =====================================================

func _on_tomou_dano(value):
	print("Miguel tomou dano")
	hp.value -= value

	if hp.value <= 0:
		set_process(false)
		set_physics_process(true)
		call_deferred("_morrer")
	else:
		sprite.modulate = Color(1.0, 0.315, 0.25, 1.0) # vermelho
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1) # normal
		var damage_tween := get_tree().create_tween()
		damage_tween.tween_property(self, "modulate", Color.WHITE, 0.2)


func _on_hitbox_body_entered(body: Node2D) -> void:
	body.emit_signal("tomou_dano", 3)

func _morrer():
	if $"../espada_miguel":
		$"../espada_miguel".queue_free()
	body.set_collision_mask_value(1,false)
	body.set_collision_layer_value(3,false)
	collision_shape_2d.disabled = true
	hp.visible = false
	damage_colision_miguel.disabled = true
	speed = 0 
	animation_player.play("morrendo")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	await get_tree().create_timer(1).timeout
	if get_parent().has_signal("matou_boss"):
		get_parent().emit_signal("matou_boss")
	await get_tree().create_timer(1).timeout
	queue_free()
