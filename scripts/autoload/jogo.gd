extends Node
## Estado global do jogo (autoload "Jogo"): party, inventário, relógio, luz e progresso.
## Dano e membros perdidos persistem entre batalhas, como em Fear & Hunger.
##
## Regra da luz: magia só funciona sob a luz do sol ou da lua (a lua reflete o
## sol). No escuro ela precisa de uma Pedra Solar, que tem 9 cargas e se
## quebra ao esgotar. A força da magia segue o sol e é máxima ao meio-dia.

signal batalha_pedida(inimigo_id: String, id_no_mapa: String)

## O jogador cria o protagonista no começo (tela de criação): nome, sexo e
## classe. O sexo escolhe a arte; a classe, os atributos e as habilidades.
const SEXOS := {
	"masculino": {
		"nome": "Masculino",
		"nome_padrao": "Aren",
		"textura": "res://assets/batalha/retrato_protagonista.png",
		# Na batalha aparece de costas, em primeiro plano: <costas><pose>.png
		"costas": "res://assets/batalha/costas/aren_",
		"folha_mapa": "res://assets/sprites/protagonista.png",
	},
	"feminino": {
		"nome": "Feminino",
		"nome_padrao": "Iselde",
		"textura": "res://assets/batalha/retrato_protagonista2.png",
		"costas": "res://assets/batalha/costas/iselde_",
		"folha_mapa": "res://assets/sprites/protagonista2.png",
	},
}

## Classes da nota Gameplay do Carlos (nomes ainda provisórios).
## As habilidades estão em Habilidades.DADOS.
const CLASSES := {
	"guerreiro": {
		"nome": "Guerreiro",
		"descricao": "Luta com armas e espadas. As técnicas dele não dependem da luz.",
		"hp": 70, "mp": 12, "ataque": 9, "defesa": 0, "agilidade": 9,
		"habilidades": ["corte_preciso", "golpe_destruidor", "grito_guerra", "postura_ferro"],
		"equipamento": {"arma": "espada_enferrujada", "corpo": "panos_velhos", "pes": "calcados_velhos"},
	},
	"mago": {
		"nome": "Mago",
		"descricao": "Conjura a luz do sol. Forte sob o céu, fraco no escuro sem Pedra Solar.",
		"hp": 50, "mp": 24, "ataque": 5, "defesa": 0, "agilidade": 11,
		"habilidades": ["lanca_solar", "clarao", "escudo_luz"],
		"equipamento": {"corpo": "panos_velhos", "pes": "calcados_velhos"},
	},
	"mago_guerreiro": {
		"nome": "Mago Guerreiro",
		"descricao": "Usa a magia para reforçar a espada. Um pouco de cada lado.",
		"hp": 60, "mp": 16, "ataque": 7, "defesa": 0, "agilidade": 10,
		"habilidades": ["corte_preciso", "lamina_solar", "arma_encantada"],
		"equipamento": {"arma": "espada_enferrujada", "corpo": "panos_velhos", "pes": "calcados_velhos"},
	},
	"bruxo": {
		"nome": "Bruxo",
		"descricao": "Magia proibida de carne e sangue: funciona no escuro, mas cobra a própria vida.",
		"hp": 58, "mp": 12, "ataque": 6, "defesa": 0, "agilidade": 10,
		"habilidades": ["sangria", "drenar_vida", "pacto_sangue"],
		"equipamento": {"corpo": "panos_velhos", "pes": "calcados_velhos"},
	},
}

## Vida de cada membro em relação ao HP total.
const PROPORCAO_PARTES := {"cabeca": 0.3, "braco_esq": 0.33, "braco_dir": 0.33, "pernas": 0.37}

const CARGAS_PEDRA := 9
const MINUTOS_POR_PASSO := 2
const HORA_INICIAL := 7

var party: Array = []
## Consumíveis e chaves: id -> quantidade.
var itens: Dictionary = {}
## Equipamentos guardados (não equipados).
var inventario: Array[String] = []
## Cargas de cada Pedra Solar carregada (uma entrada por pedra).
var pedras_solares: Array[int] = []
var inimigos_derrotados: Dictionary = {}
var eventos: Dictionary = {}  # marcos da história já vistos
var minutos := 0  # minutos desde o início do jogo
## Luz no lugar onde a próxima batalha começa: "sol", "lua" ou "escuro".
var luz_batalha := "escuro"
var fundo_batalha := "res://assets/batalha/fundo_prisao.png"
var rng := RandomNumberGenerator.new()


## Escolhas da tela de criação (usadas de novo ao recomeçar).
var criacao := {"nome": "Aren", "sexo": "masculino", "classe": "guerreiro", "sol": "vida"}


func _ready() -> void:
	rng.randomize()
	novo_jogo()


## Monta o protagonista a partir das escolhas da tela de criação. O Sol
## seguido soma as magias dele (as que já existem na batalha) às da classe.
static func criar_heroi(nome: String, sexo: String, classe: String, sol := "") -> Dictionary:
	var s: Dictionary = SEXOS[sexo]
	var c: Dictionary = CLASSES[classe]
	var hp_partes := {}
	for parte in PROPORCAO_PARTES:
		hp_partes[parte] = roundi(c["hp"] * PROPORCAO_PARTES[parte])
	var habilidades: Array = c["habilidades"].duplicate()
	for hid in Habilidades.MAGIAS_POR_SOL.get(sol, []):
		if Habilidades.DADOS.has(hid) and not hid in habilidades:
			habilidades.append(hid)
	return {
		"id": "heroi", "nome": nome.strip_edges() if nome.strip_edges() != "" else s["nome_padrao"],
		"sexo": sexo, "titulo": "Prisioneiro", "classe": c["nome"], "id_classe": classe, "sol": sol,
		"hp": c["hp"], "mp": c["mp"], "ataque": c["ataque"], "defesa": c["defesa"], "agilidade": c["agilidade"],
		"textura": s["textura"], "costas": s["costas"], "folha_mapa": s["folha_mapa"],
		"habilidades": habilidades, "equipamento": c["equipamento"].duplicate(),
		"hp_partes": hp_partes,
	}


## Começa do zero. Sem argumentos, repete as últimas escolhas da criação.
func novo_jogo(nome := "", sexo := "", classe := "", sol := "") -> void:
	if sexo != "":
		criacao = {"nome": nome, "sexo": sexo, "classe": classe, "sol": sol}
	party = [criar_heroi(criacao["nome"], criacao["sexo"], criacao["classe"], criacao["sol"])]
	itens = {"bandagem": 2}
	# Provisório, para testar o inventário até os itens estarem no mapa.
	inventario.assign(["espada_prata", "machado_guerra", "armadura_couro", "bota_couro", "colar_sol", "brinco_lebre"])
	pedras_solares.clear()
	inimigos_derrotados.clear()
	eventos.clear()
	minutos = HORA_INICIAL * 60
	luz_batalha = "escuro"


## Nome do protagonista (usado nos diálogos: {{Jogo.nome_heroi()}}).
func nome_heroi() -> String:
	return party[0]["nome"] if not party.is_empty() else criacao["nome"]


## Escolhe a palavra pelo sexo do protagonista. Nos diálogos:
## {{Jogo.genero("garoto", "garota")}}
func genero(masculino: String, feminino: String) -> String:
	return feminino if criacao["sexo"] == "feminino" else masculino


func party_viva() -> bool:
	for membro in party:
		if membro.get("hp_atual", membro["hp"]) > 0:
			return true
	return false


## Altar dos Nove Sóis: restaura HP/MP, estanca sangramento dos vivos e
## recarrega a passiva Nunca desistir. Membros perdidos não voltam.
func descansar() -> void:
	for membro in party:
		if membro.get("hp_atual", membro["hp"]) <= 0:
			continue
		membro["hp_atual"] = membro["hp"]
		membro["mp_atual"] = membro["mp"]
		membro["sangrando"] = false
		membro["nunca_desistir_usado"] = false


func pedir_batalha(inimigo_id: String, id_no_mapa: String) -> void:
	batalha_pedida.emit(inimigo_id, id_no_mapa)


# ---------------------------------------------------------------- Equipamento

## Equipa um item do inventário em `membro`. O que estava no slot volta para
## o inventário. Retorna false se o item não cabe no slot.
func equipar(membro: Dictionary, item_id: String, slot := "") -> bool:
	if slot == "":
		slot = slot_livre(membro, item_id)
	if slot == "" or not Itens.cabe_no_slot(item_id, slot) or not item_id in inventario:
		return false
	inventario.erase(item_id)
	var eq: Dictionary = membro.get_or_add("equipamento", {})
	if eq.get(slot, "") != "":
		inventario.append(eq[slot])
	eq[slot] = item_id
	return true


func desequipar(membro: Dictionary, slot: String) -> void:
	var eq: Dictionary = membro.get_or_add("equipamento", {})
	if eq.get(slot, "") != "":
		inventario.append(eq[slot])
		eq.erase(slot)


## Slot para um item: o primeiro vazio que serve, ou o primeiro que serve.
func slot_livre(membro: Dictionary, item_id: String) -> String:
	var eq: Dictionary = membro.get("equipamento", {})
	var primeiro := ""
	for slot in Itens.SLOTS:
		if Itens.cabe_no_slot(item_id, slot):
			if eq.get(slot, "") == "":
				return slot
			if primeiro == "":
				primeiro = slot
	return primeiro


## Usa um consumível fora da batalha. Retorna o texto do que aconteceu.
func usar_item(membro: Dictionary, item_id: String) -> String:
	if itens.get(item_id, 0) <= 0 or membro.get("hp_atual", membro["hp"]) <= 0:
		return ""
	itens[item_id] -= 1
	var antes: int = membro.get("hp_atual", membro["hp"])
	membro["hp_atual"] = mini(membro["hp"], antes + Itens.DADOS[item_id].get("cura", 0))
	membro["sangrando"] = false
	return "%s recupera %d HP." % [membro["nome"], membro["hp_atual"] - antes]


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
