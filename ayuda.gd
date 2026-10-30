extends CanvasLayer
## Cartel rápido de "cómo se juega" para el primer nivel (no es un tutorial:
## solo explica el gesto y desaparece solo en cuanto se da el primer golpe).

const LARGO_FLECHA := 80.0
const RECORRIDO_DEDO := 130.0

@onready var raiz: Control = $Raiz
@onready var gesto: Control = %Gesto

var _origen: Vector2 = Vector2(360, 1090)
var _progreso: float = 0.0
var _disparo: float = -1.0
var _visible_dedo: float = 0.0
var _saliendo: bool = false


func _ready() -> void:
	gesto.draw.connect(_dibujar_gesto)
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, 0.5)


## Recibe la posicion de la pelota en pantalla y empieza la animacion en bucle
func iniciar(posicion_pelota: Vector2) -> void:
	_origen = posicion_pelota
	var t := create_tween().set_loops()
	t.tween_callback(func() -> void:
		_progreso = 0.0
		_disparo = -1.0)
	t.tween_property(self, "_visible_dedo", 1.0, 0.25)
	t.tween_property(self, "_progreso", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.2)
	t.tween_property(self, "_visible_dedo", 0.0, 0.1)
	t.tween_property(self, "_disparo", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.5)


func _process(_delta: float) -> void:
	gesto.queue_redraw()


func _dibujar_gesto() -> void:
	var rojo := Color(0.95, 0.1, 0.1)
	# flecha roja: sale de la pelota hacia ARRIBA mientras el dedo arrastra hacia ABAJO
	if _progreso > 0.02 and _disparo < 0.0:
		var largo := LARGO_FLECHA * _progreso
		var punta := _origen + Vector2(0, -largo)
		gesto.draw_line(_origen, punta, rojo, 7.0)
		var base := punta + Vector2(0, 4)
		gesto.draw_colored_polygon(PackedVector2Array([
			punta + Vector2(0, -22), base + Vector2(-18, 0), base + Vector2(18, 0)]), rojo)
	if _disparo >= 0.0:
		var pos := _origen + Vector2(0, -260.0 * _disparo)
		gesto.draw_circle(pos, 30.0, Color(1, 1, 1, 0.85 * (1.0 - _disparo)))
	if _visible_dedo > 0.0:
		var dedo := _origen + Vector2(0, 20.0 + RECORRIDO_DEDO * _progreso)
		gesto.draw_circle(dedo, 46.0, Color(1, 1, 1, 0.25 * _visible_dedo))
		gesto.draw_circle(dedo, 30.0, Color(1, 1, 1, 0.55 * _visible_dedo))
		gesto.draw_arc(dedo, 46.0, 0, TAU, 32, Color(1, 1, 1, 0.9 * _visible_dedo), 3.0)


## Se llama en el primer golpe: se desvanece y se borra
func ocultar() -> void:
	if _saliendo:
		return
	_saliendo = true
	var t := create_tween()
	t.tween_property(raiz, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)


## Un toque o click en cualquier lado cierra el cartel (sin bloquear el gesto de apuntar)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		ocultar()
	elif event is InputEventScreenTouch and event.pressed:
		ocultar()
