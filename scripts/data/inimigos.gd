class_name Inimigos
## Dados dos inimigos. As regiões são retângulos (em pixels) na textura de
## batalha de cada inimigo e definem onde o jogador mira cada membro.

const REGIOES_HUMANOIDE := {
	"cabeca": Rect2(70, 8, 52, 56),
	"torso": Rect2(56, 64, 80, 100),
	"braco_esq": Rect2(24, 68, 32, 102),
	"braco_dir": Rect2(136, 68, 32, 102),
	"pernas": Rect2(64, 160, 64, 80),
}

const DADOS := {
	"cruzado": {
		"id": "cruzado",
		"nome": "Cruzado do Décimo Dia",
		"descricao": "Soldado da Igreja do Décimo Dia. Caça Marcados para o Ritual do Meio.",
		"hp": 60,
		"ataque": 16,
		"defesa": 3,
		"agilidade": 8,
		"textura": "res://assets/batalha/cruzado.png",
		"sprite_mapa": "res://assets/sprites/cruzado.png",
		"hp_partes": {"cabeca": 32, "braco_esq": 22, "braco_dir": 22, "pernas": 26},
		"ataques": [
			{"nome": "Golpe de espada", "mult": 1.0},
			{"nome": "Estocada sagrada", "mult": 1.3, "precisao": 0.8},
		],
		"regioes": REGIOES_HUMANOIDE,
	},
	"oco": {
		"id": "oco",
		"nome": "Fiel Oco",
		"descricao": "Um devoto drenado por Rannvhar XV. Ainda reza, mas não lembra para quem.",
		"hp": 40,
		"ataque": 12,
		"defesa": 1,
		"agilidade": 4,
		"textura": "res://assets/batalha/oco.png",
		"sprite_mapa": "res://assets/sprites/oco.png",
		"hp_partes": {"cabeca": 22, "braco_esq": 16, "braco_dir": 16, "pernas": 18},
		"ataques": [
			{"nome": "Arranhão", "mult": 0.9},
			{"nome": "Mordida faminta", "mult": 1.4, "precisao": 0.7},
		],
		"regioes": REGIOES_HUMANOIDE,
	},
	"sarnheim": {
		"id": "sarnheim",
		"nome": "Soldado de Sarnheim",
		"descricao": "Guarda do Reino de Correntes, a serviço da rainha Keith. Espada, escudo e elmo quase impenetrável.",
		"hp": 75,
		"ataque": 17,
		"defesa": 5,
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
}
