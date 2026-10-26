class_name Mapas
## Mapas em texto. Legenda:
##   #  parede          T  parede com tocha    |  grade de cela
##   D  cela trancada   d  cela aberta         W  porta de madeira
##   .  chão            ,  sangue              ~  chão rachado
##   *  feixe de luz (sol de dia, lua à noite: magia funciona aqui)
##   B  cama   U  balde   R  barril   Q  caixa   (objetos, bloqueiam)
##   A  Altar dos Nove Sóis (descanso)
##   S  placa   K  esqueleto   (textos, na ordem em que aparecem lendo linha a linha)
##   G  Pedra Solar no chão
##   P  início do jogador
##   H  o encapuzado (NPC)   I  Iselde presa (entra na party)
##   C  Cruzado   O  Fiel Oco   N  Soldado de Sarnheim   V  Paladino
##   X  escada (fim da demo)
##
## "luz": "escuro" para masmorras, "aberto" para lugares sob o céu.

const PRISAO := {
	"nome": "Prisão da Igreja do Décimo Dia",
	"luz": "escuro",
	"fundo_batalha": "res://assets/batalha/fundo_prisao.png",
	"linhas": [
		"##############################",
		"#B..#.K..#B..#.....#..RQ...VX#",
		"#.P.#..G.#.I.#..*..#........##",
		"#H..#..,.#...#.***.#....N...##",
		"##D###D###|D|##.*.###.####.###",
		"T...........~.......,........T",
		"#.....O...........*..........#",
		"#..~......,........C.........#",
		"###W#######.######.#####.#####",
		"#S....A..#....~.#..U..#.....R#",
		"#........W......#.....W..*..Q#",
		"#..,.....#...,..#.K...#.....R#",
		"##############################",
	],
	"textos": [
		"Ossos de um prisioneiro antigo. Entre as costelas, algo brilha em laranja.",
		"\"No Décimo Dia, os Nove Sóis julgarão os impuros.\nCem serão entregues, para que mil sejam poupados.\"\n— Inscrição da Igreja do Décimo Dia",
		"Restos de um Marcado. Nas paredes, marcas de contagem:\n97 ciclos riscados. E um novo, recém-começado.",
	],
}

const RETRATO_ENCAPUZADO := "res://assets/batalha/retrato_encapuzado.png"
const RETRATO_ISELDE := "res://assets/batalha/retrato_protagonista2.png"

## Falas do encapuzado na primeira conversa (ele entrega a chave e a Pedra Solar).
const FALAS_ENCAPUZADO := [
	"Quieto. Se os guardas ouvirem, nós dois viramos oferenda no Ritual do Meio.",
	"Tome. A chave das celas.",
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
