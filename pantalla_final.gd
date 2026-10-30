extends Control
## Pantalla final: aparece al completar el último nivel (normal o hardcore) y
## muestra tus mejores estadísticas de toda la partida.

const ESCENA_MENU := "res://menu.tscn"
const ESCENA_NIVEL_1 := "res://nivel_1.tscn"
const RUTA_FUENTE := "res://assets/w3-ip.ttf"
const DORADO := Color(1.0, 0.85, 0.3)
const VERDE := Color(0.3372549, 0.8, 0.5411765)

@onready var titulo: Label = %Titulo
@onready var rango: Label = %Rango
@onready var resumen: VBoxContainer = %Resumen
@onready var grilla: GridContainer = %Grilla
@onready var btn_jugar: Button = %BotonJugar
@onready var btn_menu: Button = %BotonMenu


func _ready() -> void:
	get_tree().paused = false
	var hardcore := Progreso.modo_hardcore
	var datos := Progreso.estadisticas()

	titulo.text = "¡HARDCORE\nCOMPLETADO!" if hardcore else "¡JUEGO\nCOMPLETADO!"
	if hardcore:
		titulo.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	rango.text = _rango(datos)

	_agregar_linea(_texto_golpes(datos), Color.WHITE)
	_agregar_linea("HOYOS EN UNO: %d" % datos.hoyos_en_uno, DORADO if datos.hoyos_en_uno > 0 else Color.WHITE)
	_agregar_linea("NIVELES CON PAR O MEJOR: %d / %d" % [datos.par_o_mejor, Progreso.TOTAL_NIVELES], VERDE)
	_agregar_linea("RECORD HARDCORE: %d / %d" % [datos.record_hardcore, Progreso.TOTAL_NIVELES], Color(1.0, 0.5, 0.45))

	_llenar_grilla()
	btn_jugar.pressed.connect(_on_jugar)
	btn_menu.pressed.connect(_on_menu)
	_entrada()
	_confeti()
	Sonidos.jingle("victoria_final")


func _rango(datos: Dictionary) -> String:
	if datos.jugados < Progreso.TOTAL_NIVELES:
		return "TERMINASTE LA PARTIDA"
	var diferencia: int = datos.golpes - datos.par
	if diferencia <= 0:
		return "MAESTRO DEL GOLF"
	if diferencia <= 4:
		return "GOLFISTA EXPERTO"
	if diferencia <= 10:
		return "BUEN GOLFISTA"
	return "GOLFISTA EN CAMINO"


func _texto_golpes(datos: Dictionary) -> String:
	if datos.jugados == 0:
		return "JUGA EL MODO NORMAL PARA VER TUS GOLPES"
	var texto := "GOLPES TOTALES: %d  (PAR %d)" % [datos.golpes, datos.par]
	if not datos.completo:
		texto = "GOLPES (%d NIVELES): %d" % [datos.jugados, datos.golpes]
	return texto


func _agregar_linea(texto: String, color: Color) -> void:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	_poner_fuente(l)
	resumen.add_child(l)


func _poner_fuente(l: Control) -> void:
	if ResourceLoader.exists(RUTA_FUENTE):
		l.add_theme_font_override("font", load(RUTA_FUENTE))


## Una celda por nivel: nombre arriba, "mejor / par" abajo. Dorada si fue hoyo en uno.
func _llenar_grilla() -> void:
	for i in Progreso.TOTAL_NIVELES:
		var mejor := Progreso.mejor(i + 1)
		var par := Progreso.PARES[i]
		var celda := PanelContainer.new()
		celda.custom_minimum_size = Vector2(140, 92)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.03, 0.06, 0.04)
		estilo.set_border_width_all(2)
		var color := Color(0.4, 0.4, 0.4)
		var detalle := "-"
		if mejor > 0:
			detalle = "%d / %d" % [mejor, par]
			color = DORADO if mejor == 1 else (VERDE if mejor <= par else Color.WHITE)
		estilo.border_color = color
		celda.add_theme_stylebox_override("panel", estilo)
		var caja := VBoxContainer.new()
		caja.alignment = BoxContainer.ALIGNMENT_CENTER
		var n := Label.new()
		n.text = "NIVEL " + Progreso.NOMBRES[i]
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", 18)
		_poner_fuente(n)
		var d := Label.new()
		d.text = detalle
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", 28)
		d.add_theme_color_override("font_color", color)
		_poner_fuente(d)
		caja.add_child(n)
		caja.add_child(d)
		celda.add_child(caja)
		grilla.add_child(celda)


func _entrada() -> void:
	# aparición escalonada, tranquila
	var bloques: Array[Control] = [titulo, rango, resumen, grilla, btn_jugar, btn_menu]
	for b in bloques:
		b.modulate.a = 0.0
	var t := create_tween()
	for b in bloques:
		t.tween_property(b, "modulate:a", 1.0, 0.45)


## Una lluvia suave de confeti desde arriba
func _confeti() -> void:
	var c := CPUParticles2D.new()
	c.position = Vector2(360, -20)
	c.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	c.emission_rect_extents = Vector2(360, 10)
	c.amount = 60
	c.lifetime = 5.0
	c.direction = Vector2.DOWN
	c.spread = 18.0
	c.gravity = Vector2(0, 90)
	c.initial_velocity_min = 60.0
	c.initial_velocity_max = 160.0
	c.angular_velocity_min = -200.0
	c.angular_velocity_max = 200.0
	c.scale_amount_min = 8.0
	c.scale_amount_max = 16.0
	var colores := Gradient.new()
	colores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colores.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colores.colors = PackedColorArray([DORADO, Color.WHITE, Color(0.35, 0.65, 1.0), Color(0.95, 0.25, 0.25)])
	c.color_initial_ramp = colores
	c.z_index = 5
	add_child(c)


func _on_jugar() -> void:
	Sonidos.reproducir("click")
	Progreso.modo_hardcore = false
	get_tree().change_scene_to_file(ESCENA_NIVEL_1)


func _on_menu() -> void:
	Sonidos.reproducir("click")
	Progreso.modo_hardcore = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_menu()
