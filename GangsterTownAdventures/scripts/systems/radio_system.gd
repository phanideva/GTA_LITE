extends Node
# Radio System — 3 procedural music stations while driving
# Press R to cycle: Hip-Hop → Classic Rock → Chill Ambient → Off

enum Station { OFF, HIP_HOP, ROCK, AMBIENT }

var current_station := Station.OFF
var _player : AudioStreamPlayer = null
var _station_names := ["OFF", "🎤 GANGSTER FM", "🎸 ROCK 101", "🌙 CHILL WAVE"]

func _ready():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -10.0
	add_child(_player)

func _input(event):
	# Check for R key press to cycle radio stations (no InputMap dependency)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		cycle_station()

func cycle_station():
	current_station = (current_station + 1) % 4
	_play_station()
	_show_station_name()

func set_volume(db: float):
	_player.volume_db = db

func stop():
	_player.stop()

func _play_station():
	match current_station:
		Station.OFF:
			_player.stop()
		Station.HIP_HOP:
			_player.stream = _gen_hiphop()
			_player.play()
		Station.ROCK:
			_player.stream = _gen_rock()
			_player.play()
		Station.AMBIENT:
			_player.stream = _gen_ambient()
			_player.play()

func _show_station_name():
	# Brief on-screen label (will be read by HUD)
	Globals.current_radio_station = _station_names[current_station]

# ─── Procedural Audio Generation ──────────────────────
func _gen_hiphop() -> AudioStreamWAV:
	var mix_rate = 22050
	var bpm      = 90
	var bars     = 4
	var beat_len = int(mix_rate * 60.0 / bpm)
	var bar_len  = beat_len * 4
	var total    = bar_len * bars
	var buf      = PackedFloat32Array()
	buf.resize(total)
	buf.fill(0.0)

	# ── Kick (beat 1 + 3, fat sub) ──
	for bar in range(bars):
		for beat in [0, 2]:
			var start = bar * bar_len + beat * beat_len
			for i in range(min(int(beat_len * 0.45), total - start)):
				var t = float(i) / mix_rate
				var env = exp(-t * 14.0)
				var kick_f = lerp(80.0, 38.0, clamp(t * 18.0, 0, 1))
				buf[start + i] += sin(TAU * kick_f * t) * env * 0.55

	# ── Snare (beat 2 + 4) ──
	for bar in range(bars):
		for beat in [1, 3]:
			var start = bar * bar_len + beat * beat_len
			for i in range(min(int(beat_len * 0.3), total - start)):
				var t = float(i) / mix_rate
				var env = exp(-t * 22.0)
				buf[start + i] += (randf() * 2 - 1) * env * 0.35
				buf[start + i] += sin(TAU * 220.0 * t) * env * 0.15

	# ── Hi-hat (every 8th) ──
	var hh_len = beat_len / 2
	for k in range(bars * 8):
		var start = k * hh_len
		if start >= total: break
		for i in range(min(int(hh_len * 0.15), total - start)):
			var t = float(i) / mix_rate
			buf[start + i] += (randf() * 2 - 1) * exp(-t * 80.0) * 0.18

	# ── Bass line (5-note loop) ──
	var bass_notes = [41.2, 41.2, 43.7, 36.7, 41.2]  # E1 E1 F1 C#1 E1
	for bar in range(bars):
		for beat in range(4):
			var note = bass_notes[(bar * 4 + beat) % bass_notes.size()]
			var start = bar * bar_len + beat * beat_len
			for i in range(min(int(beat_len * 0.85), total - start)):
				var t = float(i) / mix_rate
				var env = exp(-t * 4.5)
				buf[start + i] += sin(TAU * note * t) * env * 0.40
				buf[start + i] += sin(TAU * note * 2 * t) * env * 0.12

	# ── Synth stab chords (beats 2,4) ──
	var chord = [233.1, 293.7, 349.2]  # Bb3 D4 F4
	for bar in range(bars):
		for beat in [1, 3]:
			var start = bar * bar_len + beat * beat_len
			for i in range(min(int(beat_len * 0.25), total - start)):
				var t = float(i) / mix_rate
				var env = exp(-t * 30.0)
				for freq in chord:
					buf[start + i] += sin(TAU * freq * t) * env * 0.08

	return _buf_to_wav(buf, mix_rate)

func _gen_rock() -> AudioStreamWAV:
	var mix_rate = 22050
	var bpm      = 140
	var bars     = 4
	var beat_len = int(mix_rate * 60.0 / bpm)
	var bar_len  = beat_len * 4
	var total    = bar_len * bars
	var buf      = PackedFloat32Array()
	buf.resize(total)
	buf.fill(0.0)

	# ── Kick (every beat) ──
	for k in range(bars * 4):
		var start = k * beat_len
		if start >= total: break
		for i in range(min(int(beat_len * 0.3), total - start)):
			var t = float(i) / mix_rate
			buf[start + i] += sin(TAU * lerp(90.0, 40.0, clamp(t * 20.0, 0, 1)) * t) * exp(-t * 18.0) * 0.5

	# ── Snare (2 + 4) ──
	for bar in range(bars):
		for beat in [1, 3]:
			var start = bar * bar_len + beat * beat_len
			for i in range(min(int(beat_len * 0.25), total - start)):
				var t = float(i) / mix_rate
				buf[start + i] += ((randf() * 2 - 1) * exp(-t * 25.0) + sin(TAU * 200.0 * t) * exp(-t * 30.0)) * 0.35

	# ── Distorted guitar power chord ──
	var root = 82.4  # E2
	var fifth = 123.5  # B2
	for bar in range(bars):
		var start = bar * bar_len
		for i in range(min(bar_len, total - start)):
			var t = float(i) / mix_rate
			var env = 0.6 * (1.0 - exp(-t * 5.0)) * exp(-t * 0.4)
			# Saturated waveform (distortion approximation)
			var sig = (sin(TAU * root * t) + sin(TAU * fifth * t) * 0.7)
			sig = clamp(sig * 2.5, -1.0, 1.0)  # soft clip = distortion
			buf[start + i] += sig * env * 0.22

	# ── Crash cymbal on bar 1 and 3 ──
	for bar in [0, 2]:
		var start = bar * bar_len
		for i in range(min(int(mix_rate * 0.5), total - start)):
			var t = float(i) / mix_rate
			buf[start + i] += (randf() * 2 - 1) * exp(-t * 6.0) * 0.25

	return _buf_to_wav(buf, mix_rate)

func _gen_ambient() -> AudioStreamWAV:
	var mix_rate = 22050
	var bars     = 8
	var bar_len  = int(mix_rate * 4.0)   # 4 seconds per bar
	var total    = bar_len * bars
	var buf      = PackedFloat32Array()
	buf.resize(total)
	buf.fill(0.0)

	# ── Warm pad chord (C2 E2 G2) ──
	var chord = [65.4, 82.4, 98.0]
	for i in range(total):
		var t = float(i) / mix_rate
		var env = 0.5 * (sin(TAU * t / (float(total) / mix_rate)) + 0.6)
		for freq in chord:
			buf[i] += sin(TAU * freq * t) * env * 0.12
			buf[i] += sin(TAU * freq * 2.0 * t + 0.3) * env * 0.06

	# ── High shimmer (C5 E5 arpeggiated) ──
	var shimmer = [523.3, 659.3, 784.0, 659.3]
	var shimmer_interval = int(mix_rate * 0.5)
	for k in range(total / shimmer_interval):
		var start = k * shimmer_interval
		var freq  = shimmer[k % shimmer.size()]
		for i in range(min(shimmer_interval, total - start)):
			var t   = float(i) / mix_rate
			var env = exp(-t * 4.0) * (1.0 - exp(-t * 30.0))
			buf[start + i] += sin(TAU * freq * t) * env * 0.10

	# ── Subtle sub bass ──
	for i in range(total):
		var t = float(i) / mix_rate
		buf[i] += sin(TAU * 32.7 * t) * 0.08

	return _buf_to_wav(buf, mix_rate)

# ─── Convert float buffer to AudioStreamWAV ───────────
func _buf_to_wav(buf: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var wav   = AudioStreamWAV.new()
	wav.format      = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate    = rate
	wav.stereo      = false
	wav.loop_mode   = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin  = 0
	wav.loop_end    = buf.size()

	# Normalize to prevent clipping
	var peak = 0.0
	for s in buf:
		peak = max(peak, abs(s))
	if peak > 0.01:
		var scale = 0.88 / peak
		for i in range(buf.size()):
			buf[i] *= scale

	var bytes = PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		var s = int(clamp(buf[i], -1.0, 1.0) * 32767)
		bytes[i * 2]     = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	wav.data = bytes
	return wav
