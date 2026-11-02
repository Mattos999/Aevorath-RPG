class_name CriacaoPersonagem
extends Control
## Tela de criação do protagonista, antes do jogo começar: nome, sexo, Sol e
## atributos. Não há classes: o sexo escolhe a arte (retrato, caminhada e
## poses de costas) e o Sol, as magias e a passiva.
##
## Dois modos (abas no topo):
## - Build do Sol: escolhe um dos oito sóis e leva a build pronta dele
##   (Atributos.BUILD_SOL).
## - Distribuir pontos: 20 pontos nos sete atributos (máximo 8 em cada). O
##   Sol que combina aparece na hora (Atributos.sois_que_combinam); em empate,
##   o jogador clica num dos sóis empatados. Depois de criado, o Sol fica.
## O Sol escolhido aparece grande, brilhando na cor dele. Embaixo fica a
## fileira dos oito sóis.
## Teclado: ←/→ troca o Sol (ou tira/põe ponto no atributo em foco),
## Z/Enter começa, Tab anda entre os campos.

signal concluida(nome: String, sexo: String, sol: String, atributos: Dictionary)

const COR_OURO := MenuJogo.COR_OURO
const COR_TEXTO := Color(0.86, 0.82, 0.76)
const COR_APAGADO := Color(0.5, 0.46, 0.44)
const COR_LINHA := Color(1, 1, 1, 0.08)

var sexo := "masculino"
var sol := "vida"
var modo := "build"  # "build" ou "pontos"
var atributos: Dictionary = {}
var empate: Array = []  # sóis empatados no modo de pontos

var campo_nome: LineEdit
var botoes_sexo: Dictionary = {}
var botoes_sol: Dictionary = {}
var retrato: TextureRect
var sol_grande: SolDesenho
var halo: ColorRect
var nome_sol: Label
var foco_sol: Label
var resumo_sol: Label
var lista_sol: VBoxContainer
var linha_atributos: Label
var painel_pontos: VBoxContainer
var texto_pontos: Label
var ensina: Label
var linhas_atributo: Dictionary = {}
var botoes_modo: Dictionary = {}
var dica: Label
var botao_comecar: Button
var nome_editado := false


## Um sol desenhado com volume: esfera sombreada, brilho em camadas e uma
## coroa de raios que gira inclinada (os raios de trás ficam atrás da esfera
## e mais apagados). Animado, ele também flutua e balança devagar.
class SolDesenho extends Control:
	var nucleo := Color.WHITE
	var brilho := Color.WHITE
	var raios := 12
	var animado := true
	var aceso := true
	var _t := 0.0

	func _process(delta: float) -> void:
		if animado:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.24
		var c := size / 2 + Vector2(0, sin(_t * 1.6) * r * 0.06)
		var pulso := 1.0 + 0.03 * sin(_t * 2.2)
		var forca := 1.0 if aceso else 0.35
		# Brilho: círculos cada vez maiores e mais fracos.
		for i in range(10, 0, -1):
			var cor := brilho
			cor.a = 0.05 * forca
			draw_circle(c, r * (1.0 + i * 0.13) * pulso, cor)
		# Coroa de raios em 3D: gira no próprio plano, que inclina e balança.
		var giro := _t * 0.5
		var inclinacao := 0.55 + 0.25 * sin(_t * 0.7)
		var balanco := 0.35 * sin(_t * 0.45)
		var atras := []
		var frente := []
		for i in raios:
			var ang := TAU * i / raios + giro
			var d := Vector3(cos(ang), sin(ang), 0.0)
			d = d.rotated(Vector3.RIGHT, inclinacao).rotated(Vector3.UP, balanco)
			var ray: Dictionary = {"d": d, "comp": (1.9 if i % 2 == 0 else 1.55) * pulso,
				"largura": 0.2 if i % 2 == 0 else 0.14}
			(frente if d.z > 0.0 else atras).append(ray)
		for ray in atras:
			_raio(c, r, ray, forca * 0.55)
		_esfera(c, r, forca)
		for ray in frente:
			_raio(c, r, ray, forca)

	## Raio como um triângulo saindo da superfície da esfera na direção d.
	func _raio(c: Vector2, r: float, ray: Dictionary, forca: float) -> void:
		var d: Vector3 = ray["d"]
		var largura: float = ray["largura"]
		var comp: float = ray["comp"]
		var plano := Vector2(d.x, d.y)
		if plano.length() < 0.05:
			return  # apontando direto para a câmera: não aparece
		var lado := Vector2(-d.y, d.x).normalized() * r * largura
		var base := c + plano * r * 0.98
		var ponta := c + plano * r * comp
		var cor := brilho.darkened(0.25 * (1.0 - d.z) * 0.5)
		cor.a = 0.9 * forca
		draw_colored_polygon(PackedVector2Array([base - lado, ponta, base + lado]), cor)

	## Esfera: círculos que encolhem em direção ao ponto de luz, do escuro ao claro.
	func _esfera(c: Vector2, r: float, forca: float) -> void:
		var luz := Vector2(-0.38, -0.42).rotated(0.25 * sin(_t * 0.6))
		var escuro := nucleo.darkened(0.55)
		var claro := nucleo.lightened(0.4)
		var passos := 22
		for k in passos:
			var f := float(k) / passos
			var cor := escuro.lerp(claro, pow(f, 1.4))
			cor.a = forca
			draw_circle(c + luz * r * f * 0.62, r * (1.0 - f * 0.92), cor)
		var aro := brilho
		aro.a = 0.55 * forca
		draw_arc(c, r, 0.0, TAU, 64, aro, 2.0, true)


func _ready() -> void:
	# O pai é um Node comum, então as âncoras não pegam a tela: usa o tamanho dela.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	var fundo := ColorRect.new()
	fundo.color = Color(0.035, 0.025, 0.03)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.size = size
	add_child(fundo)

	# Clarão da cor do Sol atrás do sol grande.
	halo = ColorRect.new()
	halo.position = Vector2(0, 40)
	halo.size = Vector2(480, 420)
	halo.material = _material_halo()
	add_child(halo)

	_montar_topo()
	_montar_sol()
	_montar_detalhes()
	_montar_fileira()
	_montar_rodape()

	# Começa com as últimas escolhas (ao recomeçar depois de morrer).
	var anterior: Dictionary = Jogo.criacao
	sexo = anterior["sexo"]
	sol = anterior.get("sol", "vida")
	var at_anterior: Dictionary = anterior.get("atributos", {})
	if not at_anterior.is_empty() and at_anterior != Atributos.BUILD_SOL.get(sol, {}):
		modo = "pontos"
		atributos = at_anterior.duplicate()
	else:
		atributos = Atributos.BUILD_SOL[sol].duplicate()
	campo_nome.text = anterior["nome"]
	nome_editado = anterior["nome"] != Jogo.SEXOS[sexo]["nome_padrao"]
	_atualizar()
	campo_nome.grab_focus.call_deferred()


# ---------------------------------------------------------------- montagem

## Topo: retrato pequeno, nome e sexo numa linha só.
func _montar_topo() -> void:
	var topo := HBoxContainer.new()
	topo.position = Vector2(36, 22)
	topo.size = Vector2(888, 56)
	topo.add_theme_constant_override("separation", 14)
	add_child(topo)

	retrato = TextureRect.new()
	retrato.custom_minimum_size = Vector2(56, 56)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	topo.add_child(retrato)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(coluna)
	coluna.add_child(_texto("Quem desperta na cela?", 12, COR_APAGADO))
	campo_nome = LineEdit.new()
	campo_nome.max_length = 16
	campo_nome.placeholder_text = "Digite o nome"
	campo_nome.custom_minimum_size = Vector2(260, 0)
	campo_nome.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	campo_nome.add_theme_font_size_override("font_size", 22)
	campo_nome.add_theme_color_override("font_color", COR_TEXTO)
	campo_nome.add_theme_color_override("caret_color", COR_OURO)
	var linha := StyleBoxFlat.new()
	linha.bg_color = Color.TRANSPARENT
	linha.border_color = Color(1, 1, 1, 0.15)
	linha.border_width_bottom = 1
	linha.content_margin_bottom = 2
	campo_nome.add_theme_stylebox_override("normal", linha)
	var linha_foco := linha.duplicate()
	linha_foco.border_color = COR_OURO
	campo_nome.add_theme_stylebox_override("focus", linha_foco)
	campo_nome.text_changed.connect(func(_t): nome_editado = true)
	campo_nome.text_submitted.connect(func(_t): botoes_sol[sol if sol != "" else "vida"].grab_focus())
	coluna.add_child(campo_nome)

	var sexos := HBoxContainer.new()
	sexos.add_theme_constant_override("separation", 0)
	sexos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(sexos)
	for id in Jogo.SEXOS:
		var b := _aba(Jogo.SEXOS[id]["nome"])
		b.pressed.connect(_escolher_sexo.bind(id))
		sexos.add_child(b)
		botoes_sexo[id] = b

	var modos := HBoxContainer.new()
	modos.add_theme_constant_override("separation", 0)
	modos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(_espaco_largo(18))
	topo.add_child(modos)
	for par in [["build", "Build do Sol"], ["pontos", "Distribuir pontos"]]:
		var b := _aba(par[1])
		b.custom_minimum_size.x = 132
		b.pressed.connect(_escolher_modo.bind(par[0]))
		modos.add_child(b)
		botoes_modo[par[0]] = b


func _montar_sol() -> void:
	sol_grande = SolDesenho.new()
	sol_grande.position = Vector2(60, 110)
	sol_grande.size = Vector2(340, 300)
	sol_grande.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sol_grande)


## Direita: nome do Sol, foco, uma frase e o que ele ensina.
func _montar_detalhes() -> void:
	var caixa := VBoxContainer.new()
	caixa.position = Vector2(440, 104)
	caixa.size = Vector2(484, 300)
	caixa.add_theme_constant_override("separation", 4)
	add_child(caixa)

	nome_sol = _texto("", 34, COR_TEXTO)
	caixa.add_child(nome_sol)
	foco_sol = _texto("", 13, COR_OURO)
	caixa.add_child(foco_sol)
	linha_atributos = _texto("", 11, Color(0.6, 0.56, 0.52))
	caixa.add_child(linha_atributos)
	resumo_sol = _texto("", 14, COR_APAGADO)
	resumo_sol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resumo_sol.custom_minimum_size = Vector2(484, 0)
	caixa.add_child(resumo_sol)

	var separador := ColorRect.new()
	separador.color = COR_LINHA
	separador.custom_minimum_size = Vector2(484, 1)
	caixa.add_child(_espaco(8))
	caixa.add_child(separador)
	caixa.add_child(_espaco(6))

	lista_sol = VBoxContainer.new()
	lista_sol.add_theme_constant_override("separation", 9)
	caixa.add_child(lista_sol)

	# Modo de pontos: uma linha por atributo com − e +.
	painel_pontos = VBoxContainer.new()
	painel_pontos.add_theme_constant_override("separation", 1)
	caixa.add_child(painel_pontos)
	var cabeca := HBoxContainer.new()
	texto_pontos = _texto("", 13, COR_OURO)
	texto_pontos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabeca.add_child(texto_pontos)
	var zerar := _botao_pequeno("Zerar")
	zerar.custom_minimum_size = Vector2(64, 24)
	zerar.pressed.connect(_zerar)
	cabeca.add_child(zerar)
	painel_pontos.add_child(cabeca)
	for a in Atributos.ORDEM:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 6)
		var nome := _texto(Atributos.NOME[a], 14, COR_TEXTO)
		nome.custom_minimum_size = Vector2(108, 0)
		linha.add_child(nome)
		var menos := _botao_pequeno("-")
		menos.pressed.connect(_mudar_ponto.bind(a, -1))
		menos.set_meta("atributo", a)
		linha.add_child(menos)
		var valor := _texto("0", 15, COR_TEXTO)
		valor.custom_minimum_size = Vector2(24, 0)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		linha.add_child(valor)
		var mais := _botao_pequeno("+")
		mais.pressed.connect(_mudar_ponto.bind(a, 1))
		mais.set_meta("atributo", a)
		linha.add_child(mais)
		var barra := HBoxContainer.new()
		barra.add_theme_constant_override("separation", 2)
		barra.custom_minimum_size = Vector2(70, 0)
		barra.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in Atributos.MAXIMO:
			var quadro := ColorRect.new()
			quadro.custom_minimum_size = Vector2(6, 10)
			quadro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			barra.add_child(quadro)
		linha.add_child(barra)
		var efeito := _texto(Atributos.EFEITO[a], 11, COR_APAGADO)
		efeito.clip_text = true
		efeito.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(efeito)
		painel_pontos.add_child(linha)
		linhas_atributo[a] = {"valor": valor, "barra": barra, "menos": menos, "mais": mais, "nome": nome}
	ensina = _texto("", 11, COR_APAGADO)
	ensina.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ensina.custom_minimum_size = Vector2(484, 0)
	painel_pontos.add_child(_espaco(4))
	painel_pontos.add_child(ensina)


## Fileira dos oito sóis: clicar ou andar com ←/→ troca o escolhido.
func _montar_fileira() -> void:
	var fileira := HBoxContainer.new()
	fileira.position = Vector2(36, 418)
	fileira.size = Vector2(888, 60)
	fileira.add_theme_constant_override("separation", 6)
	fileira.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(fileira)
	var vazio := StyleBoxEmpty.new()
	for id in Habilidades.SOIS_INICIAIS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(100, 58)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_ALL
		for estado in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			b.add_theme_stylebox_override(estado, vazio)
		var icone := SolDesenho.new()
		icone.set_anchors_preset(Control.PRESET_FULL_RECT)
		icone.offset_bottom = -16
		icone.raios = 8
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cores: Array = Habilidades.COR_SOL[id]
		icone.nucleo = cores[0]
		icone.brilho = cores[1]
		b.add_child(icone)
		var nome := _texto(Habilidades.SOIS_INICIAIS[id], 11, COR_APAGADO)
		nome.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		nome.offset_top = -16
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nome)
		b.set_meta("icone", icone)
		b.set_meta("nome", nome)
		b.pressed.connect(_clicar_sol.bind(id))
		b.focus_entered.connect(func() -> void:
			if modo == "build":
				_escolher_sol(id))
		fileira.add_child(b)
		botoes_sol[id] = b


func _montar_rodape() -> void:
	dica = _texto("", 11, Color(0.4, 0.37, 0.36))
	dica.position = Vector2(36, 500)
	add_child(dica)

	botao_comecar = Button.new()
	botao_comecar.text = "Começar  ›"
	botao_comecar.position = Vector2(774, 488)
	botao_comecar.size = Vector2(150, 36)
	botao_comecar.add_theme_font_size_override("font_size", 16)
	botao_comecar.add_theme_color_override("font_color", COR_TEXTO)
	botao_comecar.add_theme_color_override("font_hover_color", Color.WHITE)
	botao_comecar.add_theme_color_override("font_focus_color", Color.WHITE)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.bg_color = Color(1, 1, 1, 0.04 if estado == "normal" else 0.1)
		e.border_color = Color(1, 1, 1, 0.12) if estado == "normal" else COR_OURO
		e.set_border_width_all(1)
		e.set_corner_radius_all(3)
		botao_comecar.add_theme_stylebox_override(estado, e)
	botao_comecar.pressed.connect(comecar)
	add_child(botao_comecar)


# ---------------------------------------------------------------- peças

func _texto(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _espaco(altura: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, altura)
	return c


func _espaco_largo(largura: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(largura, 0)
	return c


## Botãozinho (− / + / Zerar) com contorno fino.
func _botao_pequeno(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(26, 24)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", COR_TEXTO)
	b.add_theme_color_override("font_disabled_color", Color(0.3, 0.28, 0.27))
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		var e := StyleBoxFlat.new()
		e.bg_color = Color(1, 1, 1, 0.1 if estado in ["hover", "focus"] else 0.03)
		e.border_color = COR_OURO if estado == "focus" else Color(1, 1, 1, 0.1)
		e.set_border_width_all(1)
		e.set_corner_radius_all(3)
		b.add_theme_stylebox_override(estado, e)
	return b


## Botão de aba (Masculino / Feminino): só sublinhado quando escolhido.
func _aba(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(104, 34)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", COR_APAGADO)
	b.add_theme_color_override("font_hover_color", COR_TEXTO)
	b.add_theme_color_override("font_pressed_color", COR_TEXTO)
	b.add_theme_color_override("font_hover_pressed_color", COR_TEXTO)
	b.add_theme_color_override("font_focus_color", COR_TEXTO)
	for estado in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		var e := StyleBoxFlat.new()
		e.bg_color = Color.TRANSPARENT
		e.border_color = COR_OURO if estado in ["pressed", "hover_pressed"] else Color(1, 1, 1, 0.1)
		e.border_width_bottom = 2
		b.add_theme_stylebox_override(estado, e)
	return b


## Brilho radial suave (some nas bordas) para o clarão atrás do sol.
func _material_halo() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 cor : source_color = vec4(1.0);
void fragment() {
	float d = distance(UV, vec2(0.5, 0.45)) * 2.0;
	COLOR = vec4(cor.rgb, cor.a * pow(clamp(1.0 - d, 0.0, 1.0), 2.2));
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


# ---------------------------------------------------------------- escolhas

func _escolher_sexo(id: String) -> void:
	# O nome padrão acompanha o sexo enquanto o jogador não digitou outro.
	if not nome_editado or campo_nome.text.strip_edges() == "":
		campo_nome.text = Jogo.SEXOS[id]["nome_padrao"]
		nome_editado = false
	sexo = id
	_atualizar()


func _escolher_modo(id: String) -> void:
	modo = id
	if modo == "build":
		if not Atributos.BUILD_SOL.has(sol):
			sol = "vida"
		atributos = Atributos.BUILD_SOL[sol].duplicate()
	elif is_inside_tree():
		# Começa da build do Sol atual; o jogador mexe a partir dela.
		(linhas_atributo[Atributos.ORDEM[0]]["mais"] as Button).grab_focus.call_deferred()
	_atualizar()


func _escolher_sol(id: String) -> void:
	sol = id
	if modo == "build":
		atributos = Atributos.BUILD_SOL[sol].duplicate()
	_atualizar()


## Clique num sol da fileira. No modo de pontos: num empate, escolhe entre os
## empatados; fora dele, recomeça os pontos pela build daquele Sol.
func _clicar_sol(id: String) -> void:
	if modo == "pontos" and not id in empate:
		atributos = Atributos.BUILD_SOL[id].duplicate()
	_escolher_sol(id)


func _mudar_ponto(a: String, passo: int) -> void:
	var novo := int(atributos.get(a, 0)) + passo
	if novo < 0 or novo > Atributos.MAXIMO:
		return
	if passo > 0 and Atributos.gastos(atributos) >= Atributos.PONTOS:
		return
	atributos[a] = novo
	_atualizar()


func _zerar() -> void:
	atributos = Atributos.vazio()
	_atualizar()


## Sol do modo de pontos: o que combina; em empate, mantém o escolhido se ele
## estiver entre os empatados. Vazio = nenhum Sol combina ainda.
func _sol_dos_pontos() -> void:
	var combina := Atributos.sois_que_combinam(atributos)
	empate = combina if combina.size() > 1 else []
	if combina.is_empty():
		sol = ""
	elif not sol in combina:
		sol = combina[0]


## O que falta para poder começar ("" = pode).
func _falta() -> String:
	if modo == "build":
		return ""
	var sobra := Atributos.PONTOS - Atributos.gastos(atributos)
	if sobra > 0:
		return "Faltam %d pontos para distribuir." % sobra
	if sol == "":
		return "Nenhum Sol combina: ponha %d ou mais nos atributos de um Sol." % Atributos.MINIMO_SOL
	return ""


func _trocar_sol(passo: int) -> void:
	var ids := Habilidades.SOIS_INICIAIS.keys()
	var i := (ids.find(sol) + passo + ids.size()) % ids.size()
	botoes_sol[ids[i]].grab_focus()
	_escolher_sol(ids[i])


func _atualizar() -> void:
	for id in botoes_sexo:
		botoes_sexo[id].set_pressed_no_signal(id == sexo)
	for id in botoes_modo:
		botoes_modo[id].set_pressed_no_signal(id == modo)
	retrato.texture = load(Jogo.SEXOS[sexo]["textura"])
	if modo == "pontos":
		_sol_dos_pontos()
	else:
		empate = []

	var tem_sol := sol != ""
	var cores: Array = Habilidades.COR_SOL[sol] if tem_sol else [Color(0.3, 0.28, 0.27), Color(0.45, 0.42, 0.4)]
	sol_grande.nucleo = cores[0]
	sol_grande.brilho = cores[1]
	sol_grande.aceso = tem_sol
	var cor_halo: Color = cores[1]
	cor_halo.a = 0.28 if tem_sol else 0.08
	(halo.material as ShaderMaterial).set_shader_parameter("cor", cor_halo)
	for id in botoes_sol:
		var b: Button = botoes_sol[id]
		b.set_pressed_no_signal(id == sol)
		var icone_sol: SolDesenho = b.get_meta("icone")
		# Num empate, os empatados ficam acesos para mostrar que dá para escolher.
		icone_sol.aceso = id == sol or id in empate
		icone_sol.animado = id == sol
		icone_sol.queue_redraw()
		(b.get_meta("nome") as Label).add_theme_color_override("font_color",
			COR_TEXTO if id == sol else (COR_OURO if id in empate else COR_APAGADO))

	if tem_sol:
		nome_sol.text = Habilidades.NOME_SOL[sol]
		nome_sol.add_theme_color_override("font_color", (cores[1] as Color).lerp(COR_TEXTO, 0.35))
		foco_sol.text = "Foco: " + Atributos.texto_foco(sol)
	else:
		nome_sol.text = "Nenhum Sol"
		nome_sol.add_theme_color_override("font_color", COR_APAGADO)
		foco_sol.text = "Nenhum Sol combina com esses atributos ainda."
	if not empate.is_empty():
		var nomes := []
		for id in empate:
			nomes.append(Habilidades.SOIS_INICIAIS[id])
		foco_sol.text = "Empate: %s. Clique no Sol que quer seguir." % ", ".join(nomes)

	var st := Atributos.status(atributos)
	linha_atributos.text = "%s     HP %d · MP %d" % [Atributos.texto_curto(atributos), st["hp"], st["mp"]]
	resumo_sol.visible = modo == "build"
	resumo_sol.text = Habilidades.RESUMO_SOL.get(sol, "")
	lista_sol.visible = modo == "build"
	painel_pontos.visible = modo == "pontos"

	if modo == "pontos":
		_atualizar_pontos()
	else:
		_atualizar_lista()

	var falta := _falta()
	botao_comecar.disabled = falta != ""
	if falta != "":
		dica.text = falta
	elif modo == "pontos":
		dica.text = "←  →  tirar / pôr ponto        clique num Sol para partir da build dele"
	else:
		dica.text = "←  →  trocar o Sol        Z / Enter  começar"


func _atualizar_pontos() -> void:
	var sobra := Atributos.PONTOS - Atributos.gastos(atributos)
	texto_pontos.text = "Pontos: %d de %d    (máximo %d em cada)" % [sobra, Atributos.PONTOS, Atributos.MAXIMO]
	var pedidos: Array = Atributos.SOL_ATRIBUTOS.get(sol, [])
	for a in Atributos.ORDEM:
		var l: Dictionary = linhas_atributo[a]
		var v := int(atributos.get(a, 0))
		(l["valor"] as Label).text = str(v)
		(l["menos"] as Button).disabled = v <= 0
		(l["mais"] as Button).disabled = v >= Atributos.MAXIMO or sobra <= 0
		# Os atributos do Sol que combina ficam na cor dele.
		var cor := COR_TEXTO
		if a in pedidos:
			cor = (Habilidades.COR_SOL[sol][1] as Color).lerp(COR_TEXTO, 0.3)
		(l["nome"] as Label).add_theme_color_override("font_color", cor)
		var cheio: Color = cor if a in pedidos else Color(0.6, 0.55, 0.5)
		var i := 0
		for quadro in (l["barra"] as HBoxContainer).get_children():
			(quadro as ColorRect).color = cheio if i < v else Color(1, 1, 1, 0.08)
			i += 1
	# Linha curta com o que o Sol ensina.
	ensina.text = ""
	if sol != "":
		var nomes := []
		for hid in Habilidades.MAGIAS_POR_SOL[sol]:
			nomes.append(Habilidades.DADOS[hid]["nome"] if Habilidades.DADOS.has(hid) else Habilidades.PLANEJADAS[hid][0])
		ensina.text = "Magias: %s.  Passiva: %s." % [", ".join(nomes), Habilidades.PASSIVAS[sol][0]]


func _atualizar_lista() -> void:
	for filho in lista_sol.get_children():
		filho.queue_free()
	for hid in Habilidades.MAGIAS_POR_SOL[sol]:
		if Habilidades.DADOS.has(hid):
			var h: Dictionary = Habilidades.DADOS[hid]
			_item(h["nome"], "Magia · " + Habilidades.texto_custo(hid), h["descricao"])
		else:
			var p: Array = Habilidades.PLANEJADAS[hid]
			_item(p[0], "Magia · em breve", p[1], true)
	var passiva: Array = Habilidades.PASSIVAS[sol]
	_item(passiva[0], "Passiva" if sol in Habilidades.PASSIVAS_ATIVAS else "Passiva · em breve", passiva[1])
	var c: Dictionary = Jogo.HEROI_BASE
	var tecnicas := []
	for hid in c["habilidades"]:
		tecnicas.append(Habilidades.DADOS[hid]["nome"])
	var base := _texto("Todos começam com uma espada enferrujada, %s." % " e ".join(tecnicas), 11, Color(0.5, 0.46, 0.44))
	lista_sol.add_child(_espaco(2))
	lista_sol.add_child(base)


## Uma habilidade na lista: nome e tipo na mesma linha, descrição embaixo.
func _item(nome: String, tipo: String, descricao: String, planejada := false) -> void:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", 0)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	linha.add_child(_texto(nome, 15, COR_APAGADO if planejada else COR_TEXTO))
	var t := _texto(tipo, 11, Color(0.45, 0.42, 0.4))
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(t)
	item.add_child(linha)
	var d := _texto(descricao, 12, COR_APAGADO)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(484, 0)
	item.add_child(d)
	lista_sol.add_child(item)


func comecar() -> void:
	if _falta() != "":
		return
	var nome := campo_nome.text.strip_edges()
	if nome == "":
		nome = Jogo.SEXOS[sexo]["nome_padrao"]
	concluida.emit(nome, sexo, sol, atributos.duplicate())
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if campo_nome.has_focus():
		return
	var foco_atual := get_viewport().gui_get_focus_owner()
	if modo == "pontos" and foco_atual is Button and foco_atual.has_meta("atributo"):
		var passo := 0
		if evento.is_action_pressed("mover_esquerda") or evento.is_action_pressed("ui_left"):
			passo = -1
		elif evento.is_action_pressed("mover_direita") or evento.is_action_pressed("ui_right"):
			passo = 1
		if passo != 0:
			get_viewport().set_input_as_handled()
			_mudar_ponto(foco_atual.get_meta("atributo"), passo)
			return
	if modo == "pontos" and (evento.is_action_pressed("mover_esquerda") or evento.is_action_pressed("mover_direita")):
		return
	if evento.is_action_pressed("mover_esquerda") or evento.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_trocar_sol(-1)
	elif evento.is_action_pressed("mover_direita") or evento.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_trocar_sol(1)
	elif evento.is_action_pressed("interagir"):
		# Z/Enter: num botão de sexo, escolhe; no resto, começa.
		get_viewport().set_input_as_handled()
		var foco := get_viewport().gui_get_focus_owner()
		if foco is Button and (foco in botoes_sexo.values() or foco in botoes_modo.values() or foco.has_meta("atributo")):
			(foco as Button).pressed.emit()
		else:
			comecar()
