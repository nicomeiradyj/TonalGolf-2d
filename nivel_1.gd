extends Node2D
## Script compartido por TODOS los niveles. Lo único que cambia entre un nivel y
## otro son estas variables (se editan en el Inspector del nodo raíz).

## Número del nivel (para guardar el mejor puntaje y desbloquear el siguiente)
@export var numero_nivel: int = 1
## Cantidad de golpes "ideal" del nivel
@export var par: int = 2
## Escena que se abre con el botón SIGUIENTE. Vacío = es el último nivel
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
