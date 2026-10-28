extends VBoxContainer

var titulos: Array[Button] = []
var listas: Array[Control] = []


func _ready() -> void:
	var hijos := get_children()
	for i in range(0, hijos.size() - 1, 2):
		var titulo := hijos[i] as Button
		var lista := hijos[i + 1] as Control
		titulo.set_meta("nombre", titulo.text)
		titulo.pressed.connect(_on_titulo_pressed.bind(listas.size()))
		titulos.append(titulo)
		listas.append(lista)
	_abrir(_seccion_actual())


func _on_titulo_pressed(indice: int) -> void:
	Sonidos.reproducir("click")
	# la sección que ya esta abierta la cierra
	if listas[indice].visible:
		_abrir(-1)
	else:
		_abrir(indice)


func _abrir(indice: int) -> void:
	for i in listas.size():
		var abierta := i == indice
		listas[i].visible = abierta
		var signo := "-" if abierta else "+"
		titulos[i].text = "%s  %s" % [titulos[i].get_meta("nombre"), signo]


func _seccion_actual() -> int:
	var actual := 0
	for i in listas.size():
		for boton in listas[i].get_children():
			if boton is Button and not boton.disabled:
				actual = i
	return actual
