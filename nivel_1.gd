extends Node2D

## A dónde ir cuando se emboca (por ahora el menú, después nivel_2)
@export_file("*.tscn") var siguiente_escena: String = "res://menu.tscn"

@onready var hoyo: Area2D = $Hoyo


func _ready() -> void:
	hoyo.pelota_embocada.connect(_on_pelota_embocada)


func _on_pelota_embocada() -> void:
	print("¡In!")
	await get_tree().create_timer(1.0).timeout  
	get_tree().change_scene_to_file(siguiente_escena)
