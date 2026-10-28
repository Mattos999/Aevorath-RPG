"""Junta os tiles de 64x64 em atlas para o TileSet do Godot.

Uso: python3 tools/montar_atlas.py   (depois: tools/gerar_tileset.gd)
Gera assets/tiles/atlas_terreno.png, assets/tiles/atlas_entidades.png e
tools/atlas.json com a letra de cada tile (a mesma legenda de mapa_cena.gd).

A ordem das listas define a posição de cada tile no atlas. Só acrescente
tiles no fim, senão os mapas já pintados trocam de tile.
"""
import json
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
TILES = RAIZ / "assets" / "tiles"
COLUNAS = 8
T = 64

# (arquivo em assets/tiles, letra)
TERRENO = [
    ("chao", "."), ("chao2", "."), ("chao_rachado", "~"), ("chao_rachado2", "~"),
    ("chao_rachado3", "~"), ("sangue", ","), ("chao_sol", "*"), ("chao_buraco", "o"),
    ("parede", "#"), ("parede2", "#"), ("parede_topo", "#"), ("parede_tocha", "T"),
    ("correntes", "#"), ("grade", "|"), ("cela_fechada", "D"), ("cela_aberta", "d"),
    ("porta", "W"), ("escada", "X"), ("cama", "B"), ("balde", "U"),
    ("barril", "R"), ("caixa", "Q"), ("altar", "A"), ("placa", "S"),
    ("esqueleto", "K"), ("piso_madeira", "."),
    ("chao_musgo", "."), ("chao_poca", "."), ("chao_correntes", "."), ("parede_musgo", "#"),
    ("parede_musgo2", "#"), ("parede_janela", "#"), ("parede_sol", "#"),
]

# (imagem, letra). Folhas 3x4 usam o primeiro quadro (de frente).
ENTIDADES = [
    ("sprites/protagonista.png", "P"), ("sprites/encapuzado.png", "H"),
    ("sprites/protagonista2.png", "I"), ("sprites/cruzado.png", "C"),
    ("sprites/oco.png", "O"), ("sprites/sarnheim.png", "N"),
    ("sprites/paladino.png", "V"), ("itens/pedra_solar_48.png", "G"),
    ("sprites/oca.png", "F"),
]


def montar(itens, abrir, destino):
    linhas = (len(itens) + COLUNAS - 1) // COLUNAS
    atlas = Image.new("RGBA", (COLUNAS * T, linhas * T), (0, 0, 0, 0))
    mapa = []
    for i, (nome, letra) in enumerate(itens):
        x, y = i % COLUNAS, i // COLUNAS
        atlas.paste(abrir(nome), (x * T, y * T))
        mapa.append({"nome": Path(nome).stem, "letra": letra, "x": x, "y": y})
    atlas.save(destino)
    return mapa


def abrir_tile(nome):
    return Image.open(TILES / f"{nome}.png").convert("RGBA")


def abrir_entidade(caminho):
    img = Image.open(RAIZ / "assets" / caminho).convert("RGBA")
    if img.size == (3 * T, 4 * T):
        return img.crop((0, 0, T, T))
    quadro = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    quadro.paste(img, ((T - img.width) // 2, (T - img.height) // 2))
    return quadro


if __name__ == "__main__":
    dados = {
        "terreno": montar(TERRENO, abrir_tile, TILES / "atlas_terreno.png"),
        "entidades": montar(ENTIDADES, abrir_entidade, TILES / "atlas_entidades.png"),
    }
    (RAIZ / "tools" / "atlas.json").write_text(json.dumps(dados, indent=1, ensure_ascii=False))
    print("atlas ok")
