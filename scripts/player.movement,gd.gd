extends CharacterBody2D

@export_category("movement variable")
@export var move_speed = 120.0
@export var deceleration = 0.1
@export var gravity = 500.0
var movement = Vector2()

@export_category("Jump variable")
@export var jump_speed = 190.0
@export var acceleration = 290.0
@export var jump_amount = 2

@export_category("wall jump variable")
@export var wall_slide = 10
@onready var left_ray: RayCast2D = $raycast/left_ray
@onready var right_ray: RayCast2D = $raycast/right_ray
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
var dash_timer = Timer


func _physics_process(delta: float) -> void:
	if is_dashing == false:
		velocity.y += gravity * delta
	elif is_dashing == true:
		velocity.y = dash_gravity
		
	horizontal_movement()
	set_animations()
	move_and_slide()
	flip()
	jump_logic()
	wall_logic()
	
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
	if velocity.x != 0 and is_on_floor():
		$anim.play("move")
	if velocity.x == 0 and is_on_floor():
		$anim.play("idle")
	if velocity.y < 0:
		$anim.play("jump")
	if velocity.y > 10:
		$anim.play("fall")
	if is_on_wall_only():
		$anim.play("fall")
	if is_dashing == true:
		$anim.play("fall")
		
func flip():
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y * 1
		wall_x_force = 200.0
	if velocity.x < 0.0:
		facing_right = false 
		scale.x = scale.y * -1
		wall_x_force = -200.0
		
func jump_logic():
	if is_on_floor():
		dash_number = 1
		jump_amount = 2
		if Input.is_action_just_pressed("ui_accept"):
			jump_amount -= 1
			velocity.y -= lerp(jump_speed, acceleration, 0.1)
			
	if not is_on_floor():
		if jump_amount > 0:
			if Input.is_action_just_pressed("ui_accept"):
				jump_amount -= 1
				velocity.y -= lerp(jump_speed, acceleration, 1)
			if Input.is_action_just_released("ui_accept"):
				velocity.y = lerp(velocity.y, gravity, 0.2)
				velocity.y *= 0.3
	else:
		return
		
func wall_logic():
	if is_on_wall_only():
		velocity.y = wall_slide
		if Input.is_action_just_pressed("ui_accept"):
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
	
	else:
		return 
