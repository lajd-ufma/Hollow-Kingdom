extends Node2D


@export var speed_path_follow: float = 300
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var body: CharacterBody2D = $Path2D/PathFollow2D/rafael_body
@onready var tween :Tween
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Path2D/PathFollow2D/rafael_body/hitbox/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var hp: ProgressBar = $Path2D/PathFollow2D/hp

signal tomou_dano

var is_moving := false

# Move Paths
var move_basica = preload("res://tres/rafael_paths/move_basica.tres")
var ataque_queda = preload("res://tres/rafael_paths/ataque_queda.tres")

func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)
	ataque_queda.add_point(Vector2($"../player".position.x, 0))
	$Path2D.curve = ataque_queda
	await get_tree().create_timer(3).timeout
	is_moving = true
	hitbox_collision_shape_2d.disabled = false
	timer.start()
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(body, "rotation_degrees", 360.0, 2.0).from(0.0)

func _process(delta):
	if is_moving:
		path_follow_2d.progress += speed_path_follow * delta

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
	is_moving = false
	tween.stop()


func _on_hitbox_body_entered(body: Node2D) -> void:
	body.emit_signal("tomou_dano", 3)
