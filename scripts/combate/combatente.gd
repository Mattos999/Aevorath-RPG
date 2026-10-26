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

var id: String
var nome: String
var eh_jogador: bool
var hp_max: int
var hp: int
var mp_max: int
var mp: int
var ataque: int
var defesa: int
var agilidade: int
var textura: String
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
	c.textura = dados.get("textura", "")
	c.habilidades = dados.get("habilidades", []).duplicate()
	c.ataques = dados.get("ataques", [{"nome": "Golpe", "mult": 1.0}]).duplicate(true)
	c.regioes = dados.get("regioes", {})
	c.sangrando = dados.get("sangrando", false)
	c.cargas_solares = dados.get("cargas_solares", 0)
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


func ataque_efetivo() -> int:
	var valor := float(ataque)
	if decepado("braco_dir"):
		valor *= 0.4 if decepado("braco_esq") else 0.6
	elif decepado("braco_esq"):
		valor *= 0.85
	return maxi(1, int(valor))


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
	var dano := maxi(1, dano_bruto - defesa)
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
	return dano


func curar(valor: int) -> int:
	var antes := hp
	hp = mini(hp_max, hp + valor)
	return hp - antes


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
	return dados
