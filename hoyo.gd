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


func _draw() -> void:
	draw_circle(Vector2.ZERO, radio_visual, Color(0.05, 0.05, 0.05))
	draw_arc(Vector2.ZERO, radio_visual, 0, TAU, 32, Color(0.25, 0.25, 0.25), 3.0)


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
