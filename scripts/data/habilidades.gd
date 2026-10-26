class_name Habilidades
## Habilidades da party. "alvo": "inimigo" mira um membro; "aliado" escolhe um
## membro da party; "proprio" age no usuário. "magia": true segue a regra da
## luz (ver Jogo.forca_magia); técnicas físicas funcionam em qualquer lugar.
## "efeito" é o nome de um arquivo em assets/efeitos/.

const DADOS := {
	"lampejo": {
		"nome": "Lampejo do Sol Apagado",
		"descricao": "Fogo negro de Ostzhan. Não pode ser esquivado.",
		"custo": 6,
		"alvo": "inimigo",
		"poder": 16,
		"ignora_esquiva": true,
		"magia": true,
		"efeito": "fogo",
	},
	"sigilo_vida": {
		"nome": "Sigilo de Vida",
		"descricao": "Um círculo com o glifo do Sol da Vida. Cura e estanca sangramento.",
		"custo": 5,
		"alvo": "aliado",
		"cura": 22,
		"magia": true,
		"efeito": "luz",
	},
	"golpe_brutal": {
		"nome": "Golpe Brutal",
		"descricao": "Dano alto, precisão baixa.",
		"custo": 3,
		"alvo": "inimigo",
		"mult": 1.8,
		"precisao": 0.7,
		"efeito": "faisca",
	},
	"proteger": {
		"nome": "Postura de Ferro",
		"descricao": "Defende e recupera 2 MP.",
		"custo": 0,
		"alvo": "proprio",
		"mp_ganho": 2,
		"efeito": "bloqueio",
	},
}
