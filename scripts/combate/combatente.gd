class_name Combatente
extends RefCounted
## Um lutador na batalha (membro da party ou inimigo), com membros separados.
##
## Regras dos membros (inspiradas em Fear & Hunger):
## - Cabeça: difícil de acertar, dano alto. Decepada = morte.
## - Torso: fácil de acertar, dano extra no corpo, não pode ser decepado.
## - Braços: decepar o braço da arma corta o ataque; sem os dois, só chutes.
## - Pernas: decepadas = não esquiva, age por último e não consegue fugir.
## - Todo membro decepado causa sangramento até ser tratado.
##
## Dano de um golpe = força (ataque) + base da técnica + dano da arma, com
## penalidade por braços perdidos. Defesa reduz o dano em %; defendendo
## (Bloqueio) ganha +2 de defesa e corta o resto pela metade.

const PARTES := ["cabeca", "torso", "braco_esq", "braco_dir", "pernas"]

const NOME_PARTE := {
	"cabeca": "Cabeça",
	"torso": "Torso",
	"braco_esq": "Braço esq.",
	"braco_dir": "Braço dir.",
	"pernas": "Pernas",
}

## Chance base de acerto em cada parte.
const CHANCE_PARTE := {
	"cabeca": 0.55,
	"torso": 0.90,
	"braco_esq": 0.75,
	"braco_dir": 0.75,
	"pernas": 0.70,
}

## Quanto do dano no membro também vai para o HP do corpo.
const DANO_NO_CORPO := {
	"cabeca": 1.5,
	"torso": 1.25,
	"braco_esq": 0.6,
	"braco_dir": 0.6,
	"pernas": 0.6,
}

const SANGRAMENTO_POR_MEMBRO := 3
## Golpe desarmado: dano base de quem ataca sem arma.
const DANO_DESARMADO := 5
const DEFESA_BLOQUEIO := 2
const DEFESA_MAXIMA := 80

const NOME_ESTADO := {
	"veneno": "Envenenado", "paralisia": "Paralisado", "medo": "Aterrorizado",
	"encantado": "Encantado", "regeneracao": "Regenerando", "forca": "Ataque +",
	"escudo": "Defesa +", "ofuscado": "Ofuscado",
}

var id: String
var nome: String
var eh_jogador: bool
var hp_max: int
var hp: int
var mp_max: int
var mp: int
var ataque: int  # força
var defesa: int  # em %, já somando os equipamentos
var agilidade: int
## Equipamento (só da party): slot -> id do item.
var equipamento: Dictionary = {}
var dano_arma := 0
var tipo_arma := ""
var efeitos_equip: Array = []
## Efeitos que duram a batalha: nome -> {turnos (-1 = até o fim), valor}.
var estados: Dictionary = {}
var colar_usado := false
var textura: String
## Prefixo das poses de costas na batalha ("" = só o cartão com retrato).
var costas := ""
## Habilidades disponíveis (ids em Habilidades.DADOS).
var habilidades: Array = []
## Ataques do inimigo: [{nome, mult}]
var ataques: Array = []
## parte -> {hp, hp_max, decepado}
var partes: Dictionary = {}
## parte -> Rect2 na textura de batalha (usado só por inimigos, para a mira).
var regioes: Dictionary = {}
var defendendo := false
var sangrando := false
## Cargas de Pedra Solar do inimigo (a party usa as pedras do Jogo).
var cargas_solares := 0
## Sol que o membro da party segue (dá a passiva; veja Habilidades.PASSIVAS).
var sol := ""
## Passiva do Sol da Vida já usada desde o último descanso.
var nunca_desistir_usado := false
## A passiva do Sol da Vida acabou de salvar este lutador (a batalha avisa).
var resistiu := false


static func criar(dados: Dictionary, jogador: bool) -> Combatente:
	var c := Combatente.new()
	c.id = dados.get("id", "")
	c.nome = dados["nome"]
	c.eh_jogador = jogador
	c.hp_max = dados["hp"]
	c.hp = dados.get("hp_atual", c.hp_max)
	c.mp_max = dados.get("mp", 0)
	c.mp = dados.get("mp_atual", c.mp_max)
	c.ataque = dados["ataque"]
	c.defesa = dados["defesa"]
	c.agilidade = dados["agilidade"]
	c.equipamento = dados.get("equipamento", {}).duplicate()
	for slot in c.equipamento:
		var item: Dictionary = Itens.DADOS.get(c.equipamento[slot], {})
		c.dano_arma += item.get("dano", 0)
		c.defesa += item.get("defesa", 0)
		c.agilidade += item.get("mobilidade", 0)
		if item.has("tipo_arma"):
			c.tipo_arma = item["tipo_arma"]
		if item.has("efeito"):
			c.efeitos_equip.append(item["efeito"])
	c.textura = dados.get("textura", "")
	c.costas = dados.get("costas", "")
	c.habilidades = dados.get("habilidades", []).duplicate()
	c.ataques = dados.get("ataques", [{"nome": "Golpe", "mult": 1.0}]).duplicate(true)
	c.regioes = dados.get("regioes", {})
	c.sangrando = dados.get("sangrando", false)
	c.cargas_solares = dados.get("cargas_solares", 0)
	c.sol = dados.get("sol", "")
	c.nunca_desistir_usado = dados.get("nunca_desistir_usado", false)
	var hp_partes: Dictionary = dados.get("hp_partes", {})
	var decepados: Array = dados.get("decepados", [])
	for p in PARTES:
		var maximo: int = hp_partes.get(p, int(c.hp_max * 0.4))
		c.partes[p] = {"hp": maximo, "hp_max": maximo, "decepado": p in decepados}
	return c


func vivo() -> bool:
	return hp > 0 and not partes["cabeca"]["decepado"]


func decepado(parte: String) -> bool:
	return partes[parte]["decepado"]


func partes_intactas() -> Array:
	var lista := []
	for p in PARTES:
		if not decepado(p):
			lista.append(p)
	return lista


func membros_decepados() -> Array:
	var lista := []
	for p in PARTES:
		if decepado(p):
			lista.append(p)
	return lista


func pode_atacar_com_arma() -> bool:
	return not decepado("braco_dir") or not decepado("braco_esq")


func tem_arma() -> bool:
	return dano_arma > 0 or tipo_arma != ""


func tem_efeito(efeito: String) -> bool:
	return efeito in efeitos_equip


func ataque_efetivo() -> int:
	return maxi(1, roundi(ataque * _penalidade_bracos()))


func _penalidade_bracos() -> float:
	if decepado("braco_dir"):
		return 0.4 if decepado("braco_esq") else 0.6
	elif decepado("braco_esq"):
		return 0.85
	return 1.0


## Dano bruto de um golpe: força + base + arma, com penalidades e bônus.
## Quem ataca sem arma (ou sem braços) usa o golpe desarmado.
func poder_golpe(base := 0, com_arma := true) -> int:
	var valor := float(ataque + base)
	if com_arma and tem_arma() and pode_atacar_com_arma():
		valor += dano_arma
	elif eh_jogador and base == 0:
		valor += DANO_DESARMADO
	valor *= _penalidade_bracos()
	if estados.has("forca"):
		valor *= 1.0 + estados["forca"]["valor"] / 100.0
	return maxi(1, roundi(valor))


func agilidade_efetiva() -> int:
	return 0 if decepado("pernas") else agilidade


func chance_esquiva() -> float:
	if decepado("pernas") or defendendo:
		return 0.0
	return clampf(agilidade_efetiva() * 0.01, 0.0, 0.25)


## Chance de `atacante` acertar `parte` deste combatente (0..1).
func chance_de_ser_acertado(parte: String, precisao := 1.0) -> float:
	var chance: float = CHANCE_PARTE[parte] * precisao - chance_esquiva()
	if decepado("pernas"):
		chance += 0.2
	return clampf(chance, 0.05, 0.98)


## Aplica dano a uma parte. Retorna {acertou, dano, decepou, morreu}.
func receber_golpe(parte: String, dano_bruto: int, rng: RandomNumberGenerator, precisao := 1.0, ignora_esquiva := false) -> Dictionary:
	var resultado := {"acertou": false, "dano": 0, "decepou": false, "morreu": false}
	var chance := 0.98 if ignora_esquiva else chance_de_ser_acertado(parte, precisao)
	if rng.randf() > chance:
		return resultado
	resultado["acertou"] = true
	var reducao := defesa + (DEFESA_BLOQUEIO if defendendo else 0)
	if estados.has("escudo"):
		reducao += estados["escudo"]["valor"]
	var dano := maxi(1, roundi(dano_bruto * (1.0 - mini(reducao, DEFESA_MAXIMA) / 100.0)))
	if defendendo:
		dano = maxi(1, dano / 2)
	resultado["dano"] = dano

	var info: Dictionary = partes[parte]
	if parte != "torso":
		info["hp"] = maxi(0, info["hp"] - dano)
		if info["hp"] == 0 and not info["decepado"]:
			info["decepado"] = true
			sangrando = true
			resultado["decepou"] = true

	hp = maxi(0, hp - int(dano * DANO_NO_CORPO[parte]))
	nunca_desistir()
	resultado["morreu"] = not vivo()
	if resultado["morreu"]:
		hp = 0
	return resultado


## Dano de sangramento no começo do turno. Retorna o dano causado.
func aplicar_sangramento() -> int:
	if not sangrando or not vivo():
		return 0
	var dano := SANGRAMENTO_POR_MEMBRO * maxi(1, membros_decepados().size())
	hp = maxi(0, hp - dano)
	nunca_desistir()
	return dano


## Passiva do Sol da Vida (Nunca desistir): ao chegar a 0 de HP, volta com 1.
## Uma vez por descanso, e não salva de ter a cabeça decepada.
func nunca_desistir() -> void:
	if sol != "vida" or nunca_desistir_usado or hp > 0 or decepado("cabeca"):
		return
	hp = 1
	nunca_desistir_usado = true
	resistiu = true


## Passivas que impedem um estado: Senhor da Peste (Sol da Morte) contra
## doença e Abraça a escuridão (Sol do Medo) contra o medo.
func imune_a(estado: String) -> bool:
	return (sol == "morte" and estado == "veneno") or (sol == "medo" and estado == "medo")


func curar(valor: int) -> int:
	var antes := hp
	hp = mini(hp_max, hp + valor)
	return hp - antes


func descricao_estados() -> String:
	var nomes := []
	for e in estados:
		var t: int = estados[e]["turnos"]
		nomes.append(NOME_ESTADO.get(e, e) + (" %d" % t if t > 0 else ""))
	return ", ".join(nomes)


## Estado da batalha deste lutador, para Retroceder.
func foto() -> Dictionary:
	return {"hp": hp, "mp": mp, "partes": partes.duplicate(true), "sangrando": sangrando,
		"estados": estados.duplicate(true), "defendendo": defendendo, "cargas": cargas_solares,
		"colar": colar_usado}


func restaurar(f: Dictionary) -> void:
	hp = f["hp"]
	mp = f["mp"]
	partes = f["partes"].duplicate(true)
	sangrando = f["sangrando"]
	estados = f["estados"].duplicate(true)
	defendendo = f["defendendo"]
	cargas_solares = f["cargas"]
	colar_usado = f["colar"]


func descricao_membros() -> String:
	var perdidos := membros_decepados()
	if perdidos.is_empty():
		return "Membros intactos"
	var nomes := []
	for p in perdidos:
		nomes.append(NOME_PARTE[p])
	return "Perdeu: " + ", ".join(nomes)


## Volta para o formato de dicionário guardado no Jogo (persistência entre batalhas).
func para_dados(base: Dictionary) -> Dictionary:
	var dados := base.duplicate(true)
	dados["hp_atual"] = hp
	dados["mp_atual"] = mp
	dados["decepados"] = membros_decepados()
	dados["sangrando"] = sangrando
	dados["nunca_desistir_usado"] = nunca_desistir_usado
	return dados
