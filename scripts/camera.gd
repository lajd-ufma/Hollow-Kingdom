extends Camera2D

var shake_amount := 6
var shake_time := 0.2
var shake_timer := 0.0

func shake():
	shake_timer = shake_time

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		offset = Vector2.ZERO
