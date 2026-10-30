extends Button
## Botón "HARDCORE" del menú principal: arranca una partida completa desde el
## nivel 1, con tiempo límite en cada nivel. Si se acaba el tiempo se pierde todo.

const PRIMER_NIVEL := "res://nivel_1.tscn"

@export var sonido_click: AudioStream

func _ready() -> void:
	pressed.connect(_on_pressed)
	if Progreso.hardcore_record > 0:
		var etiqueta := Label.new()
		etiqueta.text = "RECORD: %d/%d" % [Progreso.hardcore_record, Progreso.TOTAL_NIVELES]
		etiqueta.add_theme_font_size_override("font_size", 22)
		etiqueta.set_anchors_preset(Control.PRESET_FULL_RECT)
		etiqueta.offset_right = -16
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(etiqueta)

func _on_pressed() -> void:
	if sonido_click and Progreso.sonido_activo:
		var audio := AudioStreamPlayer.new()
		audio.stream = sonido_click
		get_tree().root.add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
	Progreso.modo_hardcore = true
	get_tree().change_scene_to_file(PRIMER_NIVEL)
