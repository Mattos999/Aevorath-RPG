extends SceneTree
## Cria ou atualiza assets/tiles/tileset.tres a partir dos atlas de
## tools/montar_atlas.py. Uso: godot --headless -s res://tools/gerar_tileset.gd
## Fonte 0 = terreno, fonte 1 = entidades. Cada tile ganha o dado "letra".
## Se o TileSet já existe, só acrescenta os tiles novos (mantém o resto).

const SAIDA := "res://assets/tiles/tileset.tres"
const FONTES := ["terreno", "entidades"]


func _init() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/atlas.json"))
	var tileset: TileSet
	if ResourceLoader.exists(SAIDA):
		tileset = load(SAIDA)
	else:
		tileset = TileSet.new()
		tileset.tile_size = Vector2i(32, 32)
		tileset.add_custom_data_layer()
		tileset.set_custom_data_layer_name(0, "letra")
		tileset.set_custom_data_layer_type(0, TYPE_STRING)
	for i in FONTES.size():
		var atlas: TileSetAtlasSource
		if tileset.has_source(i):
			atlas = tileset.get_source(i)
		else:
			atlas = TileSetAtlasSource.new()
			atlas.resource_name = FONTES[i].capitalize()
			atlas.texture_region_size = Vector2i(32, 32)
			atlas.texture = load("res://assets/tiles/atlas_%s.png" % FONTES[i])
			tileset.add_source(atlas, i)
		for tile in dados[FONTES[i]]:
			var coords := Vector2i(tile["x"], tile["y"])
			if not atlas.has_tile(coords):
				atlas.create_tile(coords)
			atlas.get_tile_data(coords, 0).set_custom_data("letra", tile["letra"])
	print("tileset: ", ResourceSaver.save(tileset, SAIDA))
	quit()
