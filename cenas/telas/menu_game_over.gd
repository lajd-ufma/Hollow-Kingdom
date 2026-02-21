extends Control

func _on_reiniciar_btn_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
func _on_sair_btn_pressed():
	get_tree().quit()
