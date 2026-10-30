extends CanvasLayer
## Pantalla de derrota del modo HARDCORE: se acabó el tiempo y se pierde toda la partida.

const ESCENA_MENU := "res://menu.tscn"
const ESCENA_PRIMER_NIVEL := "res://nivel_1.tscn"

@onready var label_nivel: Label = %LabelNivel
@onready var label_completados: Label = %LabelCompletados
@onready var label_record: Label = %LabelRecord
@onready var btn_reintentar: Button = %BotonReintentar
@onready var btn_menu: Button = %BotonMenu


func _ready() -> void:
	visible = false
	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)


func mostrar(nombre_nivel: String, completados: int) -> void:
	label_nivel.text = "CAISTE EN EL NIVEL %s" % nombre_nivel
	label_completados.text = "NIVELES COMPLETADOS: %d / %d" % [completados, Progreso.TOTAL_NIVELES]
	label_record.text = "RECORD: %d / %d" % [Progreso.hardcore_record, Progreso.TOTAL_NIVELES]
	visible = true
	var panel: Control = $Fondo/Panel
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_reintentar() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	Progreso.modo_hardcore = true
	get_tree().change_scene_to_file(ESCENA_PRIMER_NIVEL)


func _on_menu() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	Progreso.modo_hardcore = false
	get_tree().change_scene_to_file(ESCENA_MENU)
