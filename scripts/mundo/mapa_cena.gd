class_name MapaCena
extends Node2D
## Um mapa pintado no editor do Godot. A cena tem duas camadas de tiles:
##   Terreno    chão, paredes e objetos (o que aparece no jogo)
##   Entidades  onde começam o jogador, NPCs, inimigos e itens (some no jogo)
## Cada tile tem a "letra" (dado personalizado do TileSet) que diz o que ele é:
##   #  parede          T  parede com tocha    |  grade de cela
##   D  cela trancada   d  cela aberta         W  porta de madeira
##   .  chão            ,  sangue              ~  chão rachado
##   *  feixe de luz (sol de dia, lua à noite: magia funciona aqui)
##   B  cama   U  balde   R  barril   Q  caixa   o  buraco   (bloqueiam)
##   A  Altar dos Nove Sóis (descanso)
##   S  placa   K  esqueleto   (mostram os Textos abaixo, na ordem de leitura)
##   X  escada (fim da demo)
## Entidades:
##   P  início do jogador   H  o encapuzado
##   C  Cruzado   O  Fiel Oco   F  Fiel Oca   N  Soldado de Sarnheim   V  Paladino
##   G  Pedra Solar no chão
## Pinte a partir da célula (0, 0) para a direita e para baixo.

@export var nome := "Novo mapa"
## "escuro" para masmorras, "aberto" para lugares sob o céu.
@export_enum("escuro", "aberto") var luz := "escuro"
@export_file("*.png") var fundo_batalha := "res://assets/batalha/fundo_prisao.png"
## Textos das placas (S) e esqueletos (K), na ordem em que aparecem lendo o
## mapa linha a linha, da esquerda para a direita.
@export_multiline var textos: Array[String] = []

@onready var terreno: TileMapLayer = $Terreno
@onready var entidades: TileMapLayer = $Entidades


## O mapa como linhas de letras (célula vazia = parede), com as entidades por cima.
func ler_grade() -> Array[String]:
	var a := terreno.get_used_rect().end
	var b := entidades.get_used_rect().end
	var fim := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	var grade: Array[String] = []
	for y in fim.y:
		var linha := ""
		for x in fim.x:
			var letra := _letra(entidades, Vector2i(x, y))
			if letra == "":
				letra = _letra(terreno, Vector2i(x, y))
			linha += letra if letra != "" else "#"
		grade.append(linha)
	return grade


## Troca o tile do terreno por um que tenha a letra dada (ex.: abrir uma cela).
func trocar_terreno(pos: Vector2i, letra: String) -> void:
	var fonte := terreno.get_cell_source_id(pos)
	var atlas := terreno.tile_set.get_source(maxi(fonte, 0)) as TileSetAtlasSource
	for i in atlas.get_tiles_count():
		var coords := atlas.get_tile_id(i)
		if atlas.get_tile_data(coords, 0).get_custom_data("letra") == letra:
			terreno.set_cell(pos, maxi(fonte, 0), coords)
			return


static func _letra(camada: TileMapLayer, pos: Vector2i) -> String:
	var dados := camada.get_cell_tile_data(pos)
	return dados.get_custom_data("letra") if dados else ""
