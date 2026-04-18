# hud_modern.gd
# Modern GTA-style HUD with health, armor, money, wanted level, minimap, objective
extends CanvasLayer

# HUD elements
var health_bar: ProgressBar
var armor_bar: ProgressBar
var money_label: Label
var wanted_stars: Array[TextureRect] = []
var weapon_display: Control
var ammo_label: Label
var objective_label: Label
var notification_label: Label
var time_label: Label
var minimap_container: Control

# Animation
var notification_tween: Tween = null
var money_animation_tween: Tween = null

# State
var current_money: int = 0
var target_money: int = 0

# Colors
var health_color := Color(0.9, 0.2, 0.2)
var armor_color := Color(0.2, 0.5, 0.9)
var wanted_active_color := Color(1, 0.8, 0.2)
var wanted_inactive_color := Color(0.3, 0.3, 0.3)

func _ready() -> void:
	add_to_group("hud")
	_create_hud()
	_connect_signals()

func _create_hud() -> void:
	# Main container
	var main = Control.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main)
	
	# Top right - Money and time
	_create_top_right_panel(main)
	
	# Top left - Wanted level
	_create_wanted_display(main)
	
	# Bottom left - Health, Armor, Weapon
	_create_bottom_left_panel(main)
	
	# Bottom center - Objective
	_create_objective_display(main)
	
	# Top center - Notifications
	_create_notification_display(main)
	
	# Bottom right - Minimap
	_create_minimap(main)

func _create_top_right_panel(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-200, 20)
	panel.custom_minimum_size = Vector2(180, 60)
	parent.add_child(panel)
	
	# Time
	time_label = Label.new()
	time_label.text = "08:00 AM"
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(time_label)
	
	# Money
	money_label = Label.new()
	money_label.text = "$0"
	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(money_label)

func _create_wanted_display(parent: Control) -> void:
	var panel = HBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	panel.add_theme_constant_override("separation", 5)
	parent.add_child(panel)
	
	# Create 6 stars (max wanted level)
	for i in range(6):
		var star_container = Control.new()
		star_container.custom_minimum_size = Vector2(24, 24)
		panel.add_child(star_container)
		
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 20)
		star.add_theme_color_override("font_color", wanted_inactive_color)
		star_container.add_child(star)
		wanted_stars.append(star)

func _create_bottom_left_panel(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(20, -120)
	panel.add_theme_constant_override("separation", 8)
	parent.add_child(panel)
	
	# Health bar
	var health_container = HBoxContainer.new()
	health_container.add_theme_constant_override("separation", 8)
	panel.add_child(health_container)
	
	var health_icon = Label.new()
	health_icon.text = "❤"
	health_icon.add_theme_font_size_override("font_size", 18)
	health_icon.add_theme_color_override("font_color", health_color)
	health_container.add_child(health_icon)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(150, 16)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	health_style.corner_radius_top_left = 3
	health_style.corner_radius_top_right = 3
	health_style.corner_radius_bottom_left = 3
	health_style.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("background", health_style)
	
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = health_color
	health_fill.corner_radius_top_left = 3
	health_fill.corner_radius_top_right = 3
	health_fill.corner_radius_bottom_left = 3
	health_fill.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("fill", health_fill)
	
	health_container.add_child(health_bar)
	
	# Armor bar
	var armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 8)
	panel.add_child(armor_container)
	
	var armor_icon = Label.new()
	armor_icon.text = "🛡"
	armor_icon.add_theme_font_size_override("font_size", 18)
	armor_icon.add_theme_color_override("font_color", armor_color)
	armor_container.add_child(armor_icon)
	
	armor_bar = ProgressBar.new()
	armor_bar.custom_minimum_size = Vector2(150, 16)
	armor_bar.max_value = 100
	armor_bar.value = 0
	armor_bar.show_percentage = false
	
	var armor_style = StyleBoxFlat.new()
	armor_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	armor_style.corner_radius_top_left = 3
	armor_style.corner_radius_top_right = 3
	armor_style.corner_radius_bottom_left = 3
	armor_style.corner_radius_bottom_right = 3
	armor_bar.add_theme_stylebox_override("background", armor_style)
	
	var armor_fill = StyleBoxFlat.new()
	armor_fill.bg_color = armor_color
	armor_fill.corner_radius_top_left = 3
	armor_fill.corner_radius_top_right = 3
	armor_fill.corner_radius_bottom_left = 3
	armor_fill.corner_radius_bottom_right = 3
	armor_bar.add_theme_stylebox_override("fill", armor_fill)
	
	armor_container.add_child(armor_bar)
	
	# Weapon/Ammo display
	weapon_display = HBoxContainer.new()
	weapon_display.add_theme_constant_override("separation", 10)
	panel.add_child(weapon_display)
	
	var weapon_icon = Label.new()
	weapon_icon.text = "🔫"
	weapon_icon.add_theme_font_size_override("font_size", 20)
	weapon_display.add_child(weapon_icon)
	
	ammo_label = Label.new()
	ammo_label.text = "30 / 120"
	ammo_label.add_theme_font_size_override("font_size", 16)
	ammo_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	weapon_display.add_child(ammo_label)

func _create_objective_display(parent: Control) -> void:
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.position.y = -60
	panel.custom_minimum_size = Vector2(0, 40)
	parent.add_child(panel)
	
	objective_label = Label.new()
	objective_label.text = ""
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_child(objective_label)

func _create_notification_display(parent: Control) -> void:
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 60)
	parent.add_child(panel)
	
	notification_label = Label.new()
	notification_label.text = ""
	notification_label.add_theme_font_size_override("font_size", 24)
	notification_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.set_anchors_preset(Control.PRESET_CENTER)
	notification_label.position.y = 80
	panel.add_child(notification_label)

func _create_minimap(parent: Control) -> void:
	minimap_container = Control.new()
	minimap_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap_container.position = Vector2(-180, -180)
	minimap_container.custom_minimum_size = Vector2(160, 160)
	parent.add_child(minimap_container)
	
	# Minimap background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.1, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_container.add_child(bg)
	
	# Minimap border
	var border = ColorRect.new()
	border.color = Color(0.3, 0.35, 0.3)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.size = Vector2(164, 164)
	border.position = Vector2(-2, -2)
	border.z_index = -1
	minimap_container.add_child(border)
	
	# Player marker (center)
	var player_marker = Label.new()
	player_marker.text = "▲"
	player_marker.add_theme_font_size_override("font_size", 16)
	player_marker.add_theme_color_override("font_color", Color(1, 1, 1))
	player_marker.set_anchors_preset(Control.PRESET_CENTER)
	player_marker.position = Vector2(-8, -12)
	minimap_container.add_child(player_marker)
	
	# N indicator
	var north = Label.new()
	north.text = "N"
	north.add_theme_font_size_override("font_size", 12)
	north.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	north.position = Vector2(75, 5)
	minimap_container.add_child(north)

func _connect_signals() -> void:
	# Connect to game manager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.has_signal("money_changed"):
			game_manager.connect("money_changed", _on_money_changed)
		if game_manager.has_signal("health_changed"):
			game_manager.connect("health_changed", _on_health_changed)
		if game_manager.has_signal("armor_changed"):
			game_manager.connect("armor_changed", _on_armor_changed)
		if game_manager.has_signal("wanted_level_changed"):
			game_manager.connect("wanted_level_changed", _on_wanted_changed)
	
	# Connect to event bus
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		if event_bus.has_signal("weapon_changed"):
			event_bus.connect("weapon_changed", _on_weapon_changed)
		if event_bus.has_signal("ammo_changed"):
			event_bus.connect("ammo_changed", _on_ammo_changed)
	
	# Connect to mission manager
	var mission_manager = get_node_or_null("/root/MissionManager")
	if not mission_manager:
		mission_manager = get_parent().get_node_or_null("MissionManager")
	
	if mission_manager:
		if mission_manager.has_signal("objective_updated"):
			mission_manager.connect("objective_updated", _on_objective_updated)
	
	# Connect to time/weather
	var time_weather = get_tree().get_first_node_in_group("time_weather")
	if time_weather:
		if time_weather.has_signal("time_changed"):
			time_weather.connect("time_changed", _on_time_changed)

func _process(_delta: float) -> void:
	# Animate money counter
	if current_money != target_money:
		var diff = target_money - current_money
		var step = max(1, abs(diff) / 10)
		if diff > 0:
			current_money = min(current_money + step, target_money)
		else:
			current_money = max(current_money - step, target_money)
		money_label.text = "$%d" % current_money

# ============= Update Functions =============

func update_health(value: float) -> void:
	health_bar.value = value
	
	# Flash on damage
	if value < health_bar.max_value:
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color(1.5, 0.5, 0.5), 0.1)
		tween.tween_property(health_bar, "modulate", Color.WHITE, 0.2)

func update_armor(value: float) -> void:
	armor_bar.value = value
	armor_bar.visible = value > 0

func update_money(amount: int) -> void:
	target_money = amount
	
	# Green flash for increase, red for decrease
	var color = Color(0.4, 1.0, 0.4) if amount > current_money else Color(1.0, 0.4, 0.4)
	var tween = create_tween()
	tween.tween_property(money_label, "modulate", color, 0.1)
	tween.tween_property(money_label, "modulate", Color.WHITE, 0.3)

func update_wanted(level: int) -> void:
	for i in range(wanted_stars.size()):
		if i < level:
			wanted_stars[i].add_theme_color_override("font_color", wanted_active_color)
			# Flash animation
			var tween = create_tween()
			tween.set_loops(2)
			tween.tween_property(wanted_stars[i], "modulate", Color(1.5, 1.2, 0.8), 0.15)
			tween.tween_property(wanted_stars[i], "modulate", Color.WHITE, 0.15)
		else:
			wanted_stars[i].add_theme_color_override("font_color", wanted_inactive_color)

func update_weapon(weapon_name: String, ammo_in_clip: int, ammo_reserve: int) -> void:
	ammo_label.text = "%d / %d" % [ammo_in_clip, ammo_reserve]

func update_objective(text: String) -> void:
	objective_label.text = text
	
	if text != "":
		var tween = create_tween()
		tween.tween_property(objective_label, "modulate:a", 0.0, 0.0)
		tween.tween_property(objective_label, "modulate:a", 1.0, 0.3)

func update_time(time_string: String) -> void:
	time_label.text = time_string

func show_notification(text: String, duration: float = 3.0) -> void:
	if notification_tween:
		notification_tween.kill()
	
	notification_label.text = text
	
	notification_tween = create_tween()
	notification_tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)
	notification_tween.tween_interval(duration)
	notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)

func show_mission_complete(title: String, reward: int) -> void:
	show_notification("MISSION COMPLETE\n%s\n+$%d" % [title, reward], 5.0)

# ============= Signal Callbacks =============

func _on_money_changed(amount: int) -> void:
	update_money(amount)

func _on_health_changed(value: float) -> void:
	update_health(value)

func _on_armor_changed(value: float) -> void:
	update_armor(value)

func _on_wanted_changed(level: int) -> void:
	update_wanted(level)

func _on_weapon_changed(weapon_name: String, ammo_clip: int, ammo_reserve: int) -> void:
	update_weapon(weapon_name, ammo_clip, ammo_reserve)

func _on_ammo_changed(ammo_clip: int, ammo_reserve: int) -> void:
	ammo_label.text = "%d / %d" % [ammo_clip, ammo_reserve]

func _on_objective_updated(_mission, objective) -> void:
	if objective:
		update_objective(objective.description)

func _on_time_changed(hour: float, _day: int) -> void:
	var hours = int(hour)
	var minutes = int((hour - hours) * 60)
	var am_pm = "AM" if hours < 12 else "PM"
	var display_hour = hours % 12
	if display_hour == 0:
		display_hour = 12
	update_time("%02d:%02d %s" % [display_hour, minutes, am_pm])

# Legacy compatibility
func update_mission(text: String) -> void:
	update_objective(text)
