extends RigidBody2D

signal golpe_dado(total: int)

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var en_hoyo: bool = false
var golpes: int = 0

var bloqueada: bool = false

## Tiempo que queda de "estoy en una zona de viento" (lo renueva el viento en cada frame)
var _viento_restante: float = 0.0
var en_viento: bool:
	get: return _viento_restante > 0.0

var zonas_barro: int = 0

var suciedad: float = 0.0

var zonas_hielo: int = 0

## Fuerza del tiro más fuerte posible 
@export var fuerza_maxima: float = 2500.0

## Cuántos píxeles de pantalla hay que arrastrar para llegar a la fuerza máxima
@export var arrastre_maximo: float = 300.0

## Curva de la fuerza: 1 = pareja; más alto = más precisión en los tiros cortos
@export var curva_potencia: float = 1.5

## Largo de la flecha (en píxeles del nivel) con la fuerza máxima
@export var largo_flecha: float = 400.0

@export var velocidad_minima_tiro: float = 10.0

## Por debajo de esta velocidad ya se puede apuntar y tirar 
@export var velocidad_para_tirar: float = 60.0

@export var factor_barro: float = 0.55

@export var limpieza_por_golpe: float = 0.34

@export var velocidad_ensuciar: float = 2.5

@export var damp_hielo: float = 0.12

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea: Line2D = $LineaApuntado
@onready var punta_flecha: Sprite2D = $LineaApuntado/PuntaFlecha

const COLOR_BARRO := Color(0.40, 0.25, 0.11)
const CANTIDAD_MANCHAS := 9

const COLOR_SUAVE := Color(0.30, 0.85, 0.35)
const COLOR_MEDIO := Color(1.00, 0.85, 0.20)
const COLOR_FUERTE := Color(0.95, 0.20, 0.15)

## Arrastres más cortos que esto no tiran
const ARRASTRE_MINIMO := 10.0

var _damp_normal: float = 0.0
var _manchas: Node2D
var _datos_manchas: Array[Vector3] = []   # x, y, radio (en coordenadas del sprite)
var _punta: Polygon2D

func _ready() -> void:
	add_to_group("pelota")
	_damp_normal = linear_damp
	linea.clear_points()
	# la punta vieja (imagen roja) no se puede pintar de otro color: se usa un triángulo
	punta_flecha.visible = false
	_crear_punta()
	body_entered.connect(_on_body_entered)
	_crear_manchas()

func _crear_punta() -> void:
	_punta = Polygon2D.new()
	_punta.polygon = PackedVector2Array([Vector2(0, -22), Vector2(38, 0), Vector2(0, 22)])
	_punta.visible = false
	linea.add_child(_punta)

func _unhandled_input(event: InputEvent) -> void:
	if en_hoyo or bloqueada:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Solo se puede tirar con la pelota quieta, o moviéndose sobre hielo o dentro del viento
		if not puede_apuntar():
			return
		_frenar_para_tirar()
		drag_start = get_global_mouse_position()
		dragging = true

func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if en_hoyo or bloqueada:
		_cancelar_apuntado()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		_soltar()

func _cancelar_apuntado() -> void:
	dragging = false
	linea.clear_points()
	_punta.visible = false

func _soltar() -> void:
	var potencia := _potencia()
	var direccion := _direccion()
	var arrastre := _arrastre_en_pantalla()
	_cancelar_apuntado()

	if arrastre < ARRASTRE_MINIMO:
		return

	_frenar_para_tirar()
	apply_central_impulse(direccion * fuerza_maxima * potencia * _factor_tiro())
	_limpiar_un_poco()
	golpes += 1
	golpe_dado.emit(golpes)

	Sonidos.reproducir("golpe", linear_to_db(0.4 + 0.6 * potencia))

func _process(_delta: float) -> void:
	if not dragging:
		return
	if _arrastre_en_pantalla() < ARRASTRE_MINIMO:
		linea.clear_points()
		_punta.visible = false
		return

	var potencia := _potencia()
	# la flecha muestra la fuerza real: dentro del barro es más corta
	var aim_vector := _direccion() * largo_flecha * potencia * _factor_tiro()
	var color := _color_potencia(potencia)

	linea.clear_points()
	linea.add_point(Vector2.ZERO)
	linea.add_point(aim_vector)
	linea.default_color = color

	_punta.visible = true
	_punta.position = aim_vector
	_punta.rotation = aim_vector.angle()
	_punta.color = color


## Cuánto se arrastro el tiro
func _arrastre_en_pantalla() -> float:
	return (drag_start - get_global_mouse_position()).length() * _zoom_camara()

func _zoom_camara() -> float:
	var camara := get_viewport().get_camera_2d()
	return camara.zoom.x if camara else 1.0

func _direccion() -> Vector2:
	return (drag_start - get_global_mouse_position()).normalized()

## Fuerza de 0 a 1. Con la curva, la mitad del arrastre da ~35 % de fuerza (más precisión en tiros cortos)
func _potencia() -> float:
	var t := clampf(_arrastre_en_pantalla() / arrastre_maximo, 0.0, 1.0)
	return pow(t, curva_potencia)

## Verde (suave) -> amarillo -> rojo (al máximo)
func _color_potencia(potencia: float) -> Color:
	if potencia < 0.5:
		return COLOR_SUAVE.lerp(COLOR_MEDIO, potencia / 0.5)
	return COLOR_MEDIO.lerp(COLOR_FUERTE, (potencia - 0.5) / 0.5)

func _physics_process(delta: float) -> void:
	var velocidad := linear_velocity.length()
	if velocidad > 5.0:
		sprite.rotation += velocidad * delta * 0.05

	# sobre hielo casi no hay rozamiento
	linear_damp = damp_hielo if zonas_hielo > 0 else _damp_normal

	# Por debajo de la velocidad mínima la pelota se frena del todo, salvo que el
	# viento la esté empujando (si no, el viento nunca podría moverla desde el reposo).
	if not en_hoyo and not en_viento and velocidad > 0.0 and velocidad < velocidad_minima_tiro:
		linear_velocity = Vector2.ZERO
	_viento_restante = maxf(_viento_restante - delta, 0.0)

	if zonas_barro > 0 and suciedad < 1.0:
		suciedad = minf(suciedad + velocidad_ensuciar * delta, 1.0)
		_actualizar_suciedad()

func _on_body_entered(_body: Node) -> void:
	var velocidad := linear_velocity.length()
	if velocidad < 80.0:
		return
	Sonidos.reproducir("rebote", linear_to_db(clampf(velocidad / 1200.0, 0.15, 1.0)), randf_range(0.9, 1.1))

func esta_quieta() -> bool:
	return linear_velocity.length() < velocidad_minima_tiro

## Lo llama el viento en cada frame que la pelota está dentro de la zona
func recibir_viento(fuerza: Vector2) -> void:
	apply_central_force(fuerza)
	_viento_restante = 0.1

func puede_apuntar() -> bool:
	return linear_velocity.length() < velocidad_para_tirar or zonas_hielo > 0 or en_viento

## Antes de tirar, una pelota lenta se frena del todo para que el tiro salga limpio.
## Sobre hielo o en el viento no: ahí el tiro se suma al movimiento, como siempre.
func _frenar_para_tirar() -> void:
	if zonas_hielo > 0 or en_viento:
		return
	linear_velocity = Vector2.ZERO

func entrar_barro() -> void:
	zonas_barro += 1

func salir_barro() -> void:
	zonas_barro = maxi(zonas_barro - 1, 0)

func _factor_tiro() -> float:
	return factor_barro if zonas_barro > 0 else 1.0

func _limpiar_un_poco() -> void:
	if suciedad > 0.0:
		suciedad = maxf(suciedad - limpieza_por_golpe, 0.0)
		_actualizar_suciedad()

func _crear_manchas() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	for i in CANTIDAD_MANCHAS:
		var angulo := azar.randf_range(0.0, TAU)
		var distancia := sqrt(azar.randf()) * 135.0
		_datos_manchas.append(Vector3(cos(angulo) * distancia, sin(angulo) * distancia, azar.randf_range(26.0, 58.0)))
	_manchas = Node2D.new()
	sprite.add_child(_manchas)   # hijo del sprite: rota y se achica junto con él
	_manchas.draw.connect(_dibujar_manchas)

func _dibujar_manchas() -> void:
	for i in _datos_manchas.size():
		var umbral := float(i) / float(_datos_manchas.size())
		if suciedad <= umbral:
			continue
		var d := _datos_manchas[i]
		var alfa := clampf((suciedad - umbral) * 6.0, 0.0, 0.92)
		_manchas.draw_circle(Vector2(d.x, d.y), d.z, Color(COLOR_BARRO, alfa))
		_manchas.draw_circle(Vector2(d.x - d.z * 0.25, d.y - d.z * 0.25), d.z * 0.45, Color(0.55, 0.37, 0.18, alfa * 0.8))

func _actualizar_suciedad() -> void:
	# self_modulate (y no modulate) para no pisar la animación de caída al hoyo
	sprite.self_modulate = Color.WHITE.lerp(Color(0.62, 0.48, 0.32), suciedad * 0.75)
	_manchas.queue_redraw()

func entrar_hielo() -> void:
	zonas_hielo += 1

func salir_hielo() -> void:
	zonas_hielo = maxi(zonas_hielo - 1, 0)

## Detiene todo tiro (se usa al perder en modo hardcore)
func bloquear() -> void:
	bloqueada = true
	_cancelar_apuntado()

func embocar(posicion_hoyo: Vector2) -> void:
	en_hoyo = true
	_cancelar_apuntado()

	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", posicion_hoyo, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.42) \
		.set_delay(0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate", Color(0.12, 0.12, 0.12, 1.0), 0.42) \
		.set_delay(0.08)
	tween.tween_property(sprite, "rotation", sprite.rotation + TAU * 0.8, 0.5)
	tween.chain().tween_callback(hide)
