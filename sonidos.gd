extends Node
## Autoload "Sonidos": reproduce efectos desde cualquier escena.
## Uso: Sonidos.reproducir("golpe")
## Si falta algún archivo de audio, simplemente no suena (no rompe el juego).

const RUTAS := {
	"golpe": "res://assets/golpe.wav",
	"rebote": "res://assets/rebote.wav",
	"hoyo": "res://assets/hoyo.wav",
	"click": "res://assets/menu_click.mp3",
	"casi": "res://assets/casi.wav",
	"hielo": "res://assets/hielo.wav",
	"barro": "res://assets/barro.wav",
	"barro_roce": "res://assets/barro_roce.wav",
	"tictac": "res://assets/tictac.wav",
	"derrota": "res://assets/derrota.wav",
	"victoria": "res://assets/victoria.wav",
	"victoria_final": "res://assets/victoria_final.wav",
}

## Música de fondo (OGG en loop). Para cambiarla, reemplazá este archivo
## o cambiá la ruta.
const RUTA_MUSICA := "res://assets/musica_golf.ogg"
const VOLUMEN_MUSICA_DB := -12.0

var _streams: Dictionary = {}
var _musica: AudioStreamPlayer
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# Tiene que sonar también con el juego en pausa (botones del menú de pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in RUTAS:
		if ResourceLoader.exists(RUTAS[nombre]):
			_streams[nombre] = load(RUTAS[nombre])
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_musica = AudioStreamPlayer.new()
	_musica.volume_db = VOLUMEN_MUSICA_DB
	add_child(_musica)
	if ResourceLoader.exists(RUTA_MUSICA):
		var musica = load(RUTA_MUSICA)
		if musica is AudioStreamOggVorbis or musica is AudioStreamMP3:
			musica.loop = true
		_musica.stream = musica
	actualizar_musica()


## Prende o apaga la música según el ajuste de sonido.
## Como es un autoload, sigue sonando sin cortarse al cambiar de escena.
func actualizar_musica() -> void:
	if _musica == null or _musica.stream == null:
		return
	if Progreso.sonido_activo:
		if not _musica.playing:
			_musica.play()
	else:
		_musica.stop()


## Jingle de victoria: pausa la música de fondo mientras suena y la reanuda después
func jingle(nombre: String, volumen_db: float = -4.0) -> void:
	if not Progreso.sonido_activo or not _streams.has(nombre):
		return
	reproducir(nombre, volumen_db)
	if _musica == null:
		return
	# la musica de fondo se pausa mientras suena el jingle y sigue donde estaba al terminar
	_musica.stream_paused = true
	var duracion: float = _streams[nombre].get_length()
	var t := create_tween()
	t.tween_interval(duracion + 0.2)
	t.tween_callback(func() -> void: _musica.stream_paused = false)


func reproducir(nombre: String, volumen_db: float = 0.0, pitch: float = 1.0) -> void:
	if not Progreso.sonido_activo or not _streams.has(nombre):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[nombre]
			p.volume_db = volumen_db
			p.pitch_scale = pitch
			p.play()
			return
