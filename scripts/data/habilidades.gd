class_name Habilidades
## Técnicas e magias da party.
## "alvo":
##   inimigo         escolhe um membro do inimigo para mirar
##   inimigo_corpo   afeta o inimigo inteiro (sem mira)
##   aliado          escolhe um membro da party
##   aliados         afeta a party inteira
##   proprio         age em quem usou
##   batalha         mexe na batalha toda (Retroceder)
## Técnicas: "base" de dano, "com_arma" soma a arma, "requer" pede "arma" ou
## "espada". Magias ("magia": true) seguem a regra da luz (Jogo.forca_magia)
## e pertencem a um Sol ("sol"). "estado" aplica um efeito que dura turnos
## (-1 = até o fim da batalha). "efeito" é um arquivo em assets/efeitos/ e
## "cor" tinge esse efeito.
## Magia com "dano_magico" causa esse dano vezes a força da luz (com
## "com_arma", soma o golpe da arma).
## Outros campos: "cura" (HP fixo), "estanca" (para o sangramento),
## "sanidade" (devolve sanidade), "perfura" (ignora a armadura), "sangria"
## (faz sangrar), "soma_escudo" (soma o bloqueio do escudo ao dano),
## "chance_por_hp" (falha mais contra inimigos fortes). Técnicas com alvo
## "inimigo" e "estado" aplicam o estado se o golpe acertar.

const NOME_SOL := {
	"vida": "Sol da Vida", "morte": "Sol da Morte", "alma": "Sol da Alma",
	"tempo": "Sol do Tempo", "verde": "Sol da Natureza", "coracao": "Sol do Coração",
	"esperanca": "Sol da Esperança", "medo": "Sol do Medo", "apagado": "Sol Apagado",
}

## Sóis que o jogador pode seguir ao criar o personagem (o Sol Apagado só
## no NG+). Nomes curtos para os botões da tela de criação.
const SOIS_INICIAIS := {
	"vida": "Vida", "morte": "Morte", "alma": "Alma", "tempo": "Tempo",
	"verde": "Natureza", "coracao": "Coração", "esperanca": "Esperança", "medo": "Medo",
}

## Cores de cada Sol na tela de criação: [núcleo, brilho].
const COR_SOL := {
	"vida": [Color(0.78, 0.16, 0.14), Color(1.0, 0.42, 0.32)],
	"morte": [Color(0.03, 0.03, 0.04), Color(0.62, 0.62, 0.68)],
	"alma": [Color(0.5, 0.78, 0.95), Color(0.66, 0.88, 1.0)],
	"tempo": [Color(0.85, 0.62, 0.22), Color(1.0, 0.82, 0.45)],
	"verde": [Color(0.22, 0.6, 0.2), Color(0.45, 0.88, 0.35)],
	"coracao": [Color(0.86, 0.3, 0.52), Color(1.0, 0.52, 0.7)],
	"esperanca": [Color(0.98, 0.93, 0.7), Color(1.0, 1.0, 0.86)],
	"medo": [Color(0.24, 0.05, 0.3), Color(0.58, 0.22, 0.7)],
}

## Uma frase sobre cada Sol, mostrada sob o nome na tela de criação.
const RESUMO_SOL := {
	"vida": "Cura, resistência e a teimosia de voltar de onde ninguém volta.",
	"morte": "Doença, cadáveres e o fim de todas as coisas.",
	"alma": "Espíritos, projeção e o que fica depois do corpo.",
	"tempo": "Voltar atrás, ver o que já passou e apressar as horas.",
	"verde": "A terra que cura e que prende. Energia mesmo longe do sol.",
	"coracao": "Encantar, enganar e enxergar através da mentira.",
	"esperanca": "Vontade que levanta os outros e segura a mente no lugar.",
	"medo": "Terror, presença e a escuridão como aliada.",
}

## Ordem dos Sóis no menu e o que cada um ensina (incluindo o que ainda não
## existe na batalha, marcado em PLANEJADAS).
const MAGIAS_POR_SOL := {
	"vida": ["bencao_vaelora", "regeneracao"],
	"morte": ["levantar_cadaver", "doenca"],
	"alma": ["projecao", "ouija"],
	"tempo": ["retroceder", "visualizar"],
	"verde": ["cura_natureza", "emaranhar"],
	"coracao": ["encantar", "enganar"],
	"esperanca": ["grito_vontade", "restaurar_sanidade"],
	"medo": ["aterrorizar", "presenca_ameacadora"],
}

## Passivas que já funcionam no jogo (as outras aparecem como "em breve").
const PASSIVAS_ATIVAS := ["vida", "morte", "medo", "esperanca"]

const PASSIVAS := {
	"vida": ["Nunca desistir", "Ao chegar a 0 de vida, volta com 1. Uma vez por descanso."],
	"morte": ["Senhor da Peste", "Imune a doenças."],
	"alma": ["Sexto sentido", "Sente a presença de espíritos."],
	"tempo": ["Fluxo do tempo", "Pode acelerar a passagem do tempo sob a luz do sol."],
	"verde": ["No verde", "Em terreno de natureza ganha energia, mesmo fora do sol."],
	"coracao": ["Coração Verdadeiro", "Vê através das mentiras."],
	"esperanca": ["Perseverança", "Com a sanidade em 0, ainda luta e recupera 5 pontos."],
	"medo": ["Abraça a escuridão", "Não sofre nenhum efeito negativo do medo."],
}

const DADOS := {
	# ------------------------------------------------------------ técnicas
	"corte_preciso": {
		"nome": "Corte preciso", "custo": 2, "alvo": "inimigo",
		"descricao": "Golpe de espada certeiro: 7 de dano + arma, mais fácil de acertar.",
		"base": 7, "com_arma": true, "requer": "espada", "precisao": 1.2, "efeito": "corte_reto",
	},
	"golpe_destruidor": {
		"nome": "Golpe destruidor", "custo": 4, "alvo": "inimigo",
		"descricao": "Golpe com toda a força: 10 de dano + arma, difícil de acertar.",
		"base": 10, "com_arma": true, "requer": "arma", "precisao": 0.75, "efeito": "faisca",
	},
	"rasteira": {
		"nome": "Rasteira", "custo": 2, "alvo": "inimigo",
		"descricao": "Chute baixo: 3 de dano e chance de derrubar (perde o próximo turno).",
		"base": 3, "precisao": 1.1, "efeito": "impacto",
		"estado": {"nome": "atordoado", "valor": 0, "turnos": 1}, "chance": 0.55,
	},
	"estocada": {
		"nome": "Estocada", "custo": 3, "alvo": "inimigo",
		"descricao": "Ponta da arma entre as placas: 4 de dano + arma, ignora a armadura.",
		"base": 4, "com_arma": true, "requer": "arma", "perfura": true, "efeito": "corte_reto",
	},
	"investida_escudo": {
		"nome": "Investida com escudo", "custo": 4, "alvo": "inimigo",
		"descricao": "Avança com o escudo: 5 de dano + bloqueio do escudo, pode atordoar.",
		"base": 5, "soma_escudo": true, "requer": "escudo", "efeito": "impacto",
		"estado": {"nome": "atordoado", "valor": 0, "turnos": 1}, "chance": 0.5,
	},
	"primeiros_socorros": {
		"nome": "Primeiros socorros", "custo": 3, "alvo": "aliado",
		"descricao": "Rasga a roupa e amarra a ferida: +12 HP e estanca o sangramento.",
		"cura": 12, "estanca": true, "efeito": "luz", "cor": Color(1.0, 0.9, 0.8),
	},
	# Técnicas do encapuzado (aliado da demo).
	"lamina_sombria": {
		"nome": "Lâmina sombria", "custo": 4, "alvo": "inimigo",
		"descricao": "Corte rápido nas juntas: 8 de dano + arma e faz sangrar.",
		"base": 8, "com_arma": true, "requer": "arma", "sangria": true, "precisao": 1.1, "efeito": "corte",
		"cor": Color(1.0, 0.3, 0.3),
	},
	"olhar_vermelho": {
		"nome": "Olhar vermelho", "custo": 5, "alvo": "inimigo_corpo",
		"descricao": "Os olhos dele brilham no escuro: o inimigo fica exposto por 3 turnos.",
		"estado": {"nome": "exposto", "valor": 0, "turnos": 3}, "efeito": "luz", "cor": Color(1.0, 0.2, 0.2),
	},
	# ------------------------------------------------------------ Sol da Vida
	"bencao_vaelora": {
		"nome": "Bênção de Vaelora", "custo": 4, "alvo": "aliado", "magia": true, "sol": "vida",
		"descricao": "Cura 15% da vida do alvo.", "cura_pct": 15, "efeito": "luz",
	},
	"regeneracao": {
		"nome": "Regeneração", "custo": 3, "alvo": "aliado", "magia": true, "sol": "vida",
		"descricao": "Cura sutil: 2% da vida por turno até o fim da batalha.",
		"estado": {"nome": "regeneracao", "valor": 2, "turnos": -1}, "efeito": "luz",
		"cor": Color(0.6, 1.0, 0.6),
	},
	# ------------------------------------------------------------ Sol da Morte
	"doenca": {
		"nome": "Doença", "custo": 4, "alvo": "inimigo_corpo", "magia": true, "sol": "morte",
		"descricao": "Envenena o inimigo: 5 de dano por turno até o fim da batalha.",
		"estado": {"nome": "veneno", "valor": 5, "turnos": -1}, "efeito": "luz",
		"cor": Color(0.5, 0.9, 0.2),
	},
	"levantar_cadaver": {
		"nome": "Levantar cadáver", "custo": 6, "alvo": "proprio", "magia": true, "sol": "morte",
		"descricao": "Um cadáver se ergue e ataca o inimigo a cada turno seu (4 turnos). Falha mais contra inimigos fortes.",
		"estado": {"nome": "cadaver", "valor": 7, "turnos": 4}, "chance_por_hp": true, "efeito": "luz",
		"cor": Color(0.6, 0.65, 0.55),
	},
	# ------------------------------------------------------------ Sol da Alma
	"projecao": {
		"nome": "Projeção", "custo": 5, "alvo": "proprio", "magia": true, "sol": "alma",
		"descricao": "A alma sai do corpo por 2 turnos: os golpes atravessam você.",
		"estado": {"nome": "projetado", "valor": 0, "turnos": 2}, "efeito": "luz",
		"cor": Color(0.66, 0.88, 1.0),
	},
	"ouija": {
		"nome": "Ouija", "custo": 3, "alvo": "inimigo_corpo", "magia": true, "sol": "alma",
		"descricao": "Os mortos sussurram onde o inimigo é fraco: exposto por 3 turnos (+20% de acerto, +25% de dano).",
		"estado": {"nome": "exposto", "valor": 0, "turnos": 3}, "efeito": "luz",
		"cor": Color(0.7, 0.8, 1.0),
	},
	# ------------------------------------------------------------ Sol do Tempo
	"retroceder": {
		"nome": "Retroceder", "custo": 8, "alvo": "batalha", "magia": true, "sol": "tempo",
		"descricao": "Volta 1 turno no tempo: tudo fica como no começo da rodada.",
		"efeito": "luz", "cor": Color(0.7, 0.75, 1.0),
	},
	"visualizar": {
		"nome": "Visualizar", "custo": 3, "alvo": "aliados", "magia": true, "sol": "tempo",
		"descricao": "Vê fragmentos do que vai acontecer: cada aliado desvia do próximo golpe.",
		"estado": {"nome": "previsto", "valor": 0, "turnos": -1}, "efeito": "luz",
		"cor": Color(1.0, 0.82, 0.45),
	},
	# ------------------------------------------------------------ Sol da Natureza
	"cura_natureza": {
		"nome": "Cura da natureza", "custo": 6, "alvo": "proprio", "magia": true, "sol": "verde",
		"descricao": "Usa a energia da natureza para se curar: 35% da vida.",
		"cura_pct": 35, "efeito": "luz", "cor": Color(0.55, 1.0, 0.45),
	},
	"emaranhar": {
		"nome": "Emaranhar", "custo": 6, "alvo": "inimigo_corpo", "magia": true, "sol": "verde",
		"descricao": "Espinhos prendem o oponente: paralisado por 3 turnos, 5 de dano por turno.",
		"estado": {"nome": "paralisia", "valor": 5, "turnos": 3}, "efeito": "corte",
		"cor": Color(0.4, 0.9, 0.3),
	},
	# ------------------------------------------------------------ Sol do Coração
	"encantar": {
		"nome": "Encantar", "custo": 5, "alvo": "inimigo_corpo", "magia": true, "sol": "coracao",
		"descricao": "Engana o coração do oponente para que não ataque. A cada turno ele faz um teste de vontade.",
		"estado": {"nome": "encantado", "valor": 40, "turnos": -1}, "efeito": "luz",
		"cor": Color(1.0, 0.55, 0.8),
	},
	"enganar": {
		"nome": "Enganar", "custo": 4, "alvo": "inimigo_corpo", "magia": true, "sol": "coracao",
		"descricao": "Mente para o inimigo: no próximo turno ele acredita e golpeia a si mesmo.",
		"chance": 0.75, "estado": {"nome": "enganado", "valor": 0, "turnos": 2}, "efeito": "luz",
		"cor": Color(1.0, 0.52, 0.7),
	},
	# ------------------------------------------------------------ Sol da Esperança
	"grito_vontade": {
		"nome": "Grito de vontade", "custo": 3, "alvo": "aliados", "magia": true, "sol": "esperanca",
		"descricao": "Aliados ganham +5% de ataque até o fim da batalha.",
		"estado": {"nome": "forca", "valor": 5, "turnos": -1}, "efeito": "luz",
		"cor": Color(1.0, 0.85, 0.4),
	},
	"restaurar_sanidade": {
		"nome": "Restaurar sanidade", "custo": 3, "alvo": "aliado", "magia": true, "sol": "esperanca",
		"descricao": "+10 de sanidade para o alvo (mais com luz forte) e acalma o medo.",
		"sanidade": 10, "efeito": "luz", "cor": Color(1.0, 1.0, 0.86),
	},
	# ------------------------------------------------------------ Sol do Medo
	"aterrorizar": {
		"nome": "Aterrorizar", "custo": 5, "alvo": "inimigo_corpo", "magia": true, "sol": "medo",
		"descricao": "Um ataque de medo deixa o alvo imóvel por 2 turnos. Pode falhar.",
		"chance": 0.7, "estado": {"nome": "medo", "valor": 0, "turnos": 2}, "efeito": "impacto",
		"cor": Color(0.6, 0.4, 0.9),
	},
	"presenca_ameacadora": {
		"nome": "Presença ameaçadora", "custo": 5, "alvo": "inimigo_corpo", "magia": true, "sol": "medo",
		"descricao": "Uma aura que ninguém quer encarar: por 3 turnos o inimigo hesita e erra mais (-40% de acerto).",
		"estado": {"nome": "ameacado", "valor": 40, "turnos": 3}, "efeito": "luz",
		"cor": Color(0.58, 0.22, 0.7),
	},
}

## Magias que ainda não existem na batalha (aparecem como "em breve").
## Desde a demo (2026-11-02) todas as magias dos Sóis funcionam.
const PLANEJADAS := {}


## Por que `c` não pode usar a técnica agora ("" = pode).
static func impedimento(hid: String, c: Combatente) -> String:
	var h: Dictionary = DADOS[hid]
	match h.get("requer", ""):
		"espada":
			if c.tipo_arma != "espada" or not c.pode_atacar_com_arma():
				return "Precisa de uma espada em mãos."
		"arma":
			if not c.tem_arma() or not c.pode_atacar_com_arma():
				return "Precisa de uma arma em mãos."
		"escudo":
			if not c.usa_escudo():
				return "Precisa de um escudo no braço."
	if c.mp < h["custo"]:
		return "MP insuficiente."
	return ""


## Linha da passiva de um Sol para os menus (em cinza se ainda não funciona).
static func linha_passiva(sol: String) -> String:
	var p: Array = PASSIVAS[sol]
	if sol in PASSIVAS_ATIVAS:
		return "• [b]Passiva, %s[/b]: %s\n" % [p[0], p[1]]
	return "[color=#8c8080]• Passiva, %s (em breve): %s[/color]\n" % [p[0], p[1]]


## Custo para mostrar no menu: "4 MP".
static func texto_custo(hid: String) -> String:
	return "%d MP" % DADOS[hid]["custo"]
