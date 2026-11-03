class_name Itens
## Itens do jogo. Equipamentos têm "slot" (arma, escudo, corpo, pes ou acessorio).
##   dano        soma ao dano dos golpes armados
##   defesa      reduz o dano recebido em % (25 = corta 25% do dano)
##   mobilidade  soma à agilidade (ordem dos turnos e esquiva)
##   tipo_arma   "espada", "machado" ou "adaga" (algumas técnicas pedem espada)
##   maos        2 = arma de duas mãos (golpe pesado, sem escudo)
##   bloqueio    escudo: soma à defesa ao Bloquear (veja Combatente)
##   efeito      regra especial (ver Combatente e a batalha)
## Consumíveis têm "uso" e ficam empilhados em Jogo.itens. Usos:
##   cura      +"cura" HP (com "estanca", para o sangramento)
##   mp        +"mp" MP
##   sanidade  +"sanidade" de sanidade e tira o medo
##   antidoto  cura veneno e doença
##   pedra     +"cargas" na Pedra Solar (ou vira uma pedra nova)
## Nomes e números da demo são provisórios (Carlos vai revisar).

## Slots do personagem: 1 arma, 1 escudo, 2 armaduras (corpo e pés) e 3 acessórios.
const SLOTS := ["arma", "escudo", "corpo", "pes", "acessorio1", "acessorio2", "acessorio3"]
const NOME_SLOT := {
	"arma": "Arma", "escudo": "Escudo", "corpo": "Armadura", "pes": "Calçado",
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
		"nome": "Espada de duas mãos", "slot": "arma", "tipo_arma": "espada", "dano": 12, "maos": 2,
		"descricao": "Pesada demais para qualquer um.",
	},
	"machado_guerra": {
		"nome": "Machado de guerra", "slot": "arma", "tipo_arma": "machado", "dano": 8,
		"descricao": "Feito para rachar escudos e crânios.",
	},
	"escudo_madeira": {
		"nome": "Escudo de madeira", "slot": "escudo", "bloqueio": 3,
		"descricao": "Tábuas pregadas. Aguenta alguns golpes.",
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
	"adaga_osso": {
		"nome": "Adaga de osso", "slot": "arma", "tipo_arma": "adaga", "dano": 3, "mobilidade": 2,
		"descricao": "Lascada de um fêmur. Leve: age antes e esquiva mais.",
	},
	"escudo_ferro": {
		"nome": "Escudo de ferro", "slot": "escudo", "bloqueio": 6, "mobilidade": -1,
		"descricao": "Amassado, com o símbolo dos Nove Sóis raspado.",
	},
	"gibao": {
		"nome": "Gibão acolchoado", "slot": "corpo", "defesa": 6,
		"descricao": "Camadas de pano costuradas. Melhor que nada.",
	},
	"amuleto_rato": {
		"nome": "Amuleto de dente de rato", "slot": "acessorio", "efeito": "critico",
		"descricao": "Dentes amarrados num cordão. +5% de chance de golpe crítico.",
	},
	"bandagem": {
		"nome": "Bandagem", "uso": "cura", "cura": 10, "estanca": true,
		"descricao": "Recupera 10 HP e estanca o sangramento.",
	},
	"erva_amarga": {
		"nome": "Erva amarga", "uso": "cura", "cura": 20,
		"descricao": "Cresce no limo do esgoto. Recupera 20 HP.",
	},
	"agua_benta": {
		"nome": "Água benta", "uso": "mp", "mp": 8,
		"descricao": "Roubada da capela da prisão. Recupera 8 MP.",
	},
	"tonico_lucidez": {
		"nome": "Tônico de lucidez", "uso": "sanidade", "sanidade": 25,
		"descricao": "Amargo e forte. +25 de sanidade e acalma o medo.",
	},
	"antidoto": {
		"nome": "Antídoto de cinza", "uso": "antidoto",
		"descricao": "Cinza de altar misturada em água. Cura veneno e doença.",
	},
	"fragmento_solar": {
		"nome": "Fragmento solar", "uso": "pedra", "cargas": 3,
		"descricao": "Um caco de Pedra Solar. Soma 3 cargas à sua pedra.",
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
	if d.get("maos", 1) == 2:
		partes.append("duas mãos")
	if d.has("bloqueio"):
		partes.append("+%d ao bloquear" % d["bloqueio"])
	if d.has("defesa"):
		partes.append("%d de defesa" % d["defesa"])
	if d.get("mobilidade", 0) != 0:
		partes.append("%+d de mobilidade" % d["mobilidade"])
	if d.has("cura"):
		partes.append("+%d HP" % d["cura"])
	if d.has("mp"):
		partes.append("+%d MP" % d["mp"])
	if d.has("sanidade"):
		partes.append("+%d de sanidade" % d["sanidade"])
	return ", ".join(partes)


## Consumíveis que dá para usar agora (id -> quantidade), na ordem do DADOS.
static func consumiveis() -> Array:
	var lista := []
	for id in DADOS:
		if DADOS[id].has("uso") and Jogo.itens.get(id, 0) > 0:
			lista.append(id)
	return lista
