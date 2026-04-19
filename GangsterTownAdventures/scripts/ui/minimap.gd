extends Control
# Minimap — Vice City style circular radar with roads, POI icons, compass

const MAP_SIZE = 180
const MAP_RADIUS = 90.0
const MAP_SCALE = 0.8
const ROAD_SPACING = 50.0

var map_center: Vector2

# ═══ Points of Interest — world positions for minimap icons ═══
# [name, Vector3 position, color, icon_type]
# icon_type: "star"=landmark, "diamond"=mission, "square"=establishment, "circle"=save, "cross"=hospital
const POI_LANDMARKS = [
	["Hollywood Sign", Vector3(-200, 0, -200), Color(0.95, 0.4, 0.7), "star"],
	["Griffith Observatory", Vector3(-150, 0, -150), Color(1.0, 1.0, 1.0), "circle"],
	["Santa Monica Pier", Vector3(0, 0, 160), Color(0.3, 0.6, 1.0), "triangle"],
	["Venice Beach", Vector3(-60, 0, 155), Color(1.0, 0.85, 0.3), "triangle"],
	["Walk of Fame", Vector3(-30, 0, -35), Color(0.95, 0.8, 0.2), "star"],
	["Rodeo Drive", Vector3(130, 0, 40), Color(0.85, 0.7, 0.95), "diamond"],
	["Chinatown", Vector3(-130, 0, -40), Color(0.9, 0.2, 0.15), "square"],
	["LAX Tower", Vector3(160, 0, 120), Color(0.3, 0.8, 1.0), "triangle"],
	["Beverly Hills", Vector3(-160, 0, -100), Color(0.9, 0.85, 0.6), "diamond"],
	["Dodger Stadium", Vector3(100, 0, 75), Color(0.2, 0.4, 0.9), "square"],
]

const POI_ESTABLISHMENTS = [
	["Whiskey Bar", Vector3(-60, 0, 35), Color(0.7, 0.5, 0.2), "square"],
	["Venom Nightclub", Vector3(65, 0, -35), Color(0.6, 0.1, 0.8), "square"],
	["Paradise Strip", Vector3(-35, 0, -60), Color(1.0, 0.2, 0.5), "square"],
	["Sunset Pub", Vector3(40, 0, 65), Color(0.7, 0.5, 0.15), "square"],
	["Neon Lounge", Vector3(-85, 0, -25), Color(0.2, 0.8, 0.8), "square"],
	["Liquor King", Vector3(90, 0, 25), Color(0.8, 0.3, 0.1), "square"],
	["Lucky Pawn", Vector3(-45, 0, 85), Color(0.9, 0.8, 0.2), "diamond"],
	["Wash N Dry", Vector3(50, 0, -85), Color(0.4, 0.6, 0.9), "square"],
	["Mel's Diner", Vector3(120, 0, -50), Color(0.9, 0.3, 0.2), "square"],
	["Coyote Cantina", Vector3(-75, 0, -75), Color(0.5, 0.3, 0.1), "square"],
]

# Save points (floppy disk icon — orange)
const POI_SAVE_POINTS = [
	["Starlight Motel", Vector3(-120, 0, 50), Color(1.0, 0.6, 0.1), "save"],
	["Safe House", Vector3(22, 0, 22), Color(1.0, 0.6, 0.1), "save"],
	["Mel's Diner Save", Vector3(120, 0, -50), Color(1.0, 0.6, 0.1), "save"],
]

# Hospital / respawn
const POI_SERVICES = [
	["Hospital", Vector3(55, 0, 55), Color(1.0, 0.2, 0.2), "cross"],
	["Hospital South", Vector3(-55, 0, -55), Color(1.0, 0.2, 0.2), "cross"],
]

func _ready():
	map_center = Vector2(120, 820)

func _process(_delta):
	queue_redraw()

func _world_to_minimap(world_pos: Vector3, player_pos: Vector3) -> Vector2:
	var rel = Vector2(world_pos.x - player_pos.x, world_pos.z - player_pos.z)
	return map_center + rel * MAP_SCALE

func _in_circle(pos: Vector2) -> bool:
	return pos.distance_to(map_center) < MAP_RADIUS - 2.0

func _draw():
	if not Globals.player:
		return
	var pp = Globals.player.global_position

	# Circular background
	draw_circle(map_center, MAP_RADIUS + 2, Color(0.0, 0.0, 0.0, 0.85))
	draw_circle(map_center, MAP_RADIUS, Color(0.02, 0.08, 0.02, 0.75))

	# Road grid
	_draw_roads(pp)

	# ═══ POI BLIPS ═══
	# Landmarks (always visible — arrow if off-screen)
	for poi in POI_LANDMARKS:
		_draw_poi(poi[1], pp, poi[2], poi[3], true)

	# Establishments (visible on radar only)
	for poi in POI_ESTABLISHMENTS:
		_draw_poi(poi[1], pp, poi[2], poi[3], false)

	# Save points (always visible — arrow if off-screen, pulsing)
	for poi in POI_SAVE_POINTS:
		var pulse = 0.6 + 0.4 * abs(sin(Time.get_ticks_msec() / 600.0))
		_draw_poi(poi[1], pp, poi[2] * pulse, poi[3], true)

	# Services (hospitals)
	for poi in POI_SERVICES:
		_draw_poi(poi[1], pp, poi[2], poi[3], true)

	# Mission marker (yellow blip with pulsing)
	var ms = get_tree().get_first_node_in_group("mission_system")
	if ms and ms.is_mission_active and ms.current_mission.has("marker"):
		var marker_pos = ms.current_mission["marker"]
		var mp = _world_to_minimap(marker_pos, pp)
		if _in_circle(mp):
			draw_circle(mp, 7, Color(1.0, 0.85, 0.0))
			draw_circle(mp, 5, Color(1.0, 1.0, 0.5))
		else:
			var dir = (mp - map_center).normalized()
			var edge = map_center + dir * (MAP_RADIUS - 8)
			_draw_arrow(edge, dir, Color(1.0, 0.85, 0.0))

	# Police blips (flashing blue)
	if Globals.wanted_level > 0:
		for cop in get_tree().get_nodes_in_group("police"):
			if not is_instance_valid(cop):
				continue
			var p = _world_to_minimap(cop.global_position, pp)
			if _in_circle(p):
				var flash = 1.0 if fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0 else 0.5
				draw_circle(p, 4, Color(0.2, 0.4, 1.0, flash))

	# Enemy blips (red)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var p = _world_to_minimap(enemy.global_position, pp)
		if _in_circle(p):
			draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color(0.9, 0.1, 0.1))

	# Vehicle blips (small green)
	for v in get_tree().get_nodes_in_group("vehicle"):
		if not is_instance_valid(v):
			continue
		var vp = _world_to_minimap(v.global_position, pp)
		if _in_circle(vp):
			draw_rect(Rect2(vp.x - 2, vp.y - 2, 4, 4), Color(0.2, 0.7, 0.2, 0.5))

	# Player triangle (white)
	var player_rot = Globals.player.rotation.y if not Globals.player.is_in_vehicle else (Globals.player.current_vehicle.rotation.y if Globals.player.current_vehicle else 0.0)
	_draw_player_arrow(map_center, player_rot)

	# Compass
	_draw_compass()

	# Circular border (pink like Vice City)
	_draw_circle_border(map_center, MAP_RADIUS + 2, Color(0.85, 0.3, 0.55), 3.0)

# ═══ POI Drawing ═══
func _draw_poi(world_pos: Vector3, player_pos: Vector3, color: Color, icon: String, show_arrow: bool):
	var mp = _world_to_minimap(world_pos, player_pos)
	if _in_circle(mp):
		match icon:
			"star":
				_draw_star(mp, 5.0, color)
			"diamond":
				_draw_diamond(mp, 4.0, color)
			"square":
				draw_rect(Rect2(mp.x - 3, mp.y - 3, 6, 6), color)
			"circle":
				draw_circle(mp, 4, color)
			"triangle":
				_draw_triangle_icon(mp, 5.0, color)
			"save":
				_draw_save_icon(mp, color)
			"cross":
				_draw_cross_icon(mp, color)
	elif show_arrow:
		var dir = (mp - map_center).normalized()
		var edge = map_center + dir * (MAP_RADIUS - 10)
		_draw_arrow(edge, dir, color)

func _draw_star(pos: Vector2, size: float, color: Color):
	# 4-point star
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8.0 - PI / 2.0
		var r = size if i % 2 == 0 else size * 0.4
		pts.append(pos + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

func _draw_diamond(pos: Vector2, size: float, color: Color):
	var pts = PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size, 0),
		pos + Vector2(0, size),
		pos + Vector2(-size, 0),
	])
	draw_colored_polygon(pts, color)

func _draw_triangle_icon(pos: Vector2, size: float, color: Color):
	var pts = PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.8, size * 0.6),
		pos + Vector2(-size * 0.8, size * 0.6),
	])
	draw_colored_polygon(pts, color)

func _draw_save_icon(pos: Vector2, color: Color):
	# Floppy disk shape — small square with notch
	draw_rect(Rect2(pos.x - 4, pos.y - 4, 8, 8), color)
	draw_rect(Rect2(pos.x - 2, pos.y - 4, 4, 3), Color(0.15, 0.15, 0.2))  # label slot
	draw_rect(Rect2(pos.x - 1, pos.y, 2, 3), Color(0.15, 0.15, 0.2))  # shutter

func _draw_cross_icon(pos: Vector2, color: Color):
	# Medical cross
	draw_rect(Rect2(pos.x - 1.5, pos.y - 4, 3, 8), color)
	draw_rect(Rect2(pos.x - 4, pos.y - 1.5, 8, 3), color)

func _draw_roads(player_pos: Vector3):
	var px = player_pos.x
	var pz = player_pos.z
	var view_range = MAP_RADIUS / MAP_SCALE

	var start_x = int(floor((px - view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var end_x = int(ceil((px + view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var start_z = int(floor((pz - view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var end_z = int(ceil((pz + view_range) / ROAD_SPACING)) * int(ROAD_SPACING)

	var road_color = Color(0.25, 0.25, 0.3, 0.7)

	var x = start_x
	while x <= end_x:
		var top = _world_to_minimap(Vector3(x, 0, pz - view_range), player_pos)
		var bot = _world_to_minimap(Vector3(x, 0, pz + view_range), player_pos)
		_draw_clipped_line(top, bot, road_color, 2.0)
		x += int(ROAD_SPACING)

	var z = start_z
	while z <= end_z:
		var left = _world_to_minimap(Vector3(px - view_range, 0, z), player_pos)
		var right = _world_to_minimap(Vector3(px + view_range, 0, z), player_pos)
		_draw_clipped_line(left, right, road_color, 2.0)
		z += int(ROAD_SPACING)

func _draw_clipped_line(from: Vector2, to: Vector2, color: Color, width: float):
	if from.distance_to(map_center) > MAP_RADIUS * 1.5 and to.distance_to(map_center) > MAP_RADIUS * 1.5:
		return
	draw_line(from, to, color, width, true)

func _draw_player_arrow(pos: Vector2, rot: float):
	var size = 7.0
	var fwd = Vector2(sin(rot), cos(rot))
	var right_v = Vector2(fwd.y, -fwd.x)
	var p1 = pos + fwd * size
	var p2 = pos - fwd * size * 0.6 + right_v * size * 0.5
	var p3 = pos - fwd * size * 0.6 - right_v * size * 0.5
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color.WHITE)

func _draw_arrow(pos: Vector2, dir: Vector2, color: Color):
	var size = 6.0
	var right_v = Vector2(dir.y, -dir.x)
	var p1 = pos + dir * size
	var p2 = pos - dir * size * 0.4 + right_v * size * 0.5
	var p3 = pos - dir * size * 0.4 - right_v * size * 0.5
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)

func _draw_compass():
	var offset = MAP_RADIUS - 12
	var font_size = 12
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-4, -offset + 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.8))
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-3, offset + 4), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))
	draw_string(ThemeDB.fallback_font, map_center + Vector2(offset - 4, 4), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-offset - 4, 4), "W", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))

func _draw_circle_border(center: Vector2, radius: float, color: Color, width: float):
	var segments = 48
	for i in range(segments):
		var a1 = float(i) / segments * TAU
		var a2 = float(i + 1) / segments * TAU
		var p1 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)
