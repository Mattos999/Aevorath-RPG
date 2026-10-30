@tool
@icon("res://assets/itens/pedra_solar_24.png")
class_name Entidade
extends Node2D
## Algo que vive no mapa: inimigo, NPC ou Pedra Solar no chão.
## Coloque como filho da cena do mapa (botão direito no nó raiz > Adicionar
## nó filho > Entidade), arraste até a célula e configure no Inspector.
## A posição gruda na grade de 64 px sozinha.

enum Tipo { INIMIGO, NPC, PEDRA_SOLAR }

const TILE := 64
const FOLHA_PEDRA := "res://assets/itens/pedra_solar_48.png"

@export var tipo := Tipo.INIMIGO:
	set(valor):
		tipo = valor
		notify_property_list_changed()
		queue_redraw()

@export_group("Inimigo")
@export_enum("cruzado", "oco", "oca", "sarnheim", "paladino") var inimigo := "oco":
	set(valor):
		inimigo = valor
		queue_redraw()
## parado: fica no lugar (luta se você encostar).
## vagar: anda ao acaso, nunca persegue.
## perseguir: anda ao acaso e corre atrás de você quando te vê.
## patrulhar: vai e volta numa linha e corre atrás de você quando te vê.
@export_enum("parado", "vagar", "perseguir", "patrulhar") var comportamento := "perseguir"
## Até quantas casas de distância ele te enxerga (perseguir e patrulhar).
@export_range(1, 20) var alcance_visao := 6
## Segundos entre um passo e outro (menor = mais rápido).
@export_range(0.15, 3.0, 0.05) var intervalo := 0.45
@export_enum("horizontal", "vertical") var direcao_patrulha := "horizontal"
## Quantas casas ele anda para cada lado na patrulha.
@export_range(1, 20) var distancia_patrulha := 3

@export_group("NPC")
## Nome usado nos eventos (ex.: "encapuzado"). Vazio = nome do nó.
@export var id_npc := ""
@export_file("*.png") var folha := "res://assets/sprites/encapuzado.png":
	set(valor):
		folha = valor
		queue_redraw()
## Arquivo .dialogue com a conversa (aba Dialogue do editor).
@export var dialogo: DialogueResource
## Onde a conversa começa dentro do arquivo (a linha "~ start").
@export var cue := "start"
## Se este evento já aconteceu (Jogo.eventos), o NPC não aparece.
@export var some_com_evento := ""

var _editando := false


func _ready() -> void:
	set_notify_transform(true)
	if not Engine.is_editor_hint():
		visible = false


func _notification(que: int) -> void:
	if que == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint() and not _editando:
		_editando = true
		position = (position / TILE).floor() * TILE
		_editando = false


## Célula da grade onde a entidade está.
func celula() -> Vector2i:
	return Vector2i((position / TILE).floor())


func id_unico() -> String:
	return id_npc if id_npc != "" else String(name)


func textura() -> String:
	match tipo:
		Tipo.INIMIGO:
			return Inimigos.DADOS[inimigo]["sprite_mapa"]
		Tipo.PEDRA_SOLAR:
			return FOLHA_PEDRA
	return folha


## Esconde do Inspector os campos que não valem para o tipo escolhido.
func _validate_property(propriedade: Dictionary) -> void:
	var de_inimigo := ["inimigo", "comportamento", "alcance_visao", "intervalo", "direcao_patrulha", "distancia_patrulha"]
	var de_npc := ["id_npc", "folha", "dialogo", "cue", "some_com_evento"]
	if (propriedade.name in de_inimigo and tipo != Tipo.INIMIGO) or (propriedade.name in de_npc and tipo != Tipo.NPC):
		propriedade.usage = PROPERTY_USAGE_NO_EDITOR


## No editor, mostra o primeiro quadro da folha na célula.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var caminho := textura()
	if caminho == "" or not ResourceLoader.exists(caminho):
		draw_rect(Rect2(0, 0, TILE, TILE), Color(1, 0, 1, 0.5))
		return
	var tex: Texture2D = load(caminho)
	var origem := Rect2(Vector2.ZERO, tex.get_size())
	if tex.get_width() == TILE * 3 and tex.get_height() == TILE * 4:
		origem = Rect2(0, 0, TILE, TILE)
	var destino := Rect2(Vector2.ZERO, Vector2(TILE, TILE))
	if tipo == Tipo.PEDRA_SOLAR:
		destino = Rect2(Vector2(8, 8), Vector2(48, 48))
	draw_texture_rect_region(tex, destino, origem)
	draw_rect(Rect2(0, 0, TILE, TILE), Color(1, 0.3, 0.3) if tipo == Tipo.INIMIGO else Color(0.4, 0.8, 1.0), false, 1.0)
