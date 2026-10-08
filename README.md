# TonalGolf-2d
Repositorio para la entrega del boss final de IPV-2026s2

Juego de mini golf 2D hecho en Godot 4.7, pensado para celular (vertical, 720x1280) y también jugable en PC con la misma resolución.

## Cómo se juega
- Mantené apretado (mouse o dedo) y arrastrá hacia atrás, como una gomera. La flecha roja indica hacia dónde va a salir la pelota y su largo es la fuerza.
- Soltá para pegarle. Solo se puede pegar cuando la pelota está quieta.
- Si la pelota entra muy rápido, pasa de largo por el hoyo.
- Al embocar la pelota cae al hoyo con animación, anillo y confetti.
- Música de fondo y efectos: se pueden apagar desde el menú principal o desde la pausa.
- Pausa: botón `II` (o `Esc` en PC, o el botón "atrás" en Android).

## Niveles
| Nivel | Par | Descripción |
|-------|-----|-------------|
| 1 | 2 | Cancha libre, para aprender |
| 2 | 3 | Zigzag de dos paredes |
| 3 | 4 | Tres paredes y un pilar rotado delante del hoyo |

Cada nivel se desbloquea al completar el anterior. El mejor puntaje de cada nivel se guarda en el dispositivo.

## Estructura
- `nivel_1.gd`: script compartido por todos los niveles (`numero_nivel`, `par`, `siguiente_nivel` se editan en el Inspector).
- `progreso.gd` (autoload `Progreso`): mejores puntajes, desbloqueo y ajustes.
- `sonidos.gd` (autoload `Sonidos`): música de fondo (`assets/musica_chill.ogg`, en loop) y efectos de sonido.
- `hud.tscn`: contador de golpes, par, mejor puntaje y menú de pausa.

## Crear un nivel nuevo
1. Duplicar `nivel_3.tscn` y ponerle el nombre nuevo (ej: `nivel_4.tscn`).
2. En el nodo raíz: cambiar `Numero Nivel`, `Par` y `Siguiente Nivel` (vacío si es el último).
3. Mover `Pelota` y `Hoyo`, y agregar obstáculos (`StaticBody2D` + `CollisionShape2D` + `Sprite2D` con la textura de madera repetida).
4. Sumar un botón en `menu.tscn` con su `Numero Nivel`.
