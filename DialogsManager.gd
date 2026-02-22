extends Node

func _ready():
	Dialogic.timeline_started.connect(_on_dialog_started)
	Dialogic.timeline_ended.connect(_on_dialog_ended)

# ============================================================
#  INICIAR DIÁLOGOS
# ============================================================
func start_dialog(timeline_name: String) -> void:
	if not Dialogic:
		push_error("Dialogic não encontrado!")
		return
	
	Dialogic.start(timeline_name)
	_pause_move()

# ============================================================
#  CONTROLES GERAIS
# ============================================================
func _pause_move():
	GameManager.can_move = false

func _resume_move():
	GameManager.can_move = true

# ============================================================
#  EVENTOS DO DIALOGIC
# ============================================================
func _on_dialog_started():
	_pause_move()

func _on_dialog_ended():
	_resume_move()
