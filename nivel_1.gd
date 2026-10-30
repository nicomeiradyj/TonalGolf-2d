extends Node2D
## Script compartido por TODOS los niveles. Lo único que cambia entre un nivel y
## otro son estas variables (se editan en el Inspector del nodo raíz).

const PANTALLA_GAME_OVER := preload("res://pantalla_game_over.tscn")

## Número global del nivel (1 a 12): guarda el mejor puntaje y desbloquea el siguiente
@export var numero_nivel: int = 1
## Nombre que se muestra en el HUD (ej: "2-1"). Vacío = se muestra el número
@export var nombre_nivel: String = ""
## Cantidad de golpes "ideal" del nivel
@export var par: int = 2
## Escena que se abre con el botón SIGUIENTE. Vacío = es el último nivel
@export_file("*.tscn") var siguiente_nivel: String = "res://nivel_2.tscn"
## Segundos disponibles en modo HARDCORE. 0 = automático (20 s + 10 s por cada golpe de par)
@export var tiempo_hardcore: float = 0.0

@onready var hoyo: Area2D = $Hoyo
@onready var pelota: RigidBody2D = $Pelota
@onready var pantalla_victoria: CanvasLayer = $PantallaVictoria
@onready var hud: CanvasLayer = $HUD
## Cartel de "cómo se juega": solo existe en el nivel 1
@onready var ayuda: Node = get_node_or_null("Ayuda")

var hardcore: bool = false
var tiempo_restante: float = 0.0
var terminado: bool = false


func _ready() -> void:
	get_tree().paused = false
	hardcore = Progreso.modo_hardcore
	hoyo.pelota_embocada.connect(_on_pelota_embocada)
	pelota.golpe_dado.connect(_on_golpe_dado)

	hud.visible = true
	var titulo := nombre_nivel if nombre_nivel != "" else str(numero_nivel)
	hud.configurar(titulo, par, Progreso.mejor(numero_nivel))
	hud.actualizar_golpes(0)

	if hardcore:
		tiempo_restante = tiempo_total()
		hud.activar_hardcore(tiempo_restante)

	if ayuda:
		ayuda.iniciar(pelota.get_global_transform_with_canvas().origin)


## Tiempo total que tiene el nivel en modo hardcore
func tiempo_total() -> float:
	return tiempo_hardcore if tiempo_hardcore > 0.0 else 20.0 + 10.0 * par


func _process(delta: float) -> void:
	if not hardcore or terminado:
		return
	tiempo_restante -= delta
	hud.actualizar_tiempo(tiempo_restante)
	if tiempo_restante <= 0.0:
		_perder()


func _on_golpe_dado(total: int) -> void:
	hud.actualizar_golpes(total)
	if ayuda:
		ayuda.ocultar()
		ayuda = null


func _on_pelota_embocada() -> void:
	if terminado:
		return
	terminado = true
	hud.terminar()
	Sonidos.reproducir("hoyo")

	var nuevo_record := false
	if hardcore:
		# en hardcore el record es cuantos niveles seguidos se completaron
		Progreso.registrar_hardcore(numero_nivel)
	else:
		nuevo_record = Progreso.registrar(numero_nivel, pelota.golpes)

	await get_tree().create_timer(1.2).timeout
	pantalla_victoria.mostrar(pelota.golpes, siguiente_nivel, par, nuevo_record, hardcore, tiempo_restante)


## Se acabó el tiempo en modo hardcore: se pierde la partida completa
func _perder() -> void:
	terminado = true
	pelota.bloquear()
	hud.terminar()
	Sonidos.reproducir("derrota")
	var completados := numero_nivel - 1
	Progreso.registrar_hardcore(completados)

	var titulo := nombre_nivel if nombre_nivel != "" else str(numero_nivel)
	var pantalla := PANTALLA_GAME_OVER.instantiate()
	add_child(pantalla)
	await get_tree().create_timer(0.7).timeout
	pantalla.mostrar(titulo, completados)
