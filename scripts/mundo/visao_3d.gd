class_name Visao3D
extends CanvasLayer
## Mostra o mapa do Mundo em 3D, com câmera inclinada e visual pixelado.
## A lógica continua toda no Mundo (grade de letras e Sprite2D): esta camada
## só monta o cenário a partir da grade e copia a posição e o quadro de cada
## Sprite2D para um Sprite3D em pé no chão. F3 alterna entre 2D e 3D.
##
## O cenário sai do mesmo mapa pintado no editor (scenes/mapas/), então
## pintar o TileMap 2D também muda o 3D.

## Resolução real do 3D (a tela é ampliada 2x, o que dá o visual pixelado).
const ENCOLHER := 1
## Altura das paredes. Paredes com chão logo atrás (do lado da câmera)
## ficam baixas para não esconder quem está atrás delas.
const ALTURA_PAREDE := 1.0
const ALTURA_PAREDE_FRENTE := 0.3
## Câmera: distância acima e atrás do jogador.
const CAMERA_ALTURA := 6.0
const CAMERA_DISTANCIA := 4.2
const PIXEL := 1.0 / 64.0
## Letras que viram parede (bloco), grade/porta (placa fina) ou só chão.
const PAREDES := "#T"
const PLACAS := "|D"

var mundo: Node2D
var raiz: Node3D
var camera: Camera3D
var tela: SubViewportContainer
var luz_ambiente: Environment
## Sprite2D do Mundo -> Sprite3D que o representa.
var copias: Dictionary = {}
## Grade da última montagem, para refazer só as células que mudaram.
var grade_montada: Array[String] = []
## Vector2i -> Node3D da célula.
var celulas: Dictionary = {}
var materiais: Dictionary = {}
var feixes: Array[Node3D] = []


func _init(dono: Node2D) -> void:
	mundo = dono
	layer = -1


func _ready() -> void:
	tela = SubViewportContainer.new()
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.stretch = true
	tela.stretch_shrink = ENCOLHER
	tela.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tela)
	var viewport := SubViewport.new()
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	tela.add_child(viewport)
	raiz = Node3D.new()
	viewport.add_child(raiz)

	var ambiente := WorldEnvironment.new()
	luz_ambiente = Environment.new()
	luz_ambiente.background_mode = Environment.BG_COLOR
	luz_ambiente.background_color = Color(0.02, 0.015, 0.02)
	luz_ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	luz_ambiente.ambient_light_color = Color(0.55, 0.5, 0.6)
	luz_ambiente.ambient_light_energy = 0.45
	ambiente.environment = luz_ambiente
	raiz.add_child(ambiente)

	camera = Camera3D.new()
	camera.fov = 45
	raiz.add_child(camera)

	_montar_cenario()
	_seguir_jogador(true)
	ativar(true)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F3:
		ativar(not visible)


## Liga ou desliga o 3D (com ele desligado, o Mundo aparece em 2D como antes).
func ativar(ligado: bool) -> void:
	visible = ligado
	for no in mundo.get_children():
		if no is CanvasItem:
			no.visible = not ligado
	set_process(ligado)


func _process(_delta: float) -> void:
	if mundo.grade != grade_montada:
		_atualizar_celulas()
	_copiar_sprites()
	_seguir_jogador(false)
	var dia: bool = Jogo.eh_dia()
	for feixe in feixes:
		feixe.get_child(0).light_color = Color(1.0, 0.85, 0.55) if dia else Color(0.55, 0.65, 1.0)


# ---------------------------------------------------------------- Cenário

func _montar_cenario() -> void:
	grade_montada = mundo.grade.duplicate()
	for y in grade_montada.size():
		for x in grade_montada[y].length():
			_montar_celula(Vector2i(x, y))


func _atualizar_celulas() -> void:
	var nova: Array[String] = mundo.grade.duplicate()
	for y in nova.size():
		for x in nova[y].length():
			if y >= grade_montada.size() or x >= grade_montada[y].length() or nova[y][x] != grade_montada[y][x]:
				var pos := Vector2i(x, y)
				if celulas.has(pos):
					celulas[pos].queue_free()
					celulas.erase(pos)
				grade_montada = nova
				_montar_celula(pos)
	grade_montada = nova


func _letra(pos: Vector2i) -> String:
	if pos.y < 0 or pos.y >= grade_montada.size() or pos.x < 0 or pos.x >= grade_montada[pos.y].length():
		return "#"
	return grade_montada[pos.y][pos.x]


func _montar_celula(pos: Vector2i) -> void:
	var letra := _letra(pos)
	var no := Node3D.new()
	no.position = Vector3(pos.x, 0, pos.y)
	raiz.add_child(no)
	celulas[pos] = no
	var textura := _textura_da_celula(pos)
	if letra in PAREDES:
		var frente := not _letra(pos + Vector2i.UP) in PAREDES
		var altura := ALTURA_PAREDE_FRENTE if frente else ALTURA_PAREDE
		if _tudo_parede_em_volta(pos):
			_quad(no, "topo", Vector3(0.5, altura, 0.5), Vector3(-90, 0, 0), Vector2(1, 1))
			return
		_quad(no, "topo", Vector3(0.5, altura, 0.5), Vector3(-90, 0, 0), Vector2(1, 1))
		for lado in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if not _letra(pos + lado) in PAREDES:
				_face(no, textura, lado, altura)
		if letra == "T":
			for lado in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
				if not _letra(pos + lado) in PAREDES:
					var tocha := OmniLight3D.new()
					tocha.light_color = Color(1.0, 0.6, 0.25)
					tocha.light_energy = 1.6
					tocha.omni_range = 4.5
					tocha.position = Vector3(0.5 + lado.x * 0.7, 0.8, 0.5 + lado.y * 0.7)
					no.add_child(tocha)
					break
		return
	_quad(no, textura, Vector3(0.5, 0, 0.5), Vector3(-90, 0, 0), Vector2(1, 1))
	if letra in PLACAS:
		# Grade e porta de cela: uma placa fina em pé no meio da célula.
		var deitada := _letra(pos + Vector2i.LEFT) in PAREDES + PLACAS and _letra(pos + Vector2i.RIGHT) in PAREDES + PLACAS
		var placa := Node3D.new()
		placa.position = Vector3(0.5, 0, 0.5)
		placa.rotation_degrees.y = 0 if deitada else 90
		no.add_child(placa)
		for giro in [0, 180]:
			_quad(placa, textura, Vector3(0, 0.5, 0), Vector3(0, giro, 0), Vector2(1, 1))
	elif letra == "*":
		var feixe := Node3D.new()
		var luz := SpotLight3D.new()
		luz.position = Vector3(0.5, 4, 0.5)
		luz.rotation_degrees.x = -90
		luz.spot_range = 6
		luz.spot_angle = 11
		luz.light_energy = 2.0
		feixe.add_child(luz)
		no.add_child(feixe)
		feixes.append(feixe)
		# Coluna de luz: caixas vizinhas se juntam num feixe só.
		var brilho := MeshInstance3D.new()
		var coluna := BoxMesh.new()
		coluna.size = Vector3(1, 3, 1)
		brilho.mesh = coluna
		brilho.position = Vector3(0.5, 1.5, 0.5)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.albedo_color = Color(1.0, 0.85, 0.5, 0.035)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		brilho.material_override = material
		no.add_child(brilho)


func _tudo_parede_em_volta(pos: Vector2i) -> bool:
	for lado in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		if not _letra(pos + lado) in PAREDES:
			return false
	return true


## Face vertical da parede virada para `lado`.
func _face(no: Node3D, textura: String, lado: Vector2i, altura: float) -> void:
	var centro := Vector3(0.5 + lado.x * 0.5, altura / 2, 0.5 + lado.y * 0.5)
	var giro: int = {Vector2i.DOWN: 0, Vector2i.RIGHT: 90, Vector2i.UP: 180, Vector2i.LEFT: -90}[lado]
	_quad(no, textura, centro, Vector3(0, giro, 0), Vector2(1, altura))


func _quad(no: Node3D, textura: String, pos: Vector3, giro: Vector3, tamanho: Vector2) -> void:
	var malha := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = tamanho
	malha.mesh = quad
	malha.position = pos
	malha.rotation_degrees = giro
	malha.material_override = _material(textura, tamanho.y)
	no.add_child(malha)


func _material(chave: String, altura := 1.0) -> StandardMaterial3D:
	var id := "%s@%.2f" % [chave, altura]
	if materiais.has(id):
		return materiais[id]
	var material := StandardMaterial3D.new()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	if chave == "topo":
		material.albedo_color = Color(0.16, 0.14, 0.15)
	else:
		material.albedo_texture = _atlas(chave)
		# Paredes baixas mostram só a parte de baixo da textura.
		material.uv1_scale = Vector3(1, altura, 1)
		material.uv1_offset = Vector3(0, 1.0 - altura, 0)
	materiais[id] = material
	return material


## Textura de uma célula do TileMap do terreno ("fonte:x:y").
func _textura_da_celula(pos: Vector2i) -> String:
	var terreno: TileMapLayer = mundo.mapa.terreno
	var fonte := terreno.get_cell_source_id(pos)
	if fonte < 0:
		return "topo"
	var coords := terreno.get_cell_atlas_coords(pos)
	return "%d:%d:%d" % [fonte, coords.x, coords.y]


var _texturas: Dictionary = {}


func _atlas(chave: String) -> Texture2D:
	if _texturas.has(chave):
		return _texturas[chave]
	var partes := chave.split(":")
	var fonte := mundo.mapa.terreno.tile_set.get_source(int(partes[0])) as TileSetAtlasSource
	var coords := Vector2i(int(partes[1]), int(partes[2]))
	var imagem := fonte.texture.get_image().get_region(fonte.get_tile_texture_region(coords))
	var textura := ImageTexture.create_from_image(imagem)
	_texturas[chave] = textura
	return textura


# ---------------------------------------------------------------- Personagens

func _copiar_sprites() -> void:
	var vistos := {}
	for no in mundo.get_children():
		if not no is Sprite2D or no.is_queued_for_deletion():
			continue
		var s: Sprite2D = no
		vistos[s] = true
		if not copias.has(s):
			copias[s] = _criar_copia(s)
		var c: Sprite3D = copias[s]
		c.texture = s.texture
		c.hframes = s.hframes
		c.vframes = s.vframes
		c.frame = s.frame
		c.flip_h = s.flip_h
		var retangulo := s.get_rect()
		var centro := s.position + retangulo.get_center()
		var altura := retangulo.size.y * PIXEL
		c.position = Vector3(centro.x * PIXEL, altura / 2, centro.y * PIXEL)
	for s in copias.keys():
		if not vistos.has(s):
			copias[s].queue_free()
			copias.erase(s)


func _criar_copia(s: Sprite2D) -> Sprite3D:
	var c := Sprite3D.new()
	c.pixel_size = PIXEL
	c.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	c.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	c.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	c.shaded = true
	if s == mundo.jogador:
		# Uma luz fraca em volta do jogador, para ele não sumir no escuro.
		var luz := OmniLight3D.new()
		luz.light_color = Color(0.8, 0.75, 0.7)
		luz.light_energy = 0.5
		luz.omni_range = 2.5
		luz.position = Vector3(0, 0.6, 0.3)
		c.add_child(luz)
	raiz.add_child(c)
	return c


func _seguir_jogador(na_hora: bool) -> void:
	var j: Sprite2D = mundo.jogador
	var centro := (j.position + j.get_rect().get_center()) * PIXEL
	var alvo := Vector3(centro.x, 0.4, centro.y)
	var destino := alvo + Vector3(0, CAMERA_ALTURA, CAMERA_DISTANCIA)
	camera.position = destino if na_hora else camera.position.lerp(destino, 0.15)
	camera.look_at(camera.position - Vector3(0, CAMERA_ALTURA, CAMERA_DISTANCIA))
