class_name TelaTitulo
extends Control
## Tela de título da demo: "Bem-vindo a Aevorath", Começar demo e Sair.
## Durante o jogo, Esc abre o menu, que tem Voltar ao título e Sair do jogo.

signal comecar

const COR_OURO := Color(0.85, 0.7, 0.3)
const COR_TEXTO := Color(0.86, 0.82, 0.76)

var botao_comecar: Button


func _ready() -> void:
	# O pai é um Node comum, então as âncoras não pegam a tela: usa o tamanho dela.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size

	var fundo := TextureRect.new()
	fundo.texture = load("res://assets/batalha/fundo_catedral.png")
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.size = size
	fundo.modulate = Color(0.32, 0.27, 0.3)
	add_child(fundo)
	var veu := ColorRect.new()
	veu.size = size
	veu.material = _vinheta()
	add_child(veu)

	var sol := CriacaoPersonagem.SolDesenho.new()
	sol.nucleo = Color(0.85, 0.62, 0.22)
	sol.brilho = Color(1.0, 0.82, 0.45)
	sol.raios = 9
	sol.position = Vector2(size.x / 2 - 110, 30)
	sol.size = Vector2(220, 190)
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sol)

	var coluna := VBoxContainer.new()
	coluna.position = Vector2(0, 200)
	coluna.size = Vector2(size.x, 300)
	coluna.alignment = BoxContainer.ALIGNMENT_BEGIN
	coluna.add_theme_constant_override("separation", 6)
	add_child(coluna)
	coluna.add_child(_texto("Bem-vindo a", 16, Color(0.6, 0.55, 0.5)))
	var titulo := _texto("AEVORATH", 64, COR_OURO)
	titulo.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.05))
	titulo.add_theme_constant_override("outline_size", 10)
	coluna.add_child(titulo)
	coluna.add_child(_texto("Demo · A fuga da prisão", 15, Color(0.7, 0.62, 0.55)))
	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 26)
	coluna.add_child(espaco)

	botao_comecar = _botao("Começar demo")
	botao_comecar.pressed.connect(_comecar)
	coluna.add_child(_centro(botao_comecar))
	var sair := _botao("Sair")
	sair.pressed.connect(get_tree().quit)
	coluna.add_child(_centro(sair))

	var dica := _texto("Setas / WASD andar     Z / Enter interagir     Esc menu (e sair)", 11, Color(0.45, 0.42, 0.4))
	dica.position = Vector2(0, size.y - 34)
	dica.size = Vector2(size.x, 20)
	add_child(dica)
	botao_comecar.grab_focus.call_deferred()


func _comecar() -> void:
	comecar.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		var foco := get_viewport().gui_get_focus_owner()
		if foco is Button:
			(foco as Button).pressed.emit()


func _texto(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _centro(no: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(no)
	return c


func _botao(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(220, 38)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", COR_TEXTO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.bg_color = Color(0, 0, 0, 0.35) if estado == "normal" else Color(0.3, 0.08, 0.06, 0.6)
		e.border_color = Color(1, 1, 1, 0.14) if estado == "normal" else COR_OURO
		e.set_border_width_all(1)
		e.set_corner_radius_all(3)
		b.add_theme_stylebox_override(estado, e)
	return b


func _vinheta() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.5, 0.42));
	COLOR = vec4(0.02, 0.01, 0.015, smoothstep(0.25, 0.85, d) * 0.95);
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	return m
