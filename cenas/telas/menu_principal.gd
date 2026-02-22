extends ColorRect

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/introduction.tscn")



func _on_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/telas/credits_screen.tscn")


func _on_sair_pressed() -> void:
	get_tree().quit()


func _on_controles_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/telas/MenuControles.tscn")
