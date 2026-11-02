"""Gera scenes/mapas/esgoto.tscn (mapa da demo) a partir do desenho abaixo.
Depois de gerado, o mapa pode ser repintado no editor do Godot normalmente;
rode de novo só se quiser recomeçar do desenho.

Legenda do desenho: as letras de mapa_cena.gd, mais
  c  parede com cano      w  água do esgoto (bloqueia)    =  ponte
  ,  chão com musgo       r  rato   b  barata   o  Fiel Oco   a  Fiel Oca
  H  o encapuzado (entra na party antes do chefe)          B  o chefe
  G  Pedra Solar          1..9  itens no chão (ITENS abaixo)   P  início
"""
import base64
import json
import struct
from collections import deque
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

DESENHO = [
    "########################################",
    "#P..#....c.......T.......c....#..R.Q...#",
    "#...W..r.......,......b.......W....1...#",
    "#...#wwwwwwwwwwwwwww=wwwwwwwww#wwww=www#",
    "#.2.#wwwwwwwwwwwwwww=wwwwwwwww#wwww=www#",
    "#...#....,...*......,......r.K#..b.,...#",
    "##W###########.###########S####.########",
    "#......#.....,.....#.......c...........#",
    "#..A...W.....*..o..W...R.Q.......r.....#",
    "#......#...........#..wwww.............#",
    "#,...3.#..Q..G.....#..wwww......a..4...#",
    "#################################W######",
    "#......##...c.........T................#",
    "#..B...WH.......,.......b.*............#",
    "#......##..K.......R..........Q.....5..#",
    "########################################",
]

TILE = {
    "#": "esgoto_parede", "c": "esgoto_cano", ".": "esgoto_chao", ",": "esgoto_chao2",
    "w": "esgoto_agua", "=": "esgoto_ponte", "*": "esgoto_sol", "T": "parede_tocha",
    "A": "altar", "K": "esqueleto", "S": "placa", "R": "barril", "Q": "caixa", "W": "porta",
}
PISO = "esgoto_chao"
INIMIGOS = {"r": "rato", "b": "barata", "o": "oco", "a": "oca", "B": "chefe"}
ITENS = {
    "1": ("erva_amarga", 2), "2": ("bandagem", 1), "3": ("agua_benta", 1),
    "4": ("adaga_osso", 1), "5": ("escudo_ferro", 1),
}
TEXTOS = [
    "Restos de um guarda da prisão. Ainda segura uma tocha apagada.",
    "Rabiscado na pedra: \\\"Os ratos ficaram grandes depois que jogaram os corpos do Ritual aqui.\\\"",
    "Um cadáver roído até o osso. Seja o que for que fez isso, ainda está por perto.",
]


def tiles_do_atlas():
    dados = json.loads((RAIZ / "tools" / "atlas.json").read_text())
    return {t["nome"]: (t["x"], t["y"]) for t in dados["terreno"]}


def checar():
    larg = len(DESENHO[0])
    for i, linha in enumerate(DESENHO):
        assert len(linha) == larg, f"linha {i} com {len(linha)}"
    passa = set(".,*=WrboaHGP12345BA")
    inicio = next((x, y) for y, l in enumerate(DESENHO) for x, c in enumerate(l) if c == "P")
    vistos = {inicio}
    fila = deque([inicio])
    while fila:
        x, y = fila.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in vistos and DESENHO[n[1]][n[0]] in passa and DESENHO[n[1]][n[0]] != "A":
                vistos.add(n)
                fila.append(n)
    for y, l in enumerate(DESENHO):
        for x, c in enumerate(l):
            if c in passa and c != "A" and (x, y) not in vistos:
                raise SystemExit(f"célula {c} em {(x, y)} inalcançável")
    print("mapa conectado:", len(vistos), "células")


def gerar():
    atlas = tiles_do_atlas()
    terreno = bytearray(struct.pack("<H", 0))
    ent = bytearray(struct.pack("<H", 0))
    nos = []
    contagem = {}
    for y, linha in enumerate(DESENHO):
        for x, c in enumerate(linha):
            nome = TILE.get(c, PISO)
            ax, ay = atlas[nome]
            terreno += struct.pack("<hhHHHH", x, y, 0, ax, ay, 0)
            pos = f"Vector2({x * 64}, {y * 64})"
            if c == "P":
                ent += struct.pack("<hhHHHH", x, y, 1, 0, 0, 0)
            elif c in INIMIGOS:
                tipo = INIMIGOS[c]
                contagem[tipo] = contagem.get(tipo, 0) + 1
                nome_no = {"rato": "Rato", "barata": "Barata", "oco": "FielOco", "oca": "FielOca",
                           "chefe": "Chefe"}[tipo] + str(contagem[tipo])
                jeito = "parado" if tipo == "chefe" else ("vagar" if tipo == "barata" else "perseguir")
                nos.append(f'[node name="{nome_no}" type="Node2D" parent="."]\nposition = {pos}\n'
                           f'script = ExtResource("3_ent")\ninimigo = "{tipo}"\ncomportamento = "{jeito}"\n')
            elif c == "H":
                nos.append(f'[node name="Encapuzado" type="Node2D" parent="."]\nposition = {pos}\n'
                           f'script = ExtResource("3_ent")\ntipo = 1\nid_npc = "encapuzado_esgoto"\n'
                           f'dialogo = ExtResource("4_dlg")\ncue = "esgoto"\nsome_com_evento = "encapuzado_na_party"\n')
            elif c == "G":
                nos.append(f'[node name="PedraSolar1" type="Node2D" parent="."]\nposition = {pos}\n'
                           f'script = ExtResource("3_ent")\ntipo = 2\n')
            elif c in ITENS:
                item, qtd = ITENS[c]
                nos.append(f'[node name="Item{c}" type="Node2D" parent="."]\nposition = {pos}\n'
                           f'script = ExtResource("3_ent")\ntipo = 3\nitem = "{item}"\nquantidade = {qtd}\n')
    textos = ", ".join(f'"{t}"' for t in TEXTOS)
    cena = f'''[gd_scene format=4]

[ext_resource type="Script" path="res://scripts/mundo/mapa_cena.gd" id="1_mapa"]
[ext_resource type="TileSet" path="res://assets/tiles/tileset.tres" id="2_ts"]
[ext_resource type="Script" path="res://scripts/mundo/entidade.gd" id="3_ent"]
[ext_resource type="Resource" path="res://dialogos/encapuzado.dialogue" id="4_dlg"]

[node name="Esgoto" type="Node2D"]
script = ExtResource("1_mapa")
nome = "Esgotos sob a Catedral"
fundo_batalha = "res://assets/batalha/fundo_esgoto.png"
textos = Array[String]([{textos}])

[node name="Terreno" type="TileMapLayer" parent="."]
tile_map_data = PackedByteArray("{base64.b64encode(bytes(terreno)).decode()}")
tile_set = ExtResource("2_ts")

[node name="Entidades" type="TileMapLayer" parent="."]
tile_map_data = PackedByteArray("{base64.b64encode(bytes(ent)).decode()}")
tile_set = ExtResource("2_ts")

''' + "\n".join(nos)
    (RAIZ / "scenes" / "mapas" / "esgoto.tscn").write_text(cena)
    print("esgoto.tscn ok")


if __name__ == "__main__":
    checar()
    gerar()
