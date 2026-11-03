class_name Inimigos
## Dados dos inimigos. As regiões são retângulos (em pixels) na textura de
## batalha de cada inimigo e definem onde o jogador mira cada membro.
## "defesa" é a % de dano que a armadura corta.
## Ataques com "muda_luz" não dão dano: trocam a luz da batalha por alguns
## turnos. "falas" (opcional) são as respostas quando o jogador usa Falar.
## Ataques podem ter "estado" (aplicado no alvo se acertar, com "chance") e
## "sanidade" (quanto tira da sanidade do alvo). "chefe": true = não dá para
## fugir. "saque": [[item, chance]] sorteado ao vencer.

const DADOS := {
	"cruzado": {
		"id": "cruzado",
		"nome": "Cruzado do Décimo Dia",
		"descricao": "Soldado da Igreja do Décimo Dia. Caça Marcados para o Ritual do Meio.",
		"hp": 60,
		"ataque": 16,
		"defesa": 15,
		"agilidade": 8,
		"textura": "res://assets/batalha/cruzado.png",
		"sprite_mapa": "res://assets/sprites/cruzado.png",
		"folha_mapa": true,
		"hp_partes": {"cabeca": 32, "braco_esq": 22, "braco_dir": 22, "pernas": 26},
		"ataques": [
			{"nome": "Golpe de espada", "mult": 1.0},
			{"nome": "Estocada sagrada", "mult": 1.3, "precisao": 0.8},
		],
		"regioes": {
			"cabeca": Rect2(82, 47, 30, 36),
			"torso": Rect2(75, 80, 45, 50),
			"braco_esq": Rect2(112, 65, 24, 62),
			"braco_dir": Rect2(52, 70, 30, 62),  # braço da espada
			"pernas": Rect2(45, 130, 115, 105),
		},
	},
	"oco": {
		"id": "oco",
		"nome": "Fiel Oco",
		"descricao": "Um devoto drenado por Rannvhar XV. Ainda reza, mas não lembra para quem.",
		"hp": 40,
		"ataque": 12,
		"defesa": 5,
		"agilidade": 4,
		"textura": "res://assets/batalha/oco.png",
		"sprite_mapa": "res://assets/sprites/oco.png",
		"folha_mapa": true,
		# O crânio enorme é um alvo grande: mais HP na cabeça.
		"hp_partes": {"cabeca": 26, "braco_esq": 14, "braco_dir": 14, "pernas": 18},
		"ataques": [
			{"nome": "Arranhão", "mult": 0.9},
			{"nome": "Mordida faminta", "mult": 1.4, "precisao": 0.7},
			# Reza para um deus que não responde e a luz some.
			{"nome": "Prece apagada", "muda_luz": {"luz": "escuro", "turnos": 3}},
		],
		"regioes": {
			"cabeca": Rect2(52, 26, 58, 70),
			"torso": Rect2(70, 92, 50, 62),
			"braco_esq": Rect2(120, 95, 35, 75),
			"braco_dir": Rect2(40, 90, 30, 78),
			"pernas": Rect2(45, 158, 105, 82),
		},
	},
	"oca": {
		"id": "oca",
		"nome": "Fiel Oca",
		"descricao": "Uma devota drenada por Rannvhar XV. Os olhos procuram alguém que já não existe.",
		"hp": 36,
		"ataque": 11,
		"defesa": 5,
		"agilidade": 6,
		"textura": "res://assets/batalha/oca.png",
		"sprite_mapa": "res://assets/sprites/oca.png",
		"folha_mapa": true,
		"hp_partes": {"cabeca": 24, "braco_esq": 13, "braco_dir": 13, "pernas": 16},
		"ataques": [
			{"nome": "Unhas", "mult": 1.0},
			{"nome": "Grito oco", "mult": 0.8, "precisao": 0.8, "sanidade": 10},
		],
		"regioes": {
			"cabeca": Rect2(52, 26, 58, 70),
			"torso": Rect2(70, 92, 50, 62),
			"braco_esq": Rect2(120, 95, 35, 75),
			"braco_dir": Rect2(40, 90, 30, 78),
			"pernas": Rect2(45, 158, 105, 82),
		},
	},
	"sarnheim": {
		"id": "sarnheim",
		"nome": "Soldado de Sarnheim",
		"descricao": "Guarda do Reino de Correntes, a serviço da rainha Keith. Espada, escudo e elmo quase impenetrável.",
		"hp": 75,
		"ataque": 17,
		"defesa": 25,
		"agilidade": 6,
		"textura": "res://assets/batalha/sarnheim.png",
		"sprite_mapa": "res://assets/sprites/sarnheim.png",
		# Folha 3x4 de 32x32: colunas = passos; linhas = baixo, esquerda, direita, cima.
		"folha_mapa": true,
		"hp_partes": {"cabeca": 40, "braco_esq": 26, "braco_dir": 26, "pernas": 30},
		"ataques": [
			{"nome": "Corte de espada", "mult": 1.0},
			{"nome": "Golpe de escudo", "mult": 0.8},
			{"nome": "Corrente de Sarnheim", "mult": 1.25, "precisao": 0.85},
		],
		"regioes": {
			"cabeca": Rect2(83, 50, 25, 32),
			"torso": Rect2(70, 82, 44, 64),
			"braco_esq": Rect2(114, 64, 50, 86),  # braço do escudo
			"braco_dir": Rect2(30, 64, 40, 58),  # braço da espada
			"pernas": Rect2(44, 150, 116, 86),
		},
	},
	"paladino": {
		"id": "paladino",
		"nome": "Paladino do Décimo Dia",
		"descricao": "Guarda de elite da Igreja. Carrega a luz dos Nove Sóis no peito e o raio na mão.",
		"hp": 90,
		"ataque": 15,
		"defesa": 30,
		"agilidade": 9,
		"textura": "res://assets/batalha/paladino.png",
		"sprite_mapa": "res://assets/sprites/paladino.png",
		"folha_mapa": true,
		# Pedras Solares que o paladino carrega para lançar raios no escuro.
		"cargas_solares": 3,
		"hp_partes": {"cabeca": 40, "braco_esq": 28, "braco_dir": 28, "pernas": 30},
		"ataques": [
			{"nome": "Corte sagrado", "mult": 1.0},
			{"nome": "Raio do Décimo Dia", "poder": 18, "magia": true, "ignora_esquiva": true, "efeito": "raio"},
			{"nome": "Clarão do Décimo Dia", "muda_luz": {"luz": "sol", "turnos": 2}},
		],
		"regioes": {
			"cabeca": Rect2(82, 36, 28, 34),
			"torso": Rect2(72, 70, 46, 58),
			"braco_esq": Rect2(118, 60, 56, 50),  # braço do raio
			"braco_dir": Rect2(28, 62, 44, 62),  # braço da espada
			"pernas": Rect2(48, 130, 100, 100),
		},
	},
	"rato": {
		"id": "rato",
		"nome": "Rato gigante",
		"descricao": "Cresceu comendo os corpos que a Igreja joga nos esgotos. Morde para infeccionar.",
		"hp": 24,
		"ataque": 8,
		"defesa": 0,
		"agilidade": 11,
		"textura": "res://assets/batalha/rato.png",
		"sprite_mapa": "res://assets/sprites/rato.png",
		"folha_mapa": true,
		"hp_partes": {"cabeca": 12, "braco_esq": 8, "braco_dir": 8, "pernas": 12},
		"ataques": [
			{"nome": "Mordida", "mult": 1.0},
			{"nome": "Arranhão sujo", "mult": 0.8},
			{"nome": "Mordida infecta", "mult": 0.7, "estado": {"nome": "veneno", "valor": 2, "turnos": 3}, "chance": 0.6},
		],
		"saque": [["erva_amarga", 0.35], ["antidoto", 0.2]],
		"regioes": {
			"cabeca": Rect2(64, 24, 64, 88),
			"torso": Rect2(56, 112, 80, 76),
			"braco_esq": Rect2(132, 80, 48, 64),
			"braco_dir": Rect2(12, 80, 48, 64),
			"pernas": Rect2(52, 188, 92, 62),
		},
	},
	"barata": {
		"id": "barata",
		"nome": "Barata gigante",
		"descricao": "Casca dura como armadura. O barulho das patas é pior que a mordida.",
		"hp": 20,
		"ataque": 7,
		"defesa": 25,
		"agilidade": 13,
		"textura": "res://assets/batalha/barata.png",
		"sprite_mapa": "res://assets/sprites/barata.png",
		"folha_mapa": true,
		"hp_partes": {"cabeca": 9, "braco_esq": 7, "braco_dir": 7, "pernas": 10},
		"ataques": [
			{"nome": "Pinçada", "mult": 1.0},
			{"nome": "Enxame de patas", "mult": 0.6, "sanidade": 6},
		],
		"saque": [["agua_benta", 0.25]],
		"regioes": {
			"cabeca": Rect2(76, 56, 40, 36),
			"torso": Rect2(60, 92, 72, 108),
			"braco_esq": Rect2(124, 44, 52, 68),
			"braco_dir": Rect2(16, 44, 52, 68),
			"pernas": Rect2(28, 200, 136, 54),
		},
	},
	"chefe": {
		"id": "chefe",
		"nome": "Inquisidor dos Nove Sóis",
		"descricao": "Caçador de Marcados da Igreja do Décimo Dia. Desceu aos esgotos atrás de você.",
		"hp": 150,
		"ataque": 17,
		"defesa": 25,
		"agilidade": 9,
		"chefe": true,
		"textura": "res://assets/batalha/chefe.png",
		"sprite_mapa": "res://assets/sprites/chefe.png",
		"folha_mapa": true,
		"cargas_solares": 4,
		"hp_partes": {"cabeca": 55, "braco_esq": 40, "braco_dir": 40, "pernas": 45},
		"ataques": [
			{"nome": "Corte sagrado", "mult": 1.0},
			{"nome": "Golpe de julgamento", "mult": 1.35, "precisao": 0.8},
			{"nome": "Julgamento dos Nove Sóis", "poder": 20, "magia": true, "ignora_esquiva": true, "efeito": "raio"},
			{"nome": "Sermão do Décimo Dia", "mult": 0.4, "sanidade": 15, "efeito": "luz"},
			{"nome": "Clarão do Décimo Dia", "muda_luz": {"luz": "sol", "turnos": 2}},
		],
		"falas": [
			"\"Marcado. Os Nove Sóis já te julgaram.\"",
			"\"Cem serão entregues, para que mil sejam poupados.\"",
			"\"Seu amigo de olhos vermelhos não vai te salvar do Ritual.\"",
		],
		"regioes": {
			"cabeca": Rect2(82, 36, 28, 34),
			"torso": Rect2(72, 70, 46, 58),
			"braco_esq": Rect2(118, 60, 56, 50),
			"braco_dir": Rect2(28, 62, 44, 62),
			"pernas": Rect2(48, 130, 100, 100),
		},
	},
}
