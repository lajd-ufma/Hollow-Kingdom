extends CharacterBody2D

signal tomou_dano
@onready var node_pai = $"../../.."
func _ready() -> void:
	tomou_dano.connect(_on_tomou_dano)

func _on_tomou_dano(value):
	node_pai.emit_signal("tomou_dano", value)
