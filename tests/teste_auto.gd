extends Node
## Teste automático (headless): valida o mapa e joga batalhas sozinho.
## Rode: godot --headless res://tests/teste_auto.tscn
## Sai com código 0 se tudo passar, 1 se algo falhar.

const CENA_BATALHA := preload("res://scenes/batalha.tscn")

var falhas := 0


func _ready() -> void:
	_testar_mapa()
	_testar_membros()
	_testar_luz()
	_testar_equipamento()
	await _testar_menu()
	# Varia luz, Pedra Solar e tamanho da party para exercitar a regra da magia.
	var luzes := ["escuro", "sol", "lua"]
	for aleatorio in [false, true]:
		for inimigo in ["oco", "oca", "cruzado", "sarnheim", "paladino"]:
			for i in 6:
				Jogo.novo_jogo()
				if i % 2 == 1:
					Jogo.recrutar("iselde")
				if i >= 3:
					Jogo.ganhar_pedra_solar()
				Jogo.minutos = 12 * 60 if i % 3 != 2 else 23 * 60
				Jogo.luz_batalha = luzes[i % 3]
				if aleatorio and i % 2 == 1:
					_party_de_teste()
				await _jogar_batalha(inimigo, aleatorio)
	print("RESULTADO: %s (%d falhas)" % ["OK" if falhas == 0 else "FALHOU", falhas])
	get_tree().quit(1 if falhas > 0 else 0)


func _checar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		printerr("FALHA: ", mensagem)


func _testar_mapa() -> void:
	var mapa: MapaCena = preload("res://scenes/mapas/prisao.tscn").instantiate()
	add_child(mapa)
	var linhas := mapa.ler_grade()
	var nao_mapeados := 0
	for camada in [mapa.terreno, mapa.entidades]:
		for celula in camada.get_used_cells():
			if MapaCena._letra(camada, celula) == "":
				nao_mapeados += 1
	_checar(nao_mapeados == 0, "%d tiles sem letra no TileSet" % nao_mapeados)
	var inicio := Vector2i(-1, -1)
	var textos := 0
	for y in linhas.size():
		_checar(linhas[y].length() == linhas[0].length(), "linha %d com largura diferente" % y)
		for x in linhas[y].length():
			if linhas[y][x] == "P":
				inicio = Vector2i(x, y)
			if linhas[y][x] in "SK":
				textos += 1
	_checar(textos == mapa.textos.size(), "número de placas/esqueletos != textos")
	mapa.queue_free()
	# Tudo que não é parede precisa ser alcançável a partir do início. Celas
	# trancadas (D) contam como passagem, porque o encapuzado entrega a chave.
	# Objetos e NPCs bloqueiam, mas precisam ter um vizinho alcançável.
	var paredes := "#T|"
	var andaveis := ".,~*dDWXGPCOFNV"
	var visitado := {inicio: true}
	var fila := [inicio]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_front()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + d
			if visitado.has(n) or n.y < 0 or n.y >= linhas.size() or n.x < 0 or n.x >= linhas[n.y].length():
				continue
			var c: String = linhas[n.y][n.x]
			if c in paredes:
				continue
			visitado[n] = true
			if c in andaveis:
				fila.append(n)
	for y in linhas.size():
		for x in linhas[y].length():
			if not (linhas[y][x] in paredes):
				_checar(visitado.has(Vector2i(x, y)), "tile inalcançável em %s" % Vector2i(x, y))
	print("mapa ok")


func _testar_luz() -> void:
	Jogo.novo_jogo()
	_checar(Jogo.forca_magia("escuro") == 0.0, "magia no escuro sem pedra deveria ser 0")
	Jogo.minutos = 12 * 60
	_checar(is_equal_approx(Jogo.forca_magia("sol"), 1.5), "sol ao meio-dia deveria dar 150%")
	Jogo.minutos = 7 * 60
	_checar(Jogo.forca_magia("sol") < 1.0, "sol de manhã deveria ser mais fraco que ao meio-dia")
	Jogo.minutos = 22 * 60
	_checar(Jogo.luz_do_ceu() == "lua", "às 22h a luz do céu deveria ser a lua")
	Jogo.ganhar_pedra_solar()
	_checar(Jogo.forca_magia("escuro") > 0.0, "Pedra Solar deveria permitir magia no escuro")
	var quebrou := false
	for i in Jogo.CARGAS_PEDRA:
		quebrou = Jogo.gastar_carga_solar()
	_checar(quebrou and not Jogo.tem_pedra_solar(), "a pedra deveria quebrar após %d cargas" % Jogo.CARGAS_PEDRA)
	print("luz ok")


func _testar_membros() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var c := Combatente.criar(Inimigos.DADOS["cruzado"], false)
	var ataque_antes := c.ataque_efetivo()
	while not c.decepado("braco_dir"):
		c.receber_golpe("braco_dir", 50, rng, 1.0, true)
	_checar(c.ataque_efetivo() < ataque_antes, "decepar braço da arma não reduziu o ataque")
	_checar(c.sangrando, "decepar não causou sangramento")
	var d := Combatente.criar(Inimigos.DADOS["cruzado"], false)
	d.receber_golpe("pernas", 999, rng, 1.0, true)
	_checar(d.decepado("pernas") and d.agilidade_efetiva() == 0, "pernas decepadas devem zerar agilidade")
	var e := Combatente.criar(Inimigos.DADOS["cruzado"], false)
	e.receber_golpe("cabeca", 999, rng, 1.0, true)
	_checar(not e.vivo(), "cabeça decepada deve matar")
	print("membros ok")


## Dá à party todas as habilidades e equipamentos com efeito, para as
## batalhas aleatórias exercitarem estados, Retroceder, brinco e colar.
func _party_de_teste() -> void:
	var todas := Habilidades.DADOS.keys()
	for membro in Jogo.party:
		membro["habilidades"] = todas
		membro["mp"] = 60
	Jogo.equipar(Jogo.party[0], "brinco_lebre")
	Jogo.equipar(Jogo.party[1], "colar_sol")


func _testar_equipamento() -> void:
	Jogo.novo_jogo()
	var aren: Dictionary = Jogo.party[0]
	var antes := Combatente.criar(aren, true)
	_checar(antes.dano_arma == 2 and antes.tipo_arma == "espada", "Aren deveria começar com a espada enferrujada")
	_checar(Jogo.equipar(aren, "espada_prata"), "equipar espada de prata falhou")
	_checar("espada_enferrujada" in Jogo.inventario, "a arma antiga deveria voltar ao inventário")
	_checar(not Jogo.equipar(aren, "armadura_couro", "arma"), "armadura não pode ir no slot de arma")
	Jogo.equipar(aren, "armadura_couro")
	Jogo.equipar(aren, "bota_couro")
	var depois := Combatente.criar(aren, true)
	_checar(depois.dano_arma == 5 and depois.defesa == 12 and depois.agilidade == antes.agilidade + 1, "bônus de equipamento errados")
	_checar(depois.poder_golpe() > antes.poder_golpe(), "arma melhor deveria dar mais dano")
	var rng := RandomNumberGenerator.new()
	var r := depois.receber_golpe("torso", 100, rng, 1.0, true)
	_checar(r["dano"] == 88, "defesa 12%% deveria cortar 12%% do dano (veio %d)" % r["dano"])
	Jogo.desequipar(aren, "arma")
	var sem_arma := Combatente.criar(aren, true)
	_checar(not sem_arma.tem_arma() and sem_arma.poder_golpe() == aren["ataque"] + Combatente.DANO_DESARMADO, "golpe desarmado = força + 5")
	_checar(Habilidades.impedimento("corte_preciso", sem_arma) != "", "Corte preciso deveria pedir espada")
	Jogo.equipar(aren, "machado_guerra")
	var machado := Combatente.criar(aren, true)
	_checar(Habilidades.impedimento("corte_preciso", machado) != "" and Habilidades.impedimento("golpe_destruidor", machado) == "",
		"machado: sem Corte preciso, com Golpe destruidor")
	_checar(Jogo.equipar(aren, "colar_sol") and Jogo.equipar(aren, "brinco_lebre"), "acessórios deveriam caber")
	_checar(aren["equipamento"].get("acessorio1", "") != "" and aren["equipamento"].get("acessorio2", "") != "", "dois acessórios em slots diferentes")
	print("equipamento ok")


func _testar_menu() -> void:
	Jogo.novo_jogo()
	var menu := MenuJogo.new()
	add_child(menu)
	await get_tree().process_frame
	_checar(menu.grade_itens.get_child_count() > 0, "inventário do menu vazio")
	# Arrastar e soltar: item no slot, depois o slot de volta na lista.
	var slot_arma: Button = null
	for linha in menu.coluna_slots.get_children():
		for filho in linha.get_children():
			if filho is Button and filho.get_meta("slot", "") == "arma":
				slot_arma = filho
	_checar(slot_arma != null, "slot de arma não encontrado")
	menu._equipar("espada_prata", "arma")
	_checar(Jogo.party[0]["equipamento"]["arma"] == "espada_prata", "equipar pelo menu falhou")
	menu._desequipar("arma")
	_checar(not Jogo.party[0]["equipamento"].has("arma"), "desequipar pelo menu falhou")
	menu._selecionar("item:bandagem")
	Jogo.party[0]["hp_atual"] = 30
	menu._usar_selecionado()
	_checar(Jogo.party[0]["hp_atual"] == 40 and Jogo.itens["bandagem"] == 1, "usar bandagem pelo menu falhou")
	for aba in 3:
		menu.abas.current_tab = aba
		await get_tree().process_frame
	_checar(menu.texto_magias.text.contains("Atacar") and menu.texto_atributos.text.contains("Defesa"), "abas sem conteúdo")
	menu.fechar_menu()
	await get_tree().process_frame
	print("menu ok")


## Escolhe a primeira opção habilitada (Atacar -> cabeça) ou, com `aleatorio`,
## qualquer opção, exercitando habilidades, itens e fuga.
func _jogar_batalha(inimigo: String, aleatorio: bool) -> void:
	var batalha := CENA_BATALHA.instantiate()
	batalha.inimigo_id = inimigo
	var resultado := [""]
	batalha.terminou.connect(func(r): resultado[0] = r)
	add_child(batalha)
	Engine.time_scale = 20.0
	var quadros := 0
	while resultado[0] == "" and quadros < 20000:
		await get_tree().process_frame
		quadros += 1
		var botoes := []
		for botao in batalha.menu.get_children():
			if botao is Button and not botao.disabled and not botao.is_queued_for_deletion():
				botoes.append(botao)
		if not botoes.is_empty():
			(botoes.pick_random() if aleatorio else botoes[0]).pressed.emit()
	Engine.time_scale = 1.0
	_checar(resultado[0] in ["vitoria", "derrota", "fuga"], "batalha contra %s não terminou" % inimigo)
	var membros := []
	for m in Jogo.party:
		membros.append("%s %d HP %s" % [m["nome"], m["hp_atual"], m["decepados"]])
	print("%s vs %s [%s, pedra %d]: %s (%d quadros) | %s" % ["aleatório" if aleatorio else "cabeça", inimigo,
		Jogo.luz_batalha, Jogo.cargas_solares(), resultado[0], quadros, ", ".join(membros)])
	batalha.queue_free()
	await get_tree().process_frame
