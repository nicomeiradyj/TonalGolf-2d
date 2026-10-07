extends CanvasLayer

@onready var label_golpes: Label = %Golpes
@onready var btn_siguiente: Button = %BotonSiguiente
@onready var btn_reintentar: Button = %BotonReintentar
@onready var btn_menu: Button = %BotonMenu

var siguiente_nivel: String = ""

func _ready() -> void:
	visible = false  
	btn_siguiente.pressed.connect(_on_siguiente)
	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)

func mostrar(golpes: int, nivel_siguiente: String) -> void:
	siguiente_nivel = nivel_siguiente

	if golpes == 1:
		label_golpes.text = "¡En un solo golpe!"
	else:
		label_golpes.text = "Golpes: %d" % golpes
	btn_siguiente.visible = ResourceLoader.exists(siguiente_nivel)
	visible = true


func _on_siguiente() -> void:
	get_tree().change_scene_to_file(siguiente_nivel)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
