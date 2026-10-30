extends Area2D

signal pelota_embocada

## Se emite cuando la pelota pasa rozando el hoyo sin entrar
signal casi_embocada

## por debajo de esta velocidad entra si o si
@export var velocidad_segura: float = 500.0

## nunca entra al hoyo con esta velocidad
@export var velocidad_maxima: float = 1200.0

## que tan cerca tien que pasar la pelota para entrar
@export var radio_captura: float = 50.0

## lo minimo
@export var radio_captura_minimo: float = 15.0

## fuerza con la que la pleota cae en el hoyo
@export var fuerza_atraccion: float = 800.0

## Tamaño del círculo negro que se dibuja
@export var radio_visual: float = 80.0

## Distancia (desde el centro) a la que una pelota "pasa cerca" del hoyo
@export var radio_casi: float = 120.0

## Que tanto se curva la trayectoria al rozar el borde (0 = nada)
@export var intensidad_borde: float = 0.6

## La pelota solo da la vueltita si pasa a una velocidad relativamente baja
@export var velocidad_max_giro: float = 450.0

## Giro maximo (en radianes) que puede doblar la pelota al pasar por el borde
@export var giro_maximo: float = 1.1

const RUTA_FUENTE := "res://assets/w3-ip.ttf"

var embocada: bool = false

## efecto "casi": estado de la pasada actual de la pelota por el borde
var _en_zona: bool = false
var _velocidad_zona: float = 0.0
var _giro: float = 0.0
var _enfriamiento: float = 0.0
var _onda_color: Color = Color.WHITE

## progreso del anillo expansivo de celebración (-1 = no se dibuja)
var _onda: float = -1.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, radio_visual, Color(0.05, 0.05, 0.05))
	draw_arc(Vector2.ZERO, radio_visual, 0, TAU, 32, Color(0.25, 0.25, 0.25), 3.0)
	if _onda >= 0.0:
		var radio := radio_visual * (1.0 + _onda * 1.4)
		var alfa := 1.0 - _onda
		draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(_onda_color, alfa * 0.9), 2.0 + 10.0 * alfa)


func _physics_process(delta: float) -> void:
	if embocada:
		return
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	for body in get_overlapping_bodies():
		if body.is_in_group("pelota"):
			_chequear_pelota(body, delta)
	if not embocada:
		_detectar_casi()


func _chequear_pelota(pelota: RigidBody2D, delta: float) -> void:
	var distancia := global_position.distance_to(pelota.global_position)
	var velocidad := pelota.linear_velocity.length()

	if distancia > 1.0:
		var direccion := (global_position - pelota.global_position).normalized()
		var cercania := 1.0 - clampf(distancia / radio_visual, 0.0, 1.0)
		pelota.apply_central_force(direccion * fuerza_atraccion * cercania)

	if velocidad <= velocidad_maxima:
		var radio_efectivo := radio_captura
		if velocidad > velocidad_segura:
			var t := (velocidad - velocidad_segura) / (velocidad_maxima - velocidad_segura)
			radio_efectivo = lerpf(radio_captura, radio_captura_minimo, t)

		if distancia <= radio_efectivo:
			embocada = true
			pelota.embocar(global_position)
			pelota_embocada.emit()
			_celebrar()
			return

	_redondear_borde(pelota, distancia, velocidad, delta)


## Si la pelota pasa rozando el hoyo sin entrar, su trayectoria se curva alrededor
## del borde (como cuando una pelota de golf "da la vuelta" al hoyo y sale).
func _redondear_borde(pelota: RigidBody2D, distancia: float, velocidad: float, delta: float) -> void:
	if distancia >= radio_casi or velocidad < 80.0 or velocidad > velocidad_max_giro or _giro >= giro_maximo:
		return
	var hacia_centro := global_position - pelota.global_position
	var lado := signf(pelota.linear_velocity.cross(hacia_centro))
	if lado == 0.0:
		return
	var velocidad_angular := minf(velocidad / maxf(distancia, 40.0), 14.0) * intensidad_borde
	var angulo := minf(velocidad_angular * delta, giro_maximo - _giro)
	pelota.linear_velocity = pelota.linear_velocity.rotated(lado * angulo)
	_giro += angulo


## Detecta cuando la pelota entro en la zona cercana y salio sin embocar
func _detectar_casi() -> void:
	var pelota := get_tree().get_first_node_in_group("pelota") as RigidBody2D
	if pelota == null:
		return
	var distancia := global_position.distance_to(pelota.global_position)
	if distancia < radio_casi:
		_en_zona = true
		_velocidad_zona = maxf(_velocidad_zona, pelota.linear_velocity.length())
	elif _en_zona:
		_en_zona = false
		_giro = 0.0
		if _enfriamiento <= 0.0 and _velocidad_zona > 150.0:
			_casi_embocada()
		_velocidad_zona = 0.0


## Feedback de "casi entra": sonido, anillo amarillo y cartel
func _casi_embocada() -> void:
	_enfriamiento = 1.2
	casi_embocada.emit()
	Sonidos.reproducir("casi")

	_onda_color = Color(1.0, 0.85, 0.3)
	var anillo := create_tween()
	anillo.tween_method(func(v: float) -> void:
		_onda = v
		queue_redraw(), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anillo.tween_callback(func() -> void:
		_onda = -1.0
		queue_redraw())

	var cartel := Label.new()
	cartel.text = "CASI!"
	cartel.z_index = 10
	cartel.size = Vector2(400, 120)
	cartel.position = Vector2(-200, 110)
	cartel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists(RUTA_FUENTE):
		cartel.add_theme_font_override("font", load(RUTA_FUENTE))
	cartel.add_theme_font_size_override("font_size", 84)
	cartel.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	cartel.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	cartel.add_theme_constant_override("outline_size", 14)
	add_child(cartel)
	var t := create_tween().set_parallel(true)
	t.tween_property(cartel, "position:y", 40.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(cartel, "modulate:a", 0.0, 0.5).set_delay(0.5)
	t.chain().tween_callback(cartel.queue_free)


## Efecto al embocar: cuando la pelota termina de caer, sale un anillo,
## confetti y la bandera se sacude.
func _celebrar() -> void:
	await get_tree().create_timer(0.4).timeout

	# anillo que se expande y se desvanece
	_onda_color = Color.WHITE
	var anillo := create_tween()
	anillo.tween_method(func(v: float) -> void:
		_onda = v
		queue_redraw(), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anillo.tween_callback(func() -> void:
		_onda = -1.0
		queue_redraw())

	# bandera que se sacude
	var bandera := get_node_or_null("Flag")
	if bandera:
		var sacudida := create_tween()
		sacudida.tween_property(bandera, "rotation_degrees", 7.0, 0.07)
		sacudida.tween_property(bandera, "rotation_degrees", -6.0, 0.1)
		sacudida.tween_property(bandera, "rotation_degrees", 3.0, 0.1)
		sacudida.tween_property(bandera, "rotation_degrees", 0.0, 0.12)

	# confetti
	var confetti := CPUParticles2D.new()
	confetti.z_index = 3
	confetti.one_shot = true
	confetti.emitting = false
	confetti.amount = 36
	confetti.lifetime = 1.0
	confetti.explosiveness = 1.0
	confetti.spread = 180.0
	confetti.gravity = Vector2.ZERO
	confetti.initial_velocity_min = 350.0
	confetti.initial_velocity_max = 750.0
	confetti.damping_min = 300.0
	confetti.damping_max = 450.0
	confetti.angular_velocity_min = -540.0
	confetti.angular_velocity_max = 540.0
	confetti.scale_amount_min = 14.0
	confetti.scale_amount_max = 28.0
	var colores := Gradient.new()
	colores.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colores.colors = PackedColorArray([
		Color(1.0, 0.85, 0.3), Color(1, 1, 1),
		Color(0.35, 0.65, 1.0), Color(0.95, 0.25, 0.25)])
	confetti.color_initial_ramp = colores
	var desvanecer := Gradient.new()
	desvanecer.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	desvanecer.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	confetti.color_ramp = desvanecer
	add_child(confetti)
	confetti.emitting = true
	confetti.finished.connect(confetti.queue_free)
