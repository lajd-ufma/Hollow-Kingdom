extends CharacterBody2D

@export_category("movement variable")
@export var move_speed = 120.0
@export var deceleration = 0.1
@export var gravity = 350.0
var movement = Vector2()

@export_category("Jump variable")
@export var jump_speed = 250.0
@export var acceleration = 290.0
@export var jump_amount = 2

@export_category("wall jump variable")
@export var wall_slide = 150
@onready var left_ray: RayCast2D = $raycast/left_ray
@onready var right_ray: RayCast2D = $raycast/right_ray
@onready var anim: AnimationPlayer = $anim
@export var wall_x_force = 200.0
@export var wall_y_force = -220.0
var is_wall_jumping = false

@export_category("dash variable")
@export var dash_speed = 400.0
@export var facing_right = true
@export var dash_gravity = 0
@export var dash_number = 1
var dash_key_pressed = 0
var is_dashing = false
var is_atacking = false
var is_atacking_up = false
var is_atacking_down = false
var dash_timer = Timer

@onready var shoot := preload("res://cenas/shoot.tscn")
@onready var spawnpoint_shoot: Marker2D = $spawnpoint_shoot
@onready var barra_mana: ProgressBar = $hud/mana
@onready var hp: ProgressBar = $hud/hp

signal tomou_dano

func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)

func _on_tomou_dano(value):
	hp.value -= value
	if hp.value<=0:
		print("morreu")
		get_tree().reload_current_scene()
	else:
		var tween_damage :=get_tree().create_tween()
		var tween_knockback :=get_tree().create_tween()
		tween_knockback.tween_property(self, "velocity:y", 100, 0.2)
		tween_damage.tween_property(self, "modulate", Color.RED, 0.1)
		tween_damage.tween_property(self, "modulate", Color.WHITE, 0.1)

func _physics_process(delta: float) -> void:
	if is_dashing == false:
		velocity.y += gravity * delta
	elif is_dashing == true:
		velocity.y = dash_gravity
		
	move_and_slide()
	wall_logic()

func _process(delta: float) -> void:
	horizontal_movement()
	set_animations()
	flip()

func _input(event: InputEvent) -> void:
	jump_logic()
	if Input.is_action_just_pressed("special") and barra_mana.value-3>0:
		barra_mana.value-=3
		var shoot_instance = shoot.instantiate()
		shoot_instance.global_position = spawnpoint_shoot.position
		add_child(shoot_instance)
	elif Input.is_action_just_pressed("atack"):
		if Input.is_action_pressed("up"):
			is_atacking_up = true
		elif Input.is_action_pressed("down") and not is_on_floor():
			is_atacking_down = true
		else:
			is_atacking = true
	
func horizontal_movement():
	if is_wall_jumping == false and is_dashing == false:
		movement = Input.get_axis("ui_left", "ui_right")
		
		if movement:
			velocity.x = movement * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed * deceleration)
			
	if Input.is_action_just_pressed("ui_dash") and dash_key_pressed == 0 and dash_number >= 1:
		dash_number -= 1
		dash_key_pressed = 1
		dash()
	
func set_animations():
	var animation_name = "idle"
	if is_atacking_up:
		animation_name = "atack_up"
	elif is_atacking_down:
		animation_name = "atack_down"
	elif is_atacking:
		animation_name = "atack"
	elif velocity.x != 0 and is_on_floor():
		animation_name = "move"
	elif velocity.y < 0:
		animation_name = "jump"
	elif velocity.y > 10 or is_on_wall_only() or is_dashing:
		animation_name = "fall"
	anim.play(animation_name)
func flip():
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y * 1
		wall_x_force = 200.0
	elif velocity.x < 0.0:
		facing_right = false 
		scale.x = scale.y * -1
		wall_x_force = -200.0
		
func jump_logic():
	if is_on_floor():
		dash_number = 1
		jump_amount = 2
		if Input.is_action_just_pressed("jump"):
			jump_amount -= 1
			velocity.y -= lerp(jump_speed, acceleration, 0.1)

	else:
		if jump_amount > 0:
			if Input.is_action_just_pressed("jump"):
				jump_amount -= 1
				velocity.y -= lerp(jump_speed, acceleration, 1)
			if Input.is_action_just_released("jump"):
				velocity.y = lerp(velocity.y, gravity, 0.2)
				velocity.y *= 0.3

func wall_logic():
	if is_on_wall_only():
		velocity.y += wall_slide * get_physics_process_delta_time()
		if Input.is_action_just_pressed("jump"):
			#if left_ray.is_colliding():
				#velocity = Vector2(wall_x_force, wall_y_force)
				#wall_jumping()
			if right_ray.is_colliding():
				jump_amount = 2
				velocity = Vector2(-wall_x_force, wall_y_force)
				wall_jumping()
				
func wall_jumping():
	is_wall_jumping = true 
	await get_tree().create_timer(0.12).timeout
	is_wall_jumping = false
	
func dash():
	if dash_key_pressed == 1:
		is_dashing = true
	else:
		is_dashing = false
		
	if facing_right == true:
		velocity.x = dash_speed
		dash_started()
	if facing_right == false:
		velocity.x = -dash_speed
		dash_started()

func dash_started():
	if is_dashing == true:
		dash_key_pressed = 1
		await get_tree().create_timer(0.16).timeout
		is_dashing = false
		dash_key_pressed = 0

func _on_anim_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"atack":
			is_atacking = false
		"atack_up":
			is_atacking_up = false
		"atack_down":
			is_atacking_down = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_signal("tomou_dano"):
		body.emit_signal("tomou_dano", 20)


func _on_hitbox_down_body_entered(body: Node2D) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "velocity:y", -100, 0.25)
	if body.has_signal("tomou_dano"):
		body.emit_signal("tomou_dano", 20)
