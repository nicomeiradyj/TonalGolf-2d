extends Node2D

@export_file("*.tscn") var siguiente_nivel: String = "res://nivel_2.tscn" #cuando sae cree el nivel 2

@onready var hoyo: Area2D = $Hoyo
@onready var pelota: RigidBody2D = $Pelota
@onready var pantalla_victoria: CanvasLayer = $PantallaVictoria


func _ready() -> void:
	hoyo.pelota_embocada.connect(_on_pelota_embocada)


func _on_pelota_embocada() -> void:
	await get_tree().create_timer(0.8).timeout 
	pantalla_victoria.mostrar(pelota.golpes, siguiente_nivel)
