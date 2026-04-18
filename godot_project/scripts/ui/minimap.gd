extends Control
# Minimap Script — top-down view centered on the player

const MAP_X = 10
const MAP_Y = 10
const MAP_SIZE = 200
const MAP_CENTER = Vector2(MAP_X + MAP_SIZE / 2, MAP_Y + MAP_SIZE / 2)
const MAP_SCALE = 2.0  # pixels per world unit

func _process(_delta):
	queue_redraw()

func _world_to_minimap(world_pos: Vector3, player_pos: Vector3) -> Vector2:
	var rel = Vector2(world_pos.x - player_pos.x, world_pos.z - player_pos.z)
	return MAP_CENTER + rel * MAP_SCALE

func _in_minimap(pos: Vector2) -> bool:
	return pos.x > MAP_X and pos.x < MAP_X + MAP_SIZE and pos.y > MAP_Y and pos.y < MAP_Y + MAP_SIZE

func _draw():
	# Background
	draw_rect(Rect2(MAP_X, MAP_Y, MAP_SIZE, MAP_SIZE), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(MAP_X, MAP_Y, MAP_SIZE, MAP_SIZE), Color.WHITE, false, 2.0)

	if not Globals.player:
		return
	var pp = Globals.player.global_position

	# Player (always center)
	draw_circle(MAP_CENTER, 5, Color.CYAN)

	# NPCs
	for npc in get_tree().get_nodes_in_group("npc"):
		var p = _world_to_minimap(npc.global_position, pp)
		if _in_minimap(p):
			draw_circle(p, 3, Color.GRAY)

	# Police
	for cop in get_tree().get_nodes_in_group("police"):
		var p = _world_to_minimap(cop.global_position, pp)
		if _in_minimap(p):
			draw_circle(p, 3, Color(0.2, 0.4, 1.0))

	# Enemies
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var p = _world_to_minimap(enemy.global_position, pp)
		if _in_minimap(p):
			draw_circle(p, 3, Color.RED)

	# Vehicles
	for v in get_tree().get_nodes_in_group("vehicle"):
		var p = _world_to_minimap(v.global_position, pp)
		if _in_minimap(p):
			draw_circle(p, 3, Color.GREEN)
