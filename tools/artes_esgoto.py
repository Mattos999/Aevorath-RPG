"""Artes provisórias da demo (esgotos): rato e barata gigantes, tiles do
esgoto, saco de itens e o fundo de batalha. Feitas por código porque o
PixelLab ficou sem créditos; troque pelas artes finais quando tiver.

Uso: python3 tools/artes_esgoto.py   (depois: python3 tools/montar_atlas.py)
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
ASSETS = RAIZ / "assets"
LUZ = (-0.45, -0.6, 0.66)  # vinda de cima, à esquerda


def _norm(v):
    m = math.sqrt(sum(c * c for c in v))
    return tuple(c / m for c in v)


L = _norm(LUZ)


class Tela:
    """Desenho em camadas: cada peça é um elipsoide sombreado (volume)."""

    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.img.load()
        self.w, self.h = w, h

    def elipse(self, cx, cy, rx, ry, cor, giro=0.0, brilho=0.0, ruido=0.0, seed=1, escuro=0.42):
        rnd = random.Random(seed)
        c, s = math.cos(giro), math.sin(giro)
        r = int(max(rx, ry)) + 2
        for y in range(int(cy) - r, int(cy) + r + 1):
            for x in range(int(cx) - r, int(cx) + r + 1):
                if not (0 <= x < self.w and 0 <= y < self.h):
                    continue
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                u = (dx * c + dy * s) / rx
                v = (-dx * s + dy * c) / ry
                d = u * u + v * v
                if d > 1.0:
                    continue
                z = math.sqrt(1.0 - d)
                # normal no espaço da tela (desfaz o giro)
                nx, ny = u * c - v * s, u * s + v * c
                luz = max(0.0, nx * L[0] + ny * L[1] + z * L[2])
                k = escuro + (1.0 - escuro) * 1.25 * luz
                if ruido:
                    k *= 1.0 + rnd.uniform(-ruido, ruido)
                rgb = [min(255, int(ch * k)) for ch in cor]
                if brilho and luz > 0.93:
                    rgb = [min(255, int(ch + (255 - ch) * brilho)) for ch in rgb]
                self.px[x, y] = (*rgb, 255)

    def linha(self, pontos, larg, cor, **kw):
        """Membro fino: elipses pequenas ao longo de uma linha."""
        for (x1, y1), (x2, y2) in zip(pontos, pontos[1:]):
            passos = max(2, int(math.hypot(x2 - x1, y2 - y1) / max(1.0, larg * 0.6)))
            giro = math.atan2(y2 - y1, x2 - x1)
            for i in range(passos + 1):
                t = i / passos
                self.elipse(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, larg * 0.9, larg * 0.6, cor, giro=giro, **kw)

    def ponto(self, x, y, cor):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[int(x), int(y)] = (*cor, 255)

    def contorno(self, cor=(18, 12, 12)):
        src = self.img.copy().load()
        for y in range(self.h):
            for x in range(self.w):
                if src[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h and src[nx, ny][3] > 0:
                            self.px[x, y] = (*cor, 255)
                            break

    def final(self, escala):
        return self.img.resize((self.w * escala, self.h * escala), Image.NEAREST)


# ---------------------------------------------------------------- rato

PELO = (112, 92, 80)
BARRIGA = (150, 128, 112)
ROSA = (196, 128, 128)
OLHO = (230, 40, 30)
DENTE = (230, 214, 150)


def rato_batalha():
    t = Tela(96, 128)
    pelo = (88, 72, 64)
    # rabo saindo por trás, curvo e pelado
    rabo = [(62, 112), (76, 118), (86, 108), (90, 92), (86, 78), (92, 64)]
    t.linha(rabo, 2.6, (170, 112, 110), escuro=0.5)
    # pernas de trás (coxas grandes) e pés com garras
    for lado in (-1, 1):
        t.elipse(48 + lado * 18, 100, 14, 17, pelo, giro=lado * 0.25, ruido=0.12, seed=3 + lado)
        t.elipse(48 + lado * 23, 119, 10, 4, (170, 112, 110), escuro=0.5)
    # corpo curvado para a frente, pelo eriçado nas bordas
    rnd = random.Random(5)
    for i in range(34):
        ang = math.pi * (0.15 + 0.7 * i / 33) + math.pi
        ang = rnd.uniform(-0.05, 0.05) + (math.pi - ang if i % 2 else ang)
        x = 48 + math.cos(ang) * 25
        y = 74 + math.sin(ang) * 33
        t.elipse(x, y, 5, 1.6, pelo, giro=ang, ruido=0.1, seed=i)
    t.elipse(48, 74, 25, 33, pelo, ruido=0.14, seed=7)
    t.elipse(48, 82, 14, 21, (124, 104, 92), ruido=0.1, seed=8, escuro=0.5)
    # cicatriz
    for k in range(8):
        t.ponto(36 + k, 64 + k // 2, (150, 70, 66))
    # braços erguidos com garras longas
    for lado, seed in ((-1, 11), (1, 12)):
        ombro = (48 + lado * 19, 56)
        cotovelo = (48 + lado * 32, 70)
        mao = (48 + lado * 36, 50)
        t.linha([ombro, cotovelo, mao], 4.4, pelo, ruido=0.1, seed=seed)
        for g in (-1, 0, 1):
            t.linha([mao, (mao[0] + lado * 3 + g * 3, mao[1] - 6), (mao[0] + lado * 5 + g * 4, mao[1] - 11)],
                    1.1, DENTE, escuro=0.6)
    # orelhas rasgadas
    for lado in (-1, 1):
        t.elipse(48 + lado * 15, 19, 5, 6, (150, 96, 96), escuro=0.45)
        t.elipse(48 + lado * 15, 19, 2.5, 3.5, (100, 56, 60), escuro=0.6)
    t.ponto(48 + 18, 15, (0, 0, 0)); 
    t.img.putpixel((66, 15), (0, 0, 0, 0)); t.img.putpixel((67, 16), (0, 0, 0, 0))
    # cabeça baixa e focinho comprido
    t.elipse(48, 31, 16, 13, pelo, ruido=0.12, seed=15)
    t.elipse(48, 43, 9, 10, pelo, ruido=0.1, seed=16)
    # boca aberta com presas
    t.elipse(48, 51, 6, 4, (60, 16, 18), escuro=0.8)
    for lado in (-1, 1):
        for y in range(48, 56):
            t.ponto(48 + lado * 2, y, DENTE)
            t.ponto(48 + lado * 3, y, DENTE if y < 54 else (60, 16, 18))
    t.elipse(48, 46, 3.5, 2.5, (40, 24, 26), brilho=0.5)
    # olhos vermelhos, apertados de raiva
    for lado in (-1, 1):
        t.elipse(48 + lado * 8, 31, 3.6, 1.8, OLHO, giro=lado * 0.45, brilho=0.9, escuro=0.75)
    # bigodes
    for lado in (-1, 1):
        for dy in (-2, 0, 2):
            for k in range(10):
                t.ponto(48 + lado * (9 + k), 45 + dy + (k * dy) // 5, (170, 160, 150))
    t.contorno()
    return t.final(2)


def rato_mapa():
    """Folha 3x4 de 64x64: frente, esquerda, direita, costas; 3 passos."""
    folha = Image.new("RGBA", (192, 256), (0, 0, 0, 0))
    for linha, dire in enumerate(("baixo", "esq", "dir", "cima")):
        for q in range(3):
            passo = (0, 1, -1)[q]
            t = Tela(32, 32)
            if dire in ("baixo", "cima"):
                frente = dire == "baixo"
                # rabo
                ry = 6 if frente else 28
                t.linha([(16, 18), (16 + passo * 3, ry + (4 if frente else -2)), (19 + passo * 2, ry)], 1.0, ROSA)
                for lado in (-1, 1):  # patas
                    t.elipse(16 + lado * 6, 22 + lado * passo * 1.5, 2.5, 2, ROSA, escuro=0.5)
                    t.elipse(16 + lado * 6, 13 - lado * passo * 1.5, 2.5, 2, ROSA, escuro=0.5)
                t.elipse(16, 17, 8, 10, PELO, ruido=0.1, seed=q + 1)
                cy = 25 if frente else 9
                t.elipse(16, cy, 5.5, 5, PELO, ruido=0.08, seed=5)
                for lado in (-1, 1):
                    t.elipse(16 + lado * 5, cy - (3 if frente else -3), 2.5, 2.5, ROSA, escuro=0.45)
                if frente:
                    t.ponto(14, 25, OLHO); t.ponto(18, 25, OLHO)
                    t.elipse(16, 29, 1.5, 1.2, ROSA)
            else:
                s = -1 if dire == "esq" else 1
                t.linha([(16 - s * 9, 18), (16 - s * 14, 14 + passo), (16 - s * 15, 9)], 1.0, ROSA)
                for k, px_ in enumerate((-5, 5)):
                    off = passo * (1 if k == 0 else -1) * 2
                    t.elipse(16 + px_ + off, 24, 2, 2.4, ROSA, escuro=0.5)
                t.elipse(16, 18, 11, 7, PELO, ruido=0.1, seed=q + 9)
                t.elipse(16 + s * 10, 17, 5.5, 4.5, PELO, ruido=0.08, seed=4)
                t.elipse(16 + s * 15, 18, 1.5, 1.3, ROSA)
                t.elipse(16 + s * 8, 12, 2.4, 2.6, ROSA, escuro=0.45)
                t.ponto(16 + s * 12, 16, OLHO)
            t.contorno()
            folha.paste(t.final(2), (q * 64, linha * 64))
    return folha


# ---------------------------------------------------------------- barata

CASCA = (96, 52, 26)
CASCA_CLARA = (140, 82, 40)
PATA = (70, 40, 22)


def barata_batalha():
    t = Tela(96, 128)
    # pernas de trás e do meio (espinhosas)
    for lado in (-1, 1):
        t.linha([(48 + lado * 14, 92), (48 + lado * 30, 104), (48 + lado * 34, 124)], 2.4, PATA, brilho=0.5)
        t.linha([(48 + lado * 14, 80), (48 + lado * 34, 82), (48 + lado * 42, 98)], 2.2, PATA, brilho=0.5)
        for k in range(3):
            t.ponto(48 + lado * (31 + k), 108 + k * 5, (200, 160, 110))
    # abdômen segmentado
    t.elipse(48, 94, 20, 28, CASCA, brilho=0.6, escuro=0.35)
    img = ImageDraw.Draw(t.img)
    for i, y in enumerate(range(80, 122, 7)):
        meia = int(19 * math.sqrt(max(0.0, 1 - ((y - 94) / 28) ** 2)))
        img.line([(48 - meia, y), (48 + meia, y + 1)], fill=(52, 26, 14, 255))
    # tórax (escudo) brilhante
    t.elipse(48, 58, 22, 17, CASCA_CLARA, brilho=0.8, escuro=0.35)
    t.elipse(48, 56, 15, 10, (170, 110, 58), brilho=0.6, escuro=0.5)
    # braços (pernas da frente) erguidos
    for lado in (-1, 1):
        t.linha([(48 + lado * 16, 54), (48 + lado * 30, 48), (48 + lado * 36, 30)], 2.6, PATA, brilho=0.5)
        t.linha([(48 + lado * 36, 30), (48 + lado * 32, 24)], 1.4, (200, 160, 110))
    # cabeça
    t.elipse(48, 38, 10, 8, (60, 34, 18), brilho=0.5)
    for lado in (-1, 1):
        t.elipse(48 + lado * 6, 36, 3, 3.6, (20, 14, 10), brilho=0.9, escuro=0.8)
        t.linha([(48 + lado * 3, 31), (48 + lado * 14, 14), (48 + lado * 30, 4), (48 + lado * 44, 6)], 0.9, (80, 50, 28))
        t.linha([(48 + lado * 3, 44), (48 + lado * 6, 49)], 1.0, (40, 22, 12))
    t.contorno((14, 8, 6))
    return t.final(2)


def barata_mapa():
    folha = Image.new("RGBA", (192, 256), (0, 0, 0, 0))
    for linha, dire in enumerate(("baixo", "esq", "dir", "cima")):
        for q in range(3):
            passo = (0, 1, -1)[q]
            t = Tela(32, 32)
            vertical = dire in ("baixo", "cima")
            frente = dire == "baixo"
            if vertical:
                for lado in (-1, 1):
                    for k, y in enumerate((11, 16, 21)):
                        off = passo * (1 if (k + (lado > 0)) % 2 else -1)
                        t.linha([(16 + lado * 4, y), (16 + lado * 10, y + off * 2 + (k - 1) * 2)], 0.8, PATA)
                t.elipse(16, 17, 6.5, 10, CASCA, brilho=0.6, escuro=0.35)
                hy = 26 if frente else 7
                t.elipse(16, hy, 4, 3, (60, 34, 18), brilho=0.5)
                for lado in (-1, 1):
                    ay = hy + (5 if frente else -5)
                    t.linha([(16 + lado * 2, hy), (16 + lado * 6, ay), (16 + lado * 9, ay + (2 if frente else -2))], 0.5, (80, 50, 28))
            else:
                s = -1 if dire == "esq" else 1
                for k, x in enumerate((-5, 0, 5)):
                    off = passo * (1 if k % 2 else -1)
                    t.linha([(16 + x, 20), (16 + x + off * 2 - s, 26)], 0.8, PATA)
                t.elipse(16, 19, 11, 5.5, CASCA, brilho=0.6, escuro=0.35)
                t.elipse(16 + s * 11, 19, 3.5, 3, (60, 34, 18), brilho=0.5)
                t.linha([(16 + s * 13, 17), (16 + s * 15, 10), (16 + s * 12, 5)], 0.5, (80, 50, 28))
            t.contorno((14, 8, 6))
            folha.paste(t.final(2), (q * 64, linha * 64))
    return folha


# ---------------------------------------------------------------- tiles

def tingir(img, cor, forca):
    img = img.convert("RGBA")
    camada = Image.new("RGBA", img.size, (*cor, 255))
    mistura = Image.blend(img, camada, forca)
    mistura.putalpha(img.getchannel("A"))
    return mistura


def agua(seed=4):
    rnd = random.Random(seed)
    img = Image.new("RGBA", (64, 64), (42, 54, 30, 255))
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = rnd.randrange(64), rnd.randrange(64)
        w = rnd.randrange(6, 16)
        cor = rnd.choice([(58, 72, 38), (34, 44, 24), (72, 86, 46)])
        d.line([(x, y), (x + w, y)], fill=(*cor, 255), width=1)
    for _ in range(6):  # bolhas
        x, y = rnd.randrange(4, 60), rnd.randrange(4, 60)
        d.ellipse([x, y, x + 3, y + 3], outline=(96, 110, 64, 255))
    return img


def tiles():
    t = ASSETS / "tiles"
    verde = (60, 80, 40)
    chao = Image.open(t / "chao.png")
    tingir(chao, verde, 0.28).save(t / "esgoto_chao.png")
    musgo = Image.open(t / "chao_musgo.png")
    tingir(musgo, verde, 0.22).save(t / "esgoto_chao2.png")
    agua().save(t / "esgoto_agua.png")
    tingir(Image.open(t / "parede.png"), verde, 0.25).save(t / "esgoto_parede.png")
    # parede com cano escorrendo
    p = tingir(Image.open(t / "parede2.png"), verde, 0.25)
    d = ImageDraw.Draw(p)
    d.ellipse([22, 26, 42, 46], fill=(38, 34, 30, 255), outline=(90, 84, 70, 255), width=3)
    d.rectangle([29, 44, 35, 63], fill=(70, 92, 44, 220))
    p.save(t / "esgoto_cano.png")
    # feixe de luz pela grade da rua
    sol = tingir(Image.open(t / "chao_sol.png"), verde, 0.18)
    sol.save(t / "esgoto_sol.png")
    # ponte de tábuas sobre a água
    ponte = agua(9)
    d = ImageDraw.Draw(ponte)
    rnd = random.Random(3)
    for y in range(0, 64, 11):
        cor = rnd.choice([(118, 82, 50), (104, 72, 44), (128, 90, 54)])
        d.rectangle([5, y + 1, 58, y + 9], fill=(*cor, 255), outline=(52, 34, 20, 255))
        d.line([(9, y + 4), (54, y + 5)], fill=(90, 62, 38, 255))
        d.point([(9, y + 5), (54, y + 5)], fill=(40, 40, 44, 255))
    ponte.save(t / "esgoto_ponte.png")


def saco():
    t = Tela(24, 24)
    t.elipse(12, 15, 8, 7, (150, 116, 70), ruido=0.06)
    t.elipse(12, 7, 3, 2.5, (130, 98, 60))
    t.linha([(9, 9), (15, 9)], 0.8, (90, 60, 30))
    t.contorno()
    t.final(2).save(ASSETS / "itens" / "saco_48.png")


def fundo():
    img = Image.open(ASSETS / "batalha" / "fundo_prisao.png").convert("RGB")
    img = ImageEnhance.Brightness(img).enhance(0.8)
    camada = Image.new("RGB", img.size, (50, 70, 34))
    img = Image.blend(img, camada, 0.25)
    # canal de água no chão
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(2)
    d.rectangle([0, 470, 960, 540], fill=(34, 46, 24, 230))
    for _ in range(90):
        x, y = rnd.randrange(960), rnd.randrange(474, 540)
        d.line([(x, y), (x + rnd.randrange(10, 40), y)], fill=(80, 96, 52, 160))
    img.save(ASSETS / "batalha" / "fundo_esgoto.png")


def chefe(origem, destino):
    """Inquisidor: o paladino com capa e detalhes em vermelho-sangue e ouro."""
    img = Image.open(origem).convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            claro = (r + g + b) / 3
            satur = max(r, g, b) - min(r, g, b)
            if satur < 40 and claro > 150:  # capa e tecidos claros -> vermelho
                k = claro / 255
                px[x, y] = (int(150 * k + 40), int(30 * k), int(34 * k), a)
            elif satur < 40 and 70 < claro <= 150:  # metal -> mais escuro
                px[x, y] = (int(r * 0.7), int(g * 0.66), int(b * 0.64), a)
    img.save(destino)


if __name__ == "__main__":
    chefe(ASSETS / "batalha" / "paladino.png", ASSETS / "batalha" / "chefe.png")
    chefe(ASSETS / "sprites" / "paladino.png", ASSETS / "sprites" / "chefe.png")
    rato_batalha().save(ASSETS / "batalha" / "rato.png")
    rato_mapa().save(ASSETS / "sprites" / "rato.png")
    barata_batalha().save(ASSETS / "batalha" / "barata.png")
    barata_mapa().save(ASSETS / "sprites" / "barata.png")
    tiles()
    saco()
    fundo()
    print("artes ok")
