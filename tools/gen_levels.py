import sys, json
HEADER_EXT = '''[gd_scene format=3]

[ext_resource type="Script" uid="uid://dmkkgknnt4pfu" path="res://nivel_1.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://5lhwwyyqub60" path="res://pelota.tscn" id="2_pelota"]
[ext_resource type="Texture2D" uid="uid://c78v8xalp14ll" path="res://assets/bordeMadera.jpg" id="3_madera"]
[ext_resource type="PackedScene" uid="uid://deidyefrvlptn" path="res://hoyo.tscn" id="4_hoyo"]
[ext_resource type="Texture2D" uid="uid://b5fkvwquaoxos" path="res://assets/grass2d.png" id="5_pasto"]
[ext_resource type="PackedScene" uid="uid://cmp1lowbjy75e" path="res://pantalla_victoria.tscn" id="6_victoria"]
[ext_resource type="PackedScene" path="res://hud.tscn" id="7_hud"]
[ext_resource type="PackedScene" uid="uid://r5miulvtlvjq" path="res://barro.tscn" id="8_barro"]
[ext_resource type="PackedScene" uid="uid://c1i2inicotfvi" path="res://viento.tscn" id="9_viento"]
[ext_resource type="PackedScene" path="res://hielo.tscn" id="10_hielo"]
[ext_resource type="PackedScene" path="res://cartel_zona.tscn" id="11_cartel"]
[ext_resource type="Texture2D" path="res://assets/assets editados/madera.png" id="12_madera2"]
[ext_resource type="Texture2D" path="res://assets/assets editados/pasto fondo2.jpg" id="13_fondo"]
[ext_resource type="Texture2D" path="res://assets/free-rocks-and-stones-top-down-pixel-art/PNG/Rocks_source.png" id="14_rocas"]
[ext_resource type="Texture2D" path="res://assets/assets editados/flores.png" id="15_flores"]
[ext_resource type="Texture2D" path="res://assets/assets editados/pasto.png" id="16_pasto"]
[ext_resource type="Texture2D" path="res://assets/assets editados/molinos.png" id="17_molinos"]
[ext_resource type="Script" path="res://follaje.gd" id="18_follaje"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_arriba"]
size = Vector2(1440, 60)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_abajo"]
size = Vector2(1440, 60)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_izq"]
size = Vector2(60, 2560)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_der"]
size = Vector2(60, 2560)

'''
BORDES = '''[node name="Bordes" type="StaticBody2D" parent="."]

[node name="ParedArriba" type="CollisionShape2D" parent="Bordes"]
position = Vector2(0, -1250)
shape = SubResource("RectangleShape2D_arriba")

[node name="ParedAbajo" type="CollisionShape2D" parent="Bordes"]
position = Vector2(0, 1245)
shape = SubResource("RectangleShape2D_abajo")

[node name="ParedIzquierda" type="CollisionShape2D" parent="Bordes"]
position = Vector2(-690, 0)
shape = SubResource("RectangleShape2D_izq")

[node name="ParedDerecha" type="CollisionShape2D" parent="Bordes"]
position = Vector2(690, 0)
shape = SubResource("RectangleShape2D_der")

[node name="MaderaIzquierda" type="Sprite2D" parent="Bordes"]
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

'''
def num(v): return "%g" % v
def vec(x, y): return "Vector2(%s, %s)" % (num(x), num(y))
from estilo import *


def generar(spec):
    s = HEADER_EXT
    obs = spec.get("obstaculos", [])
    for i, o in enumerate(obs, 1):
        s += '[sub_resource type="RectangleShape2D" id="RectangleShape2D_obs%d"]\nsize = %s\n\n' % (i, vec(o[2], o[3]))
    s += '[node name="%s" type="Node2D"]\nscript = ExtResource("1_script")\nnumero_nivel = %d\nnombre_nivel = "%s"\npar = %d\nsiguiente_nivel = "%s"\n' % (
        spec["raiz"], spec["numero"], spec["nombre"], spec["par"], spec["siguiente"])
    if spec.get("tiempo"): s += 'tiempo_hardcore = %s\n' % num(spec["tiempo"])
    s += '\n[node name="Camera2D" type="Camera2D" parent="."]\nzoom = Vector2(0.5, 0.5)\n\n'
    s += '[node name="Pelota" parent="." instance=ExtResource("2_pelota")]\nposition = %s\n\n' % vec(*spec["pelota"])
    s += BORDES
    s += '[node name="Obstaculos" type="Node2D" parent="."]\n\n'
    for i, o in enumerate(obs, 1):
        x, y, w, h = o[:4]
        rot = o[4] if len(o) > 4 else 0.0
        rl = "rotation = %s\n" % num(rot) if rot else ""
        s += '[node name="Obstaculo%d" type="StaticBody2D" parent="Obstaculos"]\nposition = %s\n%s\n' % (i, vec(x, y), rl)
        s += '[node name="CollisionShape2D" type="CollisionShape2D" parent="Obstaculos/Obstaculo%d"]\nshape = SubResource("RectangleShape2D_obs%d")\n\n' % (i, i)
        s += rocas_obstaculo(i, w, h, spec["raiz"])
    if spec.get("hielo"):
        s += '[node name="ZonasHielo" type="Node2D" parent="."]\n\n'
        for i, h in enumerate(spec["hielo"], 1):
            s += '[node name="Hielo%d" parent="ZonasHielo" instance=ExtResource("10_hielo")]\nposition = %s\ntamano = %s\n\n' % (i, vec(h[0], h[1]), vec(h[2], h[3]))
    if spec.get("barro"):
        s += '[node name="Barro" type="Node" parent="."]\n\n'
        for i, b in enumerate(spec["barro"], 1):
            s += '[node name="Charco%d" parent="Barro" instance=ExtResource("8_barro")]\nposition = %s\n\n' % (i, vec(b[0], b[1]))
    for i, v in enumerate(spec.get("viento", []), 1):
        s += '[node name="Viento%d" parent="." instance=ExtResource("9_viento")]\nposition = %s\n' % (i, vec(v[0], v[1]))
        if len(v) > 5 and v[5]: s += 'rotation_degrees = %s\n' % num(v[5])
        s += 'tamano = %s\nfuerza = %s\n\n' % (vec(v[2], v[3]), num(v[4]))
    s += '[node name="Hoyo" parent="." instance=ExtResource("4_hoyo")]\nposition = %s\n' % vec(*spec["hoyo"])
    s += '\n[node name="Campo" type="Sprite2D" parent="."]\nz_index = -10\ntexture_repeat = 2\nposition = Vector2(-1.0000296, 34.00004)\nscale = Vector2(1.6300449, 1.2243903)\ntexture = ExtResource("13_fondo")\nregion_enabled = true\nregion_rect = Rect2(-5.813843, -0.80841064, 892.61707, 2050.1807)\n\n'
    s += decorado(spec)
    if spec.get("nieve"):
        s += '[node name="Escarcha" type="ColorRect" parent="."]\nz_index = -9\noffset_left = -690.0\noffset_top = -1250.0\noffset_right = 690.0\noffset_bottom = 1250.0\nmouse_filter = 2\ncolor = Color(0.9, 0.96, 1, 0.74)\n\n'
    s += '[node name="PantallaVictoria" parent="." instance=ExtResource("6_victoria")]\nvisible = false\n\n'
    s += '[node name="HUD" parent="." instance=ExtResource("7_hud")]\n'
    if spec.get("cartel"):
        s += '\n[node name="Ayuda" parent="." instance=ExtResource("11_cartel")]\ntipo = "%s"\n' % spec["cartel"]
    return s
if __name__ == "__main__":
    for archivo, spec in json.load(open(sys.argv[1])).items():
        open(archivo, "w").write(generar(spec)); print("generado", archivo)
