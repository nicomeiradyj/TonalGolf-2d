extends CanvasLayer
## HUD del nivel: nivel, golpes, par, mejor puntaje y menú de pausa.

const ESCENA_MENU := "res://menu.tscn"

@onready var label_nivel: Label = %LabelNivel
@onready var label_golpes: Label = %LabelGolpes
@onready var label_info: Label = %LabelInfo
@onready var label_tiempo: Label = %LabelTiempo
@onready var btn_pausa: Button = %BotonPausa
@onready var panel_pausa: Control = %PanelPausa
@onready var btn_seguir: Button = %BotonSeguir
@onready var btn_reiniciar: Button = %BotonReiniciar
@onready var btn_sonido: Button = %BotonSonido
@onready var btn_menu: Button = %BotonMenuPausa

const VERDE := Color(0.3372549, 0.8, 0.5411765)
const DORADO := Color(1.0, 0.85, 0.3)

var bloqueado: bool = false
var _segundo_anterior: int = -1
var _par: int = 0
var _golpes: int = 0
var _pips: Control


func _ready() -> void:
	# El HUD sigue activo con el juego pausado, así los botones responden
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel_pausa.visible = false
	btn_pausa.pressed.connect(alternar_pausa)
	btn_seguir.pressed.connect(alternar_pausa)
	btn_reiniciar.pressed.connect(_on_reiniciar)
	btn_sonido.pressed.connect(_on_sonido)
	btn_menu.pressed.connect(_on_menu)
	_actualizar_texto_sonido()
	_mejorar_estilo()


## Look del HUD: tarjeta translucida con acento verde, indicador de golpes contra el par
## (un punto por golpe de par; se pone rojo si te pasas), boton de pausa y reloj redondeados.
func _mejorar_estilo() -> void:
	var textos: Control = label_nivel.get_parent()
	var fila: Control = textos.get_parent()

	var tarjeta := PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var est := StyleBoxFlat.new()
	est.bg_color = Color(0.02, 0.05, 0.03, 0.62)
	est.set_corner_radius_all(16)
	est.border_width_left = 8
	est.border_color = VERDE
	est.content_margin_left = 20.0
	est.content_margin_right = 18.0
	est.content_margin_top = 8.0
	est.content_margin_bottom = 10.0
	est.shadow_color = Color(0, 0, 0, 0.3)
	est.shadow_size = 6
	tarjeta.add_theme_stylebox_override("panel", est)
	fila.add_child(tarjeta)
	fila.move_child(tarjeta, 0)
	textos.reparent(tarjeta, false)
	textos.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	textos.add_theme_constant_override("separation", 2)

	label_nivel.add_theme_color_override("font_color", DORADO)
	# tarjeta compacta (<= 280 px de ancho) para no tapar el hoyo, que suele estar arriba al centro
	label_nivel.add_theme_font_size_override("font_size", 24)
	label_golpes.add_theme_font_size_override("font_size", 38)
	label_info.add_theme_font_size_override("font_size", 20)
	label_info.add_theme_color_override("font_color", Color(0.85, 0.95, 0.88))
	for l in [label_nivel, label_golpes, label_info]:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)

	_pips = Control.new()
	_pips.custom_minimum_size = Vector2(0, 26)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.draw.connect(_dibujar_pips)
	textos.add_child(_pips)
	textos.move_child(_pips, 2)

	# boton de pausa: cuadrado redondeado, mismo lenguaje visual
	var normal := _caja(Color(0.02, 0.05, 0.03, 0.62), VERDE, 14)
	var hover := _caja(Color(0.05, 0.12, 0.07, 0.8), DORADO, 14)
	var pulsado := _caja(Color(0.3372549, 0.8, 0.5411765, 0.35), DORADO, 14)
	btn_pausa.add_theme_stylebox_override("normal", normal)
	btn_pausa.add_theme_stylebox_override("hover", hover)
	btn_pausa.add_theme_stylebox_override("pressed", pulsado)
	btn_pausa.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn_pausa.modulate = Color.WHITE

	# reloj hardcore: una fila mas dentro de la tarjeta (asi no tapa nada del campo)
	label_tiempo.reparent(textos, false)
	label_tiempo.add_theme_font_size_override("font_size", 24)
	label_tiempo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label_tiempo.add_theme_constant_override("outline_size", 6)
	label_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_tiempo.custom_minimum_size = Vector2(0, 0)
	label_tiempo.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _caja(fondo: Color, borde: Color, radio: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(3)
	e.set_corner_radius_all(radio)
	return e


func _dibujar_pips() -> void:
	var total := maxi(_par, _golpes)
	var x := 12.0
	for i in total:
		var centro := Vector2(x, 13.0)
		var pasado := i >= _par
		if i < _golpes:
			var color := Color(1.0, 0.4, 0.35) if pasado else Color.WHITE
			_pips.draw_circle(centro, 9.0, color)
		else:
			_pips.draw_arc(centro, 8.0, 0.0, TAU, 20, Color(0.85, 0.95, 0.88, 0.7), 3.0)
		x += 28.0


func configurar(nombre: String, par: int, mejor: int) -> void:
	label_nivel.text = "NIVEL %s" % nombre
	var info := "PAR %d" % par
	if mejor > 0:
		info += "   MEJOR %d" % mejor
	label_info.text = info
	_par = par
	if _pips:
		_pips.queue_redraw()


## Prende el cronometro y ajusta los menues para el modo HARDCORE
func activar_hardcore(tiempo_total: float) -> void:
	label_tiempo.visible = true
	# (el rojo del titulo y la fila de tiempo indican el modo; "HARDCORE" ensanchaba la tarjeta)
	label_nivel.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	# no se puede reiniciar el nivel (el tiempo seria un truco) y salir abandona la partida
	btn_reiniciar.visible = false
	btn_menu.text = "ABANDONAR"
	actualizar_tiempo(tiempo_total)


func actualizar_tiempo(segundos: float) -> void:
	var restante := maxi(ceili(segundos), 0)
	label_tiempo.text = "TIEMPO %d" % restante
	var urgente := restante <= 10
	label_tiempo.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25) if urgente else Color.WHITE)
	# en los ultimos 5 segundos suena un tic y el reloj "late"
	if restante != _segundo_anterior:
		_segundo_anterior = restante
		if restante <= 5 and restante > 0:
			Sonidos.reproducir("tictac")
			label_tiempo.pivot_offset = label_tiempo.size / 2.0
			label_tiempo.scale = Vector2(1.25, 1.25)
			create_tween().tween_property(label_tiempo, "scale", Vector2.ONE, 0.3)


func actualizar_golpes(total: int) -> void:
	label_golpes.text = "GOLPES: %d" % total
	_golpes = total
	if _pips:
		_pips.queue_redraw()
	if total > 0:
		# pequeño "pop" al sumar un golpe
		label_golpes.pivot_offset = Vector2(0, label_golpes.size.y / 2.0)
		label_golpes.scale = Vector2(1.12, 1.12)
		create_tween().tween_property(label_golpes, "scale", Vector2.ONE, 0.2)


## Se llama al embocar: oculta el HUD y evita que se pause
func terminar() -> void:
	bloqueado = true
	visible = false


func alternar_pausa() -> void:
	if bloqueado:
		return
	Sonidos.reproducir("click")
	var pausar := not get_tree().paused
	get_tree().paused = pausar
	panel_pausa.visible = pausar


func _unhandled_input(event: InputEvent) -> void:
	# Escape en PC
	if event.is_action_pressed("ui_cancel"):
		alternar_pausa()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Botón "atrás" de Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		alternar_pausa()


func _on_reiniciar() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_sonido() -> void:
	Progreso.set_sonido(not Progreso.sonido_activo)
	Sonidos.actualizar_musica()
	_actualizar_texto_sonido()
	Sonidos.reproducir("click")


func _on_menu() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	Progreso.modo_hardcore = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _actualizar_texto_sonido() -> void:
	btn_sonido.text = "SONIDO: SI" if Progreso.sonido_activo else "SONIDO: NO"
