extends Area2D
## Charco de barro: al caer en él suena una salpicadura, y mientras la pelota
## rueda dentro se oye el chapoteo, para sentir la textura.

## velocidad mínima para que suene (evita ruido cuando la pelota está casi quieta)
const VELOCIDAD_MIN := 60.0

## chapoteo mientras rueda: muy espaciado y bajito para no cansar
const INTERVALO_ROCE := 0.7
const VELOCIDAD_ROCE_MIN := 140.0

var _tiempo_roce: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_exited(body: Node) -> void:
	if body.has_method("salir_barro"):
		body.salir_barro()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("pelota"):
		return
	if body.has_method("entrar_barro"):
		body.entrar_barro()
	var v: float = body.linear_velocity.length()
	if v < VELOCIDAD_MIN:
		return
	_tiempo_roce = 0.0
	Sonidos.reproducir("barro", linear_to_db(clampf(v / 2000.0, 0.15, 0.32)), randf_range(0.94, 1.06))


func _physics_process(delta: float) -> void:
	_tiempo_roce = maxf(_tiempo_roce - delta, 0.0)
	if _tiempo_roce > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("pelota"):
			var v: float = body.linear_velocity.length()
			if v >= VELOCIDAD_ROCE_MIN:
				_tiempo_roce = INTERVALO_ROCE
				Sonidos.reproducir("barro_roce", linear_to_db(clampf(v / 3000.0, 0.08, 0.16)), randf_range(0.92, 1.08))
			return
