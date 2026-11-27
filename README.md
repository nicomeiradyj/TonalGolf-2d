# TonalGolf-2d
Repositorio para la entrega del boss final de IPV-2026s2

Juego de mini golf 2D hecho en Godot 4.7, pensado para celular (vertical, 720x1280) y también jugable en PC con la misma resolución.

## Cómo se juega
- Mantené apretado (mouse o dedo) y arrastrá hacia atrás, como una gomera. La flecha roja indica hacia dónde sale la pelota y su largo es la fuerza.
- Soltá para pegarle. Solo se puede tirar con la pelota quieta, o moviéndose **sobre hielo** o **dentro del viento**.
- Si la pelota entra muy rápido al hoyo, pasa de largo. Si pasa despacio rozando el borde, da la vueltita alrededor del hoyo y aparece "CASI!".
- **Barro:** la pelota se embarra (manchas) y se va limpiando con cada golpe. Parada dentro del barro, el tiro sale más flojo.
- **Potencia completa en cualquier lado:** el arrastre que da el 100 % se acorta solo si la pelota está cerca del borde de la pantalla y se arrastra hacia afuera: llevando el dedo/mouse hasta el borde siempre se llega a la fuerza máxima.
- **Tecla `R`** (PC): reinicia el nivel (en hardcore no). No hay ningún cartel en pantalla; solo figura en el botón de la pausa como `REINICIAR (R)`.
- **Progreso:** en el HUD hay 12 segmentos (verde = completado, dorado = el actual) y `QUEDAN N` niveles; la pantalla de victoria también lo muestra.
- **"Ya podés tirar":** cuando la pelota se frena después de un golpe de verdad (no un toquecito) aparece un destello suave, como el sol pegando en una pelota de golf: halo tenue y una chispa fina arriba a la izquierda, con un "ding" muy bajito. Sucede una sola vez por golpe.
- **Topo** (`topo.tscn`): en algunos niveles (3, 4, 2-2, 2-4 y 3-3) puede aparecer un topo con un círculo de tierra y puntos rojos. Si la pelota pasa por ese círculo, el topo se agacha, se abre un hueco, la pelota cae oscureciéndose bajo la tierra, y el topo sale tapando el hueco con un "¡ALTO!" (con un poco de tierra volando); después la pelota reaparece donde hiciste el último tiro (el golpe se cuenta igual). No aparece siempre: tiene `probabilidad` = 0.35 por partida, y cuando aparece un cartel explica qué hace. La zona es chica (`radio` = 140) y se ubicó donde no tapa los tiros de hoyo en uno (verificado con un solver por fuerza bruta con el topo presente).
- Pausa: botón `II` (o `Esc` en PC, o el botón "atrás" en Android).
- El primer nivel muestra un cartel rápido con el gesto de cómo se juega; desaparece solo al primer golpe.

## Secciones y niveles (12 en total)
| Sección | Niveles | Mecánica |
|---------|---------|----------|
| 1 | 1 a 4 | Cancha con obstáculos de madera |
| 2 | 2-1 a 2-4 | Barro (frena) y viento (empuja) |
| 3 | 3-1 a 3-4 | Parches chicos de hielo (resbala y permite tirar en movimiento). 3-2 suma barro, 3-3 suma viento y 3-4 combina los tres; el hoyo cambia de lugar en cada nivel |

Cada nivel se desbloquea al completar el anterior. El mejor puntaje de cada uno se guarda en el dispositivo. Todos los niveles tienen hoyo en uno posible.

## Pantalla final
Al completar el último nivel (3-4) el botón pasa a `VER RESULTADOS` y abre `pantalla_final.tscn`: golpes totales vs par,
hoyos en uno, niveles con par o mejor, récord hardcore y la grilla con el mejor resultado de cada nivel.
Los pares y nombres están en `progreso.gd` (`PARES`, `NOMBRES`); si agregás niveles, sumalos ahí.

## Árboles y modo pánico

**Árboles:** copas de árbol (`assets/arboles/arbol1-3.png`) dibujadas por encima de la pelota. Cuando la pelota entra en la copa pasa *por debajo*: la copa se sacude, la pelota se oscurece/atenúa y suena un crujido de hojas (`follaje.gd`).

**Modo hardcore – pánico:** cuando queda el 40 % del tiempo total (mínimo 8 s, máximo 15 s):
- la música de fondo se pausa y suena la música de tensión (`assets/desesperacion.wav`), que se acelera y sube de volumen a medida que baja el tiempo;
- sirena de alerta (`assets/alarma.wav`) y cartel "¡SE ACABA EL TIEMPO!";
- el reloj tiembla y parpadea en rojo, la cámara vibra y aparece una viñeta roja pulsante;
- en celulares vibra el dispositivo (`Input.vibrate_handheld`) cada segundo.

## Estilo visual (todos los niveles)
Todos los niveles usan el estilo del 2-2 (arte del compañero). Los de la sección 1 y el 2-1 se convirtieron con `tools/estilizar.py`; 2-4 y la sección 3 se generan con `gen_levels.py`:
bordes de madera ilustrada, fondo `pasto fondo2.jpg`, paredes hechas con hileras de rocas (solo visual: la colisión
sigue siendo un rectángulo), flores y pasto de decoración y molinos junto al viento. Se genera con `gen_levels.py`.

## Carteles de terreno
`cartel_zona.tscn` (propiedad `tipo`: `barro`, `viento`, `hielo` o `topo`) muestra qué hace el terreno la primera vez que aparece
(2-1 barro, 2-3 viento, 3-1 hielo) y desaparece al primer golpe. El nodo debe llamarse `Ayuda`.

## Sonidos
Al ganar un nivel suena un jingle corto (`victoria.wav`) y en la pantalla final uno más largo (`victoria_final.wav`); la música de fondo baja un poco mientras suenan.
El viento suena (suave, en loop con fundido) solo mientras la pelota está dentro de la zona; el hielo tiene un campanilla suave al entrar.

## Modo HARDCORE
Botón `HARDCORE` del menú: se juega la partida completa desde el nivel 1 y cada nivel tiene tiempo límite
(valor `tiempo_hardcore` de cada nivel: de 20 s en el nivel 1 a 72 s en el 3-4; por defecto `20 s + 10 s por golpe de par`). No se puede reiniciar un nivel
y si se acaba el tiempo **se pierde la partida completa** (pantalla GAME OVER). Se guarda el récord de niveles seguidos.

## Estructura
- `nivel_1.gd`: script compartido por todos los niveles (`numero_nivel`, `nombre_nivel`, `par`, `siguiente_nivel`, `tiempo_hardcore`).
- `progreso.gd` (autoload `Progreso`): mejores puntajes, desbloqueo, ajustes y récord hardcore.
- `sonidos.gd` (autoload `Sonidos`): música de fondo y efectos.
- `hud.tscn`: golpes, par, mejor puntaje, reloj hardcore y menú de pausa.
- `hielo.tscn`, `barro.tscn`, `viento.tscn`: zonas con efecto. Se dimensionan con `tamano`.
- `topo.tscn` / `topo.gd`: topo que chupa la pelota (`radio`, `probabilidad`, `forzar_aparicion`). Para ponerlo en un nivel: instanciar `topo.tscn` y moverlo lejos del camino directo al hoyo (`tools/poner_topo.py nivel.tscn X Y` lo hace por script; `tools/elegir_topo.py` propone posiciones).
- `ayuda.tscn`, `pantalla_game_over.tscn`, `pantalla_victoria.tscn`.

## Crear un nivel nuevo
1. Duplicar un nivel existente (ej: `sec3_nivel4.tscn`).
2. En el nodo raíz: cambiar `Numero Nivel`, `Nombre Nivel`, `Par`, `Siguiente Nivel` (vacío si es el último) y opcionalmente `Tiempo Hardcore`.
3. Mover `Pelota` y `Hoyo` y agregar obstáculos o zonas (`Hielo`, `Barro`, `Viento`).
4. Sumar un botón en `menu.tscn` con su `Numero Nivel`.
