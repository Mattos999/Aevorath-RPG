extends Node2D
## Mapa explorável com movimento em grid de 32x32.
## Setas/WASD movem, Z/Espaço/Enter interage com o que está à frente e
## Esc/Tab/I abrem o menu (inventário, magias e personagem).
## O mapa vem de uma cena pintada no editor (MapaCena, em scenes/mapas/).

const TILE := 64
const TEMPO_PASSO := 0.14
const ALCANCE_PERSEGUICAO := 6
const INTERVALO_INIMIGO := 0.45
## Inimigos pintados com letra no TileMap usam este comportamento.
const COMPORTAMENTO_PADRAO := {"comportamento": "perseguir", "alcance": ALCANCE_PERSEGUICAO,
	"intervalo": INTERVALO_INIMIGO, "eixo": Vector2i.RIGHT, "distancia": 3}
## Conversas dos NPCs pintados com letra.
const DIALOGO_ENCAPUZADO := "res://dialogos/encapuzado.dialogue"

const INIMIGO_POR_LETRA := {"C": "cruzado", "O": "oco", "F": "oca", "N": "sarnheim", "V": "paladino"}

const PASSAVEIS := ".,~*dWXG"
## Inimigos não passam por portas nem pela escada.
const PASSAVEIS_INIMIGO := ".,~*"

const DIRECOES := {
	"mover_cima": Vector2i.UP,
	"mover_baixo": Vector2i.DOWN,
	"mover_esquerda": Vector2i.LEFT,
	"mover_direita": Vector2i.RIGHT,
}
const LINHA_FOLHA := {Vector2i.DOWN: 0, Vector2i.LEFT: 1, Vector2i.RIGHT: 2, Vector2i.UP: 3}

@export var cena_mapa: PackedScene = preload("res://scenes/mapas/prisao.tscn")
## Mostra o mapa em 3D (F3 alterna com o 2D durante o jogo).
@export var visao_3d := true

var mapa: MapaCena
var grade: Array[String] = []
var textos: Dictionary = {}  # Vector2i -> texto (placas e esqueletos)
var inimigos: Dictionary = {}  # id -> {no, pos, tipo, passo}
var npcs: Dictionary = {}  # Vector2i -> {no, id}
var pedras_no_chao: Dictionary = {}  # Vector2i -> Sprite2D

var jogador: Sprite2D
var passo_jogador := 0
var pos_jogador := Vector2i.ZERO
var direcao := Vector2i.DOWN
var movendo := false
var bloqueado := false  # diálogo aberto ou batalha começando
var tregua := 0.0  # segundos sem batalha após uma fuga

var hud: Label
var camada_ui: CanvasLayer
var caixa_dialogo: PanelContainer
var texto_dialogo: Label
var nome_dialogo: Label
var retrato_dialogo: TextureRect
var paginas: Array = []
var ao_fim_dialogo: Callable
## Conversa do Dialogue Manager em andamento (null = nenhuma).
var conversa: DialogueResource
var linha_conversa: DialogueLine
var esperando_linha := false
var lista_respostas: VBoxContainer
var resposta_escolhida := 0


func _ready() -> void:
	_carregar_mapa()
	_criar_feixes()
	_criar_interface()
	_atualizar_hud()
	if visao_3d:
		add_child(Visao3D.new(self))


func _carregar_mapa() -> void:
	mapa = cena_mapa.instantiate()
	add_child(mapa)
	mapa.entidades.visible = false
	var indice_texto := 0
	var linhas := mapa.ler_grade()
	for y in linhas.size():
		var linha: String = linhas[y]
		var limpa := ""
		for x in linha.length():
			var c := linha[x]
			var pos := Vector2i(x, y)
			match c:
				"P":
					pos_jogador = pos
					c = "."
				"S", "K":
					textos[pos] = mapa.textos[indice_texto] if indice_texto < mapa.textos.size() else "..."
					indice_texto += 1
				"G":
					if Jogo.eventos.has("pedra_%d_%d" % [x, y]):
						c = "."
					else:
						var pedra := Sprite2D.new()
						pedra.texture = load("res://assets/itens/pedra_solar_48.png")
						pedra.position = Vector2(pos * TILE) + Vector2(TILE, TILE) / 2
						pedra.z_index = 1
						add_child(pedra)
						pedras_no_chao[pos] = pedra
				"H":
					_criar_npc("encapuzado", "res://assets/sprites/encapuzado.png", pos, load(DIALOGO_ENCAPUZADO))
					c = "."
				"D":
					if Jogo.eventos.has("porta_%d_%d" % [x, y]):
						c = "d"
						mapa.trocar_terreno(pos, "d")
				"C", "O", "F", "N", "V":
					var id := "%s_%d_%d" % [c, x, y]
					if not Jogo.inimigos_derrotados.has(id):
						_criar_inimigo(id, INIMIGO_POR_LETRA[c], pos)
					c = "."
			limpa += c
		grade.append(limpa)
	_carregar_entidades()

	jogador = _sprite_de_folha(Jogo.party[0]["folha_mapa"], pos_jogador)
	jogador.z_index = 2

	var camera := Camera2D.new()
	camera.position = Vector2(TILE / 2, TILE / 2)
	camera.limit_left = 0
	camera.limit_top = 0
	# Mapa menor que a tela fica no canto de cima (o HUD usa o espaço de baixo).
	var tela := get_viewport_rect().size
	camera.limit_right = maxi(grade[0].length() * TILE, int(tela.x))
	camera.limit_bottom = maxi(grade.size() * TILE, int(tela.y))
	camera.position_smoothing_enabled = true
	jogador.add_child(camera)


func _sprite_de_folha(caminho: String, pos: Vector2i) -> Sprite2D:
	var no := Sprite2D.new()
	no.texture = load(caminho)
	no.centered = false
	no.position = Vector2(pos * TILE)
	no.z_index = 1
	if no.texture.get_width() == TILE * 3 and no.texture.get_height() == TILE * 4:
		no.hframes = 3
		no.vframes = 4
	add_child(no)
	return no


## Entidades colocadas como nós (Entidade) na cena do mapa.
func _carregar_entidades() -> void:
	for no in mapa.get_children():
		if not no is Entidade:
			continue
		var e: Entidade = no
		var pos := e.celula()
		match e.tipo:
			Entidade.Tipo.INIMIGO:
				var id := "%s_%s" % [mapa.name, e.name]
				if not Jogo.inimigos_derrotados.has(id):
					_criar_inimigo(id, e.inimigo, pos, {"comportamento": e.comportamento,
						"alcance": e.alcance_visao, "intervalo": e.intervalo,
						"eixo": Vector2i.RIGHT if e.direcao_patrulha == "horizontal" else Vector2i.DOWN,
						"distancia": e.distancia_patrulha})
			Entidade.Tipo.NPC:
				if e.some_com_evento == "" or not Jogo.eventos.has(e.some_com_evento):
					_criar_npc(e.id_unico(), e.folha, pos, e.dialogo, e.cue)
			Entidade.Tipo.PEDRA_SOLAR:
				if not Jogo.eventos.has("pedra_%d_%d" % [pos.x, pos.y]):
					_trocar_tile(pos, "G")
					var pedra := Sprite2D.new()
					pedra.texture = load("res://assets/itens/pedra_solar_48.png")
					pedra.position = Vector2(pos * TILE) + Vector2(TILE, TILE) / 2
					pedra.z_index = 1
					add_child(pedra)
					pedras_no_chao[pos] = pedra


func _criar_inimigo(id: String, tipo: String, pos: Vector2i, jeito := COMPORTAMENTO_PADRAO) -> void:
	var dados := {"no": _sprite_de_folha(Inimigos.DADOS[tipo]["sprite_mapa"], pos), "pos": pos,
		"tipo": tipo, "passo": 0, "tempo": 0.0, "origem": pos, "sentido": 1}
	dados.merge(jeito)
	inimigos[id] = dados


func _criar_npc(id: String, folha: String, pos: Vector2i, dialogo: DialogueResource = null, cue := "start") -> void:
	npcs[pos] = {"no": _sprite_de_folha(folha, pos), "id": id, "dialogo": dialogo, "cue": cue}


## Brilho aditivo sobre os feixes de luz.
func _criar_feixes() -> void:
	var feixes := Node2D.new()
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	feixes.material = material
	feixes.z_index = 3
	feixes.draw.connect(func():
		var cor := Color(1.0, 0.82, 0.45, 0.16) if Jogo.eh_dia() else Color(0.55, 0.65, 1.0, 0.12)
		for y in grade.size():
			for x in grade[y].length():
				if grade[y][x] == "*":
					feixes.draw_rect(Rect2(x * TILE + 8, (y - 1) * TILE, TILE - 16, TILE * 2), cor))
	add_child(feixes)
	set_meta("feixes", feixes)


# ---------------------------------------------------------------- Interface

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	camada_ui = camada

	var fundo_hud := PanelContainer.new()
	# Canto inferior esquerdo, crescendo para cima.
	fundo_hud.anchor_top = 1.0
	fundo_hud.anchor_bottom = 1.0
	fundo_hud.offset_left = 8
	fundo_hud.offset_top = -8
	fundo_hud.offset_bottom = -8
	fundo_hud.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fundo_hud.add_theme_stylebox_override("panel", _estilo_painel(Color(0, 0, 0, 0.65)))
	camada.add_child(fundo_hud)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 13)
	fundo_hud.add_child(hud)

	caixa_dialogo = PanelContainer.new()
	caixa_dialogo.position = Vector2(40, 380)
	caixa_dialogo.custom_minimum_size = Vector2(880, 140)
	caixa_dialogo.add_theme_stylebox_override("panel", _estilo_painel(Color(0.05, 0.03, 0.04, 1.0)))
	caixa_dialogo.visible = false
	camada.add_child(caixa_dialogo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	caixa_dialogo.add_child(linha)
	retrato_dialogo = TextureRect.new()
	retrato_dialogo.custom_minimum_size = Vector2(112, 112)
	retrato_dialogo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato_dialogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(retrato_dialogo)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(coluna)
	nome_dialogo = Label.new()
	nome_dialogo.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
	coluna.add_child(nome_dialogo)
	texto_dialogo = Label.new()
	texto_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_dialogo.custom_minimum_size = Vector2(700, 0)
	texto_dialogo.add_theme_font_size_override("font_size", 16)
	coluna.add_child(texto_dialogo)
	lista_respostas = VBoxContainer.new()
	lista_respostas.visible = false
	coluna.add_child(lista_respostas)


static func _estilo_painel(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color(0.45, 0.12, 0.12)
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(10)
	return estilo


func _luz_aqui() -> String:
	if mapa.luz == "aberto" or _tile(pos_jogador) == "*":
		return Jogo.luz_do_ceu()
	return "escuro"


func _atualizar_hud() -> void:
	var nomes_luz := {"sol": "Sob o sol", "lua": "Sob a lua", "escuro": "Escuro"}
	var luz := _luz_aqui()
	var linhas := [mapa.nome, "%s  |  %s" % [Jogo.texto_relogio(), nomes_luz[luz]]]
	if luz != "escuro":
		linhas[1] += " (magia %d%%)" % roundi(Jogo.forca_magia(luz) * 100)
	for membro in Jogo.party:
		var hp: int = membro.get("hp_atual", membro["hp"])
		var mp: int = membro.get("mp_atual", membro["mp"])
		var estado := ""
		if hp <= 0:
			estado = "  (morto)"
		elif membro.get("sangrando", false):
			estado = "  (sangrando)"
		linhas.append("%s  HP %d/%d  MP %d/%d%s" % [membro["nome"], hp, membro["hp"], mp, membro["mp"], estado])
	linhas.append("[Esc] Menu   [F3] 2D/3D")
	var itens := "Bandagens: %d" % Jogo.itens.get("bandagem", 0)
	if Jogo.tem_pedra_solar():
		itens += "   Pedra Solar: %d/%d" % [Jogo.pedras_solares[0], Jogo.CARGAS_PEDRA]
		if Jogo.pedras_solares.size() > 1:
			itens += " (+%d)" % (Jogo.pedras_solares.size() - 1)
	if Jogo.itens.get("chave", 0) > 0:
		itens += "   Chave das celas"
	linhas.append(itens)
	hud.text = "\n".join(linhas)


## Mostra uma sequência de falas. Cada página: texto (String) ou
## {texto, nome, retrato}. `ao_fim` roda quando a última fecha.
func _mostrar_dialogo(conteudo, ao_fim := Callable()) -> void:
	paginas = conteudo if conteudo is Array else [conteudo]
	ao_fim_dialogo = ao_fim
	bloqueado = true
	caixa_dialogo.visible = true
	_mostrar_pagina()


func _mostrar_pagina() -> void:
	var pagina = paginas.pop_front()
	if pagina is String:
		pagina = {"texto": pagina}
	nome_dialogo.text = pagina.get("nome", "")
	nome_dialogo.visible = nome_dialogo.text != ""
	var retrato: String = pagina.get("retrato", "")
	retrato_dialogo.texture = load(retrato) if retrato != "" else null
	retrato_dialogo.visible = retrato != ""
	texto_dialogo.text = pagina["texto"] + "\n[Z]"


func _avancar_dialogo() -> void:
	if not paginas.is_empty():
		_mostrar_pagina()
		return
	caixa_dialogo.visible = false
	bloqueado = false
	if ao_fim_dialogo.is_valid():
		var acao := ao_fim_dialogo
		ao_fim_dialogo = Callable()
		acao.call()


static func _falas(lista: Array, nome: String, retrato: String) -> Array:
	var paginas_ := []
	for texto: String in lista:
		var pagina := {"texto": texto, "nome": nome, "retrato": retrato}
		var dois_pontos := texto.find(": ")
		if dois_pontos > 0 and Mapas.retrato_de(texto.left(dois_pontos)) != "":
			pagina["nome"] = texto.left(dois_pontos)
			pagina["retrato"] = Mapas.retrato_de(pagina["nome"])
			pagina["texto"] = texto.substr(dois_pontos + 2)
		paginas_.append(pagina)
	return paginas_


# ---------------------------------------------------------------- Loop

func _process(delta: float) -> void:
	if conversa != null:
		_controlar_conversa()
		return
	if caixa_dialogo.visible:
		if Input.is_action_just_pressed("interagir"):
			_avancar_dialogo()
		return
	if bloqueado:
		return
	tregua = maxf(0.0, tregua - delta)

	_mover_inimigos(delta)
	if bloqueado:
		return

	if Input.is_action_just_pressed("interagir"):
		_interagir()
		return

	if Input.is_action_just_pressed("menu") and not movendo:
		abrir_menu()
		return

	if movendo:
		return
	for acao in DIRECOES:
		if Input.is_action_pressed(acao):
			_tentar_mover(DIRECOES[acao])
			break


func abrir_menu() -> MenuJogo:
	bloqueado = true
	var menu := MenuJogo.new()
	hud.get_parent().visible = false
	menu.fechado.connect(func():
		bloqueado = false
		hud.get_parent().visible = true
		_atualizar_hud())
	camada_ui.add_child(menu)
	return menu


func _tile(pos: Vector2i) -> String:
	if pos.y < 0 or pos.y >= grade.size() or pos.x < 0 or pos.x >= grade[pos.y].length():
		return "#"
	return grade[pos.y][pos.x]


func _trocar_tile(pos: Vector2i, c: String) -> void:
	var linha := grade[pos.y]
	grade[pos.y] = linha.substr(0, pos.x) + c + linha.substr(pos.x + 1)


func _livre(pos: Vector2i) -> bool:
	return _tile(pos) in PASSAVEIS and not npcs.has(pos)


func _inimigo_em(pos: Vector2i) -> String:
	for id in inimigos:
		if inimigos[id]["pos"] == pos:
			return id
	return ""


func _virar(no: Sprite2D, dir: Vector2i, passo: int) -> void:
	if no.hframes >= 3:
		no.frame = LINHA_FOLHA[dir] * 3 + passo
	elif dir.x != 0:
		no.flip_h = dir == Vector2i.LEFT


func _tentar_mover(dir: Vector2i) -> void:
	direcao = dir
	_virar(jogador, dir, passo_jogador)
	var alvo := pos_jogador + dir
	var inimigo := _inimigo_em(alvo)
	if inimigo != "":
		_encontro(inimigo)
		return
	if not _livre(alvo):
		return
	pos_jogador = alvo
	movendo = true
	passo_jogador = (passo_jogador + 1) % 3
	_virar(jogador, dir, passo_jogador)
	Jogo.passar_tempo()
	var tween := create_tween()
	tween.tween_property(jogador, "position", Vector2(alvo * TILE), TEMPO_PASSO)
	await tween.finished
	movendo = false
	_virar(jogador, dir, 0)
	_atualizar_hud()
	match _tile(pos_jogador):
		"G":
			_pegar_pedra(pos_jogador)
		"X":
			_mostrar_dialogo("A escada sobe para a luz dos Nove Sóis... e para os Cruzados lá fora.\nFim da demonstração. Obrigado por jogar!")


func _pegar_pedra(pos: Vector2i) -> void:
	Jogo.eventos["pedra_%d_%d" % [pos.x, pos.y]] = true
	Jogo.ganhar_pedra_solar()
	if pedras_no_chao.has(pos):
		pedras_no_chao[pos].queue_free()
		pedras_no_chao.erase(pos)
	_trocar_tile(pos, ".")
	_atualizar_hud()
	_mostrar_dialogo({"texto": "Você encontrou uma Pedra Solar. Nove sóis gravados brilham fracos na pedra.",
		"retrato": "res://assets/itens/pedra_solar_96.png"})


func _interagir() -> void:
	var alvo := pos_jogador + direcao
	if npcs.has(alvo):
		_falar_com(alvo)
	elif textos.has(alvo):
		_mostrar_dialogo(textos[alvo])
	else:
		match _tile(alvo):
			"A":
				Jogo.descansar()
				_atualizar_hud()
				_mostrar_dialogo("Você reza diante do Altar dos Nove Sóis. As feridas fecham e o sangue estanca.\nO que foi perdido, porém, não volta.")
			"D":
				if Jogo.itens.get("chave", 0) > 0:
					Jogo.eventos["porta_%d_%d" % [alvo.x, alvo.y]] = true
					_trocar_tile(alvo, "d")
					_animar_porta(alvo)
					_mostrar_dialogo("A chave gira com um rangido. A cela se abre.")
				else:
					_mostrar_dialogo("A porta da cela está trancada.")
			"G":
				_pegar_pedra(alvo)


## Toca a porta da cela abrindo (quadros 4 a 7 da tira) por cima do tile
## fechado e só então troca o tile para a cela aberta.
func _animar_porta(pos: Vector2i) -> void:
	var porta := Sprite2D.new()
	porta.texture = load("res://assets/tiles/cela_porta_anim.png")
	porta.hframes = 8
	porta.frame = 4
	porta.centered = false
	porta.position = Vector2(pos * TILE)
	porta.z_index = 1
	add_child(porta)
	var tween := create_tween()
	tween.tween_property(porta, "frame", 7, 0.45).from(4)
	tween.tween_callback(func() -> void:
		mapa.trocar_terreno(pos, "d")
		porta.queue_free())


func _falar_com(pos: Vector2i) -> void:
	var npc: Dictionary = npcs[pos]
	_virar(npc["no"], -direcao, 0)
	if npc["dialogo"] != null:
		_iniciar_conversa(npc["dialogo"], npc["cue"])
	else:
		_mostrar_dialogo("...")


# ---------------------------------------------------------------- Conversas (Dialogue Manager)
# Os arquivos .dialogue podem chamar estas funções com "$> nome(...)".

## Dá um item ao jogador. Ex.: $> dar_item("chave")
func dar_item(id: String, quantidade := 1) -> void:
	Jogo.itens[id] = Jogo.itens.get(id, 0) + quantidade
	_atualizar_hud()


## Marca que algo aconteceu. Ex.: $> marcar("falou_com_guarda")
## Depois use "if Jogo.eventos.has("falou_com_guarda")" no diálogo.
func marcar(evento: String) -> void:
	Jogo.eventos[evento] = true


func _iniciar_conversa(recurso: DialogueResource, cue: String) -> void:
	conversa = recurso
	bloqueado = true
	_ir_para_linha(cue)


func _ir_para_linha(id: String) -> void:
	esperando_linha = true
	var linha: DialogueLine = await DialogueManager.get_next_dialogue_line(conversa, id, [self])
	esperando_linha = false
	if linha == null:
		_fim_conversa()
		return
	linha_conversa = linha
	resposta_escolhida = 0
	if linha.text == "" and not linha.responses.is_empty():
		# Só as respostas: a fala anterior continua na caixa.
		texto_dialogo.text = texto_dialogo.text.trim_suffix("\n[Z]")
		_mostrar_respostas()
		return
	nome_dialogo.text = linha.character
	nome_dialogo.visible = linha.character != ""
	var retrato := Mapas.retrato_de(linha.character)
	retrato_dialogo.texture = load(retrato) if retrato != "" else null
	retrato_dialogo.visible = retrato != ""
	texto_dialogo.text = linha.text + ("" if not linha.responses.is_empty() else "\n[Z]")
	_mostrar_respostas()
	caixa_dialogo.visible = true


func _mostrar_respostas() -> void:
	for filho in lista_respostas.get_children():
		filho.queue_free()
	lista_respostas.visible = not linha_conversa.responses.is_empty()
	for i in linha_conversa.responses.size():
		var r: DialogueResponse = linha_conversa.responses[i]
		var opcao := Label.new()
		opcao.text = ("► " if i == resposta_escolhida else "   ") + r.text
		opcao.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4) if i == resposta_escolhida else Color(0.75, 0.7, 0.7))
		if not r.is_allowed:
			opcao.modulate = Color(1, 1, 1, 0.4)
		lista_respostas.add_child(opcao)


func _controlar_conversa() -> void:
	if esperando_linha or linha_conversa == null:
		return
	var respostas := linha_conversa.responses
	if respostas.is_empty():
		if Input.is_action_just_pressed("interagir"):
			_ir_para_linha(linha_conversa.next_id)
		return
	if Input.is_action_just_pressed("mover_cima"):
		resposta_escolhida = (resposta_escolhida - 1 + respostas.size()) % respostas.size()
		_mostrar_respostas()
	elif Input.is_action_just_pressed("mover_baixo"):
		resposta_escolhida = (resposta_escolhida + 1) % respostas.size()
		_mostrar_respostas()
	elif Input.is_action_just_pressed("interagir") and respostas[resposta_escolhida].is_allowed:
		_ir_para_linha(respostas[resposta_escolhida].next_id)


func _fim_conversa() -> void:
	conversa = null
	linha_conversa = null
	caixa_dialogo.visible = false
	lista_respostas.visible = false
	bloqueado = false
	_atualizar_hud()


func _mover_inimigos(delta: float) -> void:
	for id in inimigos.keys():
		var dados: Dictionary = inimigos[id]
		dados["tempo"] += delta
		if dados["tempo"] < dados["intervalo"]:
			continue
		dados["tempo"] = 0.0
		for dir in _passos_do_inimigo(dados):
			if dir == Vector2i.ZERO:
				continue
			var alvo: Vector2i = dados["pos"] + dir
			if alvo == pos_jogador:
				if tregua <= 0.0 and not movendo:
					_encontro(id)
					return
				break
			if _tile(alvo) in PASSAVEIS_INIMIGO and not npcs.has(alvo) and _inimigo_em(alvo) == "":
				dados["pos"] = alvo
				dados["passo"] = (dados["passo"] + 1) % 3
				_virar(dados["no"], dir, dados["passo"])
				var tween := create_tween()
				tween.tween_property(dados["no"], "position", Vector2(alvo * TILE), TEMPO_PASSO * 1.5)
				break
			if dados["comportamento"] == "patrulhar":
				dados["sentido"] *= -1


## Direções que o inimigo tenta, em ordem, conforme o comportamento.
func _passos_do_inimigo(dados: Dictionary) -> Array[Vector2i]:
	var pos: Vector2i = dados["pos"]
	var jeito: String = dados["comportamento"]
	if jeito == "parado":
		return []
	var dist := absi(pos.x - pos_jogador.x) + absi(pos.y - pos_jogador.y)
	if jeito in ["perseguir", "patrulhar"] and dist <= dados["alcance"] and tregua <= 0.0:
		var dx := signi(pos_jogador.x - pos.x)
		var dy := signi(pos_jogador.y - pos.y)
		if absi(pos_jogador.x - pos.x) >= absi(pos_jogador.y - pos.y):
			return [Vector2i(dx, 0), Vector2i(0, dy)]
		return [Vector2i(0, dy), Vector2i(dx, 0)]
	if jeito == "patrulhar":
		# Vai e volta pela linha, sem passar da distância a partir da origem.
		var eixo: Vector2i = dados["eixo"]
		var proximo: Vector2i = pos + eixo * dados["sentido"]
		var desvio: Vector2i = proximo - dados["origem"]
		if absi(desvio.x) + absi(desvio.y) > dados["distancia"]:
			dados["sentido"] *= -1
		# Volta para a linha se a perseguição o tirou dela.
		var origem: Vector2i = dados["origem"]
		var fora := Vector2i(origem.x - pos.x, 0) if eixo == Vector2i.DOWN else Vector2i(0, origem.y - pos.y)
		if fora != Vector2i.ZERO:
			return [fora.sign()]
		return [eixo * dados["sentido"]]
	if Jogo.rng.randf() < 0.35:
		return [[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][Jogo.rng.randi() % 4]]
	return []


func _encontro(id: String) -> void:
	if tregua > 0.0:
		return
	bloqueado = true
	Jogo.luz_batalha = _luz_aqui()
	Jogo.fundo_batalha = mapa.fundo_batalha
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2), 0.25)
	await tween.finished
	modulate = Color.WHITE
	Jogo.pedir_batalha(inimigos[id]["tipo"], id)


## Chamado pelo Main quando a batalha termina.
func ao_voltar_da_batalha(id: String, venceu: bool) -> void:
	bloqueado = false
	if venceu and inimigos.has(id):
		inimigos[id]["no"].queue_free()
		inimigos.erase(id)
	else:
		tregua = 3.0
	get_meta("feixes").queue_redraw()
	_atualizar_hud()
