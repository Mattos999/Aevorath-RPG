extends Node2D
## Mapa explorável com movimento em grid de 32x32.
## Setas/WASD movem, Z/Espaço/Enter interage com o que está à frente.

const TILE := 32
const TEMPO_PASSO := 0.14
const ALCANCE_PERSEGUICAO := 6
const INTERVALO_INIMIGO := 0.45

const TEX_CHAO := preload("res://assets/tiles/chao.png")
const TEX_PAREDE := preload("res://assets/tiles/parede.png")
const TEX_ALTAR := preload("res://assets/tiles/altar.png")
const TEX_SANGUE := preload("res://assets/tiles/sangue.png")
const TEX_PLACA := preload("res://assets/tiles/placa.png")
const TEX_SAIDA := preload("res://assets/tiles/saida.png")
const TEX_HEROI := preload("res://assets/sprites/heroi.png")

const DIRECOES := {
	"mover_cima": Vector2i.UP,
	"mover_baixo": Vector2i.DOWN,
	"mover_esquerda": Vector2i.LEFT,
	"mover_direita": Vector2i.RIGHT,
}

var mapa: Dictionary = Mapas.CRIPTA
var grade: Array[String] = []
var placas: Dictionary = {}  # Vector2i -> texto
var inimigos: Dictionary = {}  # id -> {no, pos, tipo}

var jogador: Sprite2D
var pos_jogador := Vector2i.ZERO
var direcao := Vector2i.DOWN
var movendo := false
var bloqueado := false  # diálogo aberto ou batalha começando
var tempo_inimigos := 0.0
var tregua := 0.0  # segundos sem batalha após uma fuga

var hud: Label
var caixa_dialogo: PanelContainer
var texto_dialogo: Label


func _ready() -> void:
	_carregar_mapa()
	_criar_interface()
	_atualizar_hud()


func _carregar_mapa() -> void:
	var indice_placa := 0
	for y in mapa["linhas"].size():
		var linha: String = mapa["linhas"][y]
		var limpa := ""
		for x in linha.length():
			var c := linha[x]
			var pos := Vector2i(x, y)
			match c:
				"P":
					pos_jogador = pos
					c = "."
				"S":
					placas[pos] = mapa["placas"][indice_placa] if indice_placa < mapa["placas"].size() else "..."
					indice_placa += 1
				"C", "O":
					var id := "%s_%d_%d" % [c, x, y]
					if not Jogo.inimigos_derrotados.has(id):
						_criar_inimigo(id, "cruzado" if c == "C" else "oco", pos)
					c = "."
			limpa += c
		grade.append(limpa)

	jogador = Sprite2D.new()
	jogador.texture = TEX_HEROI
	jogador.centered = false
	jogador.position = Vector2(pos_jogador * TILE)
	jogador.z_index = 2
	add_child(jogador)

	var camera := Camera2D.new()
	camera.position = Vector2(TILE / 2, TILE / 2)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = grade[0].length() * TILE
	camera.limit_bottom = grade.size() * TILE
	camera.position_smoothing_enabled = true
	jogador.add_child(camera)
	queue_redraw()


func _criar_inimigo(id: String, tipo: String, pos: Vector2i) -> void:
	var no := Sprite2D.new()
	no.texture = load(Inimigos.DADOS[tipo]["sprite_mapa"])
	no.centered = false
	no.position = Vector2(pos * TILE)
	no.z_index = 1
	add_child(no)
	inimigos[id] = {"no": no, "pos": pos, "tipo": tipo}


func _draw() -> void:
	for y in grade.size():
		for x in grade[y].length():
			var destino := Vector2(x * TILE, y * TILE)
			match grade[y][x]:
				"#":
					draw_texture(TEX_PAREDE, destino)
				"A":
					draw_texture(TEX_ALTAR, destino)
				",":
					draw_texture(TEX_SANGUE, destino)
				"S":
					draw_texture(TEX_PLACA, destino)
				"X":
					draw_texture(TEX_SAIDA, destino)
				_:
					draw_texture(TEX_CHAO, destino)


# ---------------------------------------------------------------- Interface

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)

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
	caixa_dialogo.position = Vector2(40, 390)
	caixa_dialogo.custom_minimum_size = Vector2(880, 130)
	caixa_dialogo.add_theme_stylebox_override("panel", _estilo_painel(Color(0.05, 0.03, 0.04, 0.92)))
	caixa_dialogo.visible = false
	camada.add_child(caixa_dialogo)
	texto_dialogo = Label.new()
	texto_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_dialogo.add_theme_font_size_override("font_size", 16)
	caixa_dialogo.add_child(texto_dialogo)


static func _estilo_painel(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color(0.45, 0.12, 0.12)
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(10)
	return estilo


func _atualizar_hud() -> void:
	var linhas := [mapa["nome"]]
	for membro in Jogo.party:
		var hp: int = membro.get("hp_atual", membro["hp"])
		var mp: int = membro.get("mp_atual", membro["mp"])
		var estado := ""
		if hp <= 0:
			estado = "  (morto)"
		elif membro.get("sangrando", false):
			estado = "  (sangrando)"
		linhas.append("%s  HP %d/%d  MP %d/%d%s" % [membro["nome"], hp, membro["hp"], mp, membro["mp"], estado])
	linhas.append("Bandagens: %d" % Jogo.itens.get("bandagem", 0))
	hud.text = "\n".join(linhas)


func _mostrar_dialogo(texto: String) -> void:
	texto_dialogo.text = texto + "\n\n[Z]"
	caixa_dialogo.visible = true
	bloqueado = true


func _fechar_dialogo() -> void:
	caixa_dialogo.visible = false
	bloqueado = false


# ---------------------------------------------------------------- Loop

func _process(delta: float) -> void:
	if caixa_dialogo.visible:
		if Input.is_action_just_pressed("interagir"):
			_fechar_dialogo()
		return
	if bloqueado:
		return
	tregua = maxf(0.0, tregua - delta)

	tempo_inimigos += delta
	if tempo_inimigos >= INTERVALO_INIMIGO:
		tempo_inimigos = 0.0
		_mover_inimigos()
		if bloqueado:
			return

	if Input.is_action_just_pressed("interagir"):
		_interagir()
		return

	if movendo:
		return
	for acao in DIRECOES:
		if Input.is_action_pressed(acao):
			_tentar_mover(DIRECOES[acao])
			break


func _tile(pos: Vector2i) -> String:
	if pos.y < 0 or pos.y >= grade.size() or pos.x < 0 or pos.x >= grade[pos.y].length():
		return "#"
	return grade[pos.y][pos.x]


func _livre(pos: Vector2i) -> bool:
	return _tile(pos) in [".", ",", "X"]


func _inimigo_em(pos: Vector2i) -> String:
	for id in inimigos:
		if inimigos[id]["pos"] == pos:
			return id
	return ""


func _tentar_mover(dir: Vector2i) -> void:
	direcao = dir
	jogador.flip_h = dir == Vector2i.LEFT if dir.x != 0 else jogador.flip_h
	var alvo := pos_jogador + dir
	var inimigo := _inimigo_em(alvo)
	if inimigo != "":
		_encontro(inimigo)
		return
	if not _livre(alvo):
		return
	pos_jogador = alvo
	movendo = true
	var tween := create_tween()
	tween.tween_property(jogador, "position", Vector2(alvo * TILE), TEMPO_PASSO)
	await tween.finished
	movendo = false
	if _tile(pos_jogador) == "X":
		_mostrar_dialogo("Uma escada sobe para a luz dos Nove Sóis... e para os Cruzados lá fora.\nFim da demonstração. Obrigado por jogar!")


func _interagir() -> void:
	var alvo := pos_jogador + direcao
	if placas.has(alvo):
		_mostrar_dialogo(placas[alvo])
	elif _tile(alvo) == "A":
		Jogo.descansar()
		_atualizar_hud()
		_mostrar_dialogo("Você reza diante do Altar dos Nove Sóis. As feridas fecham e o sangue estanca.\nO que foi perdido, porém, não volta.")


func _mover_inimigos() -> void:
	for id in inimigos.keys():
		var dados: Dictionary = inimigos[id]
		var pos: Vector2i = dados["pos"]
		var dist := absi(pos.x - pos_jogador.x) + absi(pos.y - pos_jogador.y)
		var opcoes: Array[Vector2i] = []
		if dist <= ALCANCE_PERSEGUICAO and tregua <= 0.0:
			var dx := signi(pos_jogador.x - pos.x)
			var dy := signi(pos_jogador.y - pos.y)
			if absi(pos_jogador.x - pos.x) >= absi(pos_jogador.y - pos.y):
				opcoes = [Vector2i(dx, 0), Vector2i(0, dy)]
			else:
				opcoes = [Vector2i(0, dy), Vector2i(dx, 0)]
		elif Jogo.rng.randf() < 0.35:
			opcoes = [[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][Jogo.rng.randi() % 4]]
		for dir in opcoes:
			if dir == Vector2i.ZERO:
				continue
			var alvo := pos + dir
			if alvo == pos_jogador:
				if tregua <= 0.0 and not movendo:
					_encontro(id)
					return
				break
			if _livre(alvo) and _inimigo_em(alvo) == "" and _tile(alvo) != "X":
				dados["pos"] = alvo
				var tween := create_tween()
				tween.tween_property(dados["no"], "position", Vector2(alvo * TILE), TEMPO_PASSO * 1.5)
				break


func _encontro(id: String) -> void:
	if tregua > 0.0:
		return
	bloqueado = true
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
	_atualizar_hud()
