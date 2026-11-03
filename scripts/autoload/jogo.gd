extends Node
## Estado global do jogo (autoload "Jogo"): party, inventário, relógio, luz e progresso.
## Dano e membros perdidos persistem entre batalhas, como em Fear & Hunger.
##
## Regra da luz: magia só funciona sob a luz do sol ou da lua (a lua reflete o
## sol). No escuro ela precisa de uma Pedra Solar, que tem 9 cargas e se
## quebra ao esgotar. A força da magia segue o sol e é máxima ao meio-dia.

signal batalha_pedida(inimigo_id: String, id_no_mapa: String)
## A escada levou para outro mapa (o Main troca a cena do Mundo).
signal mapa_pedido(cena: String)
## Menu > Voltar ao título.
signal titulo_pedido

## O jogador cria o protagonista no começo (tela de criação): nome, sexo e
## o Sol que segue. Não há classes (Carlos, 2026-11-02): o sexo escolhe a
## arte, o Sol as magias e a passiva, e o resto o jogador constrói jogando.
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

## Técnicas e equipamento iniciais, iguais para todos. HP, MP, força e
## agilidade saem dos atributos (Atributos.status).
const HEROI_BASE := {
	"defesa": 0,
	"habilidades": ["corte_preciso", "golpe_destruidor", "estocada", "rasteira", "investida_escudo", "primeiros_socorros"],
	"equipamento": {"arma": "espada_enferrujada", "corpo": "panos_velhos", "pes": "calcados_velhos"},
}

## O encapuzado de olhos vermelhos: entra na party nos esgotos, antes do chefe.
const ENCAPUZADO := {
	"id": "encapuzado", "nome": "Encapuzado", "titulo": "???", "sol": "",
	"hp": 85, "mp": 24, "ataque": 11, "defesa": 15, "agilidade": 12,
	"textura": "res://assets/batalha/retrato_encapuzado.png", "costas": "",
	"folha_mapa": "res://assets/sprites/encapuzado.png",
	"habilidades": ["lamina_sombria", "olhar_vermelho", "corte_preciso", "primeiros_socorros"],
	"equipamento": {"arma": "espada_prata", "corpo": "armadura_couro"},
	"hp_partes": {"cabeca": 26, "braco_esq": 28, "braco_dir": 28, "pernas": 31},
	"estilo": {},
}

## Mapas da demo, na ordem: a escada da prisão desce para os esgotos.
const MAPA_INICIAL := "res://scenes/mapas/prisao.tscn"

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
## Cena do mapa onde a party está.
var mapa_atual := MAPA_INICIAL
## Itens ganhos na última vitória (o mapa avisa ao voltar).
var ultimo_saque: Array = []
var rng := RandomNumberGenerator.new()


## Escolhas da tela de criação (usadas de novo ao recomeçar).
var criacao := {"nome": "Aren", "sexo": "masculino", "sol": "vida", "atributos": {}}


func _ready() -> void:
	rng.randomize()
	novo_jogo()


## Monta o protagonista a partir das escolhas da tela de criação. Sem
## atributos, usa a build pronta do Sol. O Sol seguido soma as magias dele
## (as que já existem na batalha) às técnicas.
static func criar_heroi(nome: String, sexo: String, sol := "", atributos := {}) -> Dictionary:
	var s: Dictionary = SEXOS[sexo]
	var c: Dictionary = HEROI_BASE
	var at: Dictionary = atributos.duplicate() if not atributos.is_empty() else Atributos.BUILD_SOL.get(sol, Atributos.BUILD_SOL["vida"]).duplicate()
	var st := Atributos.status(at)
	var hp_partes := {}
	for parte in PROPORCAO_PARTES:
		hp_partes[parte] = roundi(st["hp"] * PROPORCAO_PARTES[parte])
	var habilidades: Array = c["habilidades"].duplicate()
	for hid in Habilidades.MAGIAS_POR_SOL.get(sol, []):
		if Habilidades.DADOS.has(hid) and not hid in habilidades:
			habilidades.append(hid)
	return {
		"id": "heroi", "nome": nome.strip_edges() if nome.strip_edges() != "" else s["nome_padrao"],
		"sexo": sexo, "titulo": "Prisioneiro", "sol": sol, "atributos": at,
		"hp": st["hp"], "mp": st["mp"], "ataque": st["ataque"], "defesa": c["defesa"], "agilidade": st["agilidade"],
		"textura": s["textura"], "costas": s["costas"], "folha_mapa": s["folha_mapa"],
		"habilidades": habilidades, "equipamento": c["equipamento"].duplicate(),
		"hp_partes": hp_partes, "estilo": {}, "sanidade": Combatente.SANIDADE_MAXIMA,
	}


## Começa do zero. Sem argumentos, repete as últimas escolhas da criação.
func novo_jogo(nome := "", sexo := "", sol := "", atributos := {}) -> void:
	if sexo != "":
		criacao = {"nome": nome, "sexo": sexo, "sol": sol, "atributos": atributos.duplicate()}
	party = [criar_heroi(criacao["nome"], criacao["sexo"], criacao["sol"], criacao.get("atributos", {}))]
	itens = {"bandagem": 2}
	# Demo: o resto dos itens está espalhado pelos esgotos.
	inventario.assign(["escudo_madeira"])
	mapa_atual = MAPA_INICIAL
	ultimo_saque.clear()
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


## Resumo do estilo que o jogador está construindo, pelo que ele mais usa
## na batalha (membro["estilo"]: fisico, magia, defesa e magia_<sol>).
static func texto_estilo(membro: Dictionary) -> String:
	var e: Dictionary = membro.get("estilo", {})
	var fisico: int = e.get("fisico", 0)
	var magia: int = e.get("magia", 0)
	var defesa: int = e.get("defesa", 0)
	if fisico + magia + defesa < 3:
		return "Ainda indefinido. Lute mais para descobrir."
	if magia > fisico and magia >= defesa:
		var sol_mais := ""
		var maior := 0
		for chave in e:
			if String(chave).begins_with("magia_") and e[chave] > maior:
				maior = e[chave]
				sol_mais = String(chave).trim_prefix("magia_")
		return "Mais magia" + (" (%s)" % Habilidades.NOME_SOL[sol_mais] if sol_mais != "" else "")
	if defesa > fisico:
		return "Mais defesa: espera o momento certo"
	return "Mais golpes físicos"


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
		membro["sanidade_atual"] = membro.get("sanidade", Combatente.SANIDADE_MAXIMA)


func pedir_batalha(inimigo_id: String, id_no_mapa: String) -> void:
	batalha_pedida.emit(inimigo_id, id_no_mapa)


func pedir_mapa(cena: String) -> void:
	mapa_pedido.emit(cena)


func pedir_titulo() -> void:
	titulo_pedido.emit()


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
	# Arma de duas mãos não deixa usar escudo (e vice-versa).
	if slot == "arma" and Itens.DADOS[item_id].get("maos", 1) == 2:
		desequipar(membro, "escudo")
	elif slot == "escudo" and Itens.DADOS.get(eq.get("arma", ""), {}).get("maos", 1) == 2:
		desequipar(membro, "arma")
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
	var d: Dictionary = Itens.DADOS[item_id]
	var texto := ""
	match d["uso"]:
		"cura":
			var antes: int = membro.get("hp_atual", membro["hp"])
			membro["hp_atual"] = mini(membro["hp"], antes + d.get("cura", 0))
			texto = "%s recupera %d HP." % [membro["nome"], membro["hp_atual"] - antes]
			if d.get("estanca", false):
				membro["sangrando"] = false
		"mp":
			var antes: int = membro.get("mp_atual", membro["mp"])
			membro["mp_atual"] = mini(membro["mp"], antes + d.get("mp", 0))
			texto = "%s recupera %d MP." % [membro["nome"], membro["mp_atual"] - antes]
		"sanidade":
			var maximo: int = membro.get("sanidade", Combatente.SANIDADE_MAXIMA)
			var antes: int = membro.get("sanidade_atual", maximo)
			membro["sanidade_atual"] = mini(maximo, antes + d.get("sanidade", 0))
			texto = "%s recupera %d de sanidade." % [membro["nome"], membro["sanidade_atual"] - antes]
		"antidoto":
			texto = "%s bebe o antídoto. (Use na batalha contra veneno.)" % membro["nome"]
		"pedra":
			texto = ganhar_cargas(d.get("cargas", 1))
	itens[item_id] -= 1
	return texto


## Fragmento solar: soma cargas à primeira pedra (ou vira uma pedra nova).
func ganhar_cargas(cargas: int) -> String:
	if pedras_solares.is_empty():
		pedras_solares.append(cargas)
		return "O fragmento vira uma Pedra Solar com %d cargas." % cargas
	pedras_solares[0] = mini(CARGAS_PEDRA, pedras_solares[0] + cargas)
	return "A Pedra Solar brilha mais forte: %d cargas." % pedras_solares[0]


## Põe o encapuzado na party (uma vez).
func recrutar_encapuzado() -> void:
	for membro in party:
		if membro["id"] == "encapuzado":
			return
	var e: Dictionary = ENCAPUZADO.duplicate(true)
	e["sanidade"] = Combatente.SANIDADE_MAXIMA
	party.append(e)
	eventos["encapuzado_na_party"] = true


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
