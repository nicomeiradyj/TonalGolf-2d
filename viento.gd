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

var _rafagas: Array[Vector2] = []

@onready var colision: CollisionShape2D = $CollisionShape2D

#cada zona crea su forma, asi no tienen todos la misma
func _ready() -> void:
	colision.shape = RectangleShape2D.new()
	_actualizar_forma()


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
			body.apply_central_force(empuje)
