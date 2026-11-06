"""Pasa un nivel hecho a mano (tablas de madera, Tiled/grass2d) al estilo del 2-2.
Uso: python3 estilizar.py nivel_1.tscn [...]   (edita en el lugar)"""
import re, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from estilo import *


def props(bloque):
    return dict(re.findall(r'^(\w+) = (.*)$', bloque, re.M))


def cabecera(bloque):
    m = re.match(r'\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]*)")?', bloque)
    return (m.group(1), m.group(2), m.group(3)) if m else (None, None, None)


def vec_de(txt, defecto=(0.0, 0.0)):
    m = re.match(r'Vector2\(([-\d.e]+), ([-\d.e]+)\)', txt or "")
    return (float(m.group(1)), float(m.group(2))) if m else defecto


def estilizar(ruta):
    texto = open(ruta).read()
    nombre = os.path.basename(ruta).replace(".tscn", "")
    bloques = re.split(r'(?m)^(?=\[)', texto)
    tam = {}
    for b in bloques:
        m = re.match(r'\[sub_resource type="RectangleShape2D" id="([^"]+)"\]', b)
        if m:
            tam[m.group(1)] = vec_de(props(b).get("size"))
    # --- contexto del nivel (para la decoracion) ---
    ids_madera = set(re.findall(r'path="res://assets/(?:bordeMadera\.jpg|Tiled\.png)" id="([^"]+)"', texto))
    ctx = {"raiz": nombre, "pelota": (0, 1000), "hoyo": (0, -1000), "barro": [], "obstaculos": [], "hielo": [], "viento": []}
    cuerpos = {}
    ids_barro = set(re.findall(r'id="([^"]+)"\] *\n?', "\n".join(re.findall(r'\[ext_resource[^\n]*barro\.tscn[^\n]*', texto)))) 
    for b in bloques:
        n, t, p = cabecera(b)
        if n is None: continue
        pr = props(b)
        if n == "Pelota": ctx["pelota"] = vec_de(pr.get("position"), (0, 1000))
        elif n == "Hoyo": ctx["hoyo"] = vec_de(pr.get("position"), (0, -1000))
        elif p and p.startswith("Obstaculos") and t == "StaticBody2D":
            cuerpos["Obstaculos/" + n] = (vec_de(pr.get("position")), float(pr.get("rotation", 0)), vec_de(pr.get("scale"), (1.0, 1.0))[0])
        elif "barro.tscn" in texto and re.search(r'instance=ExtResource\("(%s)"\)' % "|".join(ids_barro or ["__"]), b):
            ctx["barro"].append(list(vec_de(pr.get("position"))))
        elif "tamano" in pr and "instance=" in b:
            x, y = vec_de(pr.get("position")); w, h = vec_de(pr["tamano"])
            (ctx["viento"] if "viento" in n.lower() else ctx["hielo"]).append([x, y, w, h, 0, 0] if "viento" in n.lower() else [x, y, w, h])
    # obstaculos: forma de colision de cada StaticBody
    forma = {}
    for b in bloques:
        n, t, p = cabecera(b)
        if t == "CollisionShape2D" and p and p.startswith("Obstaculos/"):
            pr = props(b); m = re.search(r'SubResource\("([^"]+)"\)', pr.get("shape", ""))
            if m and m.group(1) in tam:
                forma[p] = (vec_de(pr.get("position")), tam[m.group(1)])
    for p, (off, (w, h)) in forma.items():
        pos, rot, esc = cuerpos.get(p, ((0, 0), 0, 1.0))
        ox, oy = off[0] * esc, off[1] * esc
        cx = pos[0] + ox * math.cos(rot) - oy * math.sin(rot)
        cy = pos[1] + ox * math.sin(rot) + oy * math.cos(rot)
        lado = max(w, h) * esc if (abs(rot) > 0.01 or esc != 1.0) else None
        ctx["obstaculos"].append([cx, cy, lado or w * esc, lado or h * esc])
    # --- reescritura ---
    salida = []; insertado_bordes = False; i_obs = 0
    ultimo_ext = max(i for i, b in enumerate(bloques) if b.startswith("[ext_resource"))
    for idx, b in enumerate(bloques):
        n, t, p = cabecera(b)
        if t == "Sprite2D" and p == "Bordes":
            if not insertado_bordes:
                salida.append(BORDES_SPRITES); insertado_bordes = True
            continue
        if b.startswith("[node") and n == "Campo" and p == ".":
            salida.append(CAMPO + decorado(ctx)); continue
        if t == "Sprite2D" and p and p.startswith("Obstaculos/") and re.search(r'ExtResource\("(%s)"\)' % "|".join(ids_madera or ["__"]), b) and ("region_rect" in b or "Tiled" in texto):
            off, (w, h) = forma.get(p, ((0.0, 0.0), (200.0, 60.0)))
            esc = cuerpos.get(p, ((0, 0), 0, 1.0))[2]
            i_obs += 1
            salida.append(rocas_obstaculo(i_obs, w * esc, h * esc, nombre, parent=p, off=off, esc=esc)); continue
        salida.append(b)
        if idx == ultimo_ext:
            salida.append(ext_nuevos(texto) )
    nuevo = "".join(salida)
    nuevo = re.sub(r'\n{3,}', '\n\n', nuevo)
    open(ruta, "w").write(nuevo)
    print("estilizado", nombre, "obstaculos:", len(ctx["obstaculos"]), "barro:", len(ctx["barro"]))


for r in sys.argv[1:]:
    estilizar(r)
