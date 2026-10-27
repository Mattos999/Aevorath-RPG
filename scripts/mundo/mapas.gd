class_name Mapas
## Falas e retratos usados nos mapas. Os mapas em si são cenas pintadas no
## editor, em scenes/mapas/ (veja scripts/mundo/mapa_cena.gd).

const RETRATO_ENCAPUZADO := "res://assets/batalha/retrato_encapuzado.png"
const RETRATO_ISELDE := "res://assets/batalha/retrato_protagonista2.png"

## Quem pode falar num diálogo. Comece uma fala com "Nome: " para trocar quem
## fala, por exemplo "Aren: Quem é você?". Sem nome, fala o dono da conversa.
const FALANTES := {
	"Aren": "res://assets/batalha/retrato_protagonista.png",
	"Iselde": RETRATO_ISELDE,
	"???": RETRATO_ENCAPUZADO,
	"Encapuzado": RETRATO_ENCAPUZADO,
}

## Falas do encapuzado na primeira conversa (ele entrega a chave e a Pedra Solar).
const FALAS_ENCAPUZADO := [
	"Quieto. Se os guardas ouvirem, nós dois viramos oferenda no Ritual do Meio.",
	"Aren: Quem é você? Por que está me ajudando?",
	"Não importa agora. Tome: a chave das celas.",
	"E isto: uma Pedra Solar. Aqui embaixo, longe do sol, a magia está morta. A pedra guarda um pouco de luz.\nNove sóis gravados, nove usos. Quando o último apagar, ela vira pó.",
	"Procure os feixes de luz que entram pelas grades do teto. Dentro deles a luz é de verdade, e a magia também.",
	"A garota da terceira cela é Marcada. Leve-a com você. A escada fica depois da sala da guarda.",
]
const FALA_ENCAPUZADO_DEPOIS := "Vá. Eu não posso sair daqui... ainda."

const FALAS_ISELDE := [
	"Você... abriu a cela? Eu achei que só iam abrir no Décimo Dia.",
	"Eu sou Iselde. Eles me trouxeram porque a Marca apareceu no meu braço.",
	"Se você vai fugir, eu vou junto. Sob a luz, eu ainda sei acender um sol.",
]
