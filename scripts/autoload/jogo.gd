extends Node
## Estado global do jogo (autoload "Jogo"): party, inventário e progresso.
## Dano e membros perdidos persistem entre batalhas, como em Fear & Hunger.

signal batalha_pedida(inimigo_id: String, id_no_mapa: String)

const PARTY_INICIAL := [
	{
		"id": "iselde",
		"nome": "Iselde",
		"titulo": "Marcada (Mydrani)",
		"hp": 50,
		"mp": 20,
		"ataque": 9,
		"defesa": 1,
		"agilidade": 12,
		"textura": "res://assets/batalha/retrato_iselde.png",
		"habilidades": ["lampejo", "sigilo_vida"],
		"hp_partes": {"cabeca": 16, "braco_esq": 18, "braco_dir": 18, "pernas": 20},
	},
	{
		"id": "doran",
		"nome": "Doran",
		"titulo": "Cruzado desertor",
		"hp": 70,
		"mp": 8,
		"ataque": 13,
		"defesa": 3,
		"agilidade": 7,
		"textura": "res://assets/batalha/retrato_doran.png",
		"habilidades": ["golpe_brutal", "proteger"],
		"hp_partes": {"cabeca": 20, "braco_esq": 24, "braco_dir": 24, "pernas": 26},
	},
]

var party: Array = []
var itens: Dictionary = {}
var inimigos_derrotados: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	novo_jogo()


func novo_jogo() -> void:
	party = PARTY_INICIAL.duplicate(true)
	itens = {"bandagem": 2}
	inimigos_derrotados.clear()


func party_viva() -> bool:
	for membro in party:
		if membro.get("hp_atual", membro["hp"]) > 0:
			return true
	return false


## Altar dos Nove Sóis: restaura HP/MP e estanca sangramento dos vivos.
## Membros perdidos não voltam.
func descansar() -> void:
	for membro in party:
		if membro.get("hp_atual", membro["hp"]) <= 0:
			continue
		membro["hp_atual"] = membro["hp"]
		membro["mp_atual"] = membro["mp"]
		membro["sangrando"] = false


func pedir_batalha(inimigo_id: String, id_no_mapa: String) -> void:
	batalha_pedida.emit(inimigo_id, id_no_mapa)
