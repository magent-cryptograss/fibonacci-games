extends Node2D
## Drives the whole loop -- title, field, battle, level-up, ending -- and
## screenshots each. Catches the wiring mistakes that only appear when the
## scenes are actually talking to each other.

const OUT_DIR := "user://shots/"

var main: Node2D
var failures := 0
var step := 0
var wait := 0
var shots := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)


func _expect(cond: bool, what: String) -> void:
	if cond:
		print("  ok   %s" % what)
	else:
		print("  FAIL %s" % what)
		failures += 1


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	img.save_png(OUT_DIR + "flow-%02d-%s.png" % [shots, name])
	shots += 1


func _process(_d: float) -> void:
	wait += 1
	if wait < 5:
		return
	wait = 0
	match step:
		0:
			print("")
			print("== full flow ==")
			_expect(main.state == main.S.TITLE, "boots to the title")
			_shot("title")
		1:
			# make a character the way creation would, then walk into the world
			Game.new_game("Wren", "banjo", Sprites.build(Sprites.PRESETS[1].opts), "fire")
			_expect(Game.player != null, "player created")
			_expect(Game.player.songs.size() == 1, "level 1 taught one song")
			main._enter_field("town", Vector2i(15, 22))
			_expect(main.state == main.S.FIELD, "entered the field")
			_expect(main.current.map.id == "town", "in town")
		2:
			main.current.say(Story.OPENING)
			_shot("opening")
		3:
			main.current.msg = null
			_shot("town")
			# an ordinary fight
			main._start_battle("meadow", "", "")
			_expect(main.state == main.S.BATTLE, "battle started")
			_expect(main.current.enemies.size() >= 1, "%d creature(s) turned up" % main.current.enemies.size())
		4:
			_shot("battle-intro")
		5:
			var b: Node = main.current
			b.phase = "command"
			_shot("battle-command")
			_expect(b.alive().size() > 0, "creatures alive at the command prompt")
		6:
			var b: Node = main.current
			b.phase = "songmenu"
			b.sel = 0
			_shot("battle-songs")
			# cast the first song for real and check breath is spent
			var before_br: int = Game.player.br
			var songs: Array = Game.player.song_book()
			b.do_song(songs[0], 0)
			_expect(Game.player.br < before_br, "casting spent breath (%d -> %d)" % [before_br, Game.player.br])
		7:
			_shot("battle-song-fx")
		8:
			# win it outright and check the reward path
			var b: Node = main.current
			for e in b.enemies:
				e.hp = 0
				e["dead"] = true
			b._end(true)
			_expect(b.phase == "victory", "victory screen reached")
			_expect(b.reward.xp > 0, "xp awarded (%d)" % b.reward.xp)
			_shot("battle-victory")
		9:
			# force enough levels that the level-up screen has to appear
			Game.award_xp(4000)
			_expect(not Game.level_queue.is_empty(), "levels queued (%d)" % Game.level_queue.size())
			main._on_battle_done("win")
			_expect(main.state == main.S.LEVELUP, "level-up screen shown")
		10:
			_shot("levelup")
			var lu: Node = main.current
			var songs_before: int = Game.player.songs.size()
			lu.sel = 1                       # first element card
			lu._choose()
			_expect(lu.phase == "result", "a choice was applied")
			_expect(Game.player.songs.size() >= songs_before, "song book did not shrink")
		11:
			_shot("levelup-result")
		12:
			# the shop, reached the way an NPC would open it
			main._on_shop(["tonic", "rosin", "strings"])
			_expect(main.state == main.S.SHOP, "shop opened")
			_shot("shop")
		13:
			main.state = main.S.FIELD
			# and the ending
			main._start_ending()
			_expect(main.state == main.S.ENDING, "ending started")
			_expect(main.end_lines.size() > 20, "%d ending lines" % main.end_lines.size())
			var too_wide := 0
			for l in main.end_lines:
				if PixelFont.width(l) > UI.SCREEN_W:
					too_wide += 1
			_expect(too_wide == 0, "no ending line is wider than the screen")
		14:
			main.end_t = 6.0
			_shot("ending")
		15:
			main.end_t = 22.0
			_shot("ending-late")
		16:
			print("")
			print("FAILURES: %d" % failures if failures > 0 else "FLOW TESTS PASSED")
			get_tree().quit(1 if failures > 0 else 0)
	step += 1
