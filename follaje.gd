extends Sprite2D
## Arboles (copa): se dibuja POR ENCIMA de la pelota, así que la
## pelota pasa por debajo. Al meterse debajo, la copa se sacude, suena un
## roce suave y la pelota se ve más oscura y translucida (ver pelota.gd -> entrar_follaje).

const MARGEN := 0.2          # recorte del rectángulo (los bordes del sprite son transparentes)
const COOLDOWN_SONIDO := 0.45

var _pelota: Node2D
var _dentro: bool = false
var _rot_base: float = 0.0
var _escala_base: Vector2 = Vector2.ONE
var _tween: Tween
var _ultimo_sonido: float = -10.0
var _balanceo: float = 0.0


func _ready() -> void:
	z_index = maxi(z_index, 2)
	_rot_base = rotation
	_escala_base = scale
	if Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _pelota == null or not is_instance_valid(_pelota):
		_pelota = get_tree().get_first_node_in_group("pelota") as Node2D
		return
	var rect := get_rect()
	rect = rect.grow_individual(-rect.size.x * MARGEN, -rect.size.y * MARGEN, -rect.size.x * MARGEN, -rect.size.y * MARGEN)
	var dentro := rect.has_point(to_local(_pelota.global_position))
	if dentro != _dentro:
		_dentro = dentro
		if dentro:
			_entrar()
		else:
			_salir()
	# mientras la pelota se mueve por debajo, el follaje se balancea
	var objetivo := 0.0
	if _dentro and _pelota is RigidBody2D:
		objetivo = clampf((_pelota as RigidBody2D).linear_velocity.length() / 300.0, 0.0, 1.0)
	_balanceo = move_toward(_balanceo, objetivo, delta * 4.0)
	if _balanceo > 0.001 and (_tween == null or not _tween.is_running()):
		rotation = _rot_base + sin(Time.get_ticks_msec() / 1000.0 * 16.0) * 0.045 * _balanceo


func _entrar() -> void:
	if _pelota.has_method("entrar_follaje"):
		_pelota.entrar_follaje()
	var velocidad := 0.0
	if _pelota is RigidBody2D:
		velocidad = (_pelota as RigidBody2D).linear_velocity.length()
	# sacudida con rebote (más fuerte cuanto más rápido pasa la pelota)
	var f := clampf(0.5 + velocidad / 700.0, 0.5, 1.4)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation", _rot_base + 0.13 * f, 0.07)
	_tween.parallel().tween_property(self, "scale", _escala_base * (1.0 + 0.09 * f), 0.07)
	_tween.tween_property(self, "rotation", _rot_base - 0.10 * f, 0.1)
	_tween.tween_property(self, "rotation", _rot_base + 0.05 * f, 0.1)
	_tween.tween_property(self, "rotation", _rot_base, 0.14)
	_tween.parallel().tween_property(self, "scale", _escala_base, 0.2)
	if velocidad > 40.0:
		var ahora := Time.get_ticks_msec() / 1000.0
		if ahora - _ultimo_sonido > COOLDOWN_SONIDO:
			_ultimo_sonido = ahora
			Sonidos.reproducir("hojas", -14.0 + minf(velocidad / 120.0, 4.0), randf_range(0.92, 1.12))


func _salir() -> void:
	if _pelota != null and is_instance_valid(_pelota) and _pelota.has_method("salir_follaje"):
		_pelota.salir_follaje()
	pass
