extends Area2D

@export var damage :=10
@export var speed = 10
var direction = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(3).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.x+= speed*direction

func _on_body_entered(body: Node2D) -> void:
	body.emit_signal("tomou_dano", damage)
	queue_free()
