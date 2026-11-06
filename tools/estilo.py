"""Estilo visual compartido (el del nivel 2-2): bordes de madera, fondo pasto fondo2,
paredes de rocas, follaje decorativo (sobre la pelota) y molinos junto al viento."""
import random, math
def num(v): return "%g" % v
def vec(x, y): return "Vector2(%s, %s)" % (num(x), num(y))

EXT_NUEVOS = {
 "12_madera2": ('Texture2D', 'res://assets/assets editados/madera.png'),
 "13_fondo":   ('Texture2D', 'res://assets/assets editados/pasto fondo2.jpg'),
 "14_rocas":   ('Texture2D', 'res://assets/free-rocks-and-stones-top-down-pixel-art/PNG/Rocks_source.png'),
 "15_flores":  ('Texture2D', 'res://assets/assets editados/flores.png'),
 "16_pasto":   ('Texture2D', 'res://assets/assets editados/pasto.png'),
 "17_molinos": ('Texture2D', 'res://assets/assets editados/molinos.png'),
 "18_follaje": ('Script', 'res://follaje.gd'),
}
def ext_nuevos(texto_actual=""):
    return "".join('[ext_resource type="%s" path="%s" id="%s"]\n' % (t, p, k) for k, (t, p) in EXT_NUEVOS.items() if 'id="%s"' % k not in texto_actual)

BORDES_SPRITES = """[node name="MaderaIzquierda" type="Sprite2D" parent="Bordes"]
texture_repeat = 2
position = Vector2(-693.5, 22.50009)
scale = Vector2(0.69105697, 3.0490081)
texture = ExtResource("12_madera2")
region_enabled = true
region_rect = Rect2(1384.4121, 510.00024, 123.95874, 857.1422)

[node name="MaderaArriba" type="Sprite2D" parent="Bordes"]
texture_repeat = 2
position = Vector2(21.869358, -1252.7618)
rotation = 1.5707964
scale = Vector2(0.5212839, 1.5867532)
texture = ExtResource("12_madera2")
region_enabled = true
region_rect = Rect2(1354.4724, 1406.2643, 150.11816, 872.9083)

[node name="MaderaAbajo" type="Sprite2D" parent="Bordes"]
texture_repeat = 2
position = Vector2(-11.1197815, 1232.2083)
rotation = 3.1431947
scale = Vector2(2.8157086, 0.6881768)
texture = ExtResource("12_madera2")
region_enabled = true
region_rect = Rect2(830.24084, 2092.1602, 463.43066, 114.950195)

[node name="MaderaDerecha" type="Sprite2D" parent="Bordes"]
texture_repeat = 2
position = Vector2(678, 2.9999695)
scale = Vector2(0.8095238, 3)
texture = ExtResource("12_madera2")
region_enabled = true
region_rect = Rect2(1374.0004, 496.45132, 126.50037, 856.6489)

"""
CAMPO = """[node name="Campo" type="Sprite2D" parent="."]
z_index = -10
texture_repeat = 2
position = Vector2(-1.0000296, 34.00004)
scale = Vector2(1.6300449, 1.2243903)
texture = ExtResource("13_fondo")
region_enabled = true
region_rect = Rect2(-5.813843, -0.80841064, 892.61707, 2050.1807)

"""

REGION_ROCA = (188.36362, 2.1811516, 83.636566, 61.091045)

def rocas_obstaculo(i, w, h, semilla, parent=None, off=(0.0, 0.0), esc=1.0):
    """Hilera de rocas (solo visual) sobre el rectangulo de colision del obstaculo."""
    rnd = random.Random("%s-%d" % (semilla, i))
    horizontal = w >= h
    largo, ancho = (w, h) if horizontal else (h, w)
    n = max(1, int(round(largo / 88.0)))
    if largo < 260 and ancho >= 120: n = 3
    out = ""
    for k in range(n):
        t = (k + 0.5) / n - 0.5
        a = t * (largo - 80) if n > 1 else 0.0
        b = rnd.uniform(-5, 5)
        if largo < 260 and ancho >= 120:  # bloque cuadrado: racimo de rocas
            a = rnd.uniform(-largo * 0.25, largo * 0.25); b = rnd.uniform(-ancho * 0.25, ancho * 0.25)
        px, py = (a, b) if horizontal else (b, a)
        px = px / esc + off[0]; py = py / esc + off[1]
        sc = rnd.uniform(1.5, 1.8) * (1.6 if (largo < 260 and ancho >= 120) else 1.0) / esc
        flip = "flip_h = true\n" if rnd.random() < 0.5 else ""
        out += ('[node name="Roca%d" type="Sprite2D" parent="%s"]\nposition = %s\nscale = Vector2(%s, %s)\n%s'
                'texture = ExtResource("14_rocas")\nregion_enabled = true\nregion_rect = Rect2(%g, %g, %g, %g)\n\n') % (
                k + 1, parent or ("Obstaculos/Obstaculo%d" % i), vec(round(px, 1), round(py, 1)), num(round(sc, 3)), num(round(sc, 3)), flip, *REGION_ROCA)
    return out


FLORES = [(891.7074, 688.2613, 315.8036, 262.42828), (63.495605, 1085.9099, 337.45166, 284.1698)]
PASTOS = [(413.3798, 611.954, 127.83591, 90.42059, 2.6136363, 3.3629034), (44.433807, 153.26627, 122.51749, 143.3115, 1.9543588, 2.3457887)]
CANDIDATOS = [(520, 1080), (-540, 1100), (520, -90), (-540, 300), (540, 640), (-545, -420), (545, -560), (-480, -1110), (560, -1050), (545, 200), (-545, 800), (-300, 1130), (300, -1130), (-545, -140)]

def decorado(spec):
    """Flores, pasto y molinos de decoracion, lejos de la pelota, el hoyo y los obstaculos."""
    rnd = random.Random(spec["raiz"] + "-deco")
    ocup = [tuple(spec["pelota"]), tuple(spec["hoyo"])] + [tuple(b[:2]) for b in spec.get("barro", [])]
    rects = [o[:4] for o in spec.get("obstaculos", [])] + [h[:4] for h in spec.get("hielo", [])]
    cands = CANDIDATOS[:]; rnd.shuffle(cands)
    elegidos = []
    for (x, y) in cands:
        if any(math.hypot(x - ox, y - oy) < 300 for ox, oy in ocup): continue
        if any(abs(x - r[0]) < r[2] / 2 + 170 and abs(y - r[1]) < r[3] / 2 + 150 for r in rects): continue
        if y < -820 and x < 160: continue   # debajo del HUD no
        elegidos.append((x, y))
        if len(elegidos) >= 6: break
    s = '[node name="Deco" type="Node2D" parent="."]\nz_index = 2\n\n'
    for n, (x, y) in enumerate(elegidos, 1):
        if rnd.random() < 0.55:
            r = FLORES[rnd.randrange(2)]
            s += '[node name="Flores%d" type="Sprite2D" parent="Deco"]\nposition = %s\nscript = ExtResource("18_follaje")\ntexture = ExtResource("15_flores")\nregion_enabled = true\nregion_rect = Rect2(%g, %g, %g, %g)\n\n' % (n, vec(x, y), *r)
        else:
            r = PASTOS[rnd.randrange(2)]
            s += '[node name="Pasto%d" type="Sprite2D" parent="Deco"]\nposition = %s\nscale = Vector2(%g, %g)\nscript = ExtResource("18_follaje")\ntexture = ExtResource("16_pasto")\nregion_enabled = true\nregion_rect = Rect2(%g, %g, %g, %g)\n\n' % (n, vec(x, y), r[4], r[5], *r[:4])
    s += '[node name="Molinos" type="Node2D" parent="."]\nz_index = -6\n\n'
    for n, v in enumerate(spec.get("viento", []), 1):   # molino junto a cada zona de viento
        if any(math.hypot(-560 - b[0], v[1] - b[1]) < 260 for b in spec.get("barro", [])): continue
        s += ('[node name="Molino%d" type="Sprite2D" parent="Molinos"]\nposition = %s\nscale = Vector2(0.168, 0.1795)\n'
              'texture = ExtResource("17_molinos")\nregion_enabled = true\nregion_rect = Rect2(48.768066, 1383.3386, 1409.1069, 1277.0032)\n\n') % (n, vec(-560, v[1]))
    return s


