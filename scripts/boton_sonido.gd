extends Button
## Botón del menú principal para prender/apagar música y efectos.

func _ready() -> void:
	pressed.connect(_on_pressed)
	_actualizar_texto()

func _on_pressed() -> void:
	Progreso.set_sonido(not Progreso.sonido_activo)
	Sonidos.actualizar_musica()
	Sonidos.reproducir("click")
	_actualizar_texto()

func _actualizar_texto() -> void:
	text = "SONIDO: SI" if Progreso.sonido_activo else "SONIDO: NO"
