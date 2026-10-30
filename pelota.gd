extends RigidBody2D

signal golpe_dado(total: int)

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var en_hoyo: bool = false
var golpes: int = 0

## Bloquea los tiros (ej: se acabó el tiempo en modo hardcore)
var bloqueada: bool = false

## Tiempo que queda de "estoy en una zona de viento" (lo renueva el viento en cada frame)
var _viento_restante: float = 0.0
var en_viento: bool:
	get: return _viento_restante > 0.0

## Cantidad de charcos de barro que está pisando la pelota en este momento
var zonas_barro: int = 0

## Cuánta suciedad tiene la pelota: 0 = limpia, 1 = toda embarrada
var suciedad: float = 0.0

## Cantidad de zonas de hielo que está pisando la pelota en este momento
var zonas_hielo: int = 0

@export var power_multiplier: float = 3.0
@export var max_aim_length: float = 150.0
@export var velocidad_minima_tiro: float = 10.0

## Fuerza del tiro (0 a 1) cuando la pelota está parada dentro del barro
@export var factor_barro: float = 0.55

## Cuánta suciedad se va con cada golpe (0.34 = se limpia del todo en 3 tiros)
@export var limpieza_por_golpe: float = 0.34

## Velocidad con la que se ensucia en el barro (por segundo)
@export var velocidad_ensuciar: float = 2.5

## Rozamiento mientras la pelota está sobre hielo (el normal es el linear_damp)
@export var damp_hielo: float = 0.12

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea: Line2D = $LineaApuntado
@onready var punta_flecha: Sprite2D = $LineaApuntado/PuntaFlecha

const COLOR_BARRO := Color(0.40, 0.25, 0.11)
const CANTIDAD_MANCHAS := 9

var _damp_normal: float = 0.0
var _manchas: Node2D
var _datos_manchas: Array[Vector3] = []   # x, y, radio (en coordenadas del sprite)

func _ready() -> void:
	add_to_group("pelota")
	_damp_normal = linear_damp
	linea.clear_points()
	punta_flecha.visible = false
	body_entered.connect(_on_body_entered)
	_crear_manchas()

# El clic/toque que NO fue consumido por un botón de la interfaz (ej: el botón de
# pausa) empieza el apuntado. Así tocar "pausa" no dispara un tiro.
func _unhandled_input(event: InputEvent) -> void:
	if en_hoyo or bloqueada:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Solo se puede tirar con la pelota quieta, o moviéndose sobre hielo o dentro del viento
		if not puede_apuntar():
			return
		drag_start = get_global_mouse_position()
		dragging = true
		punta_flecha.visible = true

# Soltar siempre se escucha, aunque el dedo termine encima de un botón
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
	punta_flecha.visible = false

func _soltar() -> void:
	dragging = false
	var drag_end: Vector2 = get_global_mouse_position()
	var impulse_vector: Vector2 = (drag_start - drag_end).limit_length(max_aim_length)

	linea.clear_points()
	punta_flecha.visible = false

	if impulse_vector.length() < 10.0:
		return

	apply_central_impulse(impulse_vector * power_multiplier * _factor_tiro())
	_limpiar_un_poco()
	golpes += 1
	golpe_dado.emit(golpes)

	var fuerza := impulse_vector.length() / max_aim_length
	Sonidos.reproducir("golpe", linear_to_db(0.4 + 0.6 * fuerza))

func _process(_delta: float) -> void:
	if dragging:
		var drag_end: Vector2 = get_global_mouse_position()
		# la flecha muestra la fuerza real: dentro del barro es más corta
		var aim_vector: Vector2 = (drag_start - drag_end).limit_length(max_aim_length) * _factor_tiro()

		linea.clear_points()
		linea.add_point(Vector2.ZERO)
		linea.add_point(aim_vector)

		punta_flecha.position = aim_vector
		punta_flecha.rotation = aim_vector.angle()

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

	# en el barro la pelota se va embarrando
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

## Se puede apuntar si la pelota está quieta, resbalando sobre hielo o dentro del viento
func puede_apuntar() -> bool:
	return esta_quieta() or zonas_hielo > 0 or en_viento

## Los llama el barro cuando la pelota entra o sale
func entrar_barro() -> void:
	zonas_barro += 1

func salir_barro() -> void:
	zonas_barro = maxi(zonas_barro - 1, 0)

## Dentro del barro el tiro sale más flojo
func _factor_tiro() -> float:
	return factor_barro if zonas_barro > 0 else 1.0

func _limpiar_un_poco() -> void:
	if suciedad > 0.0:
		suciedad = maxf(suciedad - limpieza_por_golpe, 0.0)
		_actualizar_suciedad()

# --- Manchas de barro: aparecen al embarrarse y se van yendo de a poco ---

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
		# cada mancha tiene su umbral: con poca suciedad se ven pocas
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

## Los llama la zona de hielo cuando la pelota entra o sale
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
	dragging = false
	linea.clear_points()
	punta_flecha.visible = false

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
