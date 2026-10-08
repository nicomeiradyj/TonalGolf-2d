extends CanvasLayer
## HUD del nivel: nivel, golpes, par, mejor puntaje y menú de pausa.

const ESCENA_MENU := "res://menu.tscn"

@onready var label_nivel: Label = %LabelNivel
@onready var label_golpes: Label = %LabelGolpes
@onready var label_info: Label = %LabelInfo
@onready var btn_pausa: Button = %BotonPausa
@onready var panel_pausa: Control = %PanelPausa
@onready var btn_seguir: Button = %BotonSeguir
@onready var btn_reiniciar: Button = %BotonReiniciar
@onready var btn_sonido: Button = %BotonSonido
@onready var btn_menu: Button = %BotonMenuPausa

var bloqueado: bool = false


func _ready() -> void:
	# El HUD sigue activo con el juego pausado, así los botones responden
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel_pausa.visible = false
	btn_pausa.pressed.connect(alternar_pausa)
	btn_seguir.pressed.connect(alternar_pausa)
	btn_reiniciar.pressed.connect(_on_reiniciar)
	btn_sonido.pressed.connect(_on_sonido)
	btn_menu.pressed.connect(_on_menu)
	_actualizar_texto_sonido()


func configurar(numero_nivel: int, par: int, mejor: int) -> void:
	label_nivel.text = "NIVEL %d" % numero_nivel
	var info := "PAR %d" % par
	if mejor > 0:
		info += "   MEJOR %d" % mejor
	label_info.text = info


func actualizar_golpes(total: int) -> void:
	label_golpes.text = "GOLPES: %d" % total


## Se llama al embocar: oculta el HUD y evita que se pause
func terminar() -> void:
	bloqueado = true
	visible = false


func alternar_pausa() -> void:
	if bloqueado:
		return
	Sonidos.reproducir("click")
	var pausar := not get_tree().paused
	get_tree().paused = pausar
	panel_pausa.visible = pausar


func _unhandled_input(event: InputEvent) -> void:
	# Escape en PC
	if event.is_action_pressed("ui_cancel"):
		alternar_pausa()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Botón "atrás" de Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		alternar_pausa()


func _on_reiniciar() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_sonido() -> void:
	Progreso.set_sonido(not Progreso.sonido_activo)
	Sonidos.actualizar_musica()
	_actualizar_texto_sonido()
	Sonidos.reproducir("click")


func _on_menu() -> void:
	Sonidos.reproducir("click")
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _actualizar_texto_sonido() -> void:
	btn_sonido.text = "SONIDO: SI" if Progreso.sonido_activo else "SONIDO: NO"
