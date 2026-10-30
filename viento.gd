@tool
extends Area2D

#uso esto en vez de scale para que sea mas comodo
@export var tamano: Vector2 = Vector2(600, 400):
	set(valor):
		tamano = valor
		_actualizar_forma()

@export var fuerza: float = 400.0

@export var color_rafagas: Color = Color(1, 1, 1, 0.35)

#esto puede ir cambiando, vmaos probando
@export var cantidad_rafagas: int = 24:
	set(valor):
		cantidad_rafagas = valor
		_crear_rafagas()

const LARGO_RAFAGA := 60.0

## Brisa suave en bucle: se oye solo mientras la pelota está dentro de la zona
const RUTA_SONIDO := "res://assets/viento.wav"
const VOLUMEN_DB := -15.0
const VOLUMEN_SILENCIO_DB := -60.0

var _audio: AudioStreamPlayer
var _pelotas_dentro: int = 0
var _fundido: Tween

var _rafagas: Array[Vector2] = []

@onready var colision: CollisionShape2D = $CollisionShape2D

#cada zona crea su forma, asi no tienen todos la misma
func _ready() -> void:
	colision.shape = RectangleShape2D.new()
	_actualizar_forma()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		_crear_audio()


func _crear_audio() -> void:
	if not ResourceLoader.exists(RUTA_SONIDO):
		return
	var sonido = load(RUTA_SONIDO).duplicate()
	if sonido is AudioStreamWAV:
		var bytes := 2 if sonido.format == AudioStreamWAV.FORMAT_16_BITS else 1
		if sonido.stereo:
			bytes *= 2
		sonido.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sonido.loop_begin = 0
		sonido.loop_end = sonido.data.size() / bytes
	_audio = AudioStreamPlayer.new()
	_audio.stream = sonido
	_audio.volume_db = VOLUMEN_SILENCIO_DB
	add_child(_audio)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("pelota") or _audio == null:
		return
	_pelotas_dentro += 1
	if not Progreso.sonido_activo:
		return
	if _fundido:
		_fundido.kill()
	if not _audio.playing:
		_audio.play(randf_range(0.0, 3.0))   # arranca en un punto distinto cada vez
	_fundido = create_tween()
	_fundido.tween_property(_audio, "volume_db", VOLUMEN_DB, 0.7)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("pelota") or _audio == null:
		return
	_pelotas_dentro = maxi(_pelotas_dentro - 1, 0)
	if _pelotas_dentro > 0:
		return
	if _fundido:
		_fundido.kill()
	_fundido = create_tween()
	_fundido.tween_property(_audio, "volume_db", VOLUMEN_SILENCIO_DB, 0.9)
	_fundido.tween_callback(_audio.stop)


func _actualizar_forma() -> void:
	if not is_node_ready():
		return
	colision.shape.size = tamano
	_crear_rafagas()


func _crear_rafagas() -> void:
	_rafagas.clear()
	for i in cantidad_rafagas:
		_rafagas.append(_punto_al_azar(randf_range(-tamano.x / 2.0, tamano.x / 2.0)))


func _punto_al_azar(x: float) -> Vector2:
	return Vector2(x, randf_range(-tamano.y / 2.0, tamano.y / 2.0))


func _process(delta: float) -> void:
	var velocidad := 150.0 + fuerza * 0.8
	for i in _rafagas.size():
		_rafagas[i].x += velocidad * delta
		#cuando una rafaga de viento sale por un lado, vuelve a entrar por el otro
		if _rafagas[i].x > tamano.x / 2.0:
			_rafagas[i] = _punto_al_azar(-tamano.x / 2.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-tamano / 2.0, tamano), Color(color_rafagas, 0.06))
	for punta in _rafagas:
		var cola := Vector2(maxf(punta.x - LARGO_RAFAGA, -tamano.x / 2.0), punta.y)
		draw_line(cola, punta, color_rafagas, 4.0)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return  # en el editor solo se dibuja, no empuja nada
	var empuje := global_transform.x.normalized() * fuerza
	for body in get_overlapping_bodies():
		if body.is_in_group("pelota") and not body.en_hoyo:
			# la pelota se entera de que hay viento: no se frena en seco y puede arrancar desde el reposo
			if body.has_method("recibir_viento"):
				body.recibir_viento(empuje)
			else:
				body.apply_central_force(empuje)
