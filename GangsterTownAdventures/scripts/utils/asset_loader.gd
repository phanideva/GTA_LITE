extends Node
# AssetLoader — Loads optional GLB/GLTF assets if present, falls back to procedural meshes.
#
# Drop free Kenney assets into:
#   res://assets/models/vehicles/      (e.g. car_sedan.glb, taxi.glb, ambulance.glb)
#   res://assets/models/buildings/     (e.g. small_building.glb, skyscraper.glb)
#   res://assets/models/characters/    (e.g. character_male_a.glb)
#   res://assets/models/nature/        (e.g. palm_tree.glb, tree_oak.glb)
#   res://assets/models/props/         (e.g. trash_can.glb, neon_sign.glb)
#
# Free asset packs that work well:
#   • Kenney City Kit Suburban   – https://kenney.nl/assets/city-kit-suburban
#   • Kenney City Kit Commercial – https://kenney.nl/assets/city-kit-commercial
#   • Kenney Car Kit             – https://kenney.nl/assets/car-kit
#   • Kenney Mini Characters     – https://kenney.nl/assets/mini-characters-1
#   • Kenney Nature Kit          – https://kenney.nl/assets/nature-kit
# All Kenney assets are CC0 (public domain).
#
# Usage:
#   var palm = AssetLoader.load_or_null("res://assets/models/nature/palm_tree.glb")
#   if palm:
#       var instance = palm.instantiate()
#       add_child(instance)
#   else:
#       _build_procedural_palm()  # fallback

const _BASE_PATHS := {
	"vehicle": "res://assets/models/vehicles/",
	"building": "res://assets/models/buildings/",
	"character": "res://assets/models/characters/",
	"nature": "res://assets/models/nature/",
	"prop": "res://assets/models/props/",
}

var _cache: Dictionary = {}

func load_or_null(path: String) -> PackedScene:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var res = load(path)
	if res is PackedScene:
		_cache[path] = res
		return res
	# If it's a Mesh resource, wrap it in a PackedScene
	if res is Mesh:
		var s := PackedScene.new()
		var n := MeshInstance3D.new()
		n.mesh = res
		var pack_result := s.pack(n)
		if pack_result == OK:
			_cache[path] = s
			return s
	_cache[path] = null
	return null

func pick_random(category: String, names: Array) -> PackedScene:
	if not _BASE_PATHS.has(category):
		return null
	if names.is_empty():
		return null
	var n: String = names[randi() % names.size()]
	return load_or_null(_BASE_PATHS[category] + n)

func has_any(category: String) -> bool:
	if not _BASE_PATHS.has(category):
		return false
	var dir = DirAccess.open(_BASE_PATHS[category])
	if dir == null:
		return false
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if f.ends_with(".glb") or f.ends_with(".gltf") or f.ends_with(".tscn"):
			return true
	return false
