extends Node
## Troca entre o mapa (Mundo) e a batalha. O Mundo fica guardado fora da
## árvore durante a batalha para manter posições e inimigos.

const CENA_MUNDO := preload("res://scenes/mundo.tscn")
const CENA_BATALHA := preload("res://scenes/batalha.tscn")

var mundo: Node
var batalha: Node


func _ready() -> void:
	Jogo.batalha_pedida.connect(_iniciar_batalha)
	var args := OS.get_cmdline_user_args()
	if "--batalha" in args:
		# Atalho de teste: godot -- --batalha [cruzado|oco]
		var idx := args.find("--batalha")
		var inimigo := args[idx + 1] if args.size() > idx + 1 else "cruzado"
		mundo = CENA_MUNDO.instantiate()
		_iniciar_batalha(inimigo, "")
	else:
		_ir_para_mundo()


func _ir_para_mundo() -> void:
	if mundo == null:
		mundo = CENA_MUNDO.instantiate()
	add_child(mundo)


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


func _mostrar_fim_de_jogo() -> void:
	var tela := ColorRect.new()
	tela.color = Color.BLACK
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	var texto := Label.new()
	texto.text = "Sua chama se apaga como a de Ostzhan.\nO Ciclo continua sem você.\n\n[Z / Enter] Recomeçar"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_color_override("font_color", Color(0.75, 0.15, 0.15))
	texto.add_theme_font_size_override("font_size", 24)
	tela.add_child(texto)
	add_child(tela)
	await get_tree().create_timer(0.6).timeout
	while not Input.is_action_just_pressed("interagir"):
		await get_tree().process_frame
	tela.queue_free()
	_ir_para_mundo()


func _exit_tree() -> void:
	if mundo != null and not mundo.is_inside_tree():
		mundo.free()
