extends ColorRect

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/playground.tscn")



func _on_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/telas/credits_screen.tscn")


func _on_sair_pressed() -> void:
	get_tree().quit()
