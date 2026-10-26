extends Control
## Batalha por turnos com mira em membros.
## A ordem de ação é por agilidade. Em cada turno de um membro da party o
## jogador escolhe a ação; ao atacar, escolhe qual membro do inimigo mirar.
##
## Magia segue a regra da luz (Jogo.forca_magia): sob o sol ou a lua funciona;
## no escuro gasta uma carga de Pedra Solar. O inimigo carrega as próprias cargas.

signal terminou(resultado: String)  # "vitoria", "derrota" ou "fuga"
signal _escolha(valor)

const POS_INIMIGO := Vector2(384, 38)
const PAUSA := 0.8
const CHANCE_FUGA := 0.45
## Raio: folha horizontal com 8 quadros de 220x100.
const QUADROS_RAIO := 8
## Ponto da mão do raio do paladino na textura de batalha.
const MAO_RAIO := Vector2(163, 100)
const NOME_LUZ := {"sol": "Sob o sol", "lua": "Sob a lua", "escuro": "No escuro"}

## Peso de cada parte quando o inimigo escolhe onde bater.
const PESO_MIRA_INIMIGO := {"cabeca": 12, "torso": 40, "braco_esq": 16, "braco_dir": 16, "pernas": 16}

var inimigo_id := "cruzado"
var inimigo: Combatente
var party: Array[Combatente] = []
var rng: RandomNumberGenerator
var ativo: Combatente
var destaque := ""  # parte do inimigo destacada na mira
var acabou := false

var sprite_inimigo: TextureRect
var overlay: Control
var barra_inimigo: ProgressBar
var nome_inimigo: Label
var texto_log: Label
var linhas_log: Array[String] = []
var menu: VBoxContainer
var dica: Label
var texto_luz: Label
var luz := "escuro"
var cartoes: Array[Dictionary] = []


func _ready() -> void:
	rng = Jogo.rng
	luz = Jogo.luz_batalha
	inimigo = Combatente.criar(Inimigos.DADOS[inimigo_id], false)
	for dados in Jogo.party:
		party.append(Combatente.criar(dados, true))
	_montar_interface()
	_atualizar_tudo()
	_rodar_batalha()


# ================================================================ Interface

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := TextureRect.new()
	fundo.texture = load(Jogo.fundo_batalha)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	sprite_inimigo = TextureRect.new()
	sprite_inimigo.texture = load(inimigo.textura)
	sprite_inimigo.position = POS_INIMIGO
	add_child(sprite_inimigo)
	overlay = Control.new()
	overlay.size = sprite_inimigo.texture.get_size()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_desenhar_overlay)
	sprite_inimigo.add_child(overlay)

	nome_inimigo = Label.new()
	nome_inimigo.position = Vector2(POS_INIMIGO.x - 104, 0)
	nome_inimigo.size = Vector2(400, 20)
	nome_inimigo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(nome_inimigo)
	barra_inimigo = _barra(Color(0.7, 0.1, 0.1))
	barra_inimigo.position = Vector2(POS_INIMIGO.x, 24)
	barra_inimigo.size = Vector2(192, 10)
	add_child(barra_inimigo)

	texto_luz = Label.new()
	texto_luz.position = Vector2(10, 6)
	texto_luz.add_theme_font_size_override("font_size", 12)
	texto_luz.add_theme_color_override("font_outline_color", Color.BLACK)
	texto_luz.add_theme_constant_override("outline_size", 4)
	add_child(texto_luz)

	var painel_log := _painel(Vector2(10, 298), Vector2(940, 60), Color(0, 0, 0, 0.7))
	add_child(painel_log)
	texto_log = Label.new()
	texto_log.add_theme_font_size_override("font_size", 13)
	texto_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel_log.add_child(texto_log)

	add_child(_painel(Vector2(0, 364), Vector2(960, 176), Color(0.05, 0.03, 0.04, 0.95)))

	dica = Label.new()
	dica.position = Vector2(14, 370)
	dica.size = Vector2(200, 18)
	dica.add_theme_font_size_override("font_size", 11)
	dica.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(dica)

	menu = VBoxContainer.new()
	menu.position = Vector2(14, 392)
	menu.custom_minimum_size = Vector2(200, 0)
	menu.add_theme_constant_override("separation", 1)
	add_child(menu)

	for i in party.size():
		_criar_cartao(party[i], Vector2(230 + i * 365, 374))


func _painel(pos: Vector2, tamanho: Vector2, cor: Color) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.position = pos
	painel.size = tamanho
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color(0.4, 0.1, 0.1)
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(6)
	painel.add_theme_stylebox_override("panel", estilo)
	return painel


func _estilizar_botao(botao: Button) -> void:
	var estados := {
		"normal": [Color(0.1, 0.07, 0.08), Color(0.25, 0.1, 0.1)],
		"hover": [Color(0.3, 0.08, 0.08), Color(0.85, 0.7, 0.3)],
		"focus": [Color(0.3, 0.08, 0.08), Color(0.85, 0.7, 0.3)],
		"pressed": [Color(0.4, 0.1, 0.1), Color(0.85, 0.7, 0.3)],
		"disabled": [Color(0.07, 0.06, 0.06), Color(0.15, 0.1, 0.1)],
	}
	for estado in estados:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = estados[estado][0]
		estilo.border_color = estados[estado][1]
		estilo.set_border_width_all(1)
		estilo.content_margin_left = 8
		estilo.content_margin_right = 8
		estilo.content_margin_top = 3
		estilo.content_margin_bottom = 3
		botao.add_theme_stylebox_override(estado, estilo)
	botao.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.35))


func _barra(cor: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.show_percentage = false
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	var vazio := StyleBoxFlat.new()
	vazio.bg_color = Color(0.12, 0.1, 0.1)
	barra.add_theme_stylebox_override("fill", cheio)
	barra.add_theme_stylebox_override("background", vazio)
	return barra


func _criar_cartao(c: Combatente, pos: Vector2) -> void:
	var painel := _painel(pos, Vector2(355, 140), Color(0.1, 0.07, 0.08))
	add_child(painel)
	var raiz := Control.new()
	painel.add_child(raiz)
	var retrato := TextureRect.new()
	retrato.texture = load(c.textura)
	raiz.add_child(retrato)
	var info := VBoxContainer.new()
	info.position = Vector2(136, 0)
	info.custom_minimum_size = Vector2(200, 0)
	info.add_theme_constant_override("separation", 3)
	raiz.add_child(info)
	var nome := Label.new()
	info.add_child(nome)
	var barra_hp := _barra(Color(0.65, 0.12, 0.12))
	barra_hp.custom_minimum_size = Vector2(200, 10)
	info.add_child(barra_hp)
	var texto_hp := Label.new()
	texto_hp.add_theme_font_size_override("font_size", 12)
	info.add_child(texto_hp)
	var barra_mp := _barra(Color(0.2, 0.45, 0.75))
	barra_mp.custom_minimum_size = Vector2(200, 8)
	info.add_child(barra_mp)
	var estado := Label.new()
	estado.add_theme_font_size_override("font_size", 11)
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	estado.custom_minimum_size = Vector2(200, 0)
	info.add_child(estado)
	cartoes.append({"painel": painel, "retrato": retrato, "nome": nome, "hp": barra_hp,
		"texto_hp": texto_hp, "mp": barra_mp, "estado": estado})


func _atualizar_tudo() -> void:
	nome_inimigo.text = inimigo.nome
	var forca := Jogo.forca_magia(luz)
	var texto := "%s · %s · magia %d%%" % [Jogo.texto_relogio(), NOME_LUZ[luz], roundi(forca * 100)]
	if luz == "escuro":
		texto += (" · Pedra Solar: %d cargas" % Jogo.cargas_solares()) if Jogo.tem_pedra_solar() else " · sem Pedra Solar"
	texto_luz.text = texto
	texto_luz.add_theme_color_override("font_color", Color(1, 0.85, 0.4) if forca > 0 else Color(0.6, 0.55, 0.55))
	barra_inimigo.max_value = inimigo.hp_max
	barra_inimigo.value = inimigo.hp
	overlay.queue_redraw()
	for i in party.size():
		var c := party[i]
		var cartao: Dictionary = cartoes[i]
		cartao["nome"].text = c.nome + ("  ◄" if c == ativo else "")
		cartao["hp"].max_value = c.hp_max
		cartao["hp"].value = c.hp
		cartao["mp"].max_value = maxi(1, c.mp_max)
		cartao["mp"].value = c.mp
		cartao["texto_hp"].text = "HP %d/%d   MP %d/%d" % [c.hp, c.hp_max, c.mp, c.mp_max]
		var estados := [c.descricao_membros()]
		if c.sangrando:
			estados.append("Sangrando")
		if c.defendendo:
			estados.append("Defendendo")
		cartao["estado"].text = "MORTO" if not c.vivo() else " · ".join(estados)
		cartao["retrato"].modulate = Color(0.35, 0.1, 0.1) if not c.vivo() else Color.WHITE
		var estilo: StyleBoxFlat = cartao["painel"].get_theme_stylebox("panel")
		estilo.border_color = Color(0.85, 0.7, 0.3) if c == ativo else Color(0.4, 0.1, 0.1)


func _desenhar_overlay() -> void:
	for parte in inimigo.membros_decepados():
		if parte in inimigo.regioes:
			overlay.draw_rect(inimigo.regioes[parte], Color(0.05, 0, 0, 0.85))
	if destaque != "" and destaque in inimigo.regioes:
		var r: Rect2 = inimigo.regioes[destaque]
		overlay.draw_rect(r, Color(1, 0.15, 0.1, 0.3))
		overlay.draw_rect(r, Color(1, 0.3, 0.2), false, 2.0)


func _registrar(texto: String) -> void:
	linhas_log.append(texto)
	while linhas_log.size() > 3:
		linhas_log.pop_front()
	texto_log.text = "\n".join(linhas_log)
	_atualizar_tudo()


func _pausa(segundos := PAUSA) -> void:
	await get_tree().create_timer(segundos).timeout


func _piscar(no: CanvasItem) -> void:
	var tween := create_tween()
	tween.tween_property(no, "modulate", Color(1, 0.3, 0.3), 0.08)
	tween.tween_property(no, "modulate", Color.WHITE, 0.2)


# ================================================================ Menus

## Mostra opções [{texto, valor, dica?, desabilitado?, parte?}] e espera a escolha.
## Com `pode_voltar`, adiciona "Voltar", que devolve null.
func _menu(opcoes: Array, pode_voltar := false) -> Variant:
	for filho in menu.get_children():
		filho.queue_free()
	var botoes: Array[Button] = []
	if pode_voltar:
		opcoes = opcoes + [{"texto": "Voltar", "valor": null, "dica": ""}]
	for opcao in opcoes:
		var botao := Button.new()
		botao.text = opcao["texto"]
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.add_theme_font_size_override("font_size", 12)
		_estilizar_botao(botao)
		botao.disabled = opcao.get("desabilitado", false)
		botao.pressed.connect(func(): _escolha.emit(opcao["valor"]))
		botao.focus_entered.connect(func():
			dica.text = opcao.get("dica", "")
			destaque = opcao.get("parte", "")
			overlay.queue_redraw())
		if opcao.has("parte"):
			botao.mouse_entered.connect(botao.grab_focus)
		menu.add_child(botao)
		botoes.append(botao)
	for botao in botoes:
		if not botao.disabled:
			botao.grab_focus.call_deferred()
			break
	var valor = await _escolha
	for filho in menu.get_children():
		filho.queue_free()
	dica.text = ""
	destaque = ""
	overlay.queue_redraw()
	return valor


func _input(evento: InputEvent) -> void:
	# Clique direto no membro do inimigo durante a mira.
	if destaque == "" or not (evento is InputEventMouseButton) or not evento.pressed:
		return
	var local: Vector2 = evento.position - POS_INIMIGO
	for parte in inimigo.partes_intactas():
		if inimigo.regioes.has(parte) and inimigo.regioes[parte].has_point(local):
			get_viewport().set_input_as_handled()
			_escolha.emit(parte)
			return


func _menu_mira(atacante: Combatente, precisao := 1.0, ignora_esquiva := false) -> Variant:
	var opcoes := []
	for parte in inimigo.partes_intactas():
		var chance := 0.98 if ignora_esquiva else inimigo.chance_de_ser_acertado(parte, precisao)
		opcoes.append({
			"texto": "%s  (%d%%)" % [Combatente.NOME_PARTE[parte], roundi(chance * 100)],
			"valor": parte,
			"parte": parte,
			"dica": _dica_parte(parte),
		})
	return await _menu(opcoes, true)


func _dica_parte(parte: String) -> String:
	match parte:
		"cabeca": return "Difícil de acertar. Decepar mata."
		"torso": return "Fácil de acertar. Dano extra no corpo."
		"braco_dir": return "Braço da arma. Decepar enfraquece o ataque."
		"braco_esq": return "Decepar os dois braços quase anula o ataque."
		"pernas": return "Decepar impede esquiva e fuga."
	return ""


func _menu_aliado() -> Variant:
	var opcoes := []
	for c in party:
		opcoes.append({"texto": c.nome, "valor": c, "desabilitado": not c.vivo(),
			"dica": "HP %d/%d" % [c.hp, c.hp_max]})
	return await _menu(opcoes, true)


func _escolher_acao(c: Combatente) -> Dictionary:
	while true:
		var principal = await _menu([
			{"texto": "Atacar", "valor": "atacar", "dica": "Golpe com %s." % ("a arma" if c.pode_atacar_com_arma() else "os pés")},
			{"texto": "Habilidade", "valor": "habilidade", "dica": "Magias e técnicas."},
			{"texto": "Item", "valor": "item", "dica": "Bandagens: %d" % Jogo.itens.get("bandagem", 0)},
			{"texto": "Defender", "valor": "defender", "dica": "Metade do dano até o próximo turno."},
			{"texto": "Fugir", "valor": "fugir", "dica": "Impossível sem pernas."},
		])
		match principal:
			"atacar":
				var parte = await _menu_mira(c)
				if parte != null:
					return {"tipo": "atacar", "parte": parte}
			"habilidade":
				var acao := await _escolher_habilidade(c)
				if not acao.is_empty():
					return acao
			"item":
				if Jogo.itens.get("bandagem", 0) <= 0:
					continue
				var alvo = await _menu_aliado()
				if alvo != null:
					return {"tipo": "item", "item": "bandagem", "alvo": alvo}
			"defender":
				return {"tipo": "defender"}
			"fugir":
				return {"tipo": "fugir"}
	return {}


func _escolher_habilidade(c: Combatente) -> Dictionary:
	var opcoes := []
	for hid in c.habilidades:
		var h: Dictionary = Habilidades.DADOS[hid]
		var sem_luz: bool = h.get("magia", false) and Jogo.forca_magia(luz) <= 0.0
		var texto_dica: String = h["descricao"]
		if sem_luz:
			texto_dica = "Sem luz, a magia não responde. Procure um feixe de sol ou uma Pedra Solar."
		elif h.get("magia", false) and luz == "escuro":
			texto_dica += " Gasta 1 carga da Pedra Solar."
		opcoes.append({"texto": "%s (%d MP)" % [h["nome"], h["custo"]], "valor": hid,
			"desabilitado": c.mp < h["custo"] or sem_luz, "dica": texto_dica})
	var hid = await _menu(opcoes, true)
	if hid == null:
		return {}
	var h: Dictionary = Habilidades.DADOS[hid]
	match h["alvo"]:
		"inimigo":
			var parte = await _menu_mira(c, h.get("precisao", 1.0), h.get("ignora_esquiva", false))
			if parte == null:
				return {}
			return {"tipo": "habilidade", "id": hid, "parte": parte}
		"aliado":
			var alvo = await _menu_aliado()
			if alvo == null:
				return {}
			return {"tipo": "habilidade", "id": hid, "alvo": alvo}
	return {"tipo": "habilidade", "id": hid}


# ================================================================ Turnos

func _rodar_batalha() -> void:
	_registrar("%s surge das sombras!" % inimigo.nome)
	await _pausa()
	while not acabou:
		var ordem: Array[Combatente] = []
		for c in party:
			if c.vivo():
				ordem.append(c)
		ordem.append(inimigo)
		ordem.shuffle()
		ordem.sort_custom(func(a, b): return a.agilidade_efetiva() > b.agilidade_efetiva())
		for c in ordem:
			if acabou:
				return
			if not c.vivo():
				continue
			await _turno(c)
			await _verificar_fim()


func _turno(c: Combatente) -> void:
	ativo = c
	c.defendendo = false
	var sangue := c.aplicar_sangramento()
	if sangue > 0:
		_registrar("%s perde %d HP sangrando." % [c.nome, sangue])
		await _pausa(0.6)
		if not c.vivo():
			_registrar("%s sangrou até a morte." % c.nome)
			await _pausa()
			return
	_atualizar_tudo()
	if c.eh_jogador:
		var acao := await _escolher_acao(c)
		await _executar(c, acao)
	else:
		await _turno_inimigo(c)
	ativo = null
	_atualizar_tudo()


func _dano_base(c: Combatente, mult := 1.0) -> int:
	return roundi(c.ataque_efetivo() * mult * rng.randf_range(0.85, 1.15))


func _executar(c: Combatente, acao: Dictionary) -> void:
	match acao["tipo"]:
		"atacar":
			var verbo := "ataca" if c.pode_atacar_com_arma() else "chuta"
			_registrar("%s %s %s." % [c.nome, verbo, _onde(inimigo, acao["parte"])])
			await _pausa(0.5)
			var efeito := ("corte" if rng.randf() < 0.5 else "corte_reto") if c.pode_atacar_com_arma() else "impacto"
			await _golpear(inimigo, acao["parte"], _dano_base(c), 1.0, false, efeito)
		"habilidade":
			var h: Dictionary = Habilidades.DADOS[acao["id"]]
			c.mp -= h["custo"]
			var forca := 1.0
			if h.get("magia", false):
				forca = Jogo.forca_magia(luz)
				if luz == "escuro" and Jogo.gastar_carga_solar():
					_registrar("O último sol gravado na Pedra Solar se apaga. Ela vira pó.")
					await _pausa(0.6)
			_registrar("%s usa %s!" % [c.nome, h["nome"]])
			await _pausa(0.5)
			var efeito: String = h.get("efeito", "")
			match h["alvo"]:
				"inimigo":
					var dano: int
					if h.has("poder"):
						dano = roundi((h["poder"] + rng.randi_range(-2, 4)) * forca)
					else:
						dano = _dano_base(c, h.get("mult", 1.0))
					await _golpear(inimigo, acao["parte"], dano, h.get("precisao", 1.0), h.get("ignora_esquiva", false), efeito)
				"aliado":
					var alvo: Combatente = acao["alvo"]
					_efeito(efeito, _pos_alvo(alvo, "torso"))
					var curado := alvo.curar(roundi(h["cura"] * forca))
					alvo.sangrando = false
					_registrar("%s recupera %d HP. O sangramento para." % [alvo.nome, curado])
				"proprio":
					_efeito(efeito, _pos_alvo(c, "torso"))
					c.defendendo = true
					c.mp = mini(c.mp_max, c.mp + h.get("mp_ganho", 0))
					_registrar("%s firma a postura." % c.nome)
		"item":
			var alvo: Combatente = acao["alvo"]
			Jogo.itens["bandagem"] -= 1
			_efeito("luz", _pos_alvo(alvo, "torso"), 0.7)
			alvo.sangrando = false
			var curado := alvo.curar(10)
			_registrar("%s enfaixa %s: +%d HP, sangramento estancado." % [c.nome, alvo.nome, curado])
		"defender":
			_efeito("bloqueio", _pos_alvo(c, "torso"))
			c.defendendo = true
			_registrar("%s se defende." % c.nome)
		"fugir":
			var chance := CHANCE_FUGA
			for membro in party:
				if membro.vivo() and membro.decepado("pernas"):
					chance = 0.0
			if rng.randf() < chance:
				_registrar("A party foge para a escuridão...")
				await _pausa()
				_encerrar("fuga")
				return
			_registrar("Não há para onde correr!" if chance == 0.0 else "A fuga falhou!")
	await _pausa()


func _turno_inimigo(c: Combatente) -> void:
	var vivos: Array[Combatente] = []
	for membro in party:
		if membro.vivo():
			vivos.append(membro)
	if vivos.is_empty():
		return
	var alvo: Combatente = vivos[rng.randi() % vivos.size()]
	var parte := _sortear_parte(alvo)
	# Magia do inimigo segue a mesma regra da luz, com as Pedras Solares dele.
	var golpes := []
	for g in c.ataques:
		if not g.get("magia", false) or luz != "escuro" or c.cargas_solares > 0:
			golpes.append(g)
	var golpe: Dictionary = golpes[rng.randi() % golpes.size()]
	if not c.pode_atacar_com_arma():
		golpe = {"nome": "Investida desesperada", "mult": 0.8, "efeito": "impacto"}
	var magia: bool = golpe.get("magia", false)
	var dano := _dano_base(c, golpe.get("mult", 1.0))
	if magia:
		var forca := Jogo.forca_magia(luz) if luz != "escuro" else 0.8
		dano = roundi((golpe["poder"] + rng.randi_range(-2, 4)) * forca)
		if luz == "escuro":
			c.cargas_solares -= 1
	_registrar("%s usa %s %s." % [c.nome, golpe["nome"], _onde(alvo, parte)])
	await _pausa(0.5)
	var efeito: String = golpe.get("efeito", "corte")
	if efeito == "raio":
		await _raio(POS_INIMIGO + MAO_RAIO, _pos_alvo(alvo, parte))
		efeito = "faisca"
	await _golpear(alvo, parte, dano, golpe.get("precisao", 1.0), golpe.get("ignora_esquiva", false), efeito)
	if magia and luz == "escuro" and c.cargas_solares == 0:
		await _pausa(0.4)
		_registrar("A Pedra Solar de %s se desfaz em pó." % c.nome)
	await _pausa()


func _sortear_parte(alvo: Combatente) -> String:
	var total := 0
	for p in alvo.partes_intactas():
		total += PESO_MIRA_INIMIGO[p]
	var sorteio := rng.randi_range(1, total)
	for p in alvo.partes_intactas():
		sorteio -= PESO_MIRA_INIMIGO[p]
		if sorteio <= 0:
			return p
	return "torso"


func _onde(alvo: Combatente, parte: String) -> String:
	var nome_alvo := "" if alvo == inimigo else " de " + alvo.nome
	match parte:
		"cabeca": return "na cabeça" + nome_alvo
		"torso": return "no torso" + nome_alvo
		"braco_esq": return "no braço esquerdo" + nome_alvo
		"braco_dir": return "no braço direito" + nome_alvo
		"pernas": return "nas pernas" + nome_alvo
	return ""


func _golpear(alvo: Combatente, parte: String, dano: int, precisao := 1.0, ignora_esquiva := false, efeito := "corte") -> void:
	var r := alvo.receber_golpe(parte, dano, rng, precisao, ignora_esquiva)
	var pos := _pos_alvo(alvo, parte)
	if not r["acertou"]:
		_efeito("impacto", pos + Vector2(rng.randf_range(-40, 40), -20), 0.5, 0.45)
		_registrar("Errou!")
		return
	_efeito(efeito, pos)
	if r["decepou"]:
		_efeito("faisca", pos, 1.3)
	_piscar(sprite_inimigo if alvo == inimigo else cartoes[party.find(alvo)]["painel"])
	_registrar("%d de dano em %s." % [r["dano"], alvo.nome])
	if r["decepou"]:
		await _pausa(0.5)
		if parte == "cabeca":
			_registrar("A cabeça de %s é arrancada!" % alvo.nome)
		else:
			_registrar("%s de %s foi decepado! O sangue jorra." % [Combatente.NOME_PARTE[parte], alvo.nome])
	if r["morreu"] and parte != "cabeca":
		await _pausa(0.5)
		_registrar("%s cai." % alvo.nome)


# ================================================================ Efeitos

## Posição na tela de uma parte do inimigo, ou do retrato de um membro da party.
func _pos_alvo(alvo: Combatente, parte: String) -> Vector2:
	if alvo == inimigo:
		if parte in inimigo.regioes:
			var r: Rect2 = inimigo.regioes[parte]
			return POS_INIMIGO + r.get_center()
		return POS_INIMIGO + sprite_inimigo.texture.get_size() / 2
	var painel: Control = cartoes[party.find(alvo)]["painel"]
	return painel.position + Vector2(70, 70)


func _material_aditivo() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


## Efeito de golpe ou magia: brilho aditivo que cresce e some.
func _efeito(nome: String, pos: Vector2, escala := 1.0, opacidade := 1.0) -> void:
	var caminho := "res://assets/efeitos/%s.png" % nome
	if nome == "" or not ResourceLoader.exists(caminho):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(caminho)
	sprite.material = _material_aditivo()
	sprite.position = pos
	sprite.scale = Vector2.ONE * escala * 0.7
	sprite.rotation = rng.randf_range(-0.3, 0.3)
	sprite.modulate.a = opacidade
	add_child(sprite)
	var tween := sprite.create_tween()
	tween.set_parallel()
	tween.tween_property(sprite, "scale", Vector2.ONE * escala * 1.1, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tween.chain().tween_callback(sprite.queue_free)


## Raio animado, esticado de `de` até `ate`, com clarões na tela.
func _raio(de: Vector2, ate: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/efeitos/raio.png")
	sprite.hframes = QUADROS_RAIO
	sprite.centered = false
	sprite.offset = Vector2(0, -50)
	sprite.material = _material_aditivo()
	sprite.position = de
	sprite.rotation = (ate - de).angle()
	sprite.scale = Vector2(de.distance_to(ate) / 220.0, 1.0)
	add_child(sprite)
	var clarao := ColorRect.new()
	clarao.color = Color(1, 0.95, 0.6, 0.0)
	clarao.set_anchors_preset(Control.PRESET_FULL_RECT)
	clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clarao)
	for i in QUADROS_RAIO * 2:
		sprite.frame = i % QUADROS_RAIO
		clarao.color.a = 0.18 if i % 3 == 0 else 0.0
		await _pausa(0.05)
	sprite.queue_free()
	clarao.queue_free()


func _verificar_fim() -> void:
	if acabou:
		return
	if not inimigo.vivo():
		_registrar("Vitória. Os Nove Sóis assistem em silêncio.")
		await _pausa(1.2)
		_encerrar("vitoria")
		return
	for c in party:
		if c.vivo():
			return
	_registrar("A party inteira caiu...")
	await _pausa(1.2)
	_encerrar("derrota")


func _encerrar(resultado: String) -> void:
	if acabou:
		return
	acabou = true
	for i in party.size():
		Jogo.party[i] = party[i].para_dados(Jogo.party[i])
	terminou.emit(resultado)
