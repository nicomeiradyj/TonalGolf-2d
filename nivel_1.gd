extends Node2D

@export var numero_nivel: int = 1
@export var par: int = 2
@export_file("*.tscn") var siguiente_nivel: String = "res://nivel_2.tscn"

@onready var hoyo: Area2D = $Hoyo
@onready var pelota: RigidBody2D = $Pelota
@onready var pantalla_victoria: CanvasLayer = $PantallaVictoria
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	get_tree().paused = false
	hoyo.pelota_embocada.connect(_on_pelota_embocada)
	pelota.golpe_dado.connect(hud.actualizar_golpes)
	hud.configurar(numero_nivel, par, Progreso.mejor(numero_nivel))
	hud.actualizar_golpes(0)


func _on_pelota_embocada() -> void:
	hud.terminar()
	Sonidos.reproducir("hoyo")
	var nuevo_record := Progreso.registrar(numero_nivel, pelota.golpes)
	await get_tree().create_timer(1.2).timeout
	pantalla_victoria.mostrar(pelota.golpes, siguiente_nivel, par, nuevo_record)
