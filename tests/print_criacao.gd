extends Node
## Tira prints da tela de criação para mostrar ao Carlos sem abrir o jogo.
## Uso (precisa de vídeo, ex.: xvfb-run): godot --resolution 960x540 res://tests/print_criacao.tscn
## Cada print sai no console em base64 (JPG) entre PRINT_INICIO e PRINT_FIM
## e também em user://print_criacao_<sol>.jpg.


func _ready() -> void:
	# Se algo travar, sai mesmo assim depois de 60 s.
	get_tree().create_timer(60.0).timeout.connect(get_tree().quit.bind(1))
	var tela := CriacaoPersonagem.new()
	add_child(tela)
	for id in ["vida", "morte", "verde", "medo"]:
		tela._escolher_sol(id)
		for i in 30:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_jpg("user://print_criacao_%s.jpg" % id, 0.92)
		var b64 := Marshalls.raw_to_base64(img.save_jpg_to_buffer(0.92))
		print("PRINT_INICIO ", id, " ", img.get_width(), "x", img.get_height())
		for i in range(0, b64.length(), 2000):
			print(b64.substr(i, 2000))
		print("PRINT_FIM")
	# Quadros do sol se mexendo (para montar um GIF fora do Godot).
	tela._escolher_sol("vida")
	for q in 24:
		for i in 5:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_jpg("user://print_criacao_anim_%02d.jpg" % q, 0.85)
	get_tree().quit()
