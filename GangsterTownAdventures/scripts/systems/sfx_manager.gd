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
					   "ui_click", "ui_hover", "mission_complete", "pain", "explosion",
					   "tire_screech", "npc_grunt", "npc_argue", "npc_chatter",
					   "car_door", "cash_register", "glass_break", "car_crash",
					   "player_jump", "player_grunt", "ambient_bird"]
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
			data = _gen_gunshot(sample_rate)
		"shotgun":
			data = _gen_shotgun(sample_rate)
		"melee":
			data = _gen_noise_burst(sample_rate, 0.06, 0.5, 300.0)
		"footstep":
			data = _gen_footstep(sample_rate)
		"car_engine":
			data = _gen_tone(sample_rate, 0.3, 80.0, 0.3)
		"car_horn":
			data = _gen_car_horn(sample_rate)
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
		"mission_complete":
			data = _gen_mission_complete(sample_rate)
		"pain":
			data = _gen_pain_grunt(sample_rate)
		"explosion":
			data = _gen_explosion(sample_rate)
		"tire_screech":
			data = _gen_tire_screech(sample_rate)
		"npc_grunt":
			data = _gen_npc_grunt(sample_rate)
		"npc_argue":
			data = _gen_npc_argue(sample_rate)
		"npc_chatter":
			data = _gen_npc_chatter(sample_rate)
		"car_door":
			data = _gen_car_door(sample_rate)
		"cash_register":
			data = _gen_cash_register(sample_rate)
		"glass_break":
			data = _gen_glass_break(sample_rate)
		"car_crash":
			data = _gen_car_crash(sample_rate)
		"player_jump":
			data = _gen_player_jump(sample_rate)
		"player_grunt":
			data = _gen_player_grunt(sample_rate)
		"ambient_bird":
			data = _gen_bird_chirp_data(sample_rate)
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
	# GTA-style cinematic hip-hop theme — punchy drums, deep bass, smooth synths
	var rate = 44100
	var duration = 16.0
	var samples = int(rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(samples * 2)

	var bpm = 90.0
	var beat = 60.0 / bpm
	var bar = beat * 4.0
	
	# Minor key bass notes (Am pentatonic feel)
	var bass_pattern = [55.0, 55.0, 65.41, 73.42, 55.0, 49.0, 55.0, 65.41]
	# Melody notes (A minor pentatonic)
	var melody_notes = [440.0, 523.25, 587.33, 659.26, 523.25, 440.0, 392.0, 440.0,
						523.25, 587.33, 523.25, 440.0, 392.0, 349.23, 392.0, 440.0]
	# Chord pads (Am, Dm, Em, Am)
	var chord_sets = [
		[220.0, 261.63, 329.63],  # Am
		[146.83, 174.61, 220.0],  # Dm
		[164.81, 207.65, 246.94],  # Em
		[220.0, 261.63, 329.63],  # Am
	]

	for i in range(samples):
		var t = float(i) / rate
		var val = 0.0

		var beat_num = int(t / beat)
		var beat_pos = fmod(t, beat)
		var bar_num = int(t / bar)
		var bar_pos = fmod(t, bar)

		# === KICK DRUM — boom on 1 and 3, ghost on 2.5 ===
		var kick_hits = [0.0, beat * 2.0, beat * 2.5]
		for kh in kick_hits:
			var kt = bar_pos - kh
			if kt >= 0 and kt < 0.2:
				var kick_env = pow(max(0.0, 1.0 - kt * 12.0), 2.0)
				var kick_freq = 50.0 + 80.0 * max(0.0, 1.0 - kt * 15.0)
				val += sin(kt * kick_freq * TAU) * 0.30 * kick_env

		# === SNARE on beats 2 and 4 ===
		var snare_hits = [beat, beat * 3.0]
		for sh in snare_hits:
			var st = bar_pos - sh
			if st >= 0 and st < 0.15:
				var snare_env = pow(max(0.0, 1.0 - st * 14.0), 1.5)
				# Noise + tone body
				val += sin(st * 200.0 * TAU) * 0.08 * snare_env
				val += (fmod(sin(t * 7919.0) * 43758.5453, 2.0) - 1.0) * 0.12 * snare_env

		# === HI-HAT — eighth notes with velocity variation ===
		var hh_period = beat * 0.5
		var hh_pos_local = fmod(t, hh_period)
		var hh_idx = int(t / hh_period)
		if hh_pos_local < 0.04:
			var hh_vol = 0.04 if hh_idx % 2 == 0 else 0.025
			var hh_env = max(0.0, 1.0 - hh_pos_local * 50.0)
			val += (fmod(sin(t * 13417.0) * 23421.6, 2.0) - 1.0) * hh_vol * hh_env

		# === DEEP BASS LINE (comes in after 2 beats) ===
		if t > beat * 2:
			var bass_idx = (beat_num / 2) % bass_pattern.size()
			var bass_freq = bass_pattern[bass_idx]
			var bass_env = 0.8 + 0.2 * max(0.0, 1.0 - beat_pos * 2.0)
			# Sub bass (sine) + harmonics for warmth
			val += sin(t * bass_freq * TAU) * 0.22 * bass_env
			val += sin(t * bass_freq * 2.0 * TAU) * 0.08 * bass_env
			val += sin(t * bass_freq * 3.0 * TAU) * 0.03 * bass_env

		# === SMOOTH SYNTH PAD (comes in after 4 seconds) ===
		if t > 4.0:
			var chord_idx = (bar_num) % chord_sets.size()
			var chord = chord_sets[chord_idx]
			var pad_vol = clamp((t - 4.0) / 3.0, 0.0, 1.0) * 0.035
			for note in chord:
				# Detuned saw-like tone for richness
				val += sin(t * note * TAU) * pad_vol
				val += sin(t * note * 1.003 * TAU) * pad_vol * 0.7
				val += sin(t * note * 2.0 * TAU) * pad_vol * 0.3

		# === MELODY SYNTH (comes in after 6 seconds) ===
		if t > 6.0:
			var mel_t = t - 6.0
			var mel_beat_num = int(mel_t / beat)
			var mel_beat_pos = fmod(mel_t, beat)
			var mel_idx = mel_beat_num % melody_notes.size()
			var mel_freq = melody_notes[mel_idx]
			if mel_freq > 0:
				# Smooth envelope with sustain
				var mel_env = min(mel_beat_pos * 20.0, 1.0) * max(0.0, 1.0 - mel_beat_pos / beat * 0.6) * 0.6
				var mel_fade_in = clamp((t - 6.0) / 2.0, 0.0, 1.0)
				# Square-ish wave for that classic synth sound
				val += sin(t * mel_freq * TAU) * 0.07 * mel_env * mel_fade_in
				val += sin(t * mel_freq * 2.0 * TAU) * 0.025 * mel_env * mel_fade_in
				# Slight vibrato
				val += sin((t + sin(t * 5.0) * 0.002) * mel_freq * TAU) * 0.02 * mel_env * mel_fade_in

		# === RIDE CYMBAL pattern (after 8 seconds) ===
		if t > 8.0:
			var ride_period = beat
			var ride_pos_local = fmod(t, ride_period)
			if ride_pos_local < 0.06:
				var ride_env = max(0.0, 1.0 - ride_pos_local * 25.0)
				val += (fmod(sin(t * 8761.0) * 51234.7, 2.0) - 1.0) * 0.015 * ride_env

		# === Master volume — smooth fade in and fade out ===
		var master = clamp(t / 1.5, 0.0, 1.0) * 0.8
		if t > duration - 3.0:
			master *= (duration - t) / 3.0
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

# ─── Mission Complete — 3-note ascending fanfare ───────
func _gen_mission_complete(rate: int) -> PackedByteArray:
	var notes = [523.3, 659.3, 784.0, 1046.5]  # C5 E5 G5 C6
	var note_dur = int(rate * 0.18)
	var total = note_dur * notes.size()
	var data = PackedByteArray()
	data.resize(total * 2)
	for ni in range(notes.size()):
		var freq = notes[ni]
		for i in range(note_dur):
			var t = float(i) / rate
			var env = (1.0 - float(i) / note_dur) * (1.0 - exp(-t * 60.0))
			var val = (sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2 * t) * 0.15) * env
			var idx = (ni * note_dur + i) * 2
			var s = int(clamp(val, -1.0, 1.0) * 32767)
			data[idx]     = s & 0xFF
			data[idx + 1] = (s >> 8) & 0xFF
	return data

# ─── Pain grunt — short noisy vocal thump ──────────────
func _gen_pain_grunt(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.22)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var pitch = randf_range(180.0, 280.0)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 16.0) * (1.0 - exp(-t * 80.0))
		var val = (sin(TAU * pitch * t) * 0.5 + sin(TAU * pitch * 1.5 * t) * 0.2
				 + (randf() * 2 - 1) * 0.12) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Explosion — deep boom + rumble ────────────────────
func _gen_explosion(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.9)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 5.0)
		var boom = sin(TAU * lerp(90.0, 20.0, clamp(t * 4.0, 0.0, 1.0)) * t) * 0.6
		var rumble = (randf() * 2 - 1) * exp(-t * 3.0) * 0.5
		var val = (boom + rumble) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ═══════════════════ ENHANCED SOUND GENERATORS ═══════════════════

# ─── Realistic gunshot — layered crack + body + reverb tail ────
func _gen_gunshot(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.25)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		# Initial crack (sharp transient)
		var crack = (randf() * 2 - 1) * exp(-t * 80.0) * 0.9
		# Body (mid-freq resonance)
		var body = sin(TAU * 180.0 * t) * exp(-t * 25.0) * 0.4
		# Sub thump
		var thump = sin(TAU * 60.0 * t) * exp(-t * 15.0) * 0.3
		# Reverb tail (filtered noise)
		var tail = (randf() * 2 - 1) * exp(-t * 6.0) * 0.15
		var val = crack + body + thump + tail
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Shotgun — wide spread boom ───────────────────────
func _gen_shotgun(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.35)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var crack = (randf() * 2 - 1) * exp(-t * 40.0) * 1.0
		var boom = sin(TAU * 55.0 * t) * exp(-t * 10.0) * 0.5
		var rattle = sin(TAU * 320.0 * t) * exp(-t * 30.0) * 0.2
		var tail = (randf() * 2 - 1) * exp(-t * 4.0) * 0.2
		var val = crack + boom + rattle + tail
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Footstep — concrete tap with variation ───────────
func _gen_footstep(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.08)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var pitch = randf_range(150.0, 280.0)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 50.0) * (1.0 - exp(-t * 300.0))
		var tap = sin(TAU * pitch * t) * 0.15 * env
		var grit = (randf() * 2 - 1) * 0.1 * env
		var val = tap + grit
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Car horn — realistic dual-tone ───────────────────
func _gen_car_horn(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.6)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var f1 = randf_range(380.0, 460.0)
	var f2 = f1 * 1.25  # major third
	for i in range(samples):
		var t = float(i) / rate
		var attack = min(t * 30.0, 1.0)
		var release = max(0.0, 1.0 - (t - 0.45) * 7.0) if t > 0.45 else 1.0
		var env = attack * release
		var val = (sin(TAU * f1 * t) * 0.3 + sin(TAU * f2 * t) * 0.25) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Tire screech — filtered noise with pitch sweep ───
func _gen_tire_screech(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.5)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 4.0) * (1.0 - exp(-t * 50.0))
		var freq = 2000.0 + sin(t * 15.0) * 800.0
		var screech = sin(TAU * freq * t) * 0.15 * env
		var noise = (randf() * 2 - 1) * 0.25 * env
		var val = screech + noise
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── NPC grunt (fight/argue) — short vocal burst ──────
func _gen_npc_grunt(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.18)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var pitch = randf_range(120.0, 320.0)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 18.0) * (1.0 - exp(-t * 100.0))
		var vocal = sin(TAU * pitch * t) * 0.35
		var harmonic = sin(TAU * pitch * 2.0 * t) * 0.15
		var noise = (randf() * 2 - 1) * 0.08
		var val = (vocal + harmonic + noise) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── NPC argue — angry shout ──────────────────────────
func _gen_npc_argue(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.3)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var pitch = randf_range(200.0, 400.0)
	for i in range(samples):
		var t = float(i) / rate
		var env = (1.0 - exp(-t * 40.0)) * exp(-t * 8.0)
		var vocal = sin(TAU * pitch * t + sin(t * 12.0) * 0.5) * 0.4
		var harm2 = sin(TAU * pitch * 1.5 * t) * 0.15
		var noise = (randf() * 2 - 1) * 0.1
		var val = (vocal + harm2 + noise) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── NPC chatter — soft mumble ────────────────────────
func _gen_npc_chatter(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.4)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var pitch = randf_range(150.0, 350.0)
	for i in range(samples):
		var t = float(i) / rate
		var env = (0.5 + 0.5 * sin(t * 8.0)) * exp(-t * 3.0) * 0.3
		var vocal = sin(TAU * pitch * t + sin(t * 6.0) * 1.0) * env
		var noise = (randf() * 2 - 1) * 0.03 * env
		var val = vocal + noise
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Car door — metallic clunk ────────────────────────
func _gen_car_door(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.15)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 30.0) * (1.0 - exp(-t * 200.0))
		var clunk = sin(TAU * 220.0 * t) * 0.3 * env
		var metal = sin(TAU * 880.0 * t) * 0.15 * exp(-t * 50.0)
		var rattle = (randf() * 2 - 1) * 0.1 * exp(-t * 20.0)
		var val = clunk + metal + rattle
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Cash register — cha-ching! ───────────────────────
func _gen_cash_register(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.4)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var val = 0.0
		# Mechanical clunk
		if t < 0.08:
			val += (randf() * 2 - 1) * 0.3 * exp(-t * 40.0)
		# Bell ding (two harmonics)
		if t > 0.05:
			var bt = t - 0.05
			val += sin(TAU * 1200.0 * bt) * 0.35 * exp(-bt * 8.0)
			val += sin(TAU * 1800.0 * bt) * 0.15 * exp(-bt * 12.0)
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Glass break — high freq shatter ──────────────────
func _gen_glass_break(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.35)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = exp(-t * 8.0) * (1.0 - exp(-t * 200.0))
		var shatter = (randf() * 2 - 1) * 0.5 * env
		var ring1 = sin(TAU * 3500.0 * t) * 0.15 * exp(-t * 15.0)
		var ring2 = sin(TAU * 5200.0 * t) * 0.08 * exp(-t * 20.0)
		var val = shatter + ring1 + ring2
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Car crash — metallic crunch + glass ───────────────
func _gen_car_crash(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.6)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var impact = (randf() * 2 - 1) * exp(-t * 12.0) * 0.7
		var crunch = sin(TAU * 150.0 * t) * exp(-t * 8.0) * 0.3
		var glass = 0.0
		if t > 0.05 and t < 0.25:
			glass = (randf() * 2 - 1) * 0.2 * exp(-(t - 0.05) * 15.0)
		var metal = sin(TAU * 600.0 * t) * 0.1 * exp(-t * 20.0)
		var val = impact + crunch + glass + metal
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Player jump grunt — short effort ─────────────────
func _gen_player_jump(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.12)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = (1.0 - exp(-t * 60.0)) * exp(-t * 14.0)
		var val = (sin(TAU * 160.0 * t) * 0.35 + sin(TAU * 240.0 * t) * 0.15
				 + (randf() * 2 - 1) * 0.08) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Player grunt (melee) — deeper male voice ─────────
func _gen_player_grunt(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.2)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / rate
		var env = (1.0 - exp(-t * 50.0)) * exp(-t * 10.0)
		var val = (sin(TAU * 130.0 * t) * 0.45 + sin(TAU * 195.0 * t) * 0.2
				 + sin(TAU * 260.0 * t) * 0.1 + (randf() * 2 - 1) * 0.1) * env
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

# ─── Bird chirp data (for SFX system) ─────────────────
func _gen_bird_chirp_data(rate: int) -> PackedByteArray:
	var samples = int(rate * 0.25)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var base_freq = randf_range(2000.0, 3500.0)
	for i in range(samples):
		var t = float(i) / rate
		var freq = base_freq + sin(t * 30.0) * 500.0
		var envelope = (1.0 - t / 0.25) * (0.5 + 0.5 * sin(t * 20.0))
		var val = sin(t * freq * TAU) * 0.2 * max(envelope, 0.0)
		var s = int(clamp(val, -1.0, 1.0) * 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

