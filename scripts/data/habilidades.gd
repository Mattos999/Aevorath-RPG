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
## "com_arma", soma o golpe da arma). Magia de sangue ("sangue": true) é do
## Bruxo: funciona no escuro, não gasta Pedra Solar e pode custar HP
## ("custo_hp") em vez de MP. "roubo_vida" cura quem usou em % do dano;
## "sangrar" faz o alvo sangrar; "ganho_mp" devolve MP a quem usou.

const NOME_SOL := {
	"vida": "Sol da Vida", "morte": "Sol da Morte", "alma": "Sol da Alma",
	"tempo": "Sol do Tempo", "verde": "Sol Verde", "coracao": "Sol do Coração",
	"esperanca": "Sol da Esperança", "medo": "Sol do Medo", "apagado": "Sol Apagado",
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
	"grito_guerra": {
		"nome": "Grito de guerra", "custo": 3, "alvo": "proprio",
		"descricao": "Um urro que firma a mão: +25% de dano nos golpes por 3 turnos.",
		"estado": {"nome": "forca", "valor": 25, "turnos": 3}, "efeito": "impacto",
		"cor": Color(1.0, 0.6, 0.35),
	},
	"postura_ferro": {
		"nome": "Postura de ferro", "custo": 3, "alvo": "proprio",
		"descricao": "Firma os pés e se fecha: +30% de defesa por 3 turnos.",
		"estado": {"nome": "escudo", "valor": 30, "turnos": 3}, "efeito": "bloqueio",
	},
	# ------------------------------------------------------------ Mago
	"lanca_solar": {
		"nome": "Lança solar", "custo": 4, "alvo": "inimigo", "magia": true,
		"descricao": "Um raio de sol concentrado: 14 de dano, mais forte quanto mais forte a luz.",
		"dano_magico": 14, "precisao": 1.15, "efeito": "luz", "cor": Color(1.0, 0.85, 0.4),
	},
	"clarao": {
		"nome": "Clarão", "custo": 5, "alvo": "inimigo_corpo", "magia": true,
		"descricao": "Uma explosão de luz cega o inimigo: perde o próximo turno. Pode falhar.",
		"chance": 0.75, "estado": {"nome": "ofuscado", "valor": 0, "turnos": 1}, "efeito": "luz",
		"cor": Color(1.0, 1.0, 0.85),
	},
	"escudo_luz": {
		"nome": "Escudo de luz", "custo": 4, "alvo": "aliado", "magia": true,
		"descricao": "Uma camada de luz sólida: +35% de defesa por 3 turnos.",
		"estado": {"nome": "escudo", "valor": 35, "turnos": 3}, "efeito": "bloqueio",
		"cor": Color(1.0, 0.9, 0.5),
	},
	# ------------------------------------------------------------ Mago Guerreiro
	"lamina_solar": {
		"nome": "Lâmina solar", "custo": 4, "alvo": "inimigo", "magia": true,
		"descricao": "A espada se acende com o sol: golpe da arma + 8 de dano mágico.",
		"dano_magico": 8, "com_arma": true, "requer": "arma", "efeito": "corte",
		"cor": Color(1.0, 0.8, 0.35),
	},
	"arma_encantada": {
		"nome": "Arma encantada", "custo": 5, "alvo": "proprio", "magia": true,
		"descricao": "Grava um sigilo de luz na arma: +30% de dano nos golpes até o fim da batalha.",
		"estado": {"nome": "forca", "valor": 30, "turnos": -1}, "efeito": "luz",
		"cor": Color(1.0, 0.8, 0.35),
	},
	# ------------------------------------------------------------ Bruxo
	"sangria": {
		"nome": "Sangria", "custo": 0, "custo_hp": 6, "alvo": "inimigo", "magia": true, "sangue": true,
		"descricao": "Corta a própria palma e abre a carne do inimigo: 12 de dano e o alvo sangra.",
		"dano_magico": 12, "sangrar": true, "efeito": "corte", "cor": Color(0.85, 0.1, 0.1),
	},
	"drenar_vida": {
		"nome": "Drenar vida", "custo": 4, "alvo": "inimigo", "magia": true, "sangue": true,
		"descricao": "Puxa o sangue do inimigo para si: 9 de dano e cura metade disso.",
		"dano_magico": 9, "roubo_vida": 50, "ignora_esquiva": true, "efeito": "luz",
		"cor": Color(0.7, 0.05, 0.15),
	},
	"pacto_sangue": {
		"nome": "Pacto de sangue", "custo": 0, "custo_hp": 10, "alvo": "proprio", "magia": true, "sangue": true,
		"descricao": "Paga com a própria vida para recuperar 8 MP.",
		"ganho_mp": 8, "efeito": "luz", "cor": Color(0.6, 0.0, 0.1),
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
	# ------------------------------------------------------------ Sol do Tempo
	"retroceder": {
		"nome": "Retroceder", "custo": 8, "alvo": "batalha", "magia": true, "sol": "tempo",
		"descricao": "Volta 1 turno no tempo: tudo fica como no começo da rodada.",
		"efeito": "luz", "cor": Color(0.7, 0.75, 1.0),
	},
	# ------------------------------------------------------------ Sol Verde
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
	# ------------------------------------------------------------ Sol da Esperança
	"grito_vontade": {
		"nome": "Grito de vontade", "custo": 3, "alvo": "aliados", "magia": true, "sol": "esperanca",
		"descricao": "Aliados ganham +5% de ataque até o fim da batalha.",
		"estado": {"nome": "forca", "valor": 5, "turnos": -1}, "efeito": "luz",
		"cor": Color(1.0, 0.85, 0.4),
	},
	# ------------------------------------------------------------ Sol do Medo
	"aterrorizar": {
		"nome": "Aterrorizar", "custo": 5, "alvo": "inimigo_corpo", "magia": true, "sol": "medo",
		"descricao": "Um ataque de medo deixa o alvo imóvel por 2 turnos. Pode falhar.",
		"chance": 0.7, "estado": {"nome": "medo", "valor": 0, "turnos": 2}, "efeito": "impacto",
		"cor": Color(0.6, 0.4, 0.9),
	},
}

## Magias que ainda não existem na batalha (precisam de sanidade, invocações
## ou ações no mapa). Aparecem no menu como "em breve".
const PLANEJADAS := {
	"levantar_cadaver": ["Levantar cadáver", "Traz um cadáver como apoio. Quanto mais forte, mais difícil."],
	"projecao": ["Projeção", "Por 1 hora, a alma sai do corpo e anda pelo mapa, atravessando paredes."],
	"ouija": ["Ouija", "Falar com os mortos."],
	"visualizar": ["Visualizar", "Ver fragmentos do passado."],
	"enganar": ["Enganar", "Mente para o alvo, fazendo-o acreditar em algo."],
	"restaurar_sanidade": ["Restaurar sanidade", "+10 de sanidade para o alvo."],
	"presenca_ameacadora": ["Presença ameaçadora", "Aura que impede qualquer pessoa de se aproximar."],
}


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
	if c.mp < h["custo"]:
		return "MP insuficiente."
	if c.hp <= h.get("custo_hp", 0):
		return "HP insuficiente."
	return ""


## Custo para mostrar no menu: "4 MP" ou "6 HP".
static func texto_custo(hid: String) -> String:
	var h: Dictionary = DADOS[hid]
	if h.get("custo_hp", 0) > 0:
		return "%d HP" % h["custo_hp"]
	return "%d MP" % h["custo"]
