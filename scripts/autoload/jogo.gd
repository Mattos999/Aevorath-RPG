extends Node
## Estado global do jogo (autoload "Jogo"): party, inventário, relógio, luz e progresso.
## Dano e membros perdidos persistem entre batalhas, como em Fear & Hunger.
##
## Regra da luz: magia só funciona sob a luz do sol ou da lua (a lua reflete o
## sol). No escuro ela precisa de uma Pedra Solar, que tem 9 cargas e se
## quebra ao esgotar. A força da magia segue o sol e é máxima ao meio-dia.

signal batalha_pedida(inimigo_id: String, id_no_mapa: String)

## Nomes provisórios até o Carlos definir os nomes dos protagonistas.
const PERSONAGENS := {
	"aren": {
		"id": "aren",
		"nome": "Aren",
		"titulo": "Prisioneiro",
		"hp": 65,
		"mp": 10,
		"ataque": 12,
		"defesa": 2,
		"agilidade": 9,
		"textura": "res://assets/batalha/retrato_protagonista.png",
		"folha_mapa": "res://assets/sprites/protagonista.png",
		"habilidades": ["golpe_brutal", "proteger"],
		"hp_partes": {"cabeca": 20, "braco_esq": 22, "braco_dir": 22, "pernas": 24},
	},
	"iselde": {
		"id": "iselde",
		"nome": "Iselde",
		"titulo": "Marcada (Mydrani)",
		"hp": 50,
		"mp": 20,
		"ataque": 9,
		"defesa": 1,
		"agilidade": 12,
		"textura": "res://assets/batalha/retrato_protagonista2.png",
		"folha_mapa": "res://assets/sprites/protagonista2.png",
		"habilidades": ["lampejo", "sigilo_vida"],
		"hp_partes": {"cabeca": 16, "braco_esq": 18, "braco_dir": 18, "pernas": 20},
	},
}

const CARGAS_PEDRA := 9
const MINUTOS_POR_PASSO := 2
const HORA_INICIAL := 7

var party: Array = []
var itens: Dictionary = {}
## Cargas de cada Pedra Solar carregada (uma entrada por pedra).
var pedras_solares: Array[int] = []
var inimigos_derrotados: Dictionary = {}
var eventos: Dictionary = {}  # marcos da história já vistos
var minutos := 0  # minutos desde o início do jogo
## Luz no lugar onde a próxima batalha começa: "sol", "lua" ou "escuro".
var luz_batalha := "escuro"
var fundo_batalha := "res://assets/batalha/fundo_prisao.png"
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	novo_jogo()


func novo_jogo() -> void:
	party = [PERSONAGENS["aren"].duplicate(true)]
	itens = {"bandagem": 2}
	pedras_solares.clear()
	inimigos_derrotados.clear()
	eventos.clear()
	minutos = HORA_INICIAL * 60
	luz_batalha = "escuro"


func recrutar(id: String) -> void:
	for membro in party:
		if membro["id"] == id:
			return
	party.append(PERSONAGENS[id].duplicate(true))


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


# ---------------------------------------------------------------- Relógio e luz

func passar_tempo(passos := 1) -> void:
	minutos += passos * MINUTOS_POR_PASSO


func hora() -> float:
	return fmod(minutos / 60.0, 24.0)


func dia() -> int:
	return minutos / 1440 + 1


func texto_relogio() -> String:
	var h := int(hora())
	return "Dia %d, %02d:%02d" % [dia(), h, minutos % 60]


func eh_dia() -> bool:
	return hora() >= 6.0 and hora() < 18.0


## Luz recebida por quem está sob céu aberto ou num feixe de luz.
func luz_do_ceu() -> String:
	return "sol" if eh_dia() else "lua"


## Multiplicador de força da magia para a luz dada (0 = magia impossível).
## Sol: 50% no amanhecer/entardecer até 150% ao meio-dia. Lua: 60%.
## Escuro com Pedra Solar: 80% (a pedra guarda só um pouco de energia).
func forca_magia(luz: String) -> float:
	match luz:
		"sol":
			return 0.5 + sin(PI * (hora() - 6.0) / 12.0)
		"lua":
			return 0.6
	return 0.8 if tem_pedra_solar() else 0.0


func tem_pedra_solar() -> bool:
	return not pedras_solares.is_empty()


func cargas_solares() -> int:
	var total := 0
	for c in pedras_solares:
		total += c
	return total


func ganhar_pedra_solar() -> void:
	pedras_solares.append(CARGAS_PEDRA)


## Gasta uma carga. Retorna true se a pedra quebrou com isso.
func gastar_carga_solar() -> bool:
	if pedras_solares.is_empty():
		return false
	pedras_solares[0] -= 1
	if pedras_solares[0] <= 0:
		pedras_solares.remove_at(0)
		return true
	return false
