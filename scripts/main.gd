extends Node
## Troca entre a tela de título, a criação de personagem, o mapa (Mundo) e a
## batalha. O Mundo fica guardado fora da árvore durante a batalha para manter
## posições e inimigos. A escada troca o mapa (Jogo.mapa_pedido) e vencer o
## chefe dos esgotos encerra a demo.

const CENA_MUNDO := preload("res://scenes/mundo.tscn")
const CENA_BATALHA := preload("res://scenes/batalha.tscn")

var mundo: Node
var batalha: Node


func _ready() -> void:
	Jogo.batalha_pedida.connect(_iniciar_batalha)
	Jogo.mapa_pedido.connect(_trocar_mapa)
	Jogo.titulo_pedido.connect(_voltar_ao_titulo)
	var args := OS.get_cmdline_user_args()
	if "--batalha" in args:
		# Atalho de teste: godot -- --batalha [cruzado|oco|rato|barata|chefe]
		var idx := args.find("--batalha")
		var inimigo := args[idx + 1] if args.size() > idx + 1 else "cruzado"
		mundo = CENA_MUNDO.instantiate()
		_iniciar_batalha(inimigo, "")
	elif "--esgoto" in args:
		# Atalho de teste: começa direto nos esgotos.
		Jogo.novo_jogo()
		Jogo.ganhar_pedra_solar()
		Jogo.mapa_atual = "res://scenes/mapas/esgoto.tscn"
		_ir_para_mundo()
	else:
		_mostrar_titulo()


func _mostrar_titulo() -> void:
	var tela := TelaTitulo.new()
	tela.comecar.connect(_criar_personagem)
	add_child(tela)


## Tela de criação; ao confirmar, começa um jogo novo com o personagem escolhido.
func _criar_personagem() -> void:
	var tela := CriacaoPersonagem.new()
	tela.concluida.connect(func(nome: String, sexo: String, sol: String, atributos: Dictionary) -> void:
		Jogo.novo_jogo(nome, sexo, sol, atributos)
		_ir_para_mundo())
	add_child(tela)


func _ir_para_mundo() -> void:
	if mundo == null:
		mundo = CENA_MUNDO.instantiate()
	add_child(mundo)


## A escada levou a outro mapa: o Mundo é montado de novo com ele.
func _trocar_mapa(_cena: String) -> void:
	if mundo != null:
		mundo.queue_free()
		mundo = null
	await get_tree().process_frame
	_ir_para_mundo()


func _voltar_ao_titulo() -> void:
	for filho in get_children():
		filho.queue_free()
	mundo = null
	batalha = null
	Jogo.novo_jogo()
	_mostrar_titulo()


func _iniciar_batalha(inimigo_id: String, id_no_mapa: String) -> void:
	if mundo.is_inside_tree():
		remove_child(mundo)
	batalha = CENA_BATALHA.instantiate()
	batalha.inimigo_id = inimigo_id
	batalha.terminou.connect(_fim_batalha.bind(id_no_mapa))
	add_child(batalha)


func _fim_batalha(resultado: String, id_no_mapa: String) -> void:
	batalha.queue_free()
	batalha = null
	match resultado:
		"vitoria":
			if id_no_mapa != "":
				Jogo.inimigos_derrotados[id_no_mapa] = true
			if Jogo.eventos.has("chefe_derrotado"):
				mundo.free()
				mundo = null
				_mostrar_fim_da_demo()
				return
			_ir_para_mundo()
			mundo.ao_voltar_da_batalha(id_no_mapa, true)
		"fuga":
			_ir_para_mundo()
			mundo.ao_voltar_da_batalha(id_no_mapa, false)
		"derrota":
			Jogo.novo_jogo()
			mundo.queue_free()
			mundo = null
			_mostrar_fim_de_jogo()


## Tela preta com texto; Z/Enter continua.
func _tela_de_texto(texto: String, cor: Color) -> void:
	var tela := ColorRect.new()
	tela.color = Color.BLACK
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.size = get_viewport().get_visible_rect().size
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo.size = tela.size
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", 22)
	tela.add_child(rotulo)
	add_child(tela)
	await get_tree().create_timer(0.6).timeout
	while not Input.is_action_just_pressed("interagir"):
		await get_tree().process_frame
	tela.queue_free()


func _mostrar_fim_de_jogo() -> void:
	await _tela_de_texto("Sua chama se apaga como a de Ostzhan.\nO Ciclo continua sem você.\n\n[Z / Enter] Voltar ao título",
		Color(0.75, 0.15, 0.15))
	_mostrar_titulo()


func _mostrar_fim_da_demo() -> void:
	await _tela_de_texto(("O Inquisidor cai na água suja do esgoto.\n" +
		"O encapuzado limpa a lâmina e aponta para uma grade no teto, onde entra a luz do dia.\n\n" +
		"\"Ainda não acabou. A Igreja vai mandar mais. Mas hoje, você viu o sol de novo.\"\n\n\n" +
		"FIM DA DEMO\nObrigado por jogar Aevorath!\n\n[Z / Enter] Voltar ao título"),
		Color(0.9, 0.78, 0.45))
	Jogo.novo_jogo()
	_mostrar_titulo()


func _exit_tree() -> void:
	if mundo != null and not mundo.is_inside_tree():
		mundo.free()
