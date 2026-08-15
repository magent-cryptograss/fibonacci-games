class_name MapIO
extends RefCounted
## Maps as JSON on disk, so the editor can own them instead of the code.
##
## World.gd still generates a default world. Any map with a saved file
## overrides the generated one at load, which means you can redraw one corner of
## the game without touching anything else.

const DIR := "user://maps/"


static func dir_path() -> String:
	return ProjectSettings.globalize_path(DIR)


static func ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(dir_path())


static func path_for(id: String) -> String:
	return DIR + id + ".json"


static func has_saved(id: String) -> bool:
	return FileAccess.file_exists(path_for(id))


static func to_dict(m: Maps.GameMap) -> Dictionary:
	return {
		"v": 1,
		"id": m.id,
		"w": m.w,
		"h": m.h,
		"tiles": "".join(m.tiles),
		"region": m.region,
		"music": m.music,
		"indoor": m.indoor,
		"start": [m.start.x, m.start.y],
		"warps": m.warps,
		"npcs": _strip_runtime(m.npcs),
		"chests": m.chests,
		"boss": m.boss,
	}


## Drop fields the game adds while running, so saves stay diffable.
static func _strip_runtime(npcs: Array) -> Array:
	var out := []
	for n in npcs:
		var c: Dictionary = n.duplicate(true)
		c.erase("wt")
		out.append(c)
	return out


static func save(m: Maps.GameMap) -> String:
	ensure_dir()
	var f := FileAccess.open(path_for(m.id), FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(to_dict(m), "\t"))
	f.close()
	return ProjectSettings.globalize_path(path_for(m.id))


static func from_dict(d: Dictionary) -> Maps.GameMap:
	var m := Maps.GameMap.new(str(d.id), int(d.w), int(d.h), ".")
	var tiles: String = str(d.tiles)
	for i in mini(tiles.length(), m.w * m.h):
		m.tiles[i] = tiles[i]
	m.region = str(d.get("region", "meadow"))
	m.music = str(d.get("music", "field"))
	m.indoor = bool(d.get("indoor", false))
	var st: Array = d.get("start", [1, 1])
	m.start = Vector2i(int(st[0]), int(st[1]))
	m.warps = d.get("warps", [])
	m.npcs = d.get("npcs", [])
	m.chests = d.get("chests", [])
	m.boss = d.get("boss", null)
	return m


static func load_map(id: String) -> Maps.GameMap:
	if not has_saved(id):
		return null
	var f := FileAccess.open(path_for(id), FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)


## Overlay every saved map on top of the generated set.
static func apply_overrides(maps: Dictionary) -> int:
	ensure_dir()
	var n := 0
	var d := DirAccess.open(DIR)
	if d == null:
		return 0
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var id := fname.get_basename()
			var m := load_map(id)
			if m != null:
				Maps.prerender(m)
				maps[id] = m
				n += 1
		fname = d.get_next()
	d.list_dir_end()
	return n
