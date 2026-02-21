extends Button

@onready var pluma: Sprite2D = $pluma
var float_tween: Tween

func _ready():
	# Pivot no centro para o efeito de scale não "fugir" do lugar
	pivot_offset = size / 2
	
	pluma.modulate.a = 0
	pluma.position.x = -10

func _on_mouse_entered():
	if float_tween:
		float_tween.kill()
		
	var tween = create_tween().set_parallel(true)
	
	var target_x = size.x + 20 
	
	tween.tween_property(pluma, "modulate:a", 1.0, 0.2)
	tween.tween_property(pluma, "position:x", target_x, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	
	float_tween = create_tween().set_loops()

	float_tween.tween_property(pluma, "position:y", -5.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(pluma, "position:y", 5.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)

func _on_mouse_exited():
	if float_tween:
		float_tween.kill()
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pluma, "modulate:a", 0.0, 0.2)
	tween.tween_property(pluma, "position:x", -10.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(pluma, "position:y", size.y / 2, 0.2)
