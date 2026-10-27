class_name Itens
## Itens do jogo. Equipamentos têm "slot" (arma, corpo, pes ou acessorio).
##   dano        soma ao dano dos golpes armados
##   defesa      reduz o dano recebido em % (25 = corta 25% do dano)
##   mobilidade  soma à agilidade (ordem dos turnos e esquiva)
##   tipo_arma   "espada" ou "machado" (algumas técnicas pedem espada)
##   efeito      regra especial (ver Combatente e a batalha)
## Consumíveis têm "uso" e ficam empilhados em Jogo.itens.

## Slots do personagem: 1 arma, 2 armaduras (corpo e pés) e 3 acessórios.
const SLOTS := ["arma", "corpo", "pes", "acessorio1", "acessorio2", "acessorio3"]
const NOME_SLOT := {
	"arma": "Arma", "corpo": "Armadura", "pes": "Calçado",
	"acessorio1": "Acessório 1", "acessorio2": "Acessório 2", "acessorio3": "Acessório 3",
}

const DADOS := {
	"espada_enferrujada": {
		"nome": "Espada enferrujada", "slot": "arma", "tipo_arma": "espada", "dano": 2,
		"descricao": "Mais ferrugem do que fio.",
	},
	"espada_prata": {
		"nome": "Espada de prata", "slot": "arma", "tipo_arma": "espada", "dano": 5,
		"descricao": "Leve e bem equilibrada.",
	},
	"espada_duas_maos": {
		"nome": "Espada de duas mãos", "slot": "arma", "tipo_arma": "espada", "dano": 12,
		"descricao": "Pesada demais para qualquer um.",
	},
	"machado_guerra": {
		"nome": "Machado de guerra", "slot": "arma", "tipo_arma": "machado", "dano": 8,
		"descricao": "Feito para rachar escudos e crânios.",
	},
	"panos_velhos": {
		"nome": "Panos velhos", "slot": "corpo", "defesa": 0,
		"descricao": "Roupa de prisioneiro. Não protege de nada.",
	},
	"armadura_couro": {
		"nome": "Armadura de couro", "slot": "corpo", "defesa": 10,
		"descricao": "Couro curtido e costurado à mão.",
	},
	"armadura_aco": {
		"nome": "Armadura de aço", "slot": "corpo", "defesa": 25,
		"descricao": "Placas de aço de um cruzado caído.",
	},
	"calcados_velhos": {
		"nome": "Calçados velhos", "slot": "pes", "defesa": 0,
		"descricao": "Sola gasta e furada.",
	},
	"bota_couro": {
		"nome": "Bota de couro", "slot": "pes", "defesa": 2, "mobilidade": 1,
		"descricao": "Macia e silenciosa.",
	},
	"bota_aco": {
		"nome": "Bota de aço", "slot": "pes", "defesa": 5, "mobilidade": -1, "efeito": "imune_chao",
		"descricao": "Pesada. Protege de pregos, poças de ácido e fogo no chão.",
	},
	"colar_sol": {
		"nome": "Colar do Sol", "slot": "acessorio", "efeito": "magia_no_escuro",
		"descricao": "Guarda um raio de sol: permite uma magia no escuro por batalha.",
	},
	"brinco_lebre": {
		"nome": "Brinco da Lebre", "slot": "acessorio", "efeito": "ataque_extra",
		"descricao": "Quem o usa ataca duas vezes com a arma.",
	},
	"bandagem": {
		"nome": "Bandagem", "uso": "cura", "cura": 10,
		"descricao": "Recupera 10 HP e estanca o sangramento.",
	},
}


## Slot onde um item pode ir (acessórios cabem em qualquer um dos três).
static func cabe_no_slot(item_id: String, slot: String) -> bool:
	if not DADOS.has(item_id) or not DADOS[item_id].has("slot"):
		return false
	var tipo: String = DADOS[item_id]["slot"]
	return slot == tipo or (tipo == "acessorio" and slot.begins_with("acessorio"))


## Resumo dos números do item, para o menu.
static func resumo(item_id: String) -> String:
	var d: Dictionary = DADOS[item_id]
	var partes := []
	if d.has("dano"):
		partes.append("+%d de dano" % d["dano"])
	if d.has("defesa"):
		partes.append("%d de defesa" % d["defesa"])
	if d.get("mobilidade", 0) != 0:
		partes.append("%+d de mobilidade" % d["mobilidade"])
	if d.has("cura"):
		partes.append("+%d HP" % d["cura"])
	return ", ".join(partes)
