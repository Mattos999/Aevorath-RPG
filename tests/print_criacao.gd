extends Node
## Tira prints da tela de criação e da batalha para mostrar ao Carlos sem abrir o jogo.
## Uso (precisa de vídeo, ex.: xvfb-run): godot --resolution 960x540 res://tests/print_criacao.tscn
## Os prints saem em user://print_criacao_<nome>.jpg (o workflow prints.yml
## copia para tests/prints/).

const CENA_BATALHA := preload("res://scenes/batalha.tscn")


func _ready() -> void:
	# Se algo travar, sai mesmo assim depois de 90 s.
	get_tree().create_timer(90.0).timeout.connect(get_tree().quit.bind(1))
	var tela := CriacaoPersonagem.new()
	add_child(tela)
	for id in ["vida", "medo"]:
		tela._escolher_sol(id)
		await _print("build_" + id)
	# Distribuindo pontos: Esperança, depois um empate (Int 6 x Des 6).
	tela.botoes_modo["pontos"].pressed.emit()
	tela._zerar()
	for par in [["for", 6], ["sor", 6], ["con", 4], ["des", 2], ["conx", 2]]:
		for i in par[1]:
			tela._mudar_ponto(par[0], 1)
	await _print("pontos_esperanca")
	tela._zerar()
	for par in [["int", 6], ["des", 6], ["con", 4], ["sab", 2], ["conx", 2]]:
		for i in par[1]:
			tela._mudar_ponto(par[0], 1)
	await _print("pontos_empate")
	tela._zerar()
	tela._mudar_ponto("con", 1)
	await _print("pontos_vazio")
	tela.queue_free()

	# Batalhas: luz A (sol), B (lua) e C (escuro); no escuro, abre o menu Habilidade.
	for luz in ["sol", "lua", "escuro"]:
		Jogo.novo_jogo("Aren", "masculino", "vida")
		Jogo.minutos = 12 * 60 if luz == "sol" else 23 * 60
		Jogo.luz_batalha = luz
		var batalha := CENA_BATALHA.instantiate()
		batalha.inimigo_id = "cruzado"
		add_child(batalha)
		for i in 90:
			await get_tree().process_frame
		await _print("batalha_" + luz)
		if luz == "escuro":
			for botao in batalha.menu.get_children():
				if botao is Button and botao.text.begins_with("Habilidade"):
					botao.pressed.emit()
			await _print("batalha_habilidade")
		batalha.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _print(nome: String) -> void:
	for i in 30:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_jpg("user://print_criacao_%s.jpg" % nome, 0.9)
	print("print ", nome)
