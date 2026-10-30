extends Node
## Autoload "Progreso": guarda el mejor puntaje de cada nivel y los ajustes.
## Se guarda en user://progreso.cfg (funciona igual en PC y en celular).

const RUTA := "user://progreso.cfg"

## Ponelo en true para probar todos los niveles sin tener que ganarlos
const DESBLOQUEAR_TODO := false

## Cantidad total de niveles del juego (secciones 1, 2 y 3)
const TOTAL_NIVELES := 12

## Par y nombre de cada nivel (en orden). Se usan en la pantalla final de estadísticas.
## Si agregás niveles, sumalos acá y subí TOTAL_NIVELES.
const PARES: Array[int] = [2, 3, 4, 4, 3, 3, 3, 4, 2, 3, 4, 4]
const NOMBRES: Array[String] = ["1", "2", "3", "4", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4"]

var mejores: Dictionary = {}   # numero de nivel -> menor cantidad de golpes
var sonido_activo: bool = true

## MODO HARDCORE (solo en memoria): cada nivel tiene tiempo limite; si se acaba se pierde la partida.
var modo_hardcore: bool = false

## Mayor cantidad de niveles completados seguidos en una partida hardcore
var hardcore_record: int = 0


func _ready() -> void:
	cargar()


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	sonido_activo = cfg.get_value("ajustes", "sonido", true)
	hardcore_record = int(cfg.get_value("hardcore", "record", 0))
	if cfg.has_section("mejores"):
		for clave in cfg.get_section_keys("mejores"):
			mejores[int(clave)] = int(cfg.get_value("mejores", clave))


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ajustes", "sonido", sonido_activo)
	cfg.set_value("hardcore", "record", hardcore_record)
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


## Guarda cuantos niveles se completaron en la partida hardcore. true si es record.
func registrar_hardcore(niveles_completados: int) -> bool:
	if niveles_completados > hardcore_record:
		hardcore_record = niveles_completados
		guardar()
		return true
	return false


## Resumen de los mejores resultados para la pantalla final
func estadisticas() -> Dictionary:
	var jugados := 0
	var golpes := 0
	var par_jugado := 0
	var hoyos_en_uno := 0
	var par_o_mejor := 0
	for i in TOTAL_NIVELES:
		var mejor_nivel := mejor(i + 1)
		if mejor_nivel <= 0:
			continue
		jugados += 1
		golpes += mejor_nivel
		par_jugado += PARES[i]
		if mejor_nivel == 1:
			hoyos_en_uno += 1
		if mejor_nivel <= PARES[i]:
			par_o_mejor += 1
	return {
		"jugados": jugados,
		"completo": jugados == TOTAL_NIVELES,
		"golpes": golpes,
		"par": par_jugado,
		"hoyos_en_uno": hoyos_en_uno,
		"par_o_mejor": par_o_mejor,
		"record_hardcore": hardcore_record,
	}


func set_sonido(activo: bool) -> void:
	sonido_activo = activo
	guardar()
