extends Node
## Tira prints da demo para mostrar ao Carlos sem abrir o jogo.
## Uso (precisa de vídeo, ex.: xvfb-run): godot --resolution 960x540 res://tests/print_criacao.tscn
## Os prints saem em user://print_criacao_<nome>.jpg (o workflow prints.yml
## copia para tests/prints/).

const CENA_BATALHA := preload("res://scenes/batalha.tscn")
const CENA_MUNDO := preload("res://scenes/mundo.tscn")


func _ready() -> void:
	# Se algo travar, sai mesmo assim depois de 110 s.
	get_tree().create_timer(110.0).timeout.connect(get_tree().quit.bind(1))
	var titulo := TelaTitulo.new()
	add_child(titulo)
	await _print("titulo", 40)
	titulo.queue_free()

	# Esgotos, em 3D (como no jogo) e em 2D.
	Jogo.novo_jogo("Aren", "masculino", "morte")
	Jogo.ganhar_pedra_solar()
	Jogo.mapa_atual = "res://scenes/mapas/esgoto.tscn"
	for tres_d in [true, false]:
		var m = CENA_MUNDO.instantiate()
		m.visao_3d = tres_d
		add_child(m)
		await _print("esgoto_3d" if tres_d else "esgoto_2d", 40)
		if not tres_d:
			# Perto do encapuzado e do chefe.
			m.pos_jogador = Vector2i(12, 13)
			m.jogador.position = Vector2(m.pos_jogador * 64)
			await _print("esgoto_chefe", 40)
		m.queue_free()
		await get_tree().process_frame

	await _batalha("rato", "escuro", "batalha_rato")
	await _batalha("barata", "escuro", "batalha_barata", true)
	Jogo.recrutar_encapuzado()
	await _batalha("chefe", "escuro", "batalha_chefe")
	get_tree().quit()


func _batalha(inimigo: String, luz: String, nome: String, menu_habilidade := false) -> void:
	Jogo.luz_batalha = luz
	Jogo.fundo_batalha = "res://assets/batalha/fundo_esgoto.png"
	var batalha := CENA_BATALHA.instantiate()
	batalha.inimigo_id = inimigo
	add_child(batalha)
	# Espera chegar a vez do jogador (o menu aparece).
	for i in 400:
		await get_tree().process_frame
		if batalha.menu.get_child_count() > 0 and not batalha.menu.get_child(0).is_queued_for_deletion():
			break
	await _print(nome)
	if menu_habilidade:
		for botao in batalha.menu.get_children():
			if botao is Button and botao.text.begins_with("Habilidade"):
				botao.pressed.emit()
		await _print(nome + "_habilidades")
		for botao in batalha.menu.get_children():
			if botao is Button and botao.text.begins_with("Mais"):
				botao.pressed.emit()
		await _print(nome + "_habilidades2")
	batalha.queue_free()
	await get_tree().process_frame


func _print(nome: String, quadros := 30) -> void:
	for i in quadros:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_jpg("user://print_criacao_%s.jpg" % nome, 0.9)
	print("print ", nome)
