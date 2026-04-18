extends Node
# Sound Effects Manager — Procedural audio for Gangster Town Adventures
# Uses AudioStreamPlayer nodes with generated tones since no audio files are bundled

class_name SFXManager

var audio_players: Dictionary = {}
var music_player: AudioStreamPlayer

func _ready():
	add_to_group("sfx_manager")
	_create_audio_players()

func _create_audio_players():
	# Create reusable audio players for each SFX category
	var categories = ["gunshot", "shotgun", "melee", "footstep", "car_engine", 
					   "car_horn", "siren", "pickup", "hit", "death", "mission",
					   "ui_click", "ui_hover"]
	for cat in categories:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -6.0
		add_child(player)
		audio_players[cat] = player

	# Background music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -15.0
	add_child(music_player)

func play_sfx(sfx_name: String, pitch_variation: float = 0.0):
	if not Globals.audio_enabled:
		return
	var player = audio_players.get(sfx_name)
	if not player:
		return
	
	# Generate procedural audio based on type
	var stream = _generate_sound(sfx_name)
	if stream:
		player.stream = stream
		if pitch_variation > 0:
			player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		else:
			player.pitch_scale = 1.0
		player.volume_db = -6.0 * Globals.sfx_volume
		player.play()

func _generate_sound(sfx_name: String) -> AudioStream:
	# Generate short procedural audio samples
	var sample_rate = 22050
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data: PackedByteArray = PackedByteArray()
	
	match sfx_name:
		"gunshot":
			data = _gen_noise_burst(sample_rate, 0.08, 0.9, 200.0)
		"shotgun":
			data = _gen_noise_burst(sample_rate, 0.15, 1.0, 120.0)
		"melee":
			data = _gen_noise_burst(sample_rate, 0.06, 0.5, 300.0)
		"footstep":
			data = _gen_noise_burst(sample_rate, 0.04, 0.2, 100.0)
		"car_engine":
			data = _gen_tone(sample_rate, 0.3, 80.0, 0.3)
		"car_horn":
			data = _gen_tone(sample_rate, 0.5, 440.0, 0.6)
		"siren":
			data = _gen_siren(sample_rate, 0.8)
		"pickup":
			data = _gen_pickup_sound(sample_rate)
		"hit":
			data = _gen_noise_burst(sample_rate, 0.05, 0.6, 250.0)
		"death":
			data = _gen_death_sound(sample_rate)
		"mission":
			data = _gen_mission_sound(sample_rate)
		"ui_click":
			data = _gen_tone(sample_rate, 0.05, 800.0, 0.3)
		"ui_hover":
			data = _gen_tone(sample_rate, 0.03, 600.0, 0.15)
		_:
			return null
	
	stream.data = data
	return stream

func _gen_noise_burst(rate: int, duration: float, volume: float, freq_cutoff: float) -> PackedByteArray:
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var decay_rate = 1.0 / samples
	for i in range(samples):
		var t = float(i) / rate
		var noise = randf_range(-1.0, 1.0)
		var envelope = max(0.0, 1.0 - i * decay_rate * 3.0)
		var val = noise * volume * envelope * 0.8
		var sample = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

func _gen_tone(rate: int, duration: float, freq: float, volume: float) -> PackedByteArray:
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var envelope = 1.0 - (float(i) / samples)
		var val = sin(t * freq * TAU) * volume * envelope
		var sample = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

func _gen_siren(rate: int, duration: float) -> PackedByteArray:
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var freq = 600.0 + sin(t * 3.0) * 200.0  # Wobbling siren
		var val = sin(t * freq * TAU) * 0.4
		var sample = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

func _gen_pickup_sound(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.3)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var freq = 400.0 + t * 800.0  # Rising pitch
		var envelope = 1.0 - (float(i) / samples)
		var val = sin(t * freq * TAU) * 0.5 * envelope
		var sample = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

func _gen_death_sound(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.5)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var freq = 300.0 - t * 200.0  # Descending pitch
		var envelope = 1.0 - (float(i) / samples)
		var val = sin(t * freq * TAU) * 0.6 * envelope
		var sample = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

func _gen_mission_sound(rate: int) -> PackedByteArray:
	# Victory fanfare — ascending notes
	var total_samples = int(rate * 0.6)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	var notes = [523.25, 659.25, 783.99]  # C5, E5, G5
	var note_samples = total_samples / 3
	for n in range(3):
		for i in range(note_samples):
			var idx = n * note_samples + i
			if idx >= total_samples:
				break
			var t = float(i) / rate
			var envelope = 1.0 - (float(i) / note_samples) * 0.5
			var val = sin(t * notes[n] * TAU) * 0.5 * envelope
			var sample = int(clamp(val, -1.0, 1.0) * 32767)
			data[idx * 2] = sample & 0xFF
			data[idx * 2 + 1] = (sample >> 8) & 0xFF
	return data

# ═══════════════════════ AMBIENT SOUNDS ═══════════════════════
var ambient_player: AudioStreamPlayer
var ambient_city_player: AudioStreamPlayer
var ambient_wind_player: AudioStreamPlayer
var ambient_timer = 0.0
var ambient_enabled = true

func start_ambient():
	if not ambient_player:
		ambient_player = AudioStreamPlayer.new()
		ambient_player.bus = "Master"
		ambient_player.volume_db = -20.0
		add_child(ambient_player)

	if not ambient_city_player:
		ambient_city_player = AudioStreamPlayer.new()
		ambient_city_player.bus = "Master"
		ambient_city_player.volume_db = -18.0
		add_child(ambient_city_player)

	if not ambient_wind_player:
		ambient_wind_player = AudioStreamPlayer.new()
		ambient_wind_player.bus = "Master"
		ambient_wind_player.volume_db = -22.0
		add_child(ambient_wind_player)

	_play_ambient_loop()

func _play_ambient_loop():
	if not ambient_enabled or not Globals.audio_enabled:
		return
	# City ambient: layered low rumble + distant traffic
	var stream = _gen_ambient_city()
	if stream and ambient_city_player:
		ambient_city_player.stream = stream
		ambient_city_player.volume_db = -18.0 * Globals.sfx_volume
		ambient_city_player.play()
		ambient_city_player.finished.connect(_on_ambient_city_finished, CONNECT_ONE_SHOT)

	# Wind ambient
	var wind_stream = _gen_ambient_wind()
	if wind_stream and ambient_wind_player:
		ambient_wind_player.stream = wind_stream
		ambient_wind_player.volume_db = -22.0 * Globals.sfx_volume
		ambient_wind_player.play()

func _on_ambient_city_finished():
	# Loop city ambience
	_play_ambient_loop()

func _gen_ambient_city() -> AudioStream:
	var rate = 22050
	var duration = 4.0  # 4 second loops
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		# Low city rumble (multiple low freq sine waves)
		var rumble = sin(t * 45.0 * TAU) * 0.05 + sin(t * 62.0 * TAU) * 0.03
		# Distant traffic hum
		var traffic = sin(t * 85.0 * TAU) * 0.02 * (0.5 + 0.5 * sin(t * 0.3))
		# Very soft random noise (crowd murmur)
		var murmur = randf_range(-0.015, 0.015) * (0.6 + 0.4 * sin(t * 0.5))
		var val = (rumble + traffic + murmur) * 0.6
		var sample_val = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	stream.data = data
	return stream

func _gen_ambient_wind() -> AudioStream:
	var rate = 22050
	var duration = 5.0
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		# Filtered noise for wind sound
		var noise = randf_range(-1.0, 1.0)
		var envelope = 0.3 + 0.2 * sin(t * 0.4) + 0.1 * sin(t * 0.7)
		var val = noise * envelope * 0.04
		var sample_val = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	stream.data = data
	return stream

func play_ambient_bird():
	# Occasional bird chirp
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = -16.0 * Globals.sfx_volume
	add_child(player)
	var stream = _gen_bird_chirp()
	if stream:
		player.stream = stream
		player.play()
		player.finished.connect(func(): player.queue_free())

func _gen_bird_chirp() -> AudioStream:
	var rate = 22050
	var duration = 0.25
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(samples * 2)
	var base_freq = randf_range(2000.0, 3500.0)
	for i in range(samples):
		var t = float(i) / rate
		var freq = base_freq + sin(t * 30.0) * 500.0
		var envelope = (1.0 - t / duration) * (0.5 + 0.5 * sin(t * 20.0))
		var val = sin(t * freq * TAU) * 0.25 * max(envelope, 0.0)
		var sample_val = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	stream.data = data
	return stream

# ═══════════════════════ INTRO MUSIC ═══════════════════════
func generate_intro_music() -> AudioStream:
	# GTA-style funky theme — bass, synth, drums
	var rate = 22050
	var duration = 14.0
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(samples * 2)

	var beat = 0.5  # 120 BPM
	var bass_notes = [82.41, 98.0, 110.0, 82.41, 73.42, 98.0, 110.0, 123.47]
	var melody_notes = [329.63, 0.0, 392.0, 329.63, 440.0, 0.0, 392.0, 349.23,
						329.63, 293.66, 329.63, 0.0, 392.0, 440.0, 493.88, 440.0]

	for i in range(samples):
		var t = float(i) / rate
		var val = 0.0

		var beat_num = int(t / beat)
		var beat_pos = fmod(t, beat)

		# === KICK DRUM (every beat) ===
		var kick_env = max(0.0, 1.0 - beat_pos * 18.0)
		var kick_freq = 55.0 * max(0.2, 1.0 - beat_pos * 12.0)
		val += sin(t * kick_freq * TAU) * 0.28 * kick_env * kick_env

		# === SNARE on beats 1, 3 of each 4 ===
		if beat_num % 4 in [1, 3]:
			var snare_env = max(0.0, 1.0 - beat_pos * 12.0)
			val += randf_range(-1.0, 1.0) * 0.10 * snare_env

		# === HI-HAT (every half beat) ===
		var hh_pos = fmod(t, beat * 0.5)
		var hh_env = max(0.0, 1.0 - hh_pos * 30.0)
		val += randf_range(-1.0, 1.0) * 0.025 * hh_env

		# === BASS LINE ===
		var bass_idx = (beat_num / 2) % bass_notes.size()
		var bass_freq = bass_notes[bass_idx]
		var bass_env = max(0.0, 1.0 - beat_pos * 1.8)
		val += sin(t * bass_freq * TAU) * 0.22 * bass_env
		val += sin(t * bass_freq * 0.5 * TAU) * 0.12 * bass_env

		# === FUNKY GUITAR CHOPS ===
		if beat_num % 4 in [0, 2, 3]:
			var gf = bass_freq * 4.0
			var g_env = max(0.0, 1.0 - beat_pos * 10.0) * 0.7
			val += sin(t * gf * TAU) * 0.06 * g_env
			val += sin(t * gf * 1.5 * TAU) * 0.03 * g_env

		# === MELODY (comes in after 3 seconds) ===
		if t > 3.0:
			var mel_beat = int((t - 3.0) / beat)
			var mel_idx = mel_beat % melody_notes.size()
			var mel_freq = melody_notes[mel_idx]
			if mel_freq > 0:
				var mel_env = max(0.0, 1.0 - fmod(t - 3.0, beat) * 3.0) * 0.55
				val += sin(t * mel_freq * TAU) * 0.09 * mel_env
				val += sin(t * mel_freq * 2.0 * TAU) * 0.03 * mel_env

		# === PAD (warm sustained chord after 5s) ===
		if t > 5.0:
			var pad_vol = clamp((t - 5.0) / 2.0, 0.0, 1.0) * 0.04
			val += sin(t * 164.81 * TAU) * pad_vol
			val += sin(t * 207.65 * TAU) * pad_vol
			val += sin(t * 246.94 * TAU) * pad_vol

		# Master volume — fade in and fade out
		var master = clamp(t / 2.0, 0.2, 1.0) * 0.75
		if t > duration - 2.5:
			master *= (duration - t) / 2.5
		val *= master

		var sample_val_m = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sample_val_m & 0xFF
		data[i * 2 + 1] = (sample_val_m >> 8) & 0xFF
	stream.data = data
	return stream

func generate_menu_music() -> AudioStream:
	# Chill ambient loop for the menu screen
	var rate = 22050
	var duration = 8.0
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var val = 0.0
		val += sin(t * 65.41 * TAU) * 0.08
		val += sin(t * 82.41 * TAU) * 0.06
		val += sin(t * 98.0 * TAU) * 0.05
		val *= (0.6 + 0.4 * sin(t * 0.3))
		val += sin(t * 523.25 * TAU) * 0.015 * (0.5 + 0.5 * sin(t * 0.8))
		val += randf_range(-1.0, 1.0) * 0.008
		val *= 0.5
		var sv = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sv & 0xFF
		data[i * 2 + 1] = (sv >> 8) & 0xFF
	stream.data = data
	return stream

func generate_engine_loop() -> AudioStream:
	var rate = 22050
	var duration = 1.0
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var val = 0.0
		val += sin(t * 80.0 * TAU) * 0.15
		val += sin(t * 160.0 * TAU) * 0.08
		val += sin(t * 240.0 * TAU) * 0.04
		val += randf_range(-1.0, 1.0) * 0.04
		val *= 0.5
		var sv = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2] = sv & 0xFF
		data[i * 2 + 1] = (sv >> 8) & 0xFF
	stream.data = data
	return stream
