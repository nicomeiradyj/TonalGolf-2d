extends Control

@onready var panel_inicio: Control = $PanelInicio
@onready var panel_seleccion: Control = $PanelSeleccion

# Ruta directa al Nivel 1 de la Sección 1
@export_file("*.tscn") var primer_nivel: String = "uid://dy7on1h07p4jj"

func _ready() -> void:
	# Al iniciar se muestra la tarjeta de portada y se oculta el selector de niveles
	panel_inicio.visible = true
	panel_seleccion.visible = false

func _on_btn_iniciar_pressed() -> void:
	Progreso.modo_hardcore = false
	if Progreso.sonido_activo:
		Sonidos.reproducir("click")
	if primer_nivel != "":
		get_tree().change_scene_to_file(primer_nivel)

func _on_btn_niveles_pressed() -> void:
	if Progreso.sonido_activo:
		Sonidos.reproducir("click")
	panel_inicio.visible = false
	panel_seleccion.visible = true

func _on_btn_volver_pressed() -> void:
	if Progreso.sonido_activo:
		Sonidos.reproducir("click")
	panel_seleccion.visible = false
	panel_inicio.visible = true
