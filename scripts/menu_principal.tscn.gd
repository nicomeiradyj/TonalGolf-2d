extends Button

# Permite elegir la escena del nivel desde el Inspector de Godot
@export_file("*.tscn") var nivel_a_cargar: String

# Permite arrastrar el audio de click desde el Inspector
@export var sonido_click: AudioStream

func _ready() -> void:
	# Conectamos la señal que detecta cuando se suelta el clic/toque
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Si asignamos un sonido, lo reproduce
	if sonido_click:
		var audio := AudioStreamPlayer.new()
		audio.stream = sonido_click
		get_tree().root.add_child(audio)
		audio.play()
		# Se destruye solo cuando termina de sonar para no ocupar memoria
		audio.finished.connect(audio.queue_free)
	
	# Cambia a la escena del nivel elegido
	if nivel_a_cargar != "":
		get_tree().change_scene_to_file(nivel_a_cargar)
