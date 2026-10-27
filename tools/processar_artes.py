"""Converte as artes originais (arte_original/) nos assets do jogo (assets/).

Uso: python3 tools/processar_artes.py
Requer Pillow e numpy. Rode de novo sempre que trocar uma arte original.

Formatos gerados:
- Folhas de mapa: 192x256, 3 colunas (passos) x 4 linhas (baixo, esquerda,
  direita, cima), quadros de 64x64.
- Batalha: 192x256 com fundo transparente.
- Retratos: 128x128.
- Tiles: 64x64.
- Efeitos: fundo preto (o jogo desenha com mistura aditiva).
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ORIGEM = RAIZ / "arte_original"
DESTINO = RAIZ / "assets"
# Lado do tile e do quadro das folhas de mapa, em pixels.
Q = 64


def abrir(nome):
    return Image.open(ORIGEM / nome).convert("RGB")


def salvar(img, caminho):
    destino = DESTINO / caminho
    destino.parent.mkdir(parents=True, exist_ok=True)
    img.save(destino)
    print("gerado", destino.relative_to(RAIZ))


def hsv(arr):
    arr = arr.astype(np.float32)
    mx = arr.max(axis=2)
    mn = arr.min(axis=2)
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0)
    return s, mx / 255.0


# ------------------------------------------------------------ máscaras de fundo

def fundo_xadrez_claro(arr):
    s, v = hsv(arr)
    return (s < 0.13) & (v > 0.62)


def fundo_xadrez_medio(arr):
    s, v = hsv(arr)
    return (s < 0.10) & (v > 0.30) & (v < 0.66)


def fundo_cinza_escuro(arr):
    s, v = hsv(arr)
    return (s < 0.10) & (v > 0.18) & (v < 0.50)


def fundo_verde(arr):
    a = arr.astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (g > 120) & (g > r + 50) & (g > b + 50)


def preencher_de_fora(fundo):
    """Só conta como fundo o que está ligado às bordas (flood fill)."""
    h, w = fundo.shape
    visto = np.zeros_like(fundo)
    fila = deque()
    for x in range(w):
        for y in (0, h - 1):
            if fundo[y, x] and not visto[y, x]:
                visto[y, x] = True
                fila.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if fundo[y, x] and not visto[y, x]:
                visto[y, x] = True
                fila.append((y, x))
    while fila:
        y, x = fila.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and fundo[ny, nx] and not visto[ny, nx]:
                visto[ny, nx] = True
                fila.append((ny, nx))
    return visto


def com_alfa(img, mascara_fundo):
    rgba = img.convert("RGBA")
    alfa = np.where(mascara_fundo, 0, 255).astype(np.uint8)
    rgba.putalpha(Image.fromarray(alfa))
    return rgba


def caixa_util(alfa, minimo=3):
    """Caixa dos pixels opacos, ignorando linhas/colunas com pouco ruído."""
    linhas = np.where((alfa > 0).sum(axis=1) >= minimo)[0]
    colunas = np.where((alfa > 0).sum(axis=0) >= minimo)[0]
    if len(linhas) == 0 or len(colunas) == 0:
        return None
    return colunas[0], linhas[0], colunas[-1] + 1, linhas[-1] + 1


# ------------------------------------------------------------ folhas de mapa

def recortar_quadros(img, mascara, linhas, colunas):
    rgba = com_alfa(img, mascara)
    w, h = rgba.size
    cw, ch = w / colunas, h / linhas
    quadros = {}
    for r in range(linhas):
        for c in range(colunas):
            celula = rgba.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))
            caixa = caixa_util(np.array(celula)[..., 3])
            if caixa:
                quadros[(r, c)] = celula.crop(caixa)
    return quadros


def reduzir(quadro, escala):
    w, h = quadro.size
    nw, nh = max(1, round(w * escala)), max(1, round(h * escala))
    menor = quadro.resize((nw, nh), Image.BOX)
    alfa = menor.split()[3].point(lambda v: 255 if v > 110 else 0)
    menor.putalpha(alfa)
    return menor


def montar_folha(quadros, layout, altura=Q - 4):
    """layout: 4 listas (baixo, esquerda, direita, cima) de (linha, coluna, espelhar)."""
    usados = [quadros[(r, c)] for direcao in layout for (r, c, _) in direcao]
    escala = min(altura / max(q.size[1] for q in usados), Q / max(q.size[0] for q in usados))
    folha = Image.new("RGBA", (3 * Q, 4 * Q), (0, 0, 0, 0))
    for linha, direcao in enumerate(layout):
        for coluna, (r, c, espelhar) in enumerate(direcao):
            q = reduzir(quadros[(r, c)], escala)
            if espelhar:
                q = q.transpose(Image.FLIP_LEFT_RIGHT)
            x = coluna * Q + (Q - q.size[0]) // 2
            y = linha * Q + Q - q.size[1] - 1
            folha.alpha_composite(q, (x, y))
    return folha


def costas_de_frente(quadro):
    """Cria a vista de costas trocando rosto por cabelo e a frente da túnica pelas costas.
    As medidas abaixo são de um quadro de 32 px; k ajusta para o tamanho Q."""
    im = quadro.copy()
    k = Q // 32
    p = im.load()

    def pele(c):
        return c[3] and c[0] > 150 and c[0] - c[2] > 40

    colunas = [x for x in range(Q) if any(p[x, y][3] for y in range(2 * k, 16 * k))]
    x0, x1 = min(colunas), max(colunas)
    tunica = (90, 70, 50, 255)
    for y in range(17 * k, 24 * k):
        achou = False
        for x in range(x0 + 3 * k, x1 - 2 * k):
            c = p[x, y]
            if c[3] and not pele(c) and sum(c[:3]) / 3 > 55:
                tunica, achou = c, True
                break
        if achou:
            break
    cabelo, raspado = (38, 34, 32, 255), (96, 84, 76, 255)
    for y in range(6 * k, 16 * k):
        for x in range(x0 + 2 * k, x1 - k):
            c = p[x, y]
            if not c[3] or (y >= 14 * k and pele(c)):
                continue
            p[x, y] = cabelo if y < 10 * k else raspado
    for y in range(16 * k, 24 * k):
        for x in range(x0 + 3 * k, x1 - 2 * k):
            c = p[x, y]
            if c[3] and not pele(c):
                p[x, y] = tunica
    meio = (x0 + x1) // 2
    for y in range(17 * k, 23 * k):
        for x in range(meio, meio + k):
            p[x, y] = tuple(max(0, v - 35) for v in tunica[:3]) + (255,)
    return im


def folhas_de_mapa():
    frente = [(0, 0, False), (0, 1, False), (0, 2, False)]

    # Protagonista: a última linha da folha veio de frente; as costas são derivadas.
    img = abrir("protagonista_folha.jpg")
    q = recortar_quadros(img, preencher_de_fora(fundo_xadrez_claro(np.array(img))), 4, 3)
    folha = montar_folha(q, [frente, [(1, i, False) for i in range(3)], [(2, i, False) for i in range(3)], frente])
    for i in range(3):
        quadro = folha.crop((i * Q, 0, i * Q + Q, Q))
        folha.paste(costas_de_frente(quadro), (i * Q, 3 * Q))
    salvar(folha, "sprites/protagonista.png")

    img = abrir("protagonista2_folha.jpg")
    q = recortar_quadros(img, preencher_de_fora(fundo_xadrez_medio(np.array(img))), 4, 3)
    salvar(montar_folha(q, [[(r, i, False) for i in range(3)] for r in range(4)]), "sprites/protagonista2.png")

    # Sarnheim v2: frente, lado (olhando para a esquerda) e costas; a direita é espelhada.
    img = abrir("sarnheim_folha_v2.jpg")
    q = recortar_quadros(img, preencher_de_fora(fundo_xadrez_claro(np.array(img))), 3, 3)
    lado = [(1, i, False) for i in range(3)]
    salvar(montar_folha(q, [frente, lado, [(r, c, True) for r, c, _ in lado], [(2, i, False) for i in range(3)]]),
        "sprites/sarnheim.png")

    img = abrir("encapuzado_folha.jpg")
    q = recortar_quadros(img, preencher_de_fora(fundo_xadrez_claro(np.array(img))), 4, 3)
    salvar(montar_folha(q, [[(r, i, False) for i in range(3)] for r in range(4)]), "sprites/encapuzado.png")

    # Cruzado: no lado, o 3º quadro da linha 2 olha para a direita, e na última
    # linha o 1º quadro é de frente. Esquerda usa só os quadros que olham para a
    # esquerda; a direita é espelhada.
    q = quadros_sem_grade("cruzado_folha.jpg")
    esquerda = [(1, 0, False), (1, 1, False), (2, 0, False)]
    salvar(montar_folha(q, [frente, esquerda, [(r, c, True) for r, c, _ in esquerda],
        [(3, 1, False), (3, 2, False), (3, 1, True)]]), "sprites/cruzado.png")

    # Paladino: na última linha só os quadros 2 e 3 são de costas.
    img = abrir("paladino_folha.jpg")
    q = recortar_quadros(img, preencher_de_fora(fundo_cinza_escuro(np.array(img))), 4, 3)
    salvar(montar_folha(q, [frente, [(1, i, False) for i in range(3)], [(2, i, False) for i in range(3)],
        [(3, 1, False), (3, 2, False), (3, 1, True)]]), "sprites/paladino.png")


# ------------------------------------------------------------ batalha e retratos

def fundo_por_gradiente(img, tolerancia=8, protegidos=(), cinza_max=18):
    """Fundo cinza em degradê: cresce a partir das bordas por pixels cinza
    parecidos com o vizinho. `protegidos` são segmentos (x0, y0, x1, y1, raio)
    que nunca viram fundo (ex.: lâmina de espada cinza)."""
    arr = np.array(img).astype(np.int32)
    h, w, _ = arr.shape
    cinza = (arr.max(axis=2) - arr.min(axis=2)) <= cinza_max
    yy, xx = np.mgrid[0:h, 0:w]
    for ax, ay, bx, by, r in protegidos:
        dx, dy = bx - ax, by - ay
        t = np.clip(((xx - ax) * dx + (yy - ay) * dy) / float(dx * dx + dy * dy), 0, 1)
        dist = np.hypot(xx - ax - t * dx, yy - ay - t * dy)
        cinza &= dist > r
    visto = np.zeros((h, w), bool)
    fila = deque()
    for y in range(h):
        for x in range(w):
            if (y in (0, h - 1) or x in (0, w - 1)) and cinza[y, x]:
                visto[y, x] = True
                fila.append((y, x))
    while fila:
        y, x = fila.popleft()
        c = arr[y, x]
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visto[ny, nx] and cinza[ny, nx]:
                if np.abs(arr[ny, nx] - c).max() <= tolerancia:
                    visto[ny, nx] = True
                    fila.append((ny, nx))
    return visto


def fundo_limiar(img, vmin, protegidos=()):
    """Fundo cinza: pixels pouco saturados e não muito escuros, ligados às bordas."""
    arr = np.array(img)
    s, v = hsv(arr)
    fundo = (s < 0.10) & (v > vmin)
    h, w = fundo.shape
    yy, xx = np.mgrid[0:h, 0:w]
    for ax, ay, bx, by, r in protegidos:
        dx, dy = bx - ax, by - ay
        t = np.clip(((xx - ax) * dx + (yy - ay) * dy) / float(dx * dx + dy * dy), 0, 1)
        fundo &= np.hypot(xx - ax - t * dx, yy - ay - t * dy) > r
    return preencher_de_fora(fundo)


def fundo_fechado(img, fundo, folga=6, minimo=600, y_min=0):
    """Acha bolsões de fundo cercados pela figura (entre pernas, sob a capa):
    áreas grandes e cinzas cujo brilho cabe na faixa do fundo daquela linha."""
    arr = np.array(img).astype(np.int32)
    h, w, _ = arr.shape
    brilho = arr.mean(axis=2)
    cinza = (arr.max(axis=2) - arr.min(axis=2)) <= 14
    parecido = np.zeros((h, w), bool)
    for y in range(y_min, h):
        conhecidos = brilho[y][fundo[y]]
        if len(conhecidos) < 20:
            continue
        lo, hi = np.percentile(conhecidos, 2) - folga, np.percentile(conhecidos, 98) + folga
        parecido[y] = cinza[y] & (brilho[y] >= lo) & (brilho[y] <= hi) & ~fundo[y]
    bolsoes = manter_grandes(Image.fromarray(np.dstack([np.zeros((h, w, 3), np.uint8),
        np.where(parecido, 255, 0).astype(np.uint8)])), minimo)
    return fundo | (np.array(bolsoes)[..., 3] > 0)


def manter_grandes(rgba, minimo=400, so_maior=False):
    """Apaga manchas soltas de fundo que sobraram (componentes pequenos)."""
    alfa = np.array(rgba)[..., 3] > 0
    h, w = alfa.shape
    rotulo = np.zeros((h, w), np.int32)
    tamanhos = [0]
    atual = 0
    for y0 in range(h):
        for x0 in range(w):
            if alfa[y0, x0] and not rotulo[y0, x0]:
                atual += 1
                n = 0
                fila = deque([(y0, x0)])
                rotulo[y0, x0] = atual
                while fila:
                    y, x = fila.popleft()
                    n += 1
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w and alfa[ny, nx] and not rotulo[ny, nx]:
                            rotulo[ny, nx] = atual
                            fila.append((ny, nx))
                tamanhos.append(n)
    tam = np.array(tamanhos)
    if so_maior:
        minimo = tam[1:].max()
    manter = tam[rotulo] >= minimo
    manter[rotulo == 0] = False
    dados = np.array(rgba)
    dados[..., 3] = np.where(manter, 255, 0)
    return Image.fromarray(dados)


def para_batalha(rgba):
    menor = rgba.resize((192, 256), Image.LANCZOS)
    menor.putalpha(menor.split()[3].point(lambda v: 255 if v > 128 else 0))
    return menor


def retrato(img, caixa):
    return img.crop(caixa).resize((128, 128), Image.LANCZOS)


ESPADA = (88, 172, 182, 505, 14)


def batalha_e_retratos():
    img = abrir("sarnheim_batalha.jpg")
    salvar(para_batalha(manter_grandes(com_alfa(img, fundo_limiar(img, 0.22, [ESPADA])), so_maior=True)), "batalha/sarnheim.png")

    img = abrir("paladino_batalha.jpg")
    # Os bolsões só são procurados abaixo da cintura: o elmo tem o mesmo cinza do fundo.
    fundo = fundo_fechado(img, fundo_por_gradiente(img, 16, [ESPADA, (440, 600, 440, 790, 34)]), y_min=600)
    salvar(para_batalha(manter_grandes(com_alfa(img, fundo), 2000)), "batalha/paladino.png")

    img = abrir("cruzado_batalha.jpg")
    arr = np.array(img).astype(np.int32)
    sat, _ = hsv(np.array(img))
    brilho = arr.mean(axis=2)
    fundo = fundo_fechado(img, fundo_por_gradiente(img, 16, [(118, 62, 300, 470, 26)]), y_min=640)
    chao = sat < 0.06
    chao[:1000] = False
    # Sombra e chão entre as pernas (a armadura prateada também é cinza, por isso a caixa).
    entre = (sat < 0.08) & (brilho > 45) & (brilho < 170)
    entre[:760] = False
    entre[990:] = False
    entre[:, :330] = False
    entre[:, 600:] = False
    salvar(para_batalha(manter_grandes(com_alfa(img, fundo | chao | entre), 2000)), "batalha/cruzado.png")

    img = abrir("encapuzado_fundo_verde.jpg")
    rgba = manter_grandes(com_alfa(img, preencher_de_fora(fundo_verde(np.array(img)))))
    salvar(para_batalha(rgba), "batalha/encapuzado.png")
    fundo = Image.new("RGBA", (300, 300), (24, 20, 24, 255))
    fundo.alpha_composite(rgba.crop((298, 40, 598, 340)))
    salvar(fundo.resize((128, 128), Image.LANCZOS), "batalha/retrato_encapuzado.png")

    salvar(retrato(abrir("protagonista_corpo.jpg"), (300, 70, 600, 370)), "batalha/retrato_protagonista.png")
    salvar(retrato(abrir("protagonista2_corpo.jpg"), (325, 50, 625, 350)), "batalha/retrato_protagonista2.png")


# ------------------------------------------------------------ party de costas

POSES_COSTAS = {"parado": "", "soco": "_soco", "guarda": "_guarda", "magia": "_magia", "dano": "_dano"}


def limpar_tracos(figura, raio=2):
    """Abertura morfológica: apaga traços finos (linhas de movimento, respingos)."""
    def passar(m, f):
        r = m.copy()
        for dy in range(-raio, raio + 1):
            for dx in range(-raio, raio + 1):
                r = f(r, np.roll(np.roll(m, dy, 0), dx, 1))
        return r
    return passar(passar(figura, np.logical_and), np.logical_or) & figura


def costas():
    for prefixo, nome in (("protagonista", "aren"), ("protagonista2", "iselde")):
        costas_de(prefixo, nome)


def costas_de(prefixo, nome):
    """Protagonista visto de costas na batalha, espelhado (ele olha para a
    direita, onde está o inimigo). Todas as poses usam o mesmo recorte para
    não pularem de lugar quando trocam."""
    for pose, sufixo in POSES_COSTAS.items():
        img = abrir(f"{prefixo}_costas{sufixo}.jpg")
        arr = np.array(img).astype(np.int32)
        sat, _ = hsv(np.array(img))
        brilho = arr.mean(axis=2)
        if nome == "iselde":
            # Roupa branca: só cinza bem neutro vira fundo (o branco dela é amarelado).
            borda = fundo_por_gradiente(img, 6, cinza_max=9)
        else:
            # Na pose de dano o colete escuro emenda no fundo com tolerância alta.
            borda = fundo_por_gradiente(img, 8 if pose == "dano" else 16)
        bolsoes = fundo_fechado(img, borda, y_min=250) & ~borda & (brilho > 90)
        chao = sat < 0.10
        if nome == "iselde":
            neutro = (arr.max(axis=2) - arr.min(axis=2)) <= 9
            bolsoes &= neutro
            chao = neutro & (brilho < 165)
        chao[:850] = False
        figura = limpar_tracos(~(borda | bolsoes | chao))
        rgba = manter_grandes(com_alfa(img, ~figura), so_maior=True).crop((40, 80, 840, 1180))
        rgba = rgba.transpose(Image.FLIP_LEFT_RIGHT).resize((320, 440), Image.LANCZOS)
        rgba.putalpha(rgba.split()[3].point(lambda v: 255 if v > 128 else 0))
        salvar(rgba, f"batalha/costas/{nome}_{pose}.png")


# ------------------------------------------------------------ Ocos

def quadros_sem_grade(nome, inset=7):
    img = abrir(nome)
    arr = np.array(img).astype(np.int32)
    # Verde em qualquer lugar é fundo (também entre pernas e braços).
    verde = (arr[..., 1] > 110) & (arr[..., 1] > arr[..., 0] * 1.35) & (arr[..., 1] > arr[..., 2] * 1.35)
    # Tira o reflexo verde das bordas.
    lim = np.maximum(arr[..., 0], arr[..., 2])
    arr[..., 1] = np.minimum(arr[..., 1], lim + 8)
    rgba = com_alfa(Image.fromarray(arr.astype(np.uint8)), verde)
    w, h = rgba.size
    cw, ch = w / 3, h / 4
    q = {}
    for r in range(4):
        for c in range(3):
            cel = rgba.crop((round(c*cw)+inset, round(r*ch)+inset, round((c+1)*cw)-inset, round((r+1)*ch)-inset))
            cel = manter_grandes(cel, so_maior=True)
            q[(r, c)] = cel.crop(caixa_util(np.array(cel)[..., 3]))
    return q

def pescoco(q):
    larg = (np.array(q)[..., 3] > 0).sum(axis=1)
    h = len(larg); i0, i1 = int(h * .2), int(h * .5)
    return i0 + int(np.argmin(larg[i0:i1]))

def cabecao(q, lado, sx, sy, sobra=6):
    """Aumenta o crânio. lado: 'frente' cresce para cima; 'esq' (rosto à esquerda) cresce para cima e para a direita."""
    p = pescoco(q) + sobra
    w, h = q.size
    cab = q.crop((0, 0, w, p))
    nw, nh = round(w * sx), round(p * sy)
    cab = cab.resize((nw, nh), Image.LANCZOS)
    extra_y = nh - p
    if lado == "frente":
        ox = (nw - w) // 2
        novo = Image.new("RGBA", (nw, h + extra_y), (0, 0, 0, 0))
        novo.alpha_composite(q, (ox, extra_y))
        novo.alpha_composite(cab, (0, 0))
    else:
        # rosto fica no lugar, crânio cresce para trás (direita)
        bb = caixa_util(np.array(cab)[..., 3])
        novo = Image.new("RGBA", (max(w, nw), h + extra_y), (0, 0, 0, 0))
        novo.alpha_composite(q, (0, extra_y))
        novo.alpha_composite(cab, (0, 0))
    a = novo.split()[3].point(lambda v: 255 if v > 100 else 0); novo.putalpha(a)
    return novo.crop(caixa_util(np.array(novo)[..., 3]))

def folha_oco(nome, sx_f=1.22, sy_f=1.85, sx_l=1.6, sy_l=1.65):
    """Folha 3x4 dos Ocos. A IA desenhou a cabeça pequena e redonda; aqui o
    crânio cresce para cima (frente/costas) e para trás (lado). Nas linhas de
    lado e de costas o quadro do meio veio de frente, então é substituído."""
    q = quadros_sem_grade(nome)
    def F(k): return cabecao(q[k], "frente", sx_f, sy_f)
    def L(k, esp=False):
        im = q[k].transpose(Image.FLIP_LEFT_RIGHT) if esp else q[k]
        return cabecao(im, "esq", sx_l, sy_l)
    def flip(im): return im.transpose(Image.FLIP_LEFT_RIGHT)
    baixo = [F((0, 0)), F((0, 1)), F((0, 2))]
    esq = [L((1, 0)), L((2, 0)), L((1, 2), True)]
    dir_ = [flip(i) for i in esq]
    cima = [F((3, 0)), flip(F((3, 0))), F((3, 2))]
    linhas = [baixo, esq, dir_, cima]
    tudo = [i for l in linhas for i in l]
    escala = min((Q - 4) / max(i.size[1] for i in tudo), Q / max(i.size[0] for i in tudo))
    folha = Image.new("RGBA", (3 * Q, 4 * Q), (0, 0, 0, 0))
    for r, l in enumerate(linhas):
        for c, im in enumerate(l):
            m = reduzir(im, escala)
            folha.alpha_composite(m, (c * Q + (Q - m.size[0]) // 2, r * Q + Q - m.size[1] - 1))
    return folha


def ocos():
    for nome in ("oco", "oca"):
        salvar(folha_oco(f"{nome}_folha.jpg"), f"sprites/{nome}.png")
        img = abrir(f"{nome}_batalha.jpg")
        fundo = fundo_fechado(img, fundo_por_gradiente(img, 16), y_min=500)
        # Sombra no chão: cinza sem cor abaixo da cintura.
        sat, _ = hsv(np.array(img))
        chao = sat < 0.10
        chao[:800] = False
        salvar(para_batalha(manter_grandes(com_alfa(img, fundo | chao), so_maior=True)), f"batalha/{nome}.png")


# ------------------------------------------------------------ cenário

# Limites das linhas da folha de tiles (em pixels da imagem original).
LINHAS_TILES = [(0, 172), (172, 365), (365, 545)]
NOMES_TILES = [
    ["chao", "chao2", "chao_sol", "chao_rachado", "chao_rachado2", "chao_rachado3", "chao_buraco", "sangue"],
    ["parede", "parede2", "parede_tocha", "grade", "cela_fechada", "cela_aberta", "porta", "escada"],
    ["cama", "balde", "correntes", "esqueleto", "altar", "placa", "barril", "caixa"],
]


def tiles():
    img = abrir("tiles_prisao.jpg")
    largura = img.size[0] / 8
    for r, (y0, y1) in enumerate(LINHAS_TILES):
        for c, nome in enumerate(NOMES_TILES[r]):
            celula = img.crop((round(c * largura) + 3, y0 + 3, round((c + 1) * largura) - 3, y1 - 3))
            tile = celula.resize((Q, Q), Image.BOX)
            if nome == "chao_sol":
                # Reforça o feixe de sol para ele se destacar do chão comum.
                arr = np.array(tile).astype(np.float32)
                arr = np.clip(arr * [1.45, 1.3, 0.95] + [30, 20, 0], 0, 255)
                tile = Image.fromarray(arr.astype(np.uint8))
            salvar(tile, f"tiles/{nome}.png")
    # Topo de parede (parede com outra parede embaixo): pedra escura lisa.
    topo = Image.new("RGB", (Q, Q), (24, 24, 29))
    px = topo.load()
    for i in range(Q):
        for b in range(Q // 32):
            px[i, b] = px[b, i] = (44, 44, 52)
            px[i, Q - 1 - b] = px[Q - 1 - b, i] = (14, 14, 18)
    salvar(topo, "tiles/parede_topo.png")
    # Piso de madeira desenhado pelo Carlos já em 64x64.
    salvar(Image.open(ORIGEM / "piso_madeira_64.png").convert("RGB").resize((Q, Q), Image.BOX), "tiles/piso_madeira.png")

    fundo = abrir("fundo_batalha_prisao.jpg")
    salvar(fundo.resize((960, 540), Image.LANCZOS), "batalha/fundo_prisao.png")


# ------------------------------------------------------------ efeitos e itens

def fundo_para_preto(img, piso=62):
    """Tira o xadrez escuro subtraindo o brilho dele (o jogo usa mistura
    aditiva, então preto = transparente e o brilho continua suave). O brilho
    fraco é borrado para apagar o xadrez que ficou por baixo dele."""
    from PIL import ImageFilter
    orig = np.array(img).astype(np.float32)
    borrado = np.array(img.filter(ImageFilter.BoxBlur(7))).astype(np.float32)
    forte = orig.mean(axis=2, keepdims=True) > 150
    arr = np.where(forte, orig, borrado)
    arr = np.clip((arr - piso) * 255.0 / (255 - piso), 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


EFEITOS = {
    "corte": (195, 70, 335, 205),
    "corte_reto": (45, 80, 155, 195),
    "faisca": (355, 60, 495, 205),
    "impacto": (895, 80, 1020, 190),
    "bloqueio": (232, 312, 310, 455),
    "luz": (355, 310, 495, 455),
    "fogo": (515, 590, 650, 725),
}

# Início de cada quadro do raio: (x, centro_y) na imagem original.
QUADROS_RAIO = [(0, 125), (462, 125), (920, 125), (0, 375), (465, 375), (925, 375), (5, 620), (462, 620)]


def efeitos():
    img = fundo_para_preto(abrir("efeitos_ataques.jpg"))
    for nome, caixa in EFEITOS.items():
        salvar(img.crop(caixa), f"efeitos/{nome}.png")

    raio = fundo_para_preto(abrir("raio_amarelo.jpg"), 70)
    faixa = Image.new("RGB", (440 * len(QUADROS_RAIO), 200))
    for i, (x, cy) in enumerate(QUADROS_RAIO):
        faixa.paste(raio.crop((x, cy - 100, x + 440, cy + 100)), (i * 440, 0))
    salvar(faixa.resize((faixa.size[0] // 2, 100), Image.LANCZOS), "efeitos/raio.png")

    pedra = abrir("pedra_solar.png")
    arr = np.array(pedra)
    s, _ = hsv(arr)
    rgba = manter_grandes(com_alfa(pedra, preencher_de_fora(s < 0.15)), so_maior=True)
    rgba = rgba.crop(caixa_util(np.array(rgba)[..., 3]))
    for tamanho in (24, 48, 96):
        icone = rgba.copy()
        icone.thumbnail((tamanho, tamanho), Image.LANCZOS)
        icone.putalpha(icone.split()[3].point(lambda v: 255 if v > 110 else 0))
        quadro = Image.new("RGBA", (tamanho, tamanho), (0, 0, 0, 0))
        quadro.alpha_composite(icone, ((tamanho - icone.size[0]) // 2, (tamanho - icone.size[1]) // 2))
        salvar(quadro, f"itens/pedra_solar_{tamanho}.png")


if __name__ == "__main__":
    folhas_de_mapa()
    batalha_e_retratos()
    costas()
    ocos()
    tiles()
    efeitos()
