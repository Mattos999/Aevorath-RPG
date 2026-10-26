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
	# Varia luz, Pedra Solar e tamanho da party para exercitar a regra da magia.
	var luzes := ["escuro", "sol", "lua"]
	for aleatorio in [false, true]:
		for inimigo in ["oco", "cruzado", "sarnheim", "paladino"]:
			for i in 6:
				Jogo.novo_jogo()
				if i % 2 == 1:
					Jogo.recrutar("iselde")
				if i >= 3:
					Jogo.ganhar_pedra_solar()
				Jogo.minutos = 12 * 60 if i % 3 != 2 else 23 * 60
				Jogo.luz_batalha = luzes[i % 3]
				await _jogar_batalha(inimigo, aleatorio)
	print("RESULTADO: %s (%d falhas)" % ["OK" if falhas == 0 else "FALHOU", falhas])
	get_tree().quit(1 if falhas > 0 else 0)


func _checar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		printerr("FALHA: ", mensagem)


func _testar_mapa() -> void:
	var linhas: Array = Mapas.PRISAO["linhas"]
	var inicio := Vector2i(-1, -1)
	var textos := 0
	for y in linhas.size():
		_checar(linhas[y].length() == linhas[0].length(), "linha %d com largura diferente" % y)
		for x in linhas[y].length():
			if linhas[y][x] == "P":
				inicio = Vector2i(x, y)
			if linhas[y][x] in "SK":
				textos += 1
	_checar(textos == Mapas.PRISAO["textos"].size(), "número de placas/esqueletos != textos")
	# Tudo que não é parede precisa ser alcançável a partir do início. Celas
	# trancadas (D) contam como passagem, porque o encapuzado entrega a chave.
	# Objetos e NPCs bloqueiam, mas precisam ter um vizinho alcançável.
	var paredes := "#T|"
	var bloqueios := "BURQKSAHI"
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
			if not (c in bloqueios):
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
