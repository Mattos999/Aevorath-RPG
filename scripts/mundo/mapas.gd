class_name Mapas
## Mapas em texto. Legenda:
##   #  parede        .  chão          ,  sangue (chão)
##   P  início        A  Altar dos Nove Sóis (descanso)
##   S  placa/texto (na ordem em que aparecem, lendo linha a linha)
##   C  Cruzado       O  Fiel Oco      N  Soldado de Sarnheim
##   X  saída (fim da demo)

const CRIPTA := {
	"nome": "Cripta da Igreja do Décimo Dia",
	"linhas": [
		"####################################",
		"#P...#.........#..........,.......X#",
		"#....#....O....#...........#########",
		"#....#.........#....S......#.......#",
		"#.S..###.#######...........#...C...#",
		"#..........,.........###...#.......#",
		"#....###.######......#A#...###.#####",
		"#....#.........#.....#.#.........N.#",
		"###.##....C....#...........,.......#",
		"#....#.........#####.###########.###",
		"#..,.#....S....#.................O.#",
		"#....#.........#..#######.#######..#",
		"#....###########..#.....#.#........#",
		"#.................#..O..#.#....S...#",
		"#####.#############.....#.#........#",
		"#.........................#........#",
		"####################################",
	],
	"placas": [
		"Você acorda no chão frio da cripta. A Marca em seu peito pulsa em azul.\nOs Cruzados não sabem que você sobreviveu ao Ritual do Meio.",
		"\"No Décimo Dia, os Nove Sóis julgarão os impuros.\nCem serão entregues, para que mil sejam poupados.\"\n— Inscrição da Igreja do Décimo Dia",
		"Um vitral rachado mostra nove sóis. O nono está pintado de preto.\nAlguém riscou embaixo: OSTZHAN NÃO ESTÁ MORTO.",
		"Restos de um Marcado. Nas paredes, marcas de contagem:\n97 ciclos riscados. E um novo, recém-começado.",
	],
}
