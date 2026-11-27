extends RigidBody2D

signal golpe_dado(total: int)

var drag_start: Vector2 = Vector2.ZERO
## Punto donde se empezó a arrastrar, en coordenadas de pantalla (viewport)
var drag_start_vp: Vector2 = Vector2.ZERO
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

const COLOR_BARRO := Color(0.40, 0.25, 0.11)
const CANTIDAD_MANCHAS := 9

const COLOR_SUAVE := Color(0.30, 0.85, 0.35)
const COLOR_MEDIO := Color(1.00, 0.85, 0.20)
const COLOR_FUERTE := Color(0.95, 0.20, 0.15)

## Arrastres más cortos que esto no tiran
const ARRASTRE_MINIMO := 10.0

## Margen (px de pantalla) que se deja al borde de la pantalla: el dedo/mouse no puede pasarse de ahí
const MARGEN_BORDE := 24.0
## El "arrastre para fuerza máxima" nunca baja de esto, aunque la pelota esté pegada al borde
const ARRASTRE_MAXIMO_MINIMO := 70.0

var _damp_normal: float = 0.0
var _manchas: Node2D
var _datos_manchas: Array[Vector3] = []   # x, y, radio (en coordenadas del sprite)

## Flecha de tiro: se dibuja toda por código por simplicidad y no encontramos buenos graficos
const RADIO_PELOTA := 70.0          # los puntos arrancan desde el borde de la pelota
const SEPARACION_PUNTOS := 30.0
const TAMANO_TEXTO := 44
const COLOR_BORDE := Color(0.05, 0.08, 0.05, 0.85)
const RUTA_FUENTE := "res://assets/w3-ip.ttf"

var _flecha: Node2D
var _fuente: Font

func _ready() -> void:
	add_to_group("pelota")
	_damp_normal = linear_damp
	_pos_tiro = global_position
	_escala_sprite = sprite.scale
	_crear_flecha()
	_crear_brillo()
	body_entered.connect(_on_body_entered)
	_crear_manchas()

func _crear_flecha() -> void:
	_flecha = Node2D.new()
	_flecha.z_index = 5   # por encima de la pelota y de los obstáculos
	add_child(_flecha)
	_flecha.draw.connect(_dibujar_flecha)
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	else:
		_fuente = ThemeDB.fallback_font

func _unhandled_input(event: InputEvent) -> void:
	if en_hoyo or bloqueada or siendo_chupada:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Solo se puede tirar con la pelota quieta, o moviéndose sobre hielo o dentro del viento
		if not puede_apuntar():
			return
		_frenar_para_tirar()
		drag_start = get_global_mouse_position()
		drag_start_vp = get_viewport().get_mouse_position()
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
	_flecha.queue_redraw()   # con dragging en false, la flecha se borra

func _soltar() -> void:
	var potencia := _potencia()
	var direccion := _direccion()
	var arrastre := _arrastre_en_pantalla()
	_cancelar_apuntado()

	if arrastre < ARRASTRE_MINIMO:
		return

	_frenar_para_tirar()
	_pos_tiro = global_position   # el topo te devuelve acá
	_vel_max_tiro = 0.0
	apply_central_impulse(direccion * fuerza_maxima * potencia * _factor_tiro())
	_limpiar_un_poco()
	golpes += 1
	golpe_dado.emit(golpes)

	Sonidos.reproducir("golpe", linear_to_db(0.4 + 0.6 * potencia))

func _process(_delta: float) -> void:
	if dragging:
		_flecha.queue_redraw()
	pass

func _dibujar_flecha() -> void:
	if not dragging or _arrastre_en_pantalla() < ARRASTRE_MINIMO:
		return

	var potencia := _potencia()
	# la flecha muestra la fuerza real: dentro del barro es más corta
	var fuerza_real := potencia * _factor_tiro()
	var direccion := _direccion()
	var color := _color_potencia(potencia)
	var largo := RADIO_PELOTA + largo_flecha * fuerza_real
	var punta_pos := direccion * largo

	# puntos: arrancan en el borde de la pelota y crecen hacia la punta
	var cantidad := int((largo - RADIO_PELOTA) / SEPARACION_PUNTOS)
	for i in cantidad:
		var t := float(i) / float(maxi(cantidad - 1, 1))
		var centro := direccion * (RADIO_PELOTA + i * SEPARACION_PUNTOS)
		var radio := lerpf(6.0, 12.0, t)
		_flecha.draw_circle(centro, radio + 3.0, COLOR_BORDE)
		_flecha.draw_circle(centro, radio, color)

	# punta: primero un triángulo oscuro más grande (el borde) y encima el de color
	var lado := direccion.orthogonal()
	_flecha.draw_colored_polygon(_triangulo(punta_pos, direccion, lado, 6.0), COLOR_BORDE)
	_flecha.draw_colored_polygon(_triangulo(punta_pos, direccion, lado, 0.0), color)

	# porcentaje de potencia, delante de la punta
	var texto := "%d%%" % roundi(fuerza_real * 100.0)
	var ancho := 200.0
	var base := punta_pos + direccion * 90.0 + Vector2(-ancho / 2.0, TAMANO_TEXTO * 0.35)
	_flecha.draw_string_outline(_fuente, base, texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, TAMANO_TEXTO, 10, COLOR_BORDE)
	_flecha.draw_string(_fuente, base, texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, TAMANO_TEXTO, color)

func _triangulo(base: Vector2, direccion: Vector2, lado: Vector2, borde: float) -> PackedVector2Array:
	return PackedVector2Array([
		base + direccion * (44.0 + borde * 1.6),
		base + lado * (26.0 + borde) - direccion * borde,
		base - lado * (26.0 + borde) - direccion * borde,
	])


## Cuánto se arrastro el tiro
func _arrastre_en_pantalla() -> float:
	return (drag_start_vp - get_viewport().get_mouse_position()).length()

func _zoom_camara() -> float:
	var camara := get_viewport().get_camera_2d()
	return camara.zoom.x if camara else 1.0

func _direccion() -> Vector2:
	return (drag_start_vp - get_viewport().get_mouse_position()).normalized()

## Arrastre (px) que da la fuerza máxima. Normalmente `arrastre_maximo`, pero si la pelota está
## cerca del borde de la pantalla y se arrastra hacia afuera, se acorta hasta lo que entra en
## pantalla: así SIEMPRE se puede llegar al 100 % llevando el dedo/mouse hasta el borde.
func arrastre_maximo_efectivo() -> float:
	return arrastre_maximo_hacia(drag_start_vp, get_viewport().get_mouse_position() - drag_start_vp, get_viewport().get_visible_rect())

## Misma cuenta pero con los datos explícitos (inicio del arrastre, hacia dónde se arrastra y pantalla)
func arrastre_maximo_hacia(inicio: Vector2, tirar: Vector2, r: Rect2) -> float:
	if tirar.length() < 1.0:
		return arrastre_maximo
	var d := tirar.normalized()
	var hasta_borde := INF
	if d.x > 0.001:
		hasta_borde = minf(hasta_borde, (r.end.x - MARGEN_BORDE - inicio.x) / d.x)
	elif d.x < -0.001:
		hasta_borde = minf(hasta_borde, (r.position.x + MARGEN_BORDE - inicio.x) / d.x)
	if d.y > 0.001:
		hasta_borde = minf(hasta_borde, (r.end.y - MARGEN_BORDE - inicio.y) / d.y)
	elif d.y < -0.001:
		hasta_borde = minf(hasta_borde, (r.position.y + MARGEN_BORDE - inicio.y) / d.y)
	return clampf(hasta_borde, ARRASTRE_MAXIMO_MINIMO, arrastre_maximo)

## Fuerza de 0 a 1. Con la curva, la mitad del arrastre da ~35 % de fuerza (más precisión en tiros cortos)
func _potencia() -> float:
	var t := clampf(_arrastre_en_pantalla() / arrastre_maximo_efectivo(), 0.0, 1.0)
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

	# "lista para tirar": la pelota se frenó después de un golpe -> destello
	# (solo si el golpe fue de verdad: un toque suave no merece destello)
	_vel_max_tiro = maxf(_vel_max_tiro, velocidad)
	var lista := not en_hoyo and not bloqueada and not siendo_chupada and velocidad < velocidad_para_tirar
	if lista and not _estaba_lista and golpes > 0 and _vel_max_tiro >= VEL_MIN_DESTELLO:
		_brillar()
		_vel_max_tiro = 0.0
	elif lista and golpes > 0 and not _estaba_lista:
		_vel_max_tiro = 0.0
	_estaba_lista = lista

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

## Follaje (arbustos, flores): la pelota pasa POR DEBAJO; se ve mas oscura y translucida
var zonas_follaje: int = 0

func entrar_follaje() -> void:
	zonas_follaje += 1
	_tono_follaje()


func salir_follaje() -> void:
	zonas_follaje = maxi(zonas_follaje - 1, 0)
	_tono_follaje()


func _tono_follaje() -> void:
	var destino := Color(0.62, 0.78, 0.62, 0.8) if zonas_follaje > 0 else Color.WHITE
	create_tween().tween_property(self, "modulate", destino, 0.18)


## ---- Topo: te chupa la pelota y te la devuelve donde hiciste el último tiro ----
var siendo_chupada: bool = false
var _pos_tiro: Vector2 = Vector2.ZERO
var _escala_sprite: Vector2 = Vector2.ONE

## `espera`: segundos totales hasta devolver la pelota (el topo hace su animación mientras tanto)
func chupar(centro: Vector2, espera: float = 1.3) -> void:
	if siendo_chupada or en_hoyo or bloqueada:
		return
	siendo_chupada = true
	_cancelar_apuntado()
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO
	var tween := create_tween().set_parallel(true)
	# 1) la jala hacia el centro del hueco
	tween.tween_property(self, "global_position", centro, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 2) cae al hueco: se achica y se oscurece como si bajara a la tierra
	tween.tween_property(sprite, "scale", _escala_sprite * 0.1, 0.38).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate", Color(0.16, 0.1, 0.06, 1.0), 0.3).set_delay(0.2)
	tween.tween_property(sprite, "rotation", sprite.rotation + TAU * 1.2, 0.5)
	tween.chain().tween_property(sprite, "scale", Vector2.ZERO, 0.08)
	tween.chain().tween_interval(maxf(espera - 0.62, 0.0))
	tween.chain().tween_callback(_reaparecer)

func _reaparecer() -> void:
	# primero se descongela y despues se teletransporta por el servidor de fisica
	# (asignar global_position a un RigidBody2D congelado no siempre "pega")
	freeze = false
	var rid := get_rid()
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, _pos_tiro))
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	global_position = _pos_tiro
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ZERO
	_polvo(_pos_tiro, 7)
	var t := create_tween()
	t.tween_property(sprite, "scale", _escala_sprite * 1.15, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "scale", _escala_sprite, 0.1)
	siendo_chupada = false
	_estaba_lista = false   # al volver a quedar quieta, destella de nuevo


## Puñadito de tierra (partículas de un solo uso)
func _polvo(donde: Vector2, cantidad: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = cantidad
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 150.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 520)
	p.scale_amount_min = 7.0
	p.scale_amount_max = 14.0
	p.color = Color(0.45, 0.29, 0.14)
	p.z_index = 3
	p.global_position = donde
	get_parent().add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


## ---- "Ya podés tirar": un destello de luz sobre la pelota, como cuando el sol pega en una pelota de golf ----
const VEL_MIN_DESTELLO := 220.0   # el golpe tiene que haber sido de verdad
const RADIO_BRILLO := 62.0
var _brillo: Node2D
var _brillo_t: float = 1.0
var _estaba_lista: bool = false
var _vel_max_tiro: float = 0.0
var _tween_brillo: Tween

func _crear_brillo() -> void:
	_brillo = Node2D.new()
	_brillo.z_index = 6
	add_child(_brillo)
	_brillo.draw.connect(_dibujar_brillo)

func _brillar() -> void:
	if _tween_brillo:
		_tween_brillo.kill()
	_brillo_t = 0.0
	_tween_brillo = create_tween()
	_tween_brillo.tween_method(_set_brillo, 0.0, 1.0, 0.75).set_trans(Tween.TRANS_SINE)
	Sonidos.reproducir("listo", -22.0)

func _set_brillo(v: float) -> void:
	_brillo_t = v
	_brillo.queue_redraw()

func _dibujar_brillo() -> void:
	if _brillo_t >= 1.0:
		return
	var k := sin(_brillo_t * PI)          # sube y baja suave, sin golpe
	# halo muy suave alrededor de la pelota
	for i in 3:
		_brillo.draw_circle(Vector2.ZERO, RADIO_BRILLO * (1.04 + 0.12 * i), Color(1, 1, 0.92, 0.10 * k / float(i + 1)))
	# reflejo sobre la pelota (arriba a la izquierda): una chispita fina que se alarga y se apaga
	var c := Vector2(-RADIO_BRILLO * 0.38, -RADIO_BRILLO * 0.45)
	var largo := 7.0 + 20.0 * k
	var ancho := 1.2 + 2.4 * k
	var col := Color(1, 1, 1, 0.95 * k)
	_brillo.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -largo), c + Vector2(ancho, -ancho), c + Vector2(largo, 0), c + Vector2(ancho, ancho),
		c + Vector2(0, largo), c + Vector2(-ancho, ancho), c + Vector2(-largo, 0), c + Vector2(-ancho, -ancho)]), col)
	_brillo.draw_circle(c, 3.5 * k, Color(1, 1, 1, k))


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
