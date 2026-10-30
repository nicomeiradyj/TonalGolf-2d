@tool
extends Area2D
## Zona de hielo: mientras la pelota la pisa casi no se frena (resbala) y se puede
## tirar aunque esté en movimiento. Se dimensiona con "tamano" (no con scale).
## Si se rota el nodo, el hielo rota con él.

@export var tamano: Vector2 = Vector2(600, 400):
	set(valor):
		tamano = valor
		_actualizar_forma()

@export var color_hielo: Color = Color(0.5, 0.8, 1.0, 0.86)

const RADIO_ESQUINA := 46
const RUTA_FUENTE_SONIDO := "hielo"

var _brillos: Array[Vector4] = []    # x, y, fase, escala
var _destellos: Array[Vector3] = []  # x, y, fase
var _tiempo: float = 0.0
var _ultimo_sonido: float = -10.0
var _estilo_cuerpo: StyleBoxFlat
var _estilo_borde: StyleBoxFlat

@onready var colision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	colision.shape = RectangleShape2D.new()
	_crear_estilos()
	_actualizar_forma()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _crear_estilos() -> void:
	_estilo_cuerpo = StyleBoxFlat.new()
	_estilo_cuerpo.bg_color = color_hielo
	_estilo_cuerpo.set_corner_radius_all(RADIO_ESQUINA)
	_estilo_cuerpo.border_color = Color(0.94, 0.985, 1.0, 0.95)
	_estilo_cuerpo.set_border_width_all(9)
	_estilo_cuerpo.anti_aliasing = true
	# halo azulado alrededor: suaviza el borde y lo hace ver "frio"
	_estilo_borde = StyleBoxFlat.new()
	_estilo_borde.bg_color = Color(0.7, 0.9, 1.0, 0.0)
	_estilo_borde.set_corner_radius_all(RADIO_ESQUINA + 14)
	_estilo_borde.border_color = Color(0.75, 0.92, 1.0, 0.32)
	_estilo_borde.set_border_width_all(14)
	_estilo_borde.anti_aliasing = true


func _actualizar_forma() -> void:
	if not is_node_ready():
		return
	colision.shape.size = tamano
	_crear_detalles()
	queue_redraw()


func _crear_detalles() -> void:
	_brillos.clear()
	_destellos.clear()
	var azar := RandomNumberGenerator.new()
	azar.seed = int(tamano.x * 31.0 + tamano.y * 17.0)
	var cantidad := clampi(int(tamano.x * tamano.y / 26000.0), 3, 14)
	for i in cantidad:
		_brillos.append(Vector4(
			azar.randf_range(-tamano.x / 2.0 + 70.0, tamano.x / 2.0 - 110.0),
			azar.randf_range(-tamano.y / 2.0 + 90.0, tamano.y / 2.0 - 50.0),
			azar.randf_range(0.0, TAU),
			azar.randf_range(0.6, 1.4)))
	for i in clampi(cantidad, 3, 8):
		_destellos.append(Vector3(
			azar.randf_range(-tamano.x / 2.0 + 60.0, tamano.x / 2.0 - 60.0),
			azar.randf_range(-tamano.y / 2.0 + 60.0, tamano.y / 2.0 - 60.0),
			azar.randf_range(0.0, TAU)))


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	if _estilo_cuerpo == null:
		return
	var rect := Rect2(-tamano / 2.0, tamano)
	draw_style_box(_estilo_borde, rect.grow(10.0))
	draw_style_box(_estilo_cuerpo, rect)
	# capa interior mas clara: superficie lisa y brillante
	var interior := StyleBoxFlat.new()
	interior.bg_color = Color(0.88, 0.97, 1.0, 0.26)
	interior.set_corner_radius_all(RADIO_ESQUINA - 14)
	interior.anti_aliasing = true
	draw_style_box(interior, rect.grow(-20.0))
	# reflejos diagonales que titilan despacio
	for b in _brillos:
		var alfa := 0.22 + 0.32 * (0.5 + 0.5 * sin(_tiempo * 1.5 + b.z))
		var inicio := Vector2(b.x, b.y)
		draw_line(inicio, inicio + Vector2(44, -44) * b.w, Color(1, 1, 1, alfa), 5.0)
		draw_line(inicio + Vector2(16, 10) * b.w, inicio + Vector2(44, -18) * b.w, Color(1, 1, 1, alfa * 0.7), 3.0)
	# destellos en forma de estrellita que aparecen y se desvanecen
	for d in _destellos:
		var brillo := maxf(sin(_tiempo * 1.1 + d.z), 0.0)
		brillo = brillo * brillo * brillo
		if brillo < 0.02:
			continue
		var c := Vector2(d.x, d.y)
		var largo := 10.0 + 26.0 * brillo
		var color := Color(1, 1, 1, 0.9 * brillo)
		draw_line(c - Vector2(largo, 0), c + Vector2(largo, 0), color, 3.0)
		draw_line(c - Vector2(0, largo), c + Vector2(0, largo), color, 3.0)
		draw_line(c - Vector2(largo, largo) * 0.45, c + Vector2(largo, largo) * 0.45, Color(color, color.a * 0.6), 2.0)
		draw_line(c - Vector2(largo, -largo) * 0.45, c + Vector2(largo, -largo) * 0.45, Color(color, color.a * 0.6), 2.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("entrar_hielo"):
		body.entrar_hielo()
	# tintineo suave al entrar (con un pequeño margen para que no se repita)
	if body.is_in_group("pelota") and _tiempo - _ultimo_sonido > 0.8:
		var v: float = body.linear_velocity.length()
		if v > 120.0:
			_ultimo_sonido = _tiempo
			Sonidos.reproducir(RUTA_FUENTE_SONIDO, linear_to_db(clampf(v / 1500.0, 0.2, 0.45)), randf_range(0.95, 1.05))


func _on_body_exited(body: Node) -> void:
	if body.has_method("salir_hielo"):
		body.salir_hielo()
