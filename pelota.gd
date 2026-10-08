extends RigidBody2D

signal golpe_dado(total: int)

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var en_hoyo: bool = false
var golpes: int = 0

@export var power_multiplier: float = 3.0
@export var max_aim_length: float = 150.0
@export var velocidad_minima_tiro: float = 10.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea: Line2D = $LineaApuntado
@onready var punta_flecha: Sprite2D = $LineaApuntado/PuntaFlecha

func _ready() -> void:
	add_to_group("pelota")
	linea.clear_points()
	punta_flecha.visible = false
	body_entered.connect(_on_body_entered)

# El clic/toque que NO fue consumido por un botón de la interfaz (ej: el botón de
# pausa) empieza el apuntado. Así tocar "pausa" no dispara un tiro.
func _unhandled_input(event: InputEvent) -> void:
	if en_hoyo:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if not esta_quieta():
			return
		drag_start = get_global_mouse_position()
		dragging = true
		punta_flecha.visible = true

# Soltar siempre se escucha, aunque el dedo termine encima de un botón
func _input(event: InputEvent) -> void:
	if en_hoyo or not dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		_soltar()

func _soltar() -> void:
	dragging = false
	var drag_end: Vector2 = get_global_mouse_position()
	var impulse_vector: Vector2 = (drag_start - drag_end).limit_length(max_aim_length)

	linea.clear_points()
	punta_flecha.visible = false

	if impulse_vector.length() < 10.0:
		return

	apply_central_impulse(impulse_vector * power_multiplier)
	golpes += 1
	golpe_dado.emit(golpes)

	var fuerza := impulse_vector.length() / max_aim_length
	Sonidos.reproducir("golpe", linear_to_db(0.4 + 0.6 * fuerza))

func _process(_delta: float) -> void:
	if dragging:
		var drag_end: Vector2 = get_global_mouse_position()
		var aim_vector: Vector2 = (drag_start - drag_end).limit_length(max_aim_length)

		linea.clear_points()
		linea.add_point(Vector2.ZERO)
		linea.add_point(aim_vector)

		punta_flecha.position = aim_vector
		punta_flecha.rotation = aim_vector.angle()

func _physics_process(delta: float) -> void:
	var velocidad := linear_velocity.length()
	if velocidad > 5.0:
		sprite.rotation += velocidad * delta * 0.05

	if not en_hoyo and velocidad > 0.0 and velocidad < velocidad_minima_tiro:
		linear_velocity = Vector2.ZERO

func _on_body_entered(_body: Node) -> void:
	var velocidad := linear_velocity.length()
	if velocidad < 80.0:
		return
	Sonidos.reproducir("rebote", linear_to_db(clampf(velocidad / 1200.0, 0.15, 1.0)), randf_range(0.9, 1.1))

func esta_quieta() -> bool:
	return linear_velocity.length() < velocidad_minima_tiro

func embocar(posicion_hoyo: Vector2) -> void:
	en_hoyo = true
	dragging = false
	linea.clear_points()
	punta_flecha.visible = false

	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO

	# Animación de caída: la pelota se centra en el hoyo, gira, se achica y se
	# oscurece como si cayera adentro.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", posicion_hoyo, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.42) \
		.set_delay(0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate", Color(0.12, 0.12, 0.12, 1.0), 0.42) \
		.set_delay(0.08)
	tween.tween_property(sprite, "rotation", sprite.rotation + TAU * 0.8, 0.5)
	tween.chain().tween_callback(hide)
