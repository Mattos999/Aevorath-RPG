class_name Atributos
## Atributos do protagonista e a ligação deles com os Sóis (Carlos, 2026-11-02).
##
## Na criação o jogador pega a build pronta de um Sol ou distribui PONTOS
## entre os sete atributos (no máximo MAXIMO em cada). Distribuindo, o jogo
## liga o personagem ao Sol que mais combina:
## - Cada Sol pede um ou dois atributos (SOL_ATRIBUTOS), todos com pelo menos
##   MINIMO_SOL pontos. Sóis de dois atributos só valem com os dois altos;
##   senão decide o atributo mais alto sozinho (ex.: muita Constituição e
##   pouca Sabedoria vai para a Natureza; as duas altas, para a Vida).
## - Entre os Sóis que valem, ganha a maior soma dos atributos pedidos. Em
##   empate, o jogador escolhe.
## Depois de criado, o Sol não muda sozinho.

const ORDEM := ["con", "for", "des", "int", "sab", "sor", "conx"]

const NOME := {
	"con": "Constituição", "for": "Força", "des": "Destreza", "int": "Inteligência",
	"sab": "Sabedoria", "sor": "Sorte", "conx": "Conexão",
}

const SIGLA := {
	"con": "Con", "for": "For", "des": "Des", "int": "Int", "sab": "Sab", "sor": "Sor", "conx": "Conx",
}

const EFEITO := {
	"con": "+4 HP por ponto.",
	"for": "+1 de dano nos golpes.",
	"des": "Age antes e esquiva mais.",
	"int": "Dano das magias +5%, MP.",
	"sab": "Cura das magias +5%, MP.",
	"sor": "Crítico +2% por ponto.",
	"conx": "Força de todas as magias.",
}

const PONTOS := 20
const MAXIMO := 8
const MINIMO_SOL := 4

const SOL_ATRIBUTOS := {
	"vida": ["con", "sab"], "morte": ["int"], "alma": ["conx"], "tempo": ["des"],
	"verde": ["con"], "coracao": ["sor", "conx"], "esperanca": ["for", "sor"], "medo": ["for"],
}

## Build pronta de cada Sol (20 pontos). Cada uma cai no próprio Sol pela regra acima.
const BUILD_SOL := {
	"vida": {"con": 6, "for": 2, "des": 2, "int": 1, "sab": 6, "sor": 1, "conx": 2},
	"morte": {"con": 3, "for": 2, "des": 2, "int": 7, "sab": 2, "sor": 1, "conx": 3},
	"alma": {"con": 3, "for": 1, "des": 2, "int": 3, "sab": 3, "sor": 1, "conx": 7},
	"tempo": {"con": 3, "for": 2, "des": 7, "int": 3, "sab": 1, "sor": 1, "conx": 3},
	"verde": {"con": 7, "for": 3, "des": 3, "int": 1, "sab": 2, "sor": 1, "conx": 3},
	"coracao": {"con": 3, "for": 1, "des": 2, "int": 1, "sab": 1, "sor": 6, "conx": 6},
	"esperanca": {"con": 4, "for": 6, "des": 2, "int": 0, "sab": 0, "sor": 6, "conx": 2},
	"medo": {"con": 5, "for": 7, "des": 3, "int": 1, "sab": 1, "sor": 1, "conx": 2},
}


static func vazio() -> Dictionary:
	var at := {}
	for a in ORDEM:
		at[a] = 0
	return at


static func gastos(at: Dictionary) -> int:
	var total := 0
	for a in ORDEM:
		total += int(at.get(a, 0))
	return total


## Sóis que mais combinam com os atributos (mais de um = empate).
static func sois_que_combinam(at: Dictionary) -> Array:
	var melhores: Array = []
	var melhor := -1
	for sol in SOL_ATRIBUTOS:
		var pedidos: Array = SOL_ATRIBUTOS[sol]
		var soma := 0
		var vale := true
		for a in pedidos:
			soma += int(at.get(a, 0))
			if int(at.get(a, 0)) < MINIMO_SOL:
				vale = false
		if not vale:
			continue
		if soma > melhor:
			melhor = soma
			melhores = [sol]
		elif soma == melhor:
			melhores.append(sol)
	return melhores


## Atributos usados pelo Sol, em texto: "Constituição e Sabedoria".
static func texto_foco(sol: String) -> String:
	var nomes := []
	for a in SOL_ATRIBUTOS.get(sol, []):
		nomes.append(NOME[a])
	return " e ".join(nomes)


## "Con 6 · For 2 · ..."
static func texto_curto(at: Dictionary) -> String:
	var partes := []
	for a in ORDEM:
		partes.append("%s %d" % [SIGLA[a], int(at.get(a, 0))])
	return " · ".join(partes)


## Status de combate que saem dos atributos. Com 5 de Con, 4 de For, 4 de
## Des e 3+3 de Int/Sab dá o mesmo herói de antes (HP 65, força 8...).
static func status(at: Dictionary) -> Dictionary:
	return {
		"hp": 45 + 4 * int(at.get("con", 0)),
		"mp": 8 + int(at.get("int", 0)) + int(at.get("sab", 0)),
		"ataque": 4 + int(at.get("for", 0)),
		"agilidade": 6 + int(at.get("des", 0)),
	}


## Conexão com os Sóis multiplica a força da magia (junto com a luz).
## 5 pontos = 100%; cada ponto vale 8%.
static func mult_conexao(at: Dictionary) -> float:
	if at.is_empty():
		return 1.0
	return 0.6 + 0.08 * int(at.get("conx", 0))


static func mult_dano_magico(at: Dictionary) -> float:
	return 1.0 + 0.05 * int(at.get("int", 0))


static func mult_cura(at: Dictionary) -> float:
	return 1.0 + 0.05 * int(at.get("sab", 0))


static func chance_critico(at: Dictionary) -> float:
	return 0.02 * int(at.get("sor", 0))
