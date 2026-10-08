extends Control
## Pantalla "Continuará" (nivel 4): marca el final del contenido de este checkpoint.
## No es un nivel jugable; se llega desde el SIGUIENTE del nivel 3 o desde el menú.

const ESCENA_MENU := "res://menu.tscn"
const ESCENA_NIVEL_1 := "res://nivel_1.tscn"

# Mini cancha decorativa (coordenadas del viewport de 720x1280)
const CANCHA := Rect2(60, 560, 600, 360)
const HOYO := Vector2(500, 740)
const RADIO_HOYO := 52.0
const INICIO_PELOTA := Vector2(150, 740)
const ESCALA_PELOTA := 0.17   # el sprite mide 500 px

@onready var titulo: Label = %Titulo
@onready var subtitulo: Label = %Subtitulo
@onready var resumen: Label = %Resumen
@onready var pelota: Sprite2D = %Pelota
@onready var btn_nivel1: Button = %BotonNivel1
@onready var btn_menu: Button = %BotonMenu

var _primera_vez := true


func _ready() -> void:
	get_tree().paused = false
	btn_nivel1.pressed.connect(func() -> void:
		Sonidos.reproducir("click")
		get_tree().change_scene_to_file(ESCENA_NIVEL_1))
	btn_menu.pressed.connect(_ir_al_menu)

	# Total de golpes de los mejores recorridos
	var total := 0
	var completados := 0
	for nivel in range(1, 4):
		var mejor := Progreso.mejor(nivel)
		if mejor > 0:
			total += mejor
			completados += 1
	if completados > 0:
		resumen.text = "MEJOR TOTAL: %d GOLPES" % total
	else:
		resumen.text = ""

	# La cancha se dibuja en un nodo hijo ubicado DETRÁS de la pelota y los textos
	# (si se dibujara en este nodo, el fondo oscuro la taparía).
	var decorado := Control.new()
	decorado.set_anchors_preset(Control.PRESET_FULL_RECT)
	decorado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decorado.draw.connect(_dibujar_cancha.bind(decorado))
	add_child(decorado)
	move_child(decorado, 2)   # justo después del borde y el fondo

	_entrada()
	_ciclo_pelota()


func _dibujar_cancha(c: Control) -> void:
	# marco de madera y pasto, igual que la cancha del juego
	c.draw_rect(CANCHA.grow(14), Color(0.45, 0.3, 0.15))
	c.draw_rect(CANCHA, Color(0.22, 0.6, 0.28))
	# franjas de pasto
	for i in range(0, int(CANCHA.size.x), 100):
		if (i / 100) % 2 == 0:
			c.draw_rect(Rect2(CANCHA.position.x + i, CANCHA.position.y, 100, CANCHA.size.y), Color(0.25, 0.64, 0.31))
	# hoyo y bandera
	c.draw_circle(HOYO, RADIO_HOYO, Color(0.04, 0.04, 0.04))
	c.draw_line(HOYO, HOYO + Vector2(0, -150), Color.WHITE, 5.0)
	c.draw_colored_polygon(PackedVector2Array([
		HOYO + Vector2(0, -150), HOYO + Vector2(80, -125), HOYO + Vector2(0, -100)]),
		Color(0.85, 0.0, 0.0))


func _entrada() -> void:
	# aparición escalonada de los textos y botones
	var elementos: Array[Control] = [titulo, subtitulo, resumen, btn_nivel1, btn_menu]
	for e in elementos:
		e.modulate.a = 0.0
	var t := create_tween()
	for e in elementos:
		t.tween_property(e, "modulate:a", 1.0, 0.6)
	t.tween_callback(_pulso_titulo)


func _pulso_titulo() -> void:
	titulo.pivot_offset = titulo.size / 2.0
	var t := create_tween().set_loops()
	t.tween_property(titulo, "scale", Vector2(1.04, 1.04), 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(titulo, "scale", Vector2.ONE, 1.1).set_trans(Tween.TRANS_SINE)


## La pelota rueda hacia el hoyo, cae, y vuelve a empezar.
func _ciclo_pelota() -> void:
	while is_inside_tree():
		pelota.position = INICIO_PELOTA
		pelota.scale = Vector2.ONE * ESCALA_PELOTA
		pelota.modulate = Color.WHITE
		pelota.rotation = 0.0
		pelota.visible = true
		await get_tree().create_timer(1.0).timeout

		# rodar
		var distancia := HOYO.x - INICIO_PELOTA.x
		var radio := 250.0 * ESCALA_PELOTA
		var rodar := create_tween().set_parallel(true)
		rodar.tween_property(pelota, "position:x", HOYO.x, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		rodar.tween_property(pelota, "rotation", distancia / radio, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		Sonidos.reproducir("golpe")
		await rodar.finished

		# caer al hoyo
		var caer := create_tween().set_parallel(true)
		caer.tween_property(pelota, "scale", Vector2.ZERO, 0.42).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		caer.tween_property(pelota, "modulate", Color(0.12, 0.12, 0.12), 0.42).set_delay(0.05)
		caer.tween_property(pelota, "rotation", pelota.rotation + TAU * 0.6, 0.47)
		if _primera_vez:
			_primera_vez = false
			Sonidos.reproducir("hoyo")
		await caer.finished
		pelota.visible = false
		await get_tree().create_timer(1.6).timeout


func _ir_al_menu() -> void:
	Sonidos.reproducir("click")
	get_tree().change_scene_to_file(ESCENA_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_ir_al_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_ir_al_menu()
