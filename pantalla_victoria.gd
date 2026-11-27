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

func mostrar(golpes: int, nivel_siguiente: String, par: int = 0, nuevo_record: bool = false,
		hardcore: bool = false, tiempo_sobrante: float = 0.0) -> void:
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

	# el ultimo nivel no sigue a otro nivel sino a la pantalla final con las estadisticas
	if nivel_siguiente.ends_with("pantalla_final.tscn"):
		btn_siguiente.text = "VER RESULTADOS"

	if hardcore:
		# en hardcore no se puede reintentar: cada nivel se juega una sola vez
		btn_reintentar.visible = false
		label_record.visible = true
		label_record.text = "TIEMPO SOBRANTE: %d s" % int(ceil(maxf(tiempo_sobrante, 0.0)))
	_mostrar_restantes(hardcore)
	visible = true
	Sonidos.jingle("victoria")

## Linea "QUEDAN N NIVELES" debajo del resultado
func _mostrar_restantes(_hardcore: bool) -> void:
	var restantes := maxi(Progreso.TOTAL_NIVELES - _nivel_actual(), 0)
	var l := Label.new()
	l.text = "¡COMPLETASTE LOS %d NIVELES!" % Progreso.TOTAL_NIVELES if restantes == 0 else ("QUEDA 1 NIVEL" if restantes == 1 else "QUEDAN %d NIVELES" % restantes)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.3372549, 0.8, 0.5411765))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	if ResourceLoader.exists("res://assets/w3-ip.ttf"):
		l.add_theme_font_override("font", load("res://assets/w3-ip.ttf"))
	label_golpes.get_parent().add_child(l)
	label_golpes.get_parent().move_child(l, label_golpes.get_index() + 1)


func _nivel_actual() -> int:
	var raiz := get_tree().current_scene
	return int(raiz.numero_nivel) if raiz and "numero_nivel" in raiz else 0


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
