# time_weather.gd
# Dynamic time of day and weather system for GTA-style atmosphere
extends Node

class_name TimeWeatherSystem

# Time settings
@export var time_scale := 60.0  # 1 real second = 60 game seconds (1 min)
@export var starting_hour := 8.0  # Start at 8 AM

# Current time
var current_time := 0.0  # Hours (0-24)
var current_day := 1

# Weather
enum WeatherType { CLEAR, CLOUDY, OVERCAST, RAIN, STORM, FOG }
var current_weather: WeatherType = WeatherType.CLEAR
var target_weather: WeatherType = WeatherType.CLEAR
var weather_transition := 0.0
var weather_duration := 0.0

# Environment references
var sun_light: DirectionalLight3D
var env: Environment
var world_environment: WorldEnvironment

# Time colors
var dawn_color := Color(1.0, 0.6, 0.4)
var day_color := Color(1.0, 0.98, 0.95)
var dusk_color := Color(1.0, 0.5, 0.3)
var night_color := Color(0.3, 0.35, 0.5)

# Weather data
var weather_settings := {
	WeatherType.CLEAR: {
		"fog_density": 0.0,
		"fog_color": Color(0.8, 0.85, 0.9),
		"ambient_energy": 1.0,
		"sky_contribution": 1.0,
		"rain_intensity": 0.0,
		"cloud_coverage": 0.1
	},
	WeatherType.CLOUDY: {
		"fog_density": 0.001,
		"fog_color": Color(0.7, 0.72, 0.75),
		"ambient_energy": 0.8,
		"sky_contribution": 0.7,
		"rain_intensity": 0.0,
		"cloud_coverage": 0.5
	},
	WeatherType.OVERCAST: {
		"fog_density": 0.002,
		"fog_color": Color(0.5, 0.52, 0.55),
		"ambient_energy": 0.5,
		"sky_contribution": 0.3,
		"rain_intensity": 0.0,
		"cloud_coverage": 0.9
	},
	WeatherType.RAIN: {
		"fog_density": 0.003,
		"fog_color": Color(0.4, 0.42, 0.45),
		"ambient_energy": 0.4,
		"sky_contribution": 0.2,
		"rain_intensity": 0.7,
		"cloud_coverage": 0.95
	},
	WeatherType.STORM: {
		"fog_density": 0.005,
		"fog_color": Color(0.3, 0.3, 0.35),
		"ambient_energy": 0.25,
		"sky_contribution": 0.1,
		"rain_intensity": 1.0,
		"cloud_coverage": 1.0
	},
	WeatherType.FOG: {
		"fog_density": 0.02,
		"fog_color": Color(0.7, 0.72, 0.75),
		"ambient_energy": 0.6,
		"sky_contribution": 0.1,
		"rain_intensity": 0.0,
		"cloud_coverage": 0.3
	}
}

# Rain particles
var rain_particles: GPUParticles3D
var rain_material: ParticleProcessMaterial

# Signals
signal time_changed(hour: float, day: int)
signal hour_changed(hour: int)
signal weather_changed(weather: WeatherType)
signal day_night_changed(is_night: bool)

func _ready() -> void:
	current_time = starting_hour
	_setup_environment()
	_setup_rain()
	_schedule_weather_change()

func _setup_environment() -> void:
	# Find or create WorldEnvironment
	world_environment = get_tree().root.find_child("WorldEnvironment", true, false)
	
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		get_tree().root.call_deferred("add_child", world_environment)
	
	# Create environment
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	
	# Create sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.4, 0.6, 0.9)
	sky_material.sky_horizon_color = Color(0.7, 0.75, 0.85)
	sky_material.ground_bottom_color = Color(0.2, 0.18, 0.15)
	sky_material.ground_horizon_color = Color(0.6, 0.55, 0.5)
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15
	sky.sky_material = sky_material
	env.sky = sky
	
	# Ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	
	# Fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.85, 0.9)
	env.fog_density = 0.0
	
	# Volumetric fog for atmosphere
	env.volumetric_fog_enabled = false  # Enable for better GPUs
	
	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 2.0
	
	# SSR
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	
	# Glow/bloom
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	
	# Tonemap
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	
	world_environment.environment = env
	
	# Find or create sun
	sun_light = get_tree().root.find_child("Sun", true, false)
	
	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "Sun"
		sun_light.light_energy = 1.0
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun_light.directional_shadow_max_distance = 200.0
		get_tree().root.call_deferred("add_child", sun_light)

func _setup_rain() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 2000
	rain_particles.lifetime = 1.0
	rain_particles.emitting = false
	
	# Set up emission box above camera
	rain_particles.visibility_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 100, 100))
	
	# Rain material
	rain_material = ParticleProcessMaterial.new()
	rain_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_material.emission_box_extents = Vector3(30, 1, 30)
	rain_material.gravity = Vector3(0, -20, 0)
	rain_material.initial_velocity_min = 15.0
	rain_material.initial_velocity_max = 25.0
	rain_material.direction = Vector3(0, -1, 0)
	rain_material.spread = 5.0
	rain_material.scale_min = 0.5
	rain_material.scale_max = 1.0
	
	rain_particles.process_material = rain_material
	
	# Rain drop mesh
	var rain_mesh = CylinderMesh.new()
	rain_mesh.height = 0.5
	rain_mesh.top_radius = 0.01
	rain_mesh.bottom_radius = 0.01
	
	var rain_mesh_mat = StandardMaterial3D.new()
	rain_mesh_mat.albedo_color = Color(0.7, 0.75, 0.85, 0.5)
	rain_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mesh.material = rain_mesh_mat
	
	rain_particles.draw_pass_1 = rain_mesh
	
	add_child(rain_particles)

func _process(delta: float) -> void:
	_update_time(delta)
	_update_sun()
	_update_weather(delta)
	_update_rain_position()

func _update_time(delta: float) -> void:
	var old_hour = int(current_time)
	
	current_time += delta * time_scale / 3600.0  # Convert to hours
	
	if current_time >= 24.0:
		current_time -= 24.0
		current_day += 1
	
	var new_hour = int(current_time)
	
	if new_hour != old_hour:
		hour_changed.emit(new_hour)
		
		# Check day/night transition
		if (old_hour < 6 and new_hour >= 6) or (old_hour < 20 and new_hour >= 20):
			day_night_changed.emit(new_hour >= 20 or new_hour < 6)
	
	time_changed.emit(current_time, current_day)

func _update_sun() -> void:
	if not sun_light:
		return
	
	# Sun angle based on time (0-360 degrees for full day cycle)
	var sun_angle = (current_time / 24.0) * 360.0 - 90.0
	sun_light.rotation_degrees.x = sun_angle
	sun_light.rotation_degrees.y = -30.0  # Slight angle
	
	# Determine light color and energy based on time
	var sun_color: Color
	var sun_energy: float
	var ambient_energy: float
	
	if current_time < 5.0:  # Night (0-5)
		sun_color = night_color
		sun_energy = 0.1
		ambient_energy = 0.15
	elif current_time < 7.0:  # Dawn (5-7)
		var t = (current_time - 5.0) / 2.0
		sun_color = night_color.lerp(dawn_color, t)
		sun_energy = lerp(0.1, 0.5, t)
		ambient_energy = lerp(0.15, 0.4, t)
	elif current_time < 8.0:  # Sunrise (7-8)
		var t = current_time - 7.0
		sun_color = dawn_color.lerp(day_color, t)
		sun_energy = lerp(0.5, 1.0, t)
		ambient_energy = lerp(0.4, 0.6, t)
	elif current_time < 17.0:  # Day (8-17)
		sun_color = day_color
		sun_energy = 1.0
		ambient_energy = 0.6
	elif current_time < 19.0:  # Sunset (17-19)
		var t = (current_time - 17.0) / 2.0
		sun_color = day_color.lerp(dusk_color, t)
		sun_energy = lerp(1.0, 0.5, t)
		ambient_energy = lerp(0.6, 0.3, t)
	elif current_time < 20.0:  # Dusk (19-20)
		var t = current_time - 19.0
		sun_color = dusk_color.lerp(night_color, t)
		sun_energy = lerp(0.5, 0.1, t)
		ambient_energy = lerp(0.3, 0.15, t)
	else:  # Night (20-24)
		sun_color = night_color
		sun_energy = 0.1
		ambient_energy = 0.15
	
	# Apply weather modifiers
	var weather_data = weather_settings[current_weather]
	sun_energy *= weather_data.ambient_energy
	
	sun_light.light_color = sun_color
	sun_light.light_energy = sun_energy
	
	if env:
		env.ambient_light_energy = ambient_energy * weather_data.ambient_energy

func _update_weather(delta: float) -> void:
	# Update weather duration
	weather_duration -= delta
	
	if weather_duration <= 0:
		_schedule_weather_change()
	
	# Transition between weather states
	if current_weather != target_weather:
		weather_transition += delta * 0.1  # 10 second transition
		
		if weather_transition >= 1.0:
			current_weather = target_weather
			weather_transition = 0.0
			weather_changed.emit(current_weather)
	
	# Apply weather effects
	_apply_weather_effects()

func _apply_weather_effects() -> void:
	if not env:
		return
	
	var current_data = weather_settings[current_weather]
	var target_data = weather_settings[target_weather]
	
	# Interpolate fog
	var fog_density = lerp(current_data.fog_density, target_data.fog_density, weather_transition)
	var fog_color = current_data.fog_color.lerp(target_data.fog_color, weather_transition)
	
	env.fog_density = fog_density
	env.fog_light_color = fog_color
	
	# Update rain
	var rain_intensity = lerp(current_data.rain_intensity, target_data.rain_intensity, weather_transition)
	
	if rain_intensity > 0.1:
		rain_particles.emitting = true
		rain_particles.amount = int(rain_intensity * 3000)
	else:
		rain_particles.emitting = false

func _update_rain_position() -> void:
	# Follow camera/player
	var camera = get_viewport().get_camera_3d()
	if camera:
		rain_particles.global_position = camera.global_position + Vector3(0, 20, 0)

func _schedule_weather_change() -> void:
	# Random weather duration (5-30 minutes game time)
	weather_duration = randf_range(5.0, 30.0) * 60.0 / time_scale
	
	# Weight weather probabilities
	var weights := {
		WeatherType.CLEAR: 40.0,
		WeatherType.CLOUDY: 25.0,
		WeatherType.OVERCAST: 15.0,
		WeatherType.RAIN: 12.0,
		WeatherType.STORM: 3.0,
		WeatherType.FOG: 5.0
	}
	
	# Avoid same weather twice in a row
	if current_weather != WeatherType.CLEAR:
		weights[WeatherType.CLEAR] += 20.0
	weights[current_weather] *= 0.3
	
	var total_weight = 0.0
	for w in weights.values():
		total_weight += w
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for weather_type in weights:
		cumulative += weights[weather_type]
		if roll <= cumulative:
			target_weather = weather_type
			break

# Public API
func set_time(hour: float) -> void:
	current_time = fmod(hour, 24.0)
	_update_sun()

func set_weather(weather: WeatherType, instant: bool = false) -> void:
	target_weather = weather
	if instant:
		current_weather = weather
		weather_transition = 0.0
		weather_changed.emit(current_weather)

func get_time_string() -> String:
	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60)
	var am_pm = "AM" if hours < 12 else "PM"
	var display_hour = hours % 12
	if display_hour == 0:
		display_hour = 12
	return "%02d:%02d %s" % [display_hour, minutes, am_pm]

func is_night() -> bool:
	return current_time >= 20.0 or current_time < 6.0

func is_raining() -> bool:
	return current_weather in [WeatherType.RAIN, WeatherType.STORM]

func get_weather_name() -> String:
	match current_weather:
		WeatherType.CLEAR: return "Clear"
		WeatherType.CLOUDY: return "Cloudy"
		WeatherType.OVERCAST: return "Overcast"
		WeatherType.RAIN: return "Rain"
		WeatherType.STORM: return "Storm"
		WeatherType.FOG: return "Fog"
	return "Unknown"
