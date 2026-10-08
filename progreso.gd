extends Node
## Autoload "Progreso": guarda el mejor puntaje de cada nivel y los ajustes.
## Se guarda en user://progreso.cfg (funciona igual en PC y en celular).

const RUTA := "user://progreso.cfg"

## Ponelo en true para probar todos los niveles sin tener que ganarlos
const DESBLOQUEAR_TODO := false

var mejores: Dictionary = {}   # numero de nivel -> menor cantidad de golpes
var sonido_activo: bool = true


func _ready() -> void:
	cargar()


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	sonido_activo = cfg.get_value("ajustes", "sonido", true)
	if cfg.has_section("mejores"):
		for clave in cfg.get_section_keys("mejores"):
			mejores[int(clave)] = int(cfg.get_value("mejores", clave))


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ajustes", "sonido", sonido_activo)
	for nivel in mejores:
		cfg.set_value("mejores", str(nivel), mejores[nivel])
	cfg.save(RUTA)


## 0 significa que todavía no se completó
func mejor(nivel: int) -> int:
	return int(mejores.get(nivel, 0))


## Guarda el resultado. Devuelve true solo si SUPERÓ un récord anterior.
func registrar(nivel: int, golpes: int) -> bool:
	var actual := mejor(nivel)
	if actual == 0:
		mejores[nivel] = golpes
		guardar()
		return false
	if golpes < actual:
		mejores[nivel] = golpes
		guardar()
		return true
	return false


## El nivel 1 siempre está abierto; los demás se abren al completar el anterior
func esta_desbloqueado(nivel: int) -> bool:
	return DESBLOQUEAR_TODO or nivel <= 1 or mejor(nivel - 1) > 0


func set_sonido(activo: bool) -> void:
	sonido_activo = activo
	guardar()
