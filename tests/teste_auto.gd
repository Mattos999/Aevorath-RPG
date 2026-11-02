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
	_testar_atributos()
	_testar_equipamento()
	await _testar_menu()
	await _testar_mundo()
	await _testar_esgoto()
	_testar_magias()
	await _testar_criacao()
	# Varia Sol, luz, Pedra Solar e tamanho da party para exercitar a regra da magia.
	var luzes := ["escuro", "sol", "lua"]
	var sois := Habilidades.SOIS_INICIAIS.keys()
	var n := 0
	for aleatorio in [false, true]:
		for inimigo in ["oco", "oca", "cruzado", "sarnheim", "paladino", "rato", "barata", "chefe"]:
			for i in 6:
				n += 1
				Jogo.novo_jogo("Teste", "masculino" if n % 2 == 0 else "feminino", sois[n % sois.size()])
				if i % 2 == 1:
					Jogo.party.append(Jogo.criar_heroi("Segundo", "feminino", sois[(n + 3) % sois.size()]))
				elif inimigo == "chefe":
					Jogo.recrutar_encapuzado()
				Jogo.itens.merge({"erva_amarga": 1, "agua_benta": 1, "tonico_lucidez": 1, "antidoto": 1, "fragmento_solar": 1})
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


## Esgotos: entidades, itens no chão, o encapuzado entrando na party e o chefe.
func _testar_esgoto() -> void:
	Jogo.novo_jogo()
	Jogo.mapa_atual = "res://scenes/mapas/esgoto.tscn"
	var m = load("res://scenes/mundo.tscn").instantiate()
	m.visao_3d = false
	add_child(m)
	await get_tree().process_frame
	_checar(m.mapa.name == "Esgoto", "deveria carregar o mapa dos esgotos")
	var tipos := {}
	for id in m.inimigos:
		tipos[m.inimigos[id]["tipo"]] = tipos.get(m.inimigos[id]["tipo"], 0) + 1
	_checar(tipos.get("rato", 0) >= 3 and tipos.get("barata", 0) >= 3 and tipos.get("chefe", 0) == 1,
		"inimigos dos esgotos: %s" % tipos)
	_checar(m.itens_no_chao.size() >= 5, "itens no chão: %d" % m.itens_no_chao.size())
	for linha in m.grade:
		for c in linha:
			_checar(c in "#.,~*wJGTAKSRQWXdD|BUo", "letra desconhecida no esgoto: %s" % c)
	# Pegar um item no chão.
	var pos: Vector2i = m.itens_no_chao.keys()[0]
	var item: String = m.itens_no_chao[pos]["item"]
	var antes: int = Jogo.itens.get(item, 0) + Jogo.inventario.count(item)
	m._pegar_item(pos)
	m._avancar_dialogo()
	_checar(Jogo.itens.get(item, 0) + Jogo.inventario.count(item) > antes and not m.itens_no_chao.has(pos), "pegar item falhou")
	# O encapuzado entra na party e some do mapa.
	var npc_pos := Vector2i(-1, -1)
	for p in m.npcs:
		if m.npcs[p]["id"] == "encapuzado_esgoto":
			npc_pos = p
	_checar(npc_pos != Vector2i(-1, -1), "o encapuzado deveria estar nos esgotos")
	if npc_pos != Vector2i(-1, -1):
		await _conversar(m, m.npcs[npc_pos])
	_checar(Jogo.party.size() == 2 and Jogo.party[1]["id"] == "encapuzado", "o encapuzado deveria entrar na party")
	_checar(not m.npcs.has(npc_pos), "o encapuzado deveria sair do mapa")
	m.queue_free()
	await get_tree().process_frame
	# Ao recarregar o mapa ele não volta.
	var m2 = load("res://scenes/mundo.tscn").instantiate()
	m2.visao_3d = false
	add_child(m2)
	await get_tree().process_frame
	for p in m2.npcs:
		_checar(m2.npcs[p]["id"] != "encapuzado_esgoto", "o encapuzado voltou ao mapa")
	m2.queue_free()
	Jogo.mapa_atual = Jogo.MAPA_INICIAL
	print("esgoto ok")


## Magias novas e sanidade, sem rodar a batalha inteira.
func _testar_magias() -> void:
	for sol in Habilidades.MAGIAS_POR_SOL:
		for hid in Habilidades.MAGIAS_POR_SOL[sol]:
			_checar(Habilidades.DADOS.has(hid), "magia %s ainda não existe" % hid)
	var rng := RandomNumberGenerator.new()
	var h := Combatente.criar(Jogo.criar_heroi("A", "masculino", "alma"), true)
	_checar(h.sanidade == Combatente.SANIDADE_MAXIMA, "sanidade inicial")
	_checar(h.perder_sanidade(30) == 30 and h.sanidade == 70, "perder sanidade")
	h.estados["projetado"] = {"turnos": 2, "valor": 0}
	_checar(not h.receber_golpe("torso", 50, rng, 1.0, true)["acertou"], "Projeção deveria fazer o golpe atravessar")
	h.estados.clear()
	h.estados["previsto"] = {"turnos": -1, "valor": 0}
	_checar(not h.receber_golpe("torso", 50, rng, 1.0, true)["acertou"] and not h.estados.has("previsto"),
		"Visualizar desvia uma vez")
	var alvo := Combatente.criar(Inimigos.DADOS["rato"], false)
	var normal := alvo.chance_de_ser_acertado("cabeca")
	alvo.estados["exposto"] = {"turnos": 3, "valor": 0}
	_checar(alvo.chance_de_ser_acertado("cabeca") > normal, "Ouija deveria expor o inimigo")
	var dados: Dictionary = h.para_dados(Jogo.criar_heroi("A", "masculino", "alma"))
	_checar(dados["sanidade_atual"] == 70, "sanidade deveria ser guardada")
	Jogo.novo_jogo()
	Jogo.itens["fragmento_solar"] = 1
	Jogo.usar_item(Jogo.party[0], "fragmento_solar")
	_checar(Jogo.cargas_solares() == 3, "fragmento solar sem pedra vira pedra de 3")
	print("magias ok")


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
	tela.concluida.connect(func(nome, sexo, sol, at): escolha.assign([nome, sexo, sol, at]))
	tela.botoes_sexo["feminino"].pressed.emit()
	_checar(tela.campo_nome.text == "Iselde", "nome padrão deveria seguir o sexo")
	tela.campo_nome.text = "  Lyra "
	tela.botoes_sol["verde"].pressed.emit()
	tela.comecar()
	_checar(escolha.slice(0, 3) == ["Lyra", "feminino", "verde"] and escolha[3] == Atributos.BUILD_SOL["verde"],
		"criação devolveu %s" % [escolha])
	# Modo de pontos: o Sol segue os atributos; sem pontos gastos não começa.
	tela.botoes_modo["pontos"].pressed.emit()
	tela._zerar()
	_checar(tela.sol == "" and tela.botao_comecar.disabled, "sem pontos não deveria ter Sol nem poder começar")
	for i in 8:
		tela._mudar_ponto("int", 1)
	tela._mudar_ponto("int", 1)
	_checar(tela.atributos["int"] == Atributos.MAXIMO and tela.sol == "morte", "8 de Inteligência deveria dar o Sol da Morte")
	for a in ["for", "sor"]:
		for i in 6:
			tela._mudar_ponto(a, 1)
	_checar(Atributos.gastos(tela.atributos) == Atributos.PONTOS, "deveria ter gastado os 20 pontos")
	tela._mudar_ponto("con", 1)
	_checar(tela.atributos["con"] == 0, "não deveria passar de 20 pontos")
	# Int 8 x For+Sor 12: Esperança ganha pela soma.
	_checar(tela.sol == "esperanca" and not tela.botao_comecar.disabled, "For 6 + Sor 6 deveria dar Esperança (veio %s)" % tela.sol)
	tela.comecar()
	_checar(escolha[2] == "esperanca" and escolha[3]["int"] == 8, "criação por pontos devolveu %s" % [escolha])
	tela.queue_free()
	Jogo.novo_jogo(escolha[0], escolha[1], "verde")
	var heroi: Dictionary = Jogo.party[0]
	_checar(Jogo.party.size() == 1 and heroi["nome"] == "Lyra" and not heroi.has("classe"), "party errada: %s" % [heroi])
	_checar(heroi["folha_mapa"].ends_with("protagonista2.png") and "corte_preciso" in heroi["habilidades"], "arte ou técnicas erradas")
	_checar(heroi["sol"] == "verde" and "emaranhar" in heroi["habilidades"] and "cura_natureza" in heroi["habilidades"],
		"o Sol da Natureza deveria dar Cura da natureza e Emaranhar")
	for hid in Jogo.HEROI_BASE["habilidades"]:
		_checar(Habilidades.DADOS.has(hid), "técnica inicial %s não existe" % hid)
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
	# Passivas: Nunca desistir (Vida) salva uma vez por descanso; Morte e Medo dão imunidade.
	var rng := RandomNumberGenerator.new()
	var vida := Combatente.criar(Jogo.criar_heroi("V", "masculino", "vida"), true)
	vida.receber_golpe("torso", 999, rng, 1.0, true)
	_checar(vida.hp == 1 and vida.resistiu, "Nunca desistir deveria deixar com 1 HP")
	vida.receber_golpe("torso", 999, rng, 1.0, true)
	_checar(not vida.vivo(), "Nunca desistir só vale uma vez")
	_checar(vida.para_dados({})["nunca_desistir_usado"], "o uso da passiva deveria ficar guardado até descansar")
	var morte := Combatente.criar(Jogo.criar_heroi("M", "masculino", "morte"), true)
	_checar(morte.imune_a("veneno") and not morte.imune_a("medo"), "Senhor da Peste: imune só a doença")
	print("criação ok")


## Atributos: cada build cai no próprio Sol, empates e status.
func _testar_atributos() -> void:
	for sol in Atributos.BUILD_SOL:
		var at: Dictionary = Atributos.BUILD_SOL[sol]
		_checar(Atributos.gastos(at) == Atributos.PONTOS, "build de %s não soma %d" % [sol, Atributos.PONTOS])
		_checar(Atributos.sois_que_combinam(at) == [sol], "build de %s cai em %s" % [sol, Atributos.sois_que_combinam(at)])
	var empate := Atributos.vazio()
	empate["int"] = 6
	empate["des"] = 6
	var combina := Atributos.sois_que_combinam(empate)
	_checar(combina.size() == 2 and "morte" in combina and "tempo" in combina, "Int 6 e Des 6 deveriam empatar: %s" % [combina])
	var natureza := Atributos.vazio()
	natureza["con"] = 7
	natureza["sab"] = 2
	_checar(Atributos.sois_que_combinam(natureza) == ["verde"], "Con alta e Sab baixa deveria dar Natureza")
	natureza["sab"] = 5
	_checar(Atributos.sois_que_combinam(natureza) == ["vida"], "Con e Sab altas deveriam dar Vida")
	var h := Jogo.criar_heroi("A", "masculino", "medo")
	_checar(h["hp"] == 45 + 4 * 5 and h["ataque"] == 4 + 7 and h["atributos"]["for"] == 7, "status do Medo errados: %s" % [h])
	var c := Combatente.criar(Jogo.criar_heroi("B", "masculino", "alma"), true)
	_checar(c.mult_magia() > 1.0, "Conexão 7 deveria fortalecer a magia")
	print("atributos ok")


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


const INVENTARIO_TESTE := ["espada_prata", "machado_guerra", "espada_duas_maos", "escudo_madeira",
	"armadura_couro", "bota_couro", "colar_sol", "brinco_lebre"]


func _testar_equipamento() -> void:
	Jogo.novo_jogo()
	Jogo.inventario.assign(INVENTARIO_TESTE)
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
	Jogo.inventario.assign(INVENTARIO_TESTE)
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
