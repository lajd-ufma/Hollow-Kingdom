extends CharacterBody2D

signal tomou_dano

func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)
	
func _on_tomou_dano(value):
	$"../../..".emit_signal("tomou_dano", value)
