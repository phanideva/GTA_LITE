extends Control
# Minimap — Vice City style circular radar with roads, icons, compass

const MAP_SIZE = 180
const MAP_RADIUS = 90.0
const MAP_SCALE = 0.8
const ROAD_SPACING = 50.0

var map_center: Vector2

func _ready():
	# Position in bottom-left like Vice City
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

	# Circular background (dark with green tint like Vice City radar)
	draw_circle(map_center, MAP_RADIUS + 2, Color(0.0, 0.0, 0.0, 0.85))
	draw_circle(map_center, MAP_RADIUS, Color(0.02, 0.08, 0.02, 0.75))

	# Draw road grid lines on minimap
	_draw_roads(pp)

	# Mission marker (yellow blip with pulsing)
	var ms = get_tree().get_first_node_in_group("mission_system")
	if ms and ms.is_mission_active and ms.current_mission.has("marker"):
		var marker_pos = ms.current_mission["marker"]
		var mp = _world_to_minimap(marker_pos, pp)
		if _in_circle(mp):
			draw_circle(mp, 6, Color(1.0, 0.85, 0.0))
			draw_circle(mp, 4, Color(1.0, 1.0, 0.5))
		else:
			# Draw arrow at edge pointing to marker
			var dir = (mp - map_center).normalized()
			var edge = map_center + dir * (MAP_RADIUS - 8)
			_draw_arrow(edge, dir, Color(1.0, 0.85, 0.0))

	# Police blips (flashing blue when wanted)
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
			draw_rect(Rect2(vp.x - 2, vp.y - 2, 4, 4), Color(0.2, 0.7, 0.2, 0.6))

	# Player triangle (white, rotated to face direction)
	var player_rot = Globals.player.rotation.y if not Globals.player.is_in_vehicle else (Globals.player.current_vehicle.rotation.y if Globals.player.current_vehicle else 0.0)
	_draw_player_arrow(map_center, player_rot)

	# Compass letters (N, S, E, W)
	_draw_compass()

	# Circular border (pink/magenta like Vice City)
	_draw_circle_border(map_center, MAP_RADIUS + 2, Color(0.85, 0.3, 0.55), 3.0)

func _draw_roads(player_pos: Vector3):
	# Draw nearby road grid as lines on minimap
	var px = player_pos.x
	var pz = player_pos.z
	var view_range = MAP_RADIUS / MAP_SCALE

	# Find nearest grid lines
	var start_x = int(floor((px - view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var end_x = int(ceil((px + view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var start_z = int(floor((pz - view_range) / ROAD_SPACING)) * int(ROAD_SPACING)
	var end_z = int(ceil((pz + view_range) / ROAD_SPACING)) * int(ROAD_SPACING)

	var road_color = Color(0.25, 0.25, 0.3, 0.7)

	# Vertical (N-S) roads
	var x = start_x
	while x <= end_x:
		var top = _world_to_minimap(Vector3(x, 0, pz - view_range), player_pos)
		var bot = _world_to_minimap(Vector3(x, 0, pz + view_range), player_pos)
		_draw_clipped_line(top, bot, road_color, 2.0)
		x += int(ROAD_SPACING)

	# Horizontal (E-W) roads
	var z = start_z
	while z <= end_z:
		var left = _world_to_minimap(Vector3(px - view_range, 0, z), player_pos)
		var right = _world_to_minimap(Vector3(px + view_range, 0, z), player_pos)
		_draw_clipped_line(left, right, road_color, 2.0)
		z += int(ROAD_SPACING)

func _draw_clipped_line(from: Vector2, to: Vector2, color: Color, width: float):
	# Only draw within circle
	if from.distance_to(map_center) > MAP_RADIUS * 1.5 and to.distance_to(map_center) > MAP_RADIUS * 1.5:
		return
	draw_line(from, to, color, width, true)

func _draw_player_arrow(pos: Vector2, rot: float):
	# White triangle pointing in player direction
	var size = 7.0
	var fwd = Vector2(sin(rot), cos(rot))
	var right = Vector2(fwd.y, -fwd.x)
	var p1 = pos + fwd * size
	var p2 = pos - fwd * size * 0.6 + right * size * 0.5
	var p3 = pos - fwd * size * 0.6 - right * size * 0.5
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color.WHITE)

func _draw_arrow(pos: Vector2, dir: Vector2, color: Color):
	var size = 6.0
	var right = Vector2(dir.y, -dir.x)
	var p1 = pos + dir * size
	var p2 = pos - dir * size * 0.4 + right * size * 0.5
	var p3 = pos - dir * size * 0.4 - right * size * 0.5
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)

func _draw_compass():
	var offset = MAP_RADIUS - 12
	var font_size = 12
	# N
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-4, -offset + 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.8))
	# S
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-3, offset + 4), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))
	# E
	draw_string(ThemeDB.fallback_font, map_center + Vector2(offset - 4, 4), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))
	# W
	draw_string(ThemeDB.fallback_font, map_center + Vector2(-offset - 4, 4), "W", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.5))

func _draw_circle_border(center: Vector2, radius: float, color: Color, width: float):
	var segments = 48
	for i in range(segments):
		var a1 = float(i) / segments * TAU
		var a2 = float(i + 1) / segments * TAU
		var p1 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)
