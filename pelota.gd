extends RigidBody2D

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var en_hoyo: bool = false

@export var power_multiplier: float = 3.0 
@export var max_aim_length: float = 150.0 # Este es el tope máximo en píxeles que podrá estirarse la línea

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea: Line2D = $LineaApuntado
@onready var punta_flecha: Sprite2D = $LineaApuntado/PuntaFlecha

func _ready() -> void:
	add_to_group("pelota")
	linea.clear_points()
	punta_flecha.visible = false

func _input(event: InputEvent) -> void:
	if en_hoyo:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			drag_start = get_global_mouse_position()
			dragging = true
			punta_flecha.visible = true
		elif dragging:
			dragging = false
			var drag_end: Vector2 = get_global_mouse_position()
			
			var impulse_vector: Vector2 = (drag_start - drag_end).limit_length(max_aim_length)
			apply_central_impulse(impulse_vector * power_multiplier)
			
			linea.clear_points()
			punta_flecha.visible = false

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
	if linear_velocity.length() > 5.0:
		sprite.rotation += linear_velocity.length() * delta * 0.05

func embocar(posicion_hoyo: Vector2) -> void:
	en_hoyo = true
	dragging = false
	linea.clear_points()
	punta_flecha.visible = false

	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(self, "global_position", posicion_hoyo, 0.15)
