extends Node2D
## TOPO: una zona de tierra con un topo que te CHUPA la pelota si pasa por ahí.
## La pelota vuelve al lugar donde hiciste el último tiro (el golpe se cuenta igual).
## No aparece siempre: en cada partida del nivel tiene `probabilidad` de aparecer
## (y al aparecer muestra un cartel que explica qué hace). Si no toca, se borra solo
## y el nivel queda exactamente como sin topo.
##
## Para ponerlo en un nivel: instanciar topo.tscn y moverlo (el hoyo en uno tiene que
## seguir siendo posible: no tapar el camino directo de la pelota al hoyo).

## Radio de la zona que chupa (px del nivel). Chico a propósito, para que sea jugable.
@export var radio: float = 140.0
## Probabilidad de que el topo aparezca en una partida (0 a 1)
@export_range(0.0, 1.0) var probabilidad: float = 0.35
## Para pruebas: aparece siempre
@export var forzar_aparicion: bool = false
@export var mostrar_cartel: bool = true

const TEX_DORMIDO: Texture2D = preload("res://assets/topo/topo_dormido.png")
const TEX_ALERTA: Texture2D = preload("res://assets/topo/topo_alerta.png")
const TEX_ALTO: Texture2D = preload("res://assets/topo/topo_alto.png")
const TEX_BURBUJA: Texture2D = preload("res://assets/topo/burbuja_alerta.png")
const TEX_HUECO: Texture2D = preload("res://assets/topo/topo_hueco.png")
const ESCENA_CARTEL: PackedScene = preload("res://cartel_zona.tscn")

const ANCHO_TOPO := 250.0
const COLOR_TIERRA := Color(0.36, 0.22, 0.10)
const COLOR_TIERRA_CLARA := Color(0.46, 0.30, 0.15)
const COLOR_ANILLO := Color(0.95, 0.22, 0.18)

var activo: bool = false
var _suelo: Node2D
var _sprite: Sprite2D
var _burbuja: Sprite2D
var _hueco: Sprite2D
var _hueco_escala: Vector2 = Vector2.ONE
var _estado: String = ""
var _ocupado: bool = false
var _tiempo: float = 0.0
var _forma: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	if not forzar_aparicion and randf() >= probabilidad:
		queue_free()
		return
	activo = true
	add_to_group("topo")
	_crear_forma()
	_suelo = Node2D.new()
	_suelo.z_index = -4   # sobre el pasto, bajo la pelota
	add_child(_suelo)
	_suelo.draw.connect(_dibujar_suelo)

	# el hueco por donde cae la pelota: sobre la tierra y bajo la pelota
	_hueco = Sprite2D.new()
	_hueco.texture = TEX_HUECO
	_hueco.z_index = -3
	_hueco_escala = Vector2.ONE * (radio * 1.35 / float(TEX_HUECO.get_width()))
	_hueco.visible = false
	add_child(_hueco)

	_sprite = Sprite2D.new()
	_sprite.z_index = 1   # sobre la pelota: cuando el topo sale, tapa el hueco
	add_child(_sprite)
	_burbuja = Sprite2D.new()
	_burbuja.texture = TEX_BURBUJA
	_burbuja.z_index = 2
	_burbuja.scale = Vector2.ONE * 0.75
	_burbuja.position = Vector2(-radio * 0.5, -radio * 0.95)
	_burbuja.visible = false
	add_child(_burbuja)
	_poner_estado("dormido")
	if mostrar_cartel:
		_crear_cartel.call_deferred()


func _crear_forma() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = int(global_position.x * 3.0 + global_position.y * 7.0)
	var fase := azar.randf() * TAU
	for i in 56:
		var a := TAU * float(i) / 56.0
		var r := radio * (0.97 + 0.035 * sin(a * 5.0 + fase) + 0.02 * sin(a * 11.0))
		_forma.append(Vector2.from_angle(a) * r)


func _crear_cartel() -> void:
	var cartel := ESCENA_CARTEL.instantiate()
	cartel.tipo = "topo"
	cartel.name = "AyudaTopo"
	get_parent().add_child(cartel)
	var pelota := get_tree().get_first_node_in_group("pelota")
	if pelota and pelota.has_signal("golpe_dado"):
		pelota.golpe_dado.connect(func(_n: int) -> void:
			if is_instance_valid(cartel):
				cartel.ocultar())


func _dibujar_suelo() -> void:
	# tierra removida
	_suelo.draw_colored_polygon(_forma, COLOR_TIERRA)
	for i in 10:
		var a := TAU * float(i) / 10.0 + 0.4
		var c := Vector2.from_angle(a) * radio * (0.45 + 0.35 * fmod(float(i) * 0.37, 1.0))
		_suelo.draw_circle(c, radio * 0.17, COLOR_TIERRA_CLARA)
	_suelo.draw_arc(Vector2.ZERO, radio * 0.97, 0.0, TAU, 56, Color(0.2, 0.11, 0.05, 0.9), 4.0)
	# anillo de puntos rojos: es la zona que chupa (gira despacito y late)
	var latido := 0.65 + 0.35 * sin(_tiempo * 4.0)
	var puntos := 30
	for i in puntos:
		var a := TAU * float(i) / float(puntos) + _tiempo * 0.35
		var p := Vector2.from_angle(a) * radio
		_suelo.draw_circle(p, 9.0, Color(0, 0, 0, 0.35 * latido))
		_suelo.draw_circle(p, 7.0, Color(COLOR_ANILLO, latido))


func _poner_estado(nuevo: String) -> void:
	if nuevo == _estado:
		return
	_estado = nuevo
	var tex := TEX_DORMIDO
	match nuevo:
		"alerta": tex = TEX_ALERTA
		"alto": tex = TEX_ALTO
	_sprite.texture = tex
	var esc := ANCHO_TOPO / float(tex.get_width())
	if nuevo == "dormido":
		esc *= 0.85
	_sprite.scale = Vector2.ONE * esc
	_sprite.offset = Vector2(0.0, -tex.get_height() * 0.18)
	_sprite.position = Vector2.ZERO
	_burbuja.visible = (nuevo == "alerta")
	if nuevo != "dormido":
		# pequeño "salto" al despertar
		_sprite.scale = Vector2.ONE * esc * 0.8
		create_tween().tween_property(_sprite, "scale", Vector2.ONE * esc, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not activo:
		return
	_tiempo += delta
	_suelo.queue_redraw()
	# respira
	if _estado == "dormido":
		_sprite.position.y = sin(_tiempo * 2.0) * 3.0
	elif _estado == "alerta":
		_burbuja.position.y = -radio * 0.95 + sin(_tiempo * 9.0) * 5.0
	elif _estado == "alto":
		_sprite.position.x = sin(_tiempo * 60.0) * 4.0


func _physics_process(_delta: float) -> void:
	if not activo or _ocupado:
		return
	var pelota := get_tree().get_first_node_in_group("pelota")
	if pelota == null or pelota.en_hoyo or pelota.siendo_chupada:
		return
	var d := global_position.distance_to(pelota.global_position)
	if d < radio:
		_chupar(pelota)
	elif d < radio * 2.2:
		_poner_estado("alerta")
	elif d > radio * 2.6:
		_poner_estado("dormido")


## Secuencia: el topo se agacha -> se abre un hueco -> la pelota cae y se oscurece ->
## el topo sale tapando el hueco con tierra (¡ALTO!) -> se guarda y la pelota vuelve a donde tiraste
func _chupar(pelota: Node) -> void:
	_ocupado = true
	Sonidos.reproducir("topo_chupa", -4.0)
	pelota.chupar(global_position, 1.5)
	_burbuja.visible = false

	# 1) el topo se agacha y se abre el hueco
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(_sprite, "scale:y", 0.0, 0.14)
	_hueco.visible = true
	_hueco.scale = Vector2(_hueco_escala.x * 0.3, 0.0)
	t1.tween_property(_hueco, "scale", _hueco_escala, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.66).timeout

	# 2) la pelota ya cayó: sale tierra y el topo aparece tapando el hueco
	pelota._polvo(global_position, 14)
	_estado = ""
	_poner_estado("alto")
	await get_tree().create_timer(0.8).timeout

	# 3) se guarda y el hueco se cierra
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(_sprite, "scale:y", 0.0, 0.16)
	t3.tween_property(_hueco, "scale", Vector2(_hueco_escala.x * 0.3, 0.0), 0.2)
	await get_tree().create_timer(0.22).timeout
	_hueco.visible = false
	while is_instance_valid(pelota) and pelota.siendo_chupada:
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.3).timeout
	_ocupado = false
	_estado = ""
	_poner_estado("dormido")
