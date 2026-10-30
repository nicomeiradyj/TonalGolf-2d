extends CanvasLayer
## Cartel de "qué hace este terreno" para el primer nivel donde aparece cada uno
## (barro, viento, hielo). Igual que la ayuda del nivel 1: explica y desaparece
## solo en cuanto se da el primer golpe. `tipo`: "barro", "viento" o "hielo".

const RUTA_FUENTE := "res://assets/w3-ip.ttf"

const TEXTOS := {
	"barro": {
		"titulo": "BARRO",
		"color": Color(0.82, 0.58, 0.32),
		"lineas": ["FRENA LA PELOTA", "SI TE QUEDAS PARADO EN EL BARRO\nEL TIRO SALE MAS DEBIL", "TE ENSUCIA Y SE LIMPIA CON LOS TIROS"],
	},
	"viento": {
		"titulo": "VIENTO",
		"color": Color(0.8, 0.95, 1.0),
		"lineas": ["LA BRISA EMPUJA LA PELOTA", "DENTRO DEL VIENTO PODES TIRAR\nAUNQUE LA PELOTA SE MUEVA", "USALO A TU FAVOR"],
	},
	"hielo": {
		"titulo": "HIELO",
		"color": Color(0.55, 0.85, 1.0),
		"lineas": ["LA PELOTA RESBALA MUCHO MAS", "SOBRE EL HIELO PODES TIRAR\nCON LA PELOTA EN MOVIMIENTO", "EN PASTO O BARRO SOLO QUIETA"],
	},
}

@export var tipo: String = "hielo"

var _raiz: Control
var _icono: Control
var _tiempo: float = 0.0
var _saliendo: bool = false


func _ready() -> void:
	layer = 4
	var datos: Dictionary = TEXTOS.get(tipo, TEXTOS["hielo"])
	var color: Color = datos["color"]

	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -310.0
	panel.offset_right = 310.0
	panel.offset_top = 330.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.04, 0.025, 0.9)
	estilo.set_border_width_all(4)
	estilo.border_color = color
	estilo.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", estilo)
	_raiz.add_child(panel)

	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_constant_override("separation", 12)
	panel.add_child(caja)

	_icono = Control.new()
	_icono.custom_minimum_size = Vector2(0, 90)
	_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono.draw.connect(_dibujar_icono.bind(color))
	caja.add_child(_icono)

	caja.add_child(_etiqueta(datos["titulo"], 38, color))
	var lineas: Array = datos["lineas"]
	for i in lineas.size():
		caja.add_child(_etiqueta(lineas[i], 24, Color.WHITE if i < lineas.size() - 1 else Color(0.3372549, 0.8, 0.5411765)))

	_raiz.modulate.a = 0.0
	create_tween().tween_property(_raiz, "modulate:a", 1.0, 0.5)


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if ResourceLoader.exists(RUTA_FUENTE):
		l.add_theme_font_override("font", load(RUTA_FUENTE))
	return l


## Compatibilidad con el nivel 1 (mismo contrato que ayuda.tscn)
func iniciar(_posicion_pelota: Vector2) -> void:
	pass


func _process(delta: float) -> void:
	_tiempo += delta
	if _icono:
		_icono.queue_redraw()


func _dibujar_icono(color: Color) -> void:
	var c := Vector2(_icono.size.x * 0.5, 45.0)
	match tipo:
		"hielo":
			var r := Rect2(c - Vector2(70, 34), Vector2(140, 68))
			_icono.draw_rect(r, Color(0.55, 0.82, 1.0, 0.9))
			_icono.draw_rect(r, Color.WHITE, false, 4.0)
			var a := 0.5 + 0.5 * sin(_tiempo * 3.0)
			_icono.draw_line(c + Vector2(-40, 20), c + Vector2(-10, -20), Color(1, 1, 1, a), 3.0)
			_icono.draw_line(c + Vector2(20, -6), c + Vector2(40, -26), Color(1, 1, 1, 1.0 - a), 3.0)
		"barro":
			var marron := Color(0.4, 0.26, 0.13)
			for p in [Vector2(-50, 6), Vector2(0, -8), Vector2(46, 8), Vector2(-14, 18), Vector2(24, 20)]:
				_icono.draw_circle(c + p, 26.0, marron)
			_icono.draw_circle(c + Vector2(-6, -12), 6.0, Color(0.55, 0.38, 0.2))
			_icono.draw_circle(c + Vector2(30, 2), 5.0, Color(0.55, 0.38, 0.2))
		"viento":
			for i in 3:
				var y := c.y - 24.0 + 24.0 * i
				var corr := fmod(_tiempo * 70.0 + i * 40.0, 60.0)
				var pts := PackedVector2Array()
				for k in 21:
					var x := -80.0 + k * 8.0 + corr - 30.0
					pts.append(Vector2(c.x + x, y + sin((x + _tiempo * 80.0) * 0.08) * 6.0))
				_icono.draw_polyline(pts, color, 4.0)
			_icono.draw_colored_polygon(PackedVector2Array([
				c + Vector2(92, 0), c + Vector2(66, -18), c + Vector2(66, 18)]), color)


## Se llama en el primer golpe: se desvanece y se borra
func ocultar() -> void:
	if _saliendo:
		return
	_saliendo = true
	var t := create_tween()
	t.tween_property(_raiz, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)


## Un toque o click en cualquier lado cierra el cartel (sin bloquear el gesto de apuntar)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		ocultar()
	elif event is InputEventScreenTouch and event.pressed:
		ocultar()
