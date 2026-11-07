extends Node
## Procedural audio. Every sound effect and the ambient music loop are synthesized
## at startup into AudioStreamWAV buffers, so the project ships no audio files.
## To use recorded sounds instead, put .wav/.ogg files under res://audio/ and
## assign them in _streams (same keys) after _build().

const RATE := 22050
const MUSIC_VOLUME_DB := -15.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _last_play: Dictionary = {}
var _music: AudioStreamPlayer
var _music_ready: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 20:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	_build()
	WorkerThreadPool.add_task(_build_music_threaded)


func play(sound: String, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	if not _streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(sound, -1000)) < 40:
		return
	_last_play[sound] = now
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_music() -> void:
	if _music_ready and not _music.playing:
		_music.play()


# --- Sound design ----------------------------------------------------------

func _build() -> void:
	_streams["laser"] = _wav(_laser(0.20, 2600.0, 260.0, 0.15, 0.40))
	_streams["heavy"] = _wav(_laser(0.36, 1300.0, 80.0, 0.35, 0.50))
	_streams["blade"] = _wav(_blade(0.42))
	_streams["heal"] = _wav(_arpeggio([660.0, 880.0, 1320.0], 0.085, 0.3, "sine", 0.35))
	_streams["shield"] = _wav(_shield(0.38))
	_streams["burn"] = _wav(_crackle(0.30))
	_streams["toxin"] = _wav(_bubbles(0.32))
	_streams["ion"] = _wav(_ion(0.20))
	_streams["hit"] = _wav(_noise_burst(0.08, 0.5, 0.35))
	_streams["explosion"] = _wav(_explosion(1.3))
	_streams["click"] = _wav(_blip(0.035, 1900.0, 0.3))
	_streams["hover"] = _wav(_blip(0.02, 2600.0, 0.15))
	_streams["coin"] = _wav(_arpeggio([988.0, 1319.0], 0.07, 0.15, "square", 0.22))
	_streams["levelup"] = _wav(_arpeggio([523.0, 659.0, 784.0, 1047.0], 0.075, 0.35, "square", 0.22))
	_streams["error"] = _wav(_arpeggio([220.0, 175.0], 0.08, 0.1, "square", 0.2))
	_streams["alarm"] = _wav(_alarm(1.2))
	_streams["whoosh"] = _wav(_whoosh(0.5))
	_streams["victory"] = _wav(_fanfare([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0], [0.14, 0.14, 0.14, 0.28, 0.12, 0.6]))
	_streams["defeat"] = _wav(_fanfare([392.0, 311.0, 262.0, 196.0], [0.25, 0.25, 0.3, 0.8]))


func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


static func _env(t: float, dur: float, attack: float = 0.004, power: float = 2.0) -> float:
	if t < attack:
		return t / attack
	return pow(maxf(0.0, 1.0 - (t - attack) / maxf(0.0001, dur - attack)), power)


static func _osc(phase: float, wave: String) -> float:
	match wave:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"saw":
			return phase * 2.0 - 1.0
		"tri":
			return 1.0 - 4.0 * absf(phase - 0.5)
	return sin(TAU * phase)


## Classic sci-fi zap: fast exponential pitch drop, square + saw, a little grit.
func _laser(dur: float, f0: float, f1: float, grit: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var ph2 := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := f0 * pow(f1 / f0, t / dur)
		ph = fmod(ph + f / RATE, 1.0)
		ph2 = fmod(ph2 + f * 1.505 / RATE, 1.0)
		var v := _osc(ph, "square") * 0.5 + _osc(ph2, "saw") * 0.5
		v += randf_range(-1.0, 1.0) * grit * _env(t, dur * 0.5, 0.001, 3.0)
		lp += 0.55 * (v - lp)
		out[i] = lp * _env(t, dur, 0.002, 1.7) * amp
	return out


## Energy blade swing: two detuned low saws with a swelling doppler bend.
func _blade(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph1 := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var swell := sin(PI * t / dur)
		var bend := 1.0 + 0.35 * swell
		ph1 = fmod(ph1 + 92.0 * bend / RATE, 1.0)
		ph2 = fmod(ph2 + 94.5 * bend / RATE, 1.0)
		ph3 = fmod(ph3 + 184.0 * bend / RATE, 1.0)
		var v := _osc(ph1, "saw") * 0.45 + _osc(ph2, "saw") * 0.45 + _osc(ph3, "sine") * 0.4
		v += randf_range(-1.0, 1.0) * 0.15 * swell
		lp += (0.08 + 0.25 * swell) * (v - lp)
		out[i] = lp * swell * 0.75
	return out


func _shield(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var ph2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 320.0 + 380.0 * (t / dur)
		ph = fmod(ph + f / RATE, 1.0)
		ph2 = fmod(ph2 + 120.0 / RATE, 1.0)
		var trem := 0.6 + 0.4 * sin(TAU * 22.0 * t)
		var v := _osc(ph, "sine") * trem * 0.6 + _osc(ph2, "tri") * 0.3
		out[i] = v * _env(t, dur, 0.03, 1.5) * 0.45
	return out


func _crackle(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var pop := 1.0 if randf() < 0.02 else 0.25
		lp += 0.35 * (randf_range(-1.0, 1.0) * pop - lp)
		out[i] = lp * _env(t, dur, 0.01, 1.2) * 0.9
	return out


func _bubbles(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 260.0 + 240.0 * fmod(t * 14.0, 1.0)
		ph = fmod(ph + f / RATE, 1.0)
		out[i] = _osc(ph, "sine") * _env(t, dur, 0.01, 1.5) * 0.4
	return out


func _ion(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var f := 2500.0
	for i in n:
		var t := float(i) / RATE
		if i % 180 == 0:
			f = randf_range(1400.0, 4200.0)
		ph = fmod(ph + f / RATE, 1.0)
		out[i] = _osc(ph, "square") * _env(t, dur, 0.002, 1.4) * 0.18
	return out


func _noise_burst(dur: float, smooth: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += smooth * (randf_range(-1.0, 1.0) - lp)
		out[i] = lp * _env(t, dur, 0.001, 2.5) * amp
	return out


func _explosion(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var cutoff := lerpf(0.5, 0.02, minf(1.0, t / dur * 1.4))
		lp += cutoff * (randf_range(-1.0, 1.0) - lp)
		ph = fmod(ph + (55.0 - 25.0 * t / dur) / RATE, 1.0)
		var v := lp * 1.6 + _osc(ph, "sine") * 0.6 * _env(t, dur * 0.6, 0.005, 2.0)
		out[i] = v * _env(t, dur, 0.004, 1.8) * 0.8
	return out


func _blip(dur: float, f: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph = fmod(ph + f / RATE, 1.0)
		out[i] = _osc(ph, "sine") * _env(t, dur, 0.001, 2.0) * amp
	return out


func _arpeggio(notes: Array, step: float, tail: float, wave: String, amp: float) -> PackedFloat32Array:
	var dur := step * notes.size() + tail
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in notes.size():
		var start := int(k * step * RATE)
		var f: float = notes[k]
		var note_dur := dur - k * step
		var ph := 0.0
		for i in range(start, n):
			var t := float(i - start) / RATE
			ph = fmod(ph + f / RATE, 1.0)
			out[i] += _osc(ph, wave) * _env(t, note_dur, 0.004, 3.0) * amp
	return out


func _alarm(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 620.0 if fmod(t, 0.6) < 0.3 else 820.0
		ph = fmod(ph + f / RATE, 1.0)
		lp += 0.3 * (_osc(ph, "square") - lp)
		out[i] = lp * _env(t, dur, 0.01, 0.6) * 0.35
	return out


func _whoosh(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var swell := sin(PI * t / dur)
		lp += (0.02 + 0.3 * swell) * (randf_range(-1.0, 1.0) - lp)
		out[i] = lp * swell * 0.7
	return out


func _fanfare(notes: Array, lengths: Array) -> PackedFloat32Array:
	var total := 0.0
	for l: float in lengths:
		total += l
	total += 0.4
	var n := int(total * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var start_t := 0.0
	for k in notes.size():
		var f: float = notes[k]
		var len_s: float = lengths[k] + 0.4
		var start := int(start_t * RATE)
		var ph1 := 0.0
		var ph2 := 0.0
		var lp := 0.0
		for i in range(start, mini(n, start + int(len_s * RATE))):
			var t := float(i - start) / RATE
			ph1 = fmod(ph1 + f / RATE, 1.0)
			ph2 = fmod(ph2 + f * 1.004 / RATE, 1.0)
			var v := _osc(ph1, "saw") * 0.5 + _osc(ph2, "saw") * 0.5
			lp += 0.18 * (v - lp)
			out[i] += lp * _env(t, len_s, 0.02, 1.4) * 0.32
		start_t += float(lengths[k])
	return out


# --- Music -------------------------------------------------------------------

## Slow, original four-chord pad with a soft plucked arpeggio. Built on a worker
## thread because it is ~10 seconds of audio.
func _build_music_threaded() -> void:
	var chords := [
		[146.83, 174.61, 220.00],
		[116.54, 146.83, 174.61],
		[130.81, 174.61, 220.00],
		[130.81, 164.81, 196.00],
	]
	var chord_len := 2.5
	var n := int(chord_len * chords.size() * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var phases := PackedFloat32Array()
	phases.resize(8)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var ci := mini(int(t / chord_len), chords.size() - 1)
		var local := t - ci * chord_len
		var chord: Array = chords[ci]
		var swell := sin(PI * local / chord_len)
		var v := 0.0
		for k in 3:
			var f: float = chord[k]
			phases[k * 2] = fmod(phases[k * 2] + f / RATE, 1.0)
			phases[k * 2 + 1] = fmod(phases[k * 2 + 1] + f * 1.006 / RATE, 1.0)
			v += (phases[k * 2] * 2.0 - 1.0) + (phases[k * 2 + 1] * 2.0 - 1.0)
		phases[6] = fmod(phases[6] + float(chord[0]) * 0.5 / RATE, 1.0)
		v = v * 0.08 + sin(TAU * phases[6]) * 0.25
		lp += (0.03 + 0.02 * sin(TAU * t / 5.0)) * (v - lp)
		var pad := lp * (0.35 + 0.65 * swell)
		# arpeggio: 8 plucks per chord, an octave or two up
		var step := chord_len / 8.0
		var pk := int(local / step)
		var pt := local - pk * step
		var pf: float = float(chord[pk % 3]) * (4.0 if pk % 4 < 2 else 2.0)
		var pluck := sin(TAU * pf * pt) * exp(-pt * 9.0) * 0.12
		out[i] = (pad + pluck) * 0.9
	var stream := _wav(out, true)
	call_deferred("_on_music_built", stream)


func _on_music_built(stream: AudioStreamWAV) -> void:
	_music.stream = stream
	_music_ready = true
	_music.play()
