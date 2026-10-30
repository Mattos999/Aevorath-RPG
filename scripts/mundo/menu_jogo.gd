class_name MenuJogo
extends Control
## Menu do mapa (Esc, Tab ou I): Inventário, Magias e habilidades, Personagem.
## No inventário, arraste o item até um slot (ou clique no item e em Equipar).
## Arrastar um slot de volta para a lista de itens desequipa.

signal fechado

const COR_FUNDO := Color(0.06, 0.04, 0.05)
const COR_BORDA := Color(0.45, 0.12, 0.12)
const COR_OURO := Color(0.85, 0.7, 0.3)
const COR_APAGADO := Color(0.55, 0.5, 0.5)

var membro_idx := 0
var selecionado := ""  # item ("item:<id>") ou slot ("slot:<slot>") escolhido no inventário

var abas: TabContainer
var botoes_membro: HBoxContainer
var coluna_slots: VBoxContainer
var grade_itens: GridContainer
var lista_itens: PanelContainer
var detalhe_nome: Label
var detalhe_texto: Label
var botao_equipar: Button
var botao_desequipar: Button
var botao_usar: Button
var aviso: Label
var texto_magias: RichTextLabel
var retrato: TextureRect
var texto_atributos: RichTextLabel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var painel := PanelContainer.new()
	painel.position = Vector2(30, 20)
	painel.size = Vector2(900, 500)
	painel.add_theme_stylebox_override("panel", _estilo(COR_FUNDO, COR_BORDA))
	add_child(painel)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	painel.add_child(raiz)

	var topo := HBoxContainer.new()
	raiz.add_child(topo)
	var titulo := Label.new()
	titulo.text = "Menu"
	titulo.add_theme_color_override("font_color", COR_OURO)
	titulo.add_theme_font_size_override("font_size", 18)
	topo.add_child(titulo)
	botoes_membro = HBoxContainer.new()
	botoes_membro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botoes_membro.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.add_child(botoes_membro)
	var fechar := _botao("Fechar [Esc]")
	fechar.pressed.connect(fechar_menu)
	topo.add_child(fechar)

	abas = TabContainer.new()
	abas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(abas)
	abas.add_child(_aba_inventario())
	abas.add_child(_aba_magias())
	abas.add_child(_aba_personagem())
	abas.tab_changed.connect(func(_i): atualizar())
	atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu") or evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar_menu()


func fechar_menu() -> void:
	fechado.emit()
	queue_free()


func membro() -> Dictionary:
	return Jogo.party[membro_idx]


# ---------------------------------------------------------------- Estilo

static func _estilo(cor: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(8)
	return estilo


static func _botao(texto: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 13)
	for estado in ["normal", "hover", "focus", "pressed", "disabled"]:
		var cor := Color(0.12, 0.08, 0.09)
		var borda := Color(0.3, 0.12, 0.12)
		if estado in ["hover", "focus", "pressed"]:
			cor = Color(0.3, 0.08, 0.08)
			borda = COR_OURO
		var estilo := _estilo(cor, borda)
		estilo.set_border_width_all(1)
		estilo.set_content_margin_all(5)
		botao.add_theme_stylebox_override(estado, estilo)
	botao.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.35))
	return botao


func _titulo(texto: String) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_color_override("font_color", COR_OURO)
	return label


# ---------------------------------------------------------------- Inventário

func _aba_inventario() -> Control:
	var aba := HBoxContainer.new()
	aba.name = "Inventário"
	aba.add_theme_constant_override("separation", 12)

	var esquerda := VBoxContainer.new()
	esquerda.custom_minimum_size = Vector2(270, 0)
	esquerda.add_child(_titulo("Equipado"))
	coluna_slots = VBoxContainer.new()
	coluna_slots.add_theme_constant_override("separation", 4)
	esquerda.add_child(coluna_slots)
	aba.add_child(esquerda)

	var meio := VBoxContainer.new()
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meio.add_child(_titulo("Itens (arraste até um slot)"))
	lista_itens = PanelContainer.new()
	lista_itens.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lista_itens.add_theme_stylebox_override("panel", _estilo(Color(0.09, 0.06, 0.07), Color(0.25, 0.1, 0.1)))
	# Soltar um slot aqui desequipa.
	lista_itens.set_drag_forwarding(Callable(),
		func(_pos, dados): return dados is Dictionary and dados.has("slot"),
		func(_pos, dados): _desequipar(dados["slot"]))
	meio.add_child(lista_itens)
	var rolagem := ScrollContainer.new()
	rolagem.mouse_filter = Control.MOUSE_FILTER_PASS
	lista_itens.add_child(rolagem)
	grade_itens = GridContainer.new()
	grade_itens.columns = 2
	grade_itens.add_theme_constant_override("h_separation", 6)
	grade_itens.add_theme_constant_override("v_separation", 6)
	rolagem.add_child(grade_itens)
	aba.add_child(meio)

	var direita := VBoxContainer.new()
	direita.custom_minimum_size = Vector2(230, 0)
	direita.add_theme_constant_override("separation", 6)
	detalhe_nome = _titulo("")
	direita.add_child(detalhe_nome)
	detalhe_texto = Label.new()
	detalhe_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe_texto.custom_minimum_size = Vector2(230, 0)
	detalhe_texto.add_theme_font_size_override("font_size", 13)
	direita.add_child(detalhe_texto)
	botao_equipar = _botao("Equipar")
	botao_equipar.pressed.connect(_equipar_selecionado)
	direita.add_child(botao_equipar)
	botao_desequipar = _botao("Desequipar")
	botao_desequipar.pressed.connect(func(): _desequipar(selecionado.trim_prefix("slot:")))
	direita.add_child(botao_desequipar)
	botao_usar = _botao("Usar")
	botao_usar.pressed.connect(_usar_selecionado)
	direita.add_child(botao_usar)
	aviso = Label.new()
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.custom_minimum_size = Vector2(230, 0)
	aviso.add_theme_font_size_override("font_size", 12)
	aviso.add_theme_color_override("font_color", COR_APAGADO)
	direita.add_child(aviso)
	aba.add_child(direita)
	return aba


func _atualizar_inventario() -> void:
	for filho in coluna_slots.get_children():
		filho.queue_free()
	for filho in grade_itens.get_children():
		filho.queue_free()
	var eq: Dictionary = membro().get("equipamento", {})
	for slot in Itens.SLOTS:
		var linha := HBoxContainer.new()
		var nome := Label.new()
		nome.text = Itens.NOME_SLOT[slot]
		nome.custom_minimum_size = Vector2(95, 0)
		nome.add_theme_font_size_override("font_size", 13)
		nome.add_theme_color_override("font_color", COR_APAGADO)
		linha.add_child(nome)
		var item: String = eq.get(slot, "")
		var botao := _botao(Itens.DADOS[item]["nome"] if item != "" else "— vazio —")
		botao.custom_minimum_size = Vector2(170, 0)
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.set_meta("slot", slot)
		botao.pressed.connect(func(): _selecionar("slot:" + slot))
		botao.set_drag_forwarding(
			func(_pos): return _arrastar({"slot": slot}, item) if item != "" else null,
			func(_pos, dados): return dados is Dictionary and dados.has("item") and Itens.cabe_no_slot(dados["item"], slot),
			func(_pos, dados): _equipar(dados["item"], slot))
		linha.add_child(botao)
		coluna_slots.add_child(linha)

	for item in Jogo.inventario:
		_botao_item(item, Itens.DADOS[item]["nome"])
	for item in Jogo.itens:
		if Jogo.itens[item] > 0 and Itens.DADOS.has(item):
			_botao_item(item, "%s x%d" % [Itens.DADOS[item]["nome"], Jogo.itens[item]])
	if Jogo.itens.get("chave", 0) > 0:
		var chave := _botao("Chave das celas")
		chave.disabled = true
		grade_itens.add_child(chave)
	_atualizar_detalhe()


func _botao_item(item: String, texto: String) -> void:
	var botao := _botao(texto)
	botao.custom_minimum_size = Vector2(160, 0)
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.set_meta("item", item)
	botao.pressed.connect(func(): _selecionar("item:" + item))
	if Itens.DADOS[item].has("slot"):
		botao.set_drag_forwarding(func(_pos): return _arrastar({"item": item}, item), Callable(), Callable())
	grade_itens.add_child(botao)


func _arrastar(dados: Dictionary, item: String) -> Dictionary:
	var previa := Label.new()
	previa.text = Itens.DADOS[item]["nome"]
	previa.add_theme_color_override("font_color", COR_OURO)
	set_drag_preview(previa)
	return dados


func _selecionar(chave: String) -> void:
	selecionado = chave
	aviso.text = ""
	_atualizar_detalhe()


func _atualizar_detalhe() -> void:
	var item := ""
	var eq: Dictionary = membro().get("equipamento", {})
	if selecionado.begins_with("item:"):
		item = selecionado.trim_prefix("item:")
		if not (item in Jogo.inventario or Jogo.itens.get(item, 0) > 0):
			item = ""
	elif selecionado.begins_with("slot:"):
		item = eq.get(selecionado.trim_prefix("slot:"), "")
	botao_equipar.visible = item != "" and selecionado.begins_with("item:") and Itens.DADOS[item].has("slot")
	botao_desequipar.visible = item != "" and selecionado.begins_with("slot:")
	botao_usar.visible = item != "" and Itens.DADOS[item].has("uso")
	if item == "":
		detalhe_nome.text = "Escolha um item"
		detalhe_texto.text = "Clique num item ou arraste para um slot."
		return
	var d: Dictionary = Itens.DADOS[item]
	detalhe_nome.text = d["nome"]
	var texto: String = Itens.resumo(item)
	if d.has("slot"):
		texto = "Vai em: %s\n%s" % ["Acessório" if d["slot"] == "acessorio" else Itens.NOME_SLOT[d["slot"]], texto]
	detalhe_texto.text = texto.strip_edges() + "\n\n" + d["descricao"]


func _equipar(item: String, slot := "") -> void:
	if Jogo.equipar(membro(), item, slot):
		aviso.text = "%s equipou %s." % [membro()["nome"], Itens.DADOS[item]["nome"]]
		selecionado = "slot:" + (slot if slot != "" else _slot_de(item))
	else:
		aviso.text = "Esse item não cabe nesse slot."
	atualizar()


func _slot_de(item: String) -> String:
	var eq: Dictionary = membro().get("equipamento", {})
	for slot in eq:
		if eq[slot] == item:
			return slot
	return ""


func _equipar_selecionado() -> void:
	_equipar(selecionado.trim_prefix("item:"))


func _desequipar(slot: String) -> void:
	var item: String = membro().get("equipamento", {}).get(slot, "")
	if item == "":
		return
	Jogo.desequipar(membro(), slot)
	aviso.text = "%s guardou %s." % [membro()["nome"], Itens.DADOS[item]["nome"]]
	selecionado = "item:" + item
	atualizar()


func _usar_selecionado() -> void:
	var item := selecionado.trim_prefix("item:")
	var texto := Jogo.usar_item(membro(), item)
	aviso.text = texto if texto != "" else "Não dá para usar agora."
	atualizar()


# ---------------------------------------------------------------- Magias e habilidades

func _aba_magias() -> Control:
	texto_magias = RichTextLabel.new()
	texto_magias.name = "Magias e habilidades"
	texto_magias.bbcode_enabled = true
	texto_magias.add_theme_font_size_override("normal_font_size", 14)
	texto_magias.add_theme_font_size_override("bold_font_size", 14)
	return texto_magias


func _atualizar_magias() -> void:
	var m := membro()
	var c := Combatente.criar(m, true)
	var t := "[color=#d9b34d][b]Ações[/b][/color]\n"
	t += "• [b]Atacar[/b]: %d de dano (%s).\n" % [c.poder_golpe(), "com a arma" if c.tem_arma() else "golpe desarmado, 5 + força"]
	t += "• [b]Bloquear[/b]: +%d de defesa e metade do dano até o próximo turno.\n\n" % Combatente.DEFESA_BLOQUEIO
	var tecnicas := []
	var magias := []
	for hid in m["habilidades"]:
		(magias if Habilidades.DADOS[hid].get("magia", false) else tecnicas).append(hid)
	if not tecnicas.is_empty():
		t += "[color=#d9b34d][b]Técnicas[/b][/color]\n"
		for hid in tecnicas:
			t += _linha_habilidade(hid, c)
		t += "\n"
	var de_classe := magias.filter(func(hid): return Habilidades.DADOS[hid].get("sol", "") == "")
	if not de_classe.is_empty():
		var sangue: bool = Habilidades.DADOS[de_classe[0]].get("sangue", false)
		t += "[color=#d9b34d][b]Magias de %s[/b][/color]  [color=#8c8080](%s)[/color]\n" % [m.get("classe", "classe"),
			"magia de sangue: funciona no escuro" if sangue else "só sob o sol, a lua ou com Pedra Solar"]
		for hid in de_classe:
			t += _linha_habilidade(hid, c)
		t += "\n"
	var sol: String = m.get("sol", "")
	if sol != "":
		t += "[color=#d9b34d][b]%s[/b][/color]  [color=#8c8080](magia só sob o sol, a lua ou com Pedra Solar)[/color]\n" % Habilidades.NOME_SOL[sol]
		for hid in Habilidades.MAGIAS_POR_SOL[sol]:
			if hid in magias:
				t += _linha_habilidade(hid, c)
			elif Habilidades.PLANEJADAS.has(hid):
				var p: Array = Habilidades.PLANEJADAS[hid]
				t += "[color=#8c8080]• %s (em breve): %s[/color]\n" % [p[0], p[1]]
		t += Habilidades.linha_passiva(sol)
	elif de_classe.is_empty():
		t += "[color=#8c8080]%s não usa magia.[/color]\n" % m["nome"]
	texto_magias.text = t


func _linha_habilidade(hid: String, c: Combatente) -> String:
	var h: Dictionary = Habilidades.DADOS[hid]
	var linha := "• [b]%s[/b] (%s): %s" % [h["nome"], Habilidades.texto_custo(hid), h["descricao"]]
	var motivo := Habilidades.impedimento(hid, c)
	if motivo != "" and not motivo in ["MP insuficiente.", "HP insuficiente."]:
		linha += " [color=#c05050](%s)[/color]" % motivo
	return linha + "\n"


# ---------------------------------------------------------------- Personagem

func _aba_personagem() -> Control:
	var aba := HBoxContainer.new()
	aba.name = "Personagem"
	aba.add_theme_constant_override("separation", 16)
	retrato = TextureRect.new()
	retrato.custom_minimum_size = Vector2(128, 128)
	retrato.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	aba.add_child(retrato)
	texto_atributos = RichTextLabel.new()
	texto_atributos.bbcode_enabled = true
	texto_atributos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto_atributos.add_theme_font_size_override("normal_font_size", 15)
	texto_atributos.add_theme_font_size_override("bold_font_size", 15)
	aba.add_child(texto_atributos)
	return aba


func _atualizar_personagem() -> void:
	var m := membro()
	var c := Combatente.criar(m, true)
	retrato.texture = load(m["textura"])
	var sol: String = m.get("sol", "")
	var t := "[color=#d9b34d][b]%s[/b][/color], %s\n" % [m["nome"], m["titulo"]]
	t += "Classe: %s    Sol: %s\n\n" % [m.get("classe", "—"), Habilidades.NOME_SOL.get(sol, "nenhum")]
	t += "HP: %d / %d\nMP: %d / %d\n" % [c.hp, c.hp_max, c.mp, c.mp_max]
	t += "Força: %d\nDano da arma: %d\nDano do ataque: %d\n" % [c.ataque, c.dano_arma, c.poder_golpe()]
	t += "Defesa: %d%% (o dano recebido cai %d%%)\n" % [c.defesa, mini(c.defesa, Combatente.DEFESA_MAXIMA)]
	t += "Agilidade: %d\n\n" % c.agilidade
	t += "Membros: %s\n" % c.descricao_membros()
	if not c.vivo():
		t += "[color=#c05050]Morto[/color]\n"
	elif c.sangrando:
		t += "[color=#c05050]Sangrando[/color]\n"
	if not c.efeitos_equip.is_empty():
		var nomes := []
		for slot in m.get("equipamento", {}):
			var d: Dictionary = Itens.DADOS[m["equipamento"][slot]]
			if d.has("efeito"):
				nomes.append(d["nome"])
		t += "Efeitos de equipamento: %s\n" % ", ".join(nomes)
	texto_atributos.text = t


# ---------------------------------------------------------------- Geral

func atualizar() -> void:
	for filho in botoes_membro.get_children():
		filho.queue_free()
	for i in Jogo.party.size():
		var botao := _botao(Jogo.party[i]["nome"])
		botao.toggle_mode = true
		botao.button_pressed = i == membro_idx
		botao.pressed.connect(func():
			membro_idx = i
			selecionado = ""
			atualizar())
		botoes_membro.add_child(botao)
	match abas.current_tab:
		0: _atualizar_inventario()
		1: _atualizar_magias()
		2: _atualizar_personagem()
