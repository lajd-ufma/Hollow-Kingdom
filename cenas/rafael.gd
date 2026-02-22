extends Node2D

# =====================================================
# CONFIGURAÇÕES EDITÁVEIS
# =====================================================

@export var return_pause_time: float = 0.8
@export var speed_path_follow: float = 300
@export var ground_pause_time: float = 1.5
@export var dive_arc_height: float = 250.0   # Altura da parábola do mergulho

# =====================================================
# REFERÊNCIAS DE NÓS
# =====================================================

@onready var camera: Camera2D = $"../player/Camera2D"
@onready var path_2d: Path2D = $Path2D
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var body: CharacterBody2D = $Path2D/PathFollow2D/rafael_body
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/rafael_body/hitbox/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var hp: ProgressBar = $Path2D/PathFollow2D/hp
@onready var rafael_spawn_point: Marker2D = $"../rafael_spawn_point"
@onready var player: CharacterBody2D = $"../player"
@onready var animation_player: AnimationPlayer = $Path2D/PathFollow2D/rafael_body/AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/rafael_body/CollisionShape2D

signal tomou_dano

# =====================================================
# ESTADOS DO BOSS
# =====================================================

var current_state := "idle"
var tween: Tween

# =====================================================
# CURVAS
# =====================================================

var move_basica = preload("res://tres/rafael_paths/move_basica.tres")
var ataque_queda_original = preload("res://tres/rafael_paths/ataque_queda.tres")
var return_curve := Curve2D.new()


# =====================================================
# INICIALIZAÇÃO
# =====================================================

func _ready() -> void:
	set_physics_process(false)
	tomou_dano.connect(_on_tomou_dano)

	# Define curva inicial (ataque horizontal)
	path_2d.curve = move_basica
	path_follow_2d.progress = 0
	path_follow_2d.cubic_interp = true   # Suaviza interpolação

	# Hitbox começa desativada
	hitbox_collision_shape_2d.disabled = true

	# Pequeno delay antes de iniciar comportamento
	await get_tree().create_timer(2).timeout

	current_state = "horizontal_attack"
	timer.start()

func _physics_process(delta: float) -> void:
	body.velocity += body.get_gravity() * delta
	body.move_and_slide()

# =====================================================
# LOOP PRINCIPAL
# =====================================================

func _process(delta):
	if !GameManager.can_move: return
	match current_state:

		# -----------------------------------------
		# ATAQUE HORIZONTAL (ATRAVESSA A ARENA)
		# -----------------------------------------
		"horizontal_attack":

			hitbox_collision_shape_2d.disabled = false

			path_follow_2d.progress += speed_path_follow * delta

			# Mantém movimento contínuo
			if path_follow_2d.progress_ratio >= 1.0:
				path_follow_2d.progress = 0


		# -----------------------------------------
		# PREPARAÇÃO PARA MERGULHO
		# -----------------------------------------
		"aiming":
			_start_aiming()


		# -----------------------------------------
		# MERGULHO EM PARÁBOLA
		# -----------------------------------------
		"diving":

			hitbox_collision_shape_2d.disabled = false

			path_follow_2d.progress += speed_path_follow * 2 * delta

			# Quando termina a curva
			if path_follow_2d.progress_ratio >= 1.0:
				_end_dive()


		# -----------------------------------------
		# PAUSA APÓS IMPACTO NO CHÃO
		# -----------------------------------------
		"ground_pause":
			pass


		# -----------------------------------------
		# RETORNO AO PONTO INICIAL
		# -----------------------------------------
		"returning":
			path_follow_2d.progress += speed_path_follow * delta

			if path_follow_2d.progress_ratio >= 1.0:
				_finish_return()
				


# =====================================================
# TRANSIÇÃO DO ATAQUE HORIZONTAL PARA MERGULHO
# =====================================================

func _on_timer_timeout() -> void:
	if current_state == "horizontal_attack":
		hitbox_collision_shape_2d.disabled = true
		current_state = "aiming"


# =====================================================
# CONFIGURA E INICIA O MERGULHO
# =====================================================

func _start_aiming() -> void:

	current_state = "idle"

	await get_tree().create_timer(0.8).timeout

	# Duplicamos a curva original para não modificar o recurso base
	var attack_curve: Curve2D = ataque_queda_original.duplicate()

	var player_local = path_2d.to_local(player.global_position)
	var ground_local = path_2d.to_local(rafael_spawn_point.global_position)

	# -----------------------------------------
	# Ajuste do ponto final (garante altura exata do chão)
	# -----------------------------------------
	var final_point = Vector2(player_local.x, ground_local.y)

	# -----------------------------------------
	# Ajuste do ponto intermediário para suavizar parábola
	# -----------------------------------------
	var middle_point = Vector2(player_local.x, ground_local.y - dive_arc_height)

	if attack_curve.point_count >= 2:
		attack_curve.set_point_position(attack_curve.point_count - 2, middle_point)

	if attack_curve.point_count >= 1:
		attack_curve.set_point_position(attack_curve.point_count - 1, final_point)

	path_2d.curve = attack_curve
	path_follow_2d.progress = 0

	current_state = "diving"


# =====================================================
# FINAL DO MERGULHO (IMPACTO NO CHÃO)
# =====================================================

func _end_dive():

	var ground_y = path_2d.to_local(rafael_spawn_point.global_position).y
	path_follow_2d.position.y = ground_y

	hitbox_collision_shape_2d.disabled = true

	#  CAMERA SHAKE
	camera.shake(12.0)

	current_state = "ground_pause"

	await get_tree().create_timer(ground_pause_time).timeout
	
	hitbox_collision_shape_2d.disabled = false
	_start_return()

# =====================================================
# INÍCIO DO RETORNO
# =====================================================

func _start_return():

	var current_global = path_follow_2d.global_position
	var current_local = path_2d.to_local(current_global)
	var spawn_local = path_2d.to_local(rafael_spawn_point.global_position)

	return_curve.clear_points()
	return_curve.add_point(current_local)
	return_curve.add_point(spawn_local)

	path_2d.curve = return_curve
	path_follow_2d.progress = 0

	current_state = "returning"


# =====================================================
# FINALIZA RETORNO
# =====================================================

func _finish_return():

	path_2d.curve = move_basica
	path_follow_2d.progress = 0

	current_state = "idle"

	await get_tree().create_timer(return_pause_time).timeout

	current_state = "horizontal_attack"
	timer.start()


# =====================================================
# SISTEMA DE DANO
# =====================================================

func _on_tomou_dano(value):

	# Boss não toma dano durante ataques ativos
	if current_state == "diving":
		return

	hp.value -= value

	if hp.value <= 0:
		set_process(false)
		set_physics_process(true)
		call_deferred("_morrer")
	else:
		var damage_tween := get_tree().create_tween()
		damage_tween.tween_property(self, "modulate", Color.WHITE, 0.2)


func _on_hitbox_body_entered(body: Node2D) -> void:
	body.emit_signal("tomou_dano", 3)

func _morrer():
	body.set_collision_mask_value(1,false)
	body.set_collision_layer_value(3,false)
	collision_shape_2d.disabled = true
	hp.visible = false
	hitbox_collision_shape_2d.disabled = true
	speed_path_follow = 0 
	animation_player.play("morrendo")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	await get_tree().create_timer(3).timeout
	if get_parent().has_signal("matou_boss"):
		get_parent().emit_signal("matou_boss")
	await get_tree().create_timer(1).timeout
	queue_free()
