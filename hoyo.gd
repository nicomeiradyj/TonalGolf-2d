extends Area2D

signal pelota_embocada

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

var embocada: bool = false

## progreso del anillo expansivo de celebración (-1 = no se dibuja)
var _onda: float = -1.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, radio_visual, Color(0.05, 0.05, 0.05))
	draw_arc(Vector2.ZERO, radio_visual, 0, TAU, 32, Color(0.25, 0.25, 0.25), 3.0)
	if _onda >= 0.0:
		var radio := radio_visual * (1.0 + _onda * 1.4)
		var alfa := 1.0 - _onda
		draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(1, 1, 1, alfa * 0.9), 2.0 + 10.0 * alfa)


func _physics_process(_delta: float) -> void:
	if embocada:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("pelota"):
			_chequear_pelota(body)


func _chequear_pelota(pelota: RigidBody2D) -> void:
	var distancia := global_position.distance_to(pelota.global_position)
	var velocidad := pelota.linear_velocity.length()

	if distancia > 1.0:
		var direccion := (global_position - pelota.global_position).normalized()
		var cercania := 1.0 - clampf(distancia / radio_visual, 0.0, 1.0)
		pelota.apply_central_force(direccion * fuerza_atraccion * cercania)

	if velocidad > velocidad_maxima:
		return

	var radio_efectivo := radio_captura
	if velocidad > velocidad_segura:
		var t := (velocidad - velocidad_segura) / (velocidad_maxima - velocidad_segura)
		radio_efectivo = lerpf(radio_captura, radio_captura_minimo, t)

	if distancia <= radio_efectivo:
		embocada = true
		pelota.embocar(global_position)
		pelota_embocada.emit()
		_celebrar()


## Efecto al embocar: cuando la pelota termina de caer, sale un anillo,
## confetti y la bandera se sacude.
func _celebrar() -> void:
	await get_tree().create_timer(0.4).timeout

	# anillo que se expande y se desvanece
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
