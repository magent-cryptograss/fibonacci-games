extends Node2D
## Entry point. Scene routing lives here; the individual screens are children
## swapped in and out, so each stays a self-contained scene.

var current: Node = null


func _ready() -> void:
	# placeholder until the screens land -- proves the boot path and the data
	var lbl := Label.new()
	lbl.text = "SONGBOUND\n%d elements, %d songs, %d instruments\n%d creatures" % [
		Data.ELEMENTS.size(),
		_song_count(),
		Data.INSTRUMENTS.size(),
		Data.BESTIARY.size(),
	]
	lbl.position = Vector2(12, 12)
	add_child(lbl)

	var p := Sprites.build(Sprites.PRESETS[1].opts)
	var tex := Sprites.to_texture(p)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(3, 3)
	s.position = Vector2(140, 120)
	add_child(s)


func _song_count() -> int:
	var n := 0
	for k in Data.SONGS:
		n += Data.SONGS[k].size()
	return n
