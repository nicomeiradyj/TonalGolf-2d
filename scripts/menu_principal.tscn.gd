extends Button

# Permite elegir la escena del nivel desde el Inspector de Godot
@export_file("*.tscn") var nivel_a_cargar: String

# Número del nivel (para saber si está desbloqueado y mostrar el mejor puntaje)
@export var numero_nivel: int = 1

# Permite arrastrar el audio de click desde el Inspector
@export var sonido_click: AudioStream

func _ready() -> void:
	# Conectamos la señal que detecta cuando se suelta el clic/toque
	pressed.connect(_on_pressed)

	# Un nivel se desbloquea al completar el anterior
	var desbloqueado := Progreso.esta_desbloqueado(numero_nivel)
	disabled = not desbloqueado

	var mejor := Progreso.mejor(numero_nivel)
	if not desbloqueado:
		_agregar_etiqueta("BLOQUEADO")
	elif mejor > 0:
		_agregar_etiqueta("MEJOR: %d" % mejor)

func _agregar_etiqueta(texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 22)
	etiqueta.set_anchors_preset(Control.PRESET_FULL_RECT)
	etiqueta.offset_right = -16
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(etiqueta)

func _on_pressed() -> void:
	# Si asignamos un sonido, lo reproduce
	if sonido_click and Progreso.sonido_activo:
		var audio := AudioStreamPlayer.new()
		audio.stream = sonido_click
		get_tree().root.add_child(audio)
		audio.play()
		# Se destruye solo cuando termina de sonar para no ocupar memoria
		audio.finished.connect(audio.queue_free)

	# Cambia a la escena del nivel elegido
	if nivel_a_cargar != "":
		get_tree().change_scene_to_file(nivel_a_cargar)
