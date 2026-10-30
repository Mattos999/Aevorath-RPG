class_name CriacaoPersonagem
extends Control
## Tela de criação do protagonista, antes do jogo começar: nome, sexo,
## classe e o Sol que ele segue. O sexo escolhe a arte (retrato, caminhada e
## poses de costas); a classe, atributos, equipamento inicial e habilidades;
## o Sol soma as magias e a passiva dele.
## Funciona com mouse ou teclado (setas/Tab para andar, Z/Enter para escolher).

signal concluida(nome: String, sexo: String, classe: String, sol: String)

const COR_OURO := MenuJogo.COR_OURO
const COR_APAGADO := MenuJogo.COR_APAGADO

var sexo := "masculino"
var classe := "guerreiro"
var sol := "vida"

var campo_nome: LineEdit
var botoes_sexo: Dictionary = {}
var botoes_classe: Dictionary = {}
var botoes_sol: Dictionary = {}
var retrato: TextureRect
var boneco: TextureRect
var texto_classe: RichTextLabel
var botao_comecar: Button
var nome_editado := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var painel := PanelContainer.new()
	painel.position = Vector2(30, 20)
	painel.size = Vector2(900, 500)
	painel.add_theme_stylebox_override("panel", MenuJogo._estilo(MenuJogo.COR_FUNDO, MenuJogo.COR_BORDA))
	add_child(painel)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 10)
	painel.add_child(raiz)

	var titulo := Label.new()
	titulo.text = "Quem desperta na cela?"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COR_OURO)
	titulo.add_theme_font_size_override("font_size", 22)
	raiz.add_child(titulo)

	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 18)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(corpo)

	# Esquerda: retrato e boneco do mapa.
	var esquerda := VBoxContainer.new()
	esquerda.add_theme_constant_override("separation", 12)
	corpo.add_child(esquerda)
	retrato = TextureRect.new()
	retrato.custom_minimum_size = Vector2(176, 176)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esquerda.add_child(retrato)
	boneco = TextureRect.new()
	boneco.custom_minimum_size = Vector2(192, 128)
	boneco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boneco.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boneco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	esquerda.add_child(boneco)

	# Direita: nome, sexo, classe e descrição.
	var direita := VBoxContainer.new()
	direita.add_theme_constant_override("separation", 8)
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_child(direita)

	campo_nome = LineEdit.new()
	campo_nome.max_length = 16
	campo_nome.placeholder_text = "Digite o nome"
	campo_nome.add_theme_font_size_override("font_size", 15)
	campo_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_nome.add_theme_stylebox_override("normal", MenuJogo._estilo(Color(0.12, 0.08, 0.09), Color(0.3, 0.12, 0.12)))
	campo_nome.add_theme_stylebox_override("focus", MenuJogo._estilo(Color(0.12, 0.08, 0.09), COR_OURO))
	campo_nome.text_changed.connect(func(_t): nome_editado = true)
	campo_nome.text_submitted.connect(func(_t): botoes_sexo[sexo].grab_focus())
	_linha(direita, "Nome").add_child(campo_nome)

	var linha_sexo := _linha(direita, "Sexo")
	for id in Jogo.SEXOS:
		var b := _opcao(Jogo.SEXOS[id]["nome"])
		b.pressed.connect(_escolher_sexo.bind(id))
		linha_sexo.add_child(b)
		botoes_sexo[id] = b

	var linha_classe := _linha(direita, "Classe")
	for id in Jogo.CLASSES:
		var b := _opcao(Jogo.CLASSES[id]["nome"])
		b.pressed.connect(_escolher_classe.bind(id))
		b.focus_entered.connect(_escolher_classe.bind(id))
		linha_classe.add_child(b)
		botoes_classe[id] = b

	var grade_sol := GridContainer.new()
	grade_sol.columns = 4
	_linha(direita, "Sol").add_child(grade_sol)
	for id in Habilidades.SOIS_INICIAIS:
		var b := _opcao(Habilidades.SOIS_INICIAIS[id])
		b.pressed.connect(_escolher_sol.bind(id))
		b.focus_entered.connect(_escolher_sol.bind(id))
		grade_sol.add_child(b)
		botoes_sol[id] = b

	texto_classe = RichTextLabel.new()
	texto_classe.bbcode_enabled = true
	texto_classe.fit_content = true
	texto_classe.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto_classe.add_theme_font_size_override("normal_font_size", 12)
	texto_classe.add_theme_font_size_override("bold_font_size", 12)
	direita.add_child(texto_classe)

	botao_comecar = MenuJogo._botao("Começar")
	botao_comecar.add_theme_font_size_override("font_size", 16)
	botao_comecar.custom_minimum_size = Vector2(176, 40)
	botao_comecar.size_flags_vertical = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	botao_comecar.pressed.connect(comecar)
	esquerda.add_child(botao_comecar)

	# Começa com as últimas escolhas (ao recomeçar depois de morrer).
	var anterior: Dictionary = Jogo.criacao
	sexo = anterior["sexo"]
	classe = anterior["classe"]
	sol = anterior.get("sol", "vida")
	campo_nome.text = anterior["nome"]
	nome_editado = anterior["nome"] != Jogo.SEXOS[sexo]["nome_padrao"]
	_atualizar()
	campo_nome.grab_focus.call_deferred()


## Uma linha do formulário: rótulo à esquerda e os controles à direita.
func _linha(pai: Control, texto: String) -> HBoxContainer:
	var linha := HBoxContainer.new()
	var rotulo := _rotulo(texto)
	rotulo.custom_minimum_size = Vector2(60, 0)
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	linha.add_child(rotulo)
	pai.add_child(linha)
	return linha


func _rotulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", COR_OURO)
	l.add_theme_font_size_override("font_size", 14)
	return l


func _opcao(texto: String) -> Button:
	var b: Button = MenuJogo._botao(texto)
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(124, 0)
	b.add_theme_font_size_override("font_size", 14)
	var marcado := MenuJogo._estilo(Color(0.35, 0.1, 0.08), COR_OURO)
	marcado.set_content_margin_all(5)
	b.add_theme_stylebox_override("pressed", marcado)
	return b


func _escolher_sexo(id: String) -> void:
	# O nome padrão acompanha o sexo enquanto o jogador não digitou outro.
	if not nome_editado or campo_nome.text.strip_edges() == "":
		campo_nome.text = Jogo.SEXOS[id]["nome_padrao"]
		nome_editado = false
	sexo = id
	_atualizar()


func _escolher_classe(id: String) -> void:
	classe = id
	_atualizar()


func _escolher_sol(id: String) -> void:
	sol = id
	_atualizar()


func _atualizar() -> void:
	for id in botoes_sexo:
		botoes_sexo[id].set_pressed_no_signal(id == sexo)
	for id in botoes_classe:
		botoes_classe[id].set_pressed_no_signal(id == classe)
	for id in botoes_sol:
		botoes_sol[id].set_pressed_no_signal(id == sol)
	var s: Dictionary = Jogo.SEXOS[sexo]
	retrato.texture = load(s["textura"])
	var folha := AtlasTexture.new()
	folha.atlas = load(s["folha_mapa"])
	folha.region = Rect2(0, 0, folha.atlas.get_width() / 3.0, folha.atlas.get_height() / 4.0)
	boneco.texture = folha

	var c: Dictionary = Jogo.CLASSES[classe]
	var t := "[color=#d9b34d][b]%s[/b][/color]: %s\n" % [c["nome"], c["descricao"]]
	t += "[color=#8c8080]HP %d · MP %d · Força %d · Agilidade %d[/color]\n" % [c["hp"], c["mp"], c["ataque"], c["agilidade"]]
	for hid in c["habilidades"]:
		t += _linha_habilidade(hid)
	t += "[color=#d9b34d][b]%s[/b][/color]\n" % Habilidades.NOME_SOL[sol]
	for hid in Habilidades.MAGIAS_POR_SOL[sol]:
		if Habilidades.DADOS.has(hid):
			t += _linha_habilidade(hid)
		else:
			var p: Array = Habilidades.PLANEJADAS[hid]
			t += "[color=#8c8080]• %s (em breve): %s[/color]\n" % [p[0], p[1]]
	t += Habilidades.linha_passiva(sol)
	texto_classe.text = t


func _linha_habilidade(hid: String) -> String:
	var h: Dictionary = Habilidades.DADOS[hid]
	var tipo := "técnica"
	if h.get("sangue", false):
		tipo = "magia de sangue"
	elif h.get("magia", false):
		tipo = "magia"
	return "• [b]%s[/b] [color=#8c8080](%s, %s)[/color]: %s\n" % [h["nome"], tipo, Habilidades.texto_custo(hid), h["descricao"]]


func comecar() -> void:
	var nome := campo_nome.text.strip_edges()
	if nome == "":
		nome = Jogo.SEXOS[sexo]["nome_padrao"]
	concluida.emit(nome, sexo, classe, sol)
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	# Z (interagir) confirma quando o foco não está no campo de nome.
	if evento.is_action_pressed("interagir") and not campo_nome.has_focus():
		var foco := get_viewport().gui_get_focus_owner()
		if foco is Button:
			get_viewport().set_input_as_handled()
			(foco as Button).pressed.emit()
