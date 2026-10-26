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
}
