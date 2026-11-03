"""Gera a arte placeholder do jogo (PNG) em assets/.

Uso: python3 tools/gerar_placeholders.py
Requer Pillow. Substitua os PNGs por arte final mantendo nomes e tamanhos.

Atenção: este script sobrescreve PNGs que hoje vêm da arte do Carlos. Depois
de rodá-lo, rode também tools/processar_artes.py.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent / "assets"
random.seed(9)


def salvar(img, caminho):
    destino = RAIZ / caminho
    destino.parent.mkdir(parents=True, exist_ok=True)
    img.save(destino)
    print("gerado", destino.relative_to(RAIZ.parent))


def ruido(d, w, h, cores, n):
    for _ in range(n):
        x, y = random.randrange(w), random.randrange(h)
        d.point((x, y), fill=random.choice(cores))


# ---------- Tiles 32x32 ----------
def tile_chao():
    img = Image.new("RGBA", (32, 32), (46, 40, 38, 255))
    d = ImageDraw.Draw(img)
    ruido(d, 32, 32, [(38, 33, 31), (55, 48, 45), (60, 52, 48)], 120)
    d.line([(0, 15), (31, 15)], fill=(30, 26, 25))
    d.line([(15, 0), (15, 15)], fill=(30, 26, 25))
    d.line([(7, 16), (7, 31)], fill=(30, 26, 25))
    d.line([(23, 16), (23, 31)], fill=(30, 26, 25))
    return img


def tile_parede():
    img = Image.new("RGBA", (32, 32), (24, 20, 22, 255))
    d = ImageDraw.Draw(img)
    for linha in range(4):
        y = linha * 8
        desloc = 0 if linha % 2 == 0 else 8
        for x in range(-16 + desloc, 32, 16):
            cor = random.choice([(70, 62, 64), (62, 55, 58), (78, 70, 70)])
            d.rectangle([x + 1, y + 1, x + 14, y + 6], fill=cor)
    ruido(d, 32, 32, [(40, 34, 36), (90, 80, 80)], 40)
    return img


def tile_altar():
    img = tile_chao()
    d = ImageDraw.Draw(img)
    d.rectangle([4, 12, 27, 28], fill=(90, 84, 92), outline=(30, 26, 30))
    d.rectangle([6, 8, 25, 12], fill=(110, 104, 112), outline=(30, 26, 30))
    # Nove sóis: pontos dourados, o nono apagado
    for i in range(9):
        cor = (40, 40, 40) if i == 8 else (230, 190, 70)
        d.point((7 + i * 2, 18), fill=cor)
    d.ellipse([12, 1, 19, 8], fill=(200, 150, 60))
    return img


def tile_sangue():
    img = tile_chao()
    d = ImageDraw.Draw(img)
    d.ellipse([8, 10, 22, 20], fill=(90, 12, 14))
    d.ellipse([18, 18, 25, 24], fill=(75, 10, 12))
    return img


def tile_placa():
    img = tile_chao()
    d = ImageDraw.Draw(img)
    d.rectangle([14, 14, 17, 30], fill=(70, 48, 30))
    d.rectangle([6, 5, 25, 15], fill=(110, 80, 50), outline=(50, 34, 20))
    for y in (8, 11):
        d.line([(9, y), (22, y)], fill=(50, 34, 20))
    return img


def tile_saida():
    img = tile_chao()
    d = ImageDraw.Draw(img)
    d.rectangle([4, 2, 27, 31], fill=(10, 8, 10), outline=(70, 62, 64))
    d.rectangle([8, 6, 23, 31], fill=(20, 16, 24))
    return img


# ---------- Sprites de mapa 32x32 ----------
def boneco(corpo, cabeca, detalhe=None, capuz=False):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([9, 27, 23, 31], fill=(0, 0, 0, 90))
    d.rectangle([11, 12, 20, 24], fill=corpo, outline=(15, 12, 12))
    d.rectangle([12, 24, 14, 29], fill=(30, 26, 26))
    d.rectangle([17, 24, 19, 29], fill=(30, 26, 26))
    d.rectangle([8, 13, 10, 22], fill=corpo, outline=(15, 12, 12))
    d.rectangle([21, 13, 23, 22], fill=corpo, outline=(15, 12, 12))
    d.ellipse([11, 3, 20, 12], fill=cabeca, outline=(15, 12, 12))
    if capuz:
        d.pieslice([10, 2, 21, 14], 180, 360, fill=corpo, outline=(15, 12, 12))
    if detalhe:
        detalhe(d)
    return img


def heroi():
    def marca(d):
        # A Marca dos Mydrani: brilho no peito
        d.point((15, 16), fill=(120, 220, 255))
        d.point((16, 16), fill=(120, 220, 255))
        d.point((15, 17), fill=(60, 140, 200))
    return boneco((70, 60, 90), (200, 170, 150), marca, capuz=True)


def cruzado_mapa():
    def cruz(d):
        d.line([(15, 14), (15, 21)], fill=(200, 30, 30))
        d.line([(13, 16), (18, 16)], fill=(200, 30, 30))
        d.rectangle([11, 3, 20, 8], fill=(150, 150, 160))
    return boneco((160, 160, 170), (180, 150, 130), cruz)


def oco_mapa():
    def olhos(d):
        d.point((13, 7), fill=(0, 0, 0))
        d.point((18, 7), fill=(0, 0, 0))
        d.line([(14, 10), (17, 10)], fill=(60, 0, 0))
    return boneco((90, 80, 70), (170, 160, 140), olhos)


# ---------- Batalha: inimigos 192x256 ----------
# As regiões dos membros usadas pelo jogo estão em scripts/data/inimigos.gd.
# Se mudar o desenho, ajuste as regiões lá.
def inimigo_grande(cor_armadura, cor_pele, cruz=True, oco=False):
    img = Image.new("RGBA", (192, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    contorno = (12, 10, 10)
    d.ellipse([40, 236, 152, 254], fill=(0, 0, 0, 110))
    # pernas (64..128 x, 160..240 y)
    d.rectangle([66, 160, 92, 240], fill=cor_armadura, outline=contorno, width=2)
    d.rectangle([100, 160, 126, 240], fill=cor_armadura, outline=contorno, width=2)
    # torso (56..136, 64..164)
    d.rectangle([56, 64, 136, 164], fill=cor_armadura, outline=contorno, width=3)
    # braços
    d.rectangle([26, 68, 54, 150], fill=cor_armadura, outline=contorno, width=2)
    d.rectangle([138, 68, 166, 150], fill=cor_armadura, outline=contorno, width=2)
    d.ellipse([24, 146, 56, 170], fill=cor_pele, outline=contorno, width=2)
    d.ellipse([136, 146, 168, 170], fill=cor_pele, outline=contorno, width=2)
    # cabeça (72..120, 8..62)
    d.ellipse([70, 8, 122, 64], fill=cor_pele, outline=contorno, width=3)
    if oco:
        d.ellipse([82, 26, 94, 40], fill=(0, 0, 0))
        d.ellipse([98, 26, 110, 40], fill=(0, 0, 0))
        d.line([(84, 50), (108, 50)], fill=(80, 0, 0), width=3)
        for _ in range(25):
            x, y = random.randrange(58, 134), random.randrange(70, 160)
            d.ellipse([x, y, x + 4, y + 4], fill=(90, 15, 15))
    else:
        d.rectangle([70, 8, 122, 30], fill=(150, 150, 160), outline=contorno, width=2)
        d.rectangle([82, 32, 110, 38], fill=(20, 20, 20))
    if cruz:
        d.rectangle([90, 78, 102, 150], fill=(170, 25, 25))
        d.rectangle([70, 98, 122, 110], fill=(170, 25, 25))
        # espada
        d.rectangle([156, 40, 162, 150], fill=(190, 190, 200), outline=contorno)
        d.rectangle([146, 140, 172, 146], fill=(110, 80, 40))
    return img


# ---------- Batalha: retratos 128x128 ----------
def retrato(cor_fundo, cor_roupa, cor_pele, marca=False, elmo=False):
    img = Image.new("RGBA", (128, 128), cor_fundo + (255,))
    d = ImageDraw.Draw(img)
    contorno = (12, 10, 10)
    d.rectangle([20, 84, 108, 128], fill=cor_roupa, outline=contorno, width=2)
    d.ellipse([36, 20, 92, 88], fill=cor_pele, outline=contorno, width=2)
    d.ellipse([50, 48, 58, 56], fill=(20, 16, 16))
    d.ellipse([70, 48, 78, 56], fill=(20, 16, 16))
    d.line([(56, 72), (72, 72)], fill=(90, 40, 40), width=2)
    if marca:
        d.pieslice([30, 10, 98, 70], 180, 360, fill=cor_roupa, outline=contorno, width=2)
        d.line([(60, 60), (66, 66)], fill=(120, 220, 255), width=2)
        d.line([(66, 60), (60, 66)], fill=(120, 220, 255), width=2)
    if elmo:
        d.rectangle([34, 16, 94, 44], fill=(120, 120, 130), outline=contorno, width=2)
        d.line([(40, 100), (88, 100)], fill=(120, 20, 20), width=4)
    return img


def fundo_batalha():
    w, h = 960, 540
    img = Image.new("RGBA", (w, h), (14, 11, 14, 255))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(30 - 18 * t), int(22 - 14 * t), int(30 - 16 * t)))
    # colunas da catedral
    for x in range(40, w, 180):
        d.rectangle([x, 40, x + 46, 400], fill=(36, 30, 34), outline=(20, 16, 20), width=3)
    # Os Nove Sóis no vitral; o nono (Ostzhan) apagado
    for i in range(9):
        cx = 160 + i * 80
        cor = (40, 36, 40) if i == 8 else (170, 130, 50)
        d.ellipse([cx - 18, 60, cx + 18, 96], fill=cor, outline=(10, 8, 10), width=3)
    d.rectangle([0, 400, w, h], fill=(28, 22, 22))
    ruido(d, w, h, [(10, 8, 10), (40, 30, 30)], 4000)
    return img


if __name__ == "__main__":
    salvar(tile_chao(), "tiles/chao.png")
    salvar(tile_parede(), "tiles/parede.png")
    salvar(tile_altar(), "tiles/altar.png")
    salvar(tile_sangue(), "tiles/sangue.png")
    salvar(tile_placa(), "tiles/placa.png")
    salvar(tile_saida(), "tiles/saida.png")
    salvar(heroi(), "sprites/heroi.png")
    salvar(cruzado_mapa(), "sprites/cruzado.png")
    salvar(oco_mapa(), "sprites/oco.png")
    salvar(inimigo_grande((150, 150, 165), (190, 160, 140)), "batalha/cruzado.png")
    salvar(inimigo_grande((80, 70, 60), (165, 155, 135), cruz=False, oco=True), "batalha/oco.png")
    salvar(retrato((30, 26, 40), (70, 60, 90), (200, 170, 150), marca=True), "batalha/retrato_iselde.png")
    salvar(retrato((40, 24, 24), (110, 110, 120), (180, 150, 130), elmo=True), "batalha/retrato_doran.png")
    salvar(fundo_batalha(), "batalha/fundo_catedral.png")
