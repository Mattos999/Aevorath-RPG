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
	await _testar_mundo()
	await _testar_criacao()
	# Varia classe, luz, Pedra Solar e tamanho da party para exercitar a regra da magia.
	var luzes := ["escuro", "sol", "lua"]
	var classes := Jogo.CLASSES.keys()
	var n := 0
	for aleatorio in [false, true]:
		for inimigo in ["oco", "oca", "cruzado", "sarnheim", "paladino"]:
			for i in 6:
				n += 1
				var sois := Habilidades.SOIS_INICIAIS.keys()
				Jogo.novo_jogo("Teste", "masculino" if n % 2 == 0 else "feminino", classes[n % classes.size()], sois[n % sois.size()])
				if i % 2 == 1:
					Jogo.party.append(Jogo.criar_heroi("Segundo", "feminino", classes[(n + 1) % classes.size()], sois[(n + 3) % sois.size()]))
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


## Entidades do mapa, conversas do Dialogue Manager e comportamentos.
func _testar_mundo() -> void:
	Jogo.novo_jogo()
	var m = load("res://scenes/mundo.tscn").instantiate()
	m.visao_3d = false
	add_child(m)
	await get_tree().process_frame
	var ids := {}
	for pos in m.npcs:
		ids[m.npcs[pos]["id"]] = pos
	_checar(ids.has("encapuzado") and not ids.has("iselde"), "NPCs do mapa errados: %s" % [ids.keys()])
	_checar(m.pedras_no_chao.size() == 1, "a Pedra Solar do chão não carregou")
	var jeitos := {}
	for id in m.inimigos:
		jeitos[m.inimigos[id]["tipo"]] = m.inimigos[id]["comportamento"]
	_checar(jeitos.get("sarnheim") == "patrulhar" and jeitos.get("paladino") == "parado", "comportamentos errados: %s" % jeitos)

	await _conversar(m, m.npcs[ids["encapuzado"]])
	_checar(Jogo.itens.get("chave", 0) == 1 and Jogo.tem_pedra_solar(), "o encapuzado deveria dar a chave e a pedra")
	_checar(Jogo.eventos.has("encapuzado"), "evento do encapuzado não marcado")

	# Longe do jogador: o paladino não sai do lugar e a patrulha fica na linha.
	m.pos_jogador = Vector2i(-50, -50)
	for id in m.inimigos:
		var d: Dictionary = m.inimigos[id]
		var origem: Vector2i = d["origem"]
		for i in 30:
			m._mover_inimigos(10.0)
			var desvio: Vector2i = d["pos"] - origem
			if d["comportamento"] == "parado":
				_checar(d["pos"] == origem, "inimigo parado andou")
			elif d["comportamento"] == "patrulhar":
				_checar(absi(desvio.x) + absi(desvio.y) <= d["distancia"] and desvio.y == 0, "patrulha saiu da linha: %s" % desvio)
	m.queue_free()
	print("mundo ok")


## Lê uma conversa inteira escolhendo sempre a primeira resposta.
## Retorna os nomes de quem falou.
func _conversar(m, npc: Dictionary) -> Array:
	var falantes := []
	m._iniciar_conversa(npc["dialogo"], npc["cue"])
	var passos := 0
	while m.conversa != null and passos < 100:
		passos += 1
		await get_tree().process_frame
		if m.esperando_linha or m.linha_conversa == null:
			continue
		var linha: DialogueLine = m.linha_conversa
		if not linha.character in falantes:
			falantes.append(linha.character)
		m._ir_para_linha(linha.responses[0].next_id if not linha.responses.is_empty() else linha.next_id)
	_checar(m.conversa == null, "conversa não terminou")
	return falantes


## Tela de criação: o personagem escolhido vira a party (só ele) e aparece
## nos diálogos com o nome dado.
func _testar_criacao() -> void:
	var tela := CriacaoPersonagem.new()
	add_child(tela)
	var escolha := []
	tela.concluida.connect(func(nome, sexo, classe, sol): escolha.assign([nome, sexo, classe, sol]))
	tela.botoes_sexo["feminino"].pressed.emit()
	_checar(tela.campo_nome.text == "Iselde", "nome padrão deveria seguir o sexo")
	tela.campo_nome.text = "  Lyra "
	tela.botoes_classe["bruxo"].pressed.emit()
	tela.botoes_sol["verde"].pressed.emit()
	tela.comecar()
	_checar(escolha == ["Lyra", "feminino", "bruxo", "verde"], "criação devolveu %s" % [escolha])
	Jogo.novo_jogo(escolha[0], escolha[1], escolha[2], escolha[3])
	var heroi: Dictionary = Jogo.party[0]
	_checar(Jogo.party.size() == 1 and heroi["nome"] == "Lyra" and heroi["classe"] == "Bruxo", "party errada: %s" % [heroi])
	_checar(heroi["folha_mapa"].ends_with("protagonista2.png") and "sangria" in heroi["habilidades"], "arte ou magias erradas")
	_checar(heroi["sol"] == "verde" and "emaranhar" in heroi["habilidades"], "o Sol Verde deveria dar Emaranhar")
	for id in Jogo.CLASSES:
		for hid in Jogo.CLASSES[id]["habilidades"]:
			_checar(Habilidades.DADOS.has(hid), "habilidade %s da classe %s não existe" % [hid, id])
	var m = load("res://scenes/mundo.tscn").instantiate()
	m.visao_3d = false
	add_child(m)
	await get_tree().process_frame
	for pos in m.npcs:
		if m.npcs[pos]["id"] == "encapuzado":
			var falantes: Array = await _conversar(m, m.npcs[pos])
			_checar("Lyra" in falantes, "o diálogo deveria usar o nome escolhido: %s" % [falantes])
			_checar(Mapas.retrato_de("Lyra") == heroi["textura"], "retrato do protagonista no diálogo")
	m.queue_free()
	# Magia de sangue: funciona no escuro sem Pedra Solar e custa HP.
	var b := CENA_BATALHA.instantiate()
	b.inimigo_id = "oco"
	Jogo.luz_batalha = "escuro"
	add_child(b)
	var bruxo: Combatente = b.party[0]
	var hp_antes := bruxo.hp
	var cargas := Jogo.cargas_solares()
	await b._usar_habilidade(bruxo, {"id": "sangria", "parte": "torso"})
	_checar(bruxo.hp == hp_antes - 6, "Sangria deveria custar 6 HP")
	_checar(Jogo.cargas_solares() == cargas, "sangria não deveria gastar a Pedra Solar")
	b.queue_free()
	await get_tree().process_frame
	# Passivas: Nunca desistir (Vida) salva uma vez por descanso; Morte e Medo dão imunidade.
	var rng := RandomNumberGenerator.new()
	var vida := Combatente.criar(Jogo.criar_heroi("V", "masculino", "guerreiro", "vida"), true)
	vida.receber_golpe("torso", 999, rng, 1.0, true)
	_checar(vida.hp == 1 and vida.resistiu, "Nunca desistir deveria deixar com 1 HP")
	vida.receber_golpe("torso", 999, rng, 1.0, true)
	_checar(not vida.vivo(), "Nunca desistir só vale uma vez")
	_checar(vida.para_dados({})["nunca_desistir_usado"], "o uso da passiva deveria ficar guardado até descansar")
	var morte := Combatente.criar(Jogo.criar_heroi("M", "masculino", "mago", "morte"), true)
	_checar(morte.imune_a("veneno") and not morte.imune_a("medo"), "Senhor da Peste: imune só a doença")
	print("criação ok")


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
	Jogo.inventario.append_array(["brinco_lebre", "colar_sol"])
	Jogo.equipar(Jogo.party[0], "brinco_lebre")
	Jogo.equipar(Jogo.party[-1], "colar_sol")


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
	# Mesmo ignorando a esquiva há 2% de erro: tenta até acertar.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var r := depois.receber_golpe("torso", 100, rng, 1.0, true)
	while not r["acertou"]:
		r = depois.receber_golpe("torso", 100, rng, 1.0, true)
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
