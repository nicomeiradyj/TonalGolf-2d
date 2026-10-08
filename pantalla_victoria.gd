extends CanvasLayer

@onready var label_resultado: Label = %Resultado
@onready var label_golpes: Label = %Golpes
@onready var label_record: Label = %Record
@onready var btn_siguiente: Button = %BotonSiguiente
@onready var btn_reintentar: Button = %BotonReintentar
@onready var btn_menu: Button = %BotonMenu

var siguiente_nivel: String = ""

func _ready() -> void:
	visible = false
	btn_siguiente.pressed.connect(_on_siguiente)
	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)

func mostrar(golpes: int, nivel_siguiente: String, par: int = 0, nuevo_record: bool = false) -> void:
	siguiente_nivel = nivel_siguiente

	if golpes == 1:
		label_golpes.text = "¡En un solo golpe!"
	else:
		label_golpes.text = "Golpes: %d" % golpes

	if par > 0:
		label_resultado.text = _nombre_resultado(golpes, par)
		label_resultado.visible = true
	else:
		label_resultado.visible = false

	label_record.visible = nuevo_record
	btn_siguiente.visible = ResourceLoader.exists(siguiente_nivel)
	visible = true

# Terminología de golf según la diferencia contra el par
func _nombre_resultado(golpes: int, par: int) -> String:
	if golpes == 1:
		return "HOLE IN ONE!"
	var diferencia := golpes - par
	match diferencia:
		-2: return "EAGLE!"
		-1: return "BIRDIE!"
		0: return "PAR"
		1: return "BOGEY"
		2: return "DOBLE BOGEY"
	if diferencia < -2:
		return "ALBATROSS!"
	return "+%d SOBRE EL PAR" % diferencia

func _on_siguiente() -> void:
	Sonidos.reproducir("click")
	get_tree().change_scene_to_file(siguiente_nivel)

func _on_reintentar() -> void:
	Sonidos.reproducir("click")
	get_tree().reload_current_scene()

func _on_menu() -> void:
	Sonidos.reproducir("click")
	get_tree().change_scene_to_file("res://menu.tscn")
