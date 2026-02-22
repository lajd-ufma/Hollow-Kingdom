extends Area2D

# ============================================================
# CONFIGURAÇÃO VISUAL
# ============================================================

@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D   # sprite vermelho

@export var blink_time: float = 1.2     # tempo piscando (durante grito)
@export var blink_speed: float = 0.08   # velocidade do pisca
@export var active_time: float = 0.6    # tempo causando dano depois

var warning_active: bool = false


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	hitbox.disabled = true
	sprite.visible = false


# ============================================================
# FUNÇÃO CHAMADA QUANDO O BOSS COMEÇA O GRITO
# (VOCÊ VAI CONECTAR NO EDITOR)
# ============================================================
func _on_miguel_scream_started() -> void:
	warning_active = true
	sprite.visible = true

	await _blink_warning()

	# terminou o telegraph → ativa dano
	hitbox.disabled = false

	await get_tree().create_timer(active_time).timeout

	hitbox.disabled = true
	sprite.visible = false
	warning_active = false # Replace with function body.

# ============================================================
# EFEITO DE PISCAR
# ============================================================

func _blink_warning() -> void:

	var timer: float = 0.0

	while timer < blink_time:

		sprite.visible = !sprite.visible

		await get_tree().create_timer(blink_speed).timeout
		timer += blink_speed

	sprite.visible = true  # garante que termina visível


# ============================================================
# DANO
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if hitbox.disabled:
		return

	if body.has_signal("tomou_dano"):
		body.emit_signal("tomou_dano", 3)
