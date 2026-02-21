extends Button

@onready var pluma: Sprite2D = $pluma


func _ready():
	pluma.modulate.a = 0
	pluma.position.x -= 10 
	

func _on_mouse_entered():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pluma, "modulate:a", 1.0, 0.2)
	tween.tween_property(pluma, "position:x", 200, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	var float_tween = create_tween().set_loops()
	float_tween.tween_property(pluma, "position:y", pluma.position.y - 5, 0.6).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(pluma, "position:y", pluma.position.y, 0.6).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pluma, "modulate:a", 0.0, 0.2)
	tween.tween_property(pluma, "position:x", -10.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
