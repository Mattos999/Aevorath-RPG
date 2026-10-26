extends SceneTree
## Cria assets/tiles/tileset.tres a partir dos atlas de tools/montar_atlas.py.
## Uso: godot --headless -s res://tools/gerar_tileset.gd
## Fonte 0 = terreno, fonte 1 = entidades. Cada tile ganha o dado "letra".

const SAIDA := "res://assets/tiles/tileset.tres"


func _init() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/atlas.json"))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "letra")
	tileset.set_custom_data_layer_type(0, TYPE_STRING)
	for fonte in ["terreno", "entidades"]:
		var atlas := TileSetAtlasSource.new()
		atlas.resource_name = fonte.capitalize()
		atlas.texture = load("res://assets/tiles/atlas_%s.png" % fonte)
		atlas.texture_region_size = Vector2i(32, 32)
		tileset.add_source(atlas)
		for tile in dados[fonte]:
			var coords := Vector2i(tile["x"], tile["y"])
			atlas.create_tile(coords)
			atlas.get_tile_data(coords, 0).set_custom_data("letra", tile["letra"])
	print("tileset: ", ResourceSaver.save(tileset, SAIDA))
	quit()
