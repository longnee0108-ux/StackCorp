extends SceneTree
## Offline authoring tool: original, quiet plucked-keyboard loops. No runtime synthesis.

const RATE = 22050
const SECONDS = 16.0
const STEP = 0.5

func _initialize() -> void:
	call_deferred("_run")

func _frequency(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)

func _tone(buffer: PackedFloat32Array, start: float, note: int, duration: float, gain: float, mellow = false) -> void:
	if note <= 0: return
	var begin = int(start * RATE)
	var frequency = _frequency(note)
	for index in range(int(duration * RATE)):
		var t = float(index) / RATE
		var attack = minf(t / (0.035 if mellow else 0.009), 1.0)
		var release = minf((duration - t) / 0.18, 1.0)
		var envelope = attack * release * exp(-t * (1.3 if mellow else 3.8))
		var phase = TAU * frequency * t
		var wave = sin(phase) * 0.82 + sin(phase * 2.0) * 0.12 + sin(phase * 3.0) * 0.04 + sin(phase * 5.0) * 0.02
		var value = wave * envelope * gain
		buffer[(begin + index) % buffer.size()] += value
		# Two quiet, wrapped echoes make the loop continuous without external effects.
		if not mellow:
			buffer[(begin + index + int(RATE * 0.19)) % buffer.size()] += value * 0.14
			buffer[(begin + index + int(RATE * 0.38)) % buffer.size()] += value * 0.06

func _render(phase: int, melody: Array, roots: Array, thirds: Array) -> void:
	var buffer = PackedFloat32Array()
	buffer.resize(int(RATE * SECONDS))
	buffer.fill(0.0)
	for index in range(melody.size()):
		_tone(buffer, float(index) * STEP, int(melody[index]), 1.5, 0.11 if index % 4 == 0 else 0.075)
	for bar in range(8):
		var root_note = int(roots[bar % roots.size()])
		var third = int(thirds[bar % thirds.size()])
		var at = float(bar) * 2.0
		_tone(buffer, at, root_note, 2.7, 0.065, true)
		for note in [root_note + 12, root_note + 12 + third, root_note + 19]:
			_tone(buffer, at + 0.035 * (note % 3), note, 3.2, 0.024, true)
	var peak = 0.0
	var energy = 0.0
	var bytes = PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for index in range(buffer.size()):
		var sample = clampf(buffer[index], -0.85, 0.85)
		peak = maxf(peak, absf(sample))
		energy += sample * sample
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	assert(peak > 0.01 and peak < 0.85 and energy > 1.0, "Empty or clipped music loop")
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	var path = "res://assets/audio/phase_%d.wav" % phase
	assert(stream.save_to_wav(path) == OK, "Could not write music loop")
	print("Original music phase %d: 16 seconds, peak %.3f, rms %.3f" % [phase, peak, sqrt(energy / buffer.size())])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	_render(1, [64,67,69,0,67,64,60,0,65,69,72,69,67,64,62,0,64,67,71,0,69,67,64,0,62,67,69,67,64,62,60,0], [45,41,48,43], [3,4,4,4])
	_render(2, [67,71,74,0,71,69,67,0,64,67,71,67,69,67,64,0,69,72,76,0,72,71,69,0,66,69,74,72,69,66,62,0], [43,40,45,38], [4,3,3,4])
	_render(3, [69,72,74,0,77,76,74,0,69,72,77,76,72,69,65,0,67,71,74,0,76,74,71,0,67,72,76,74,72,67,64,0], [38,41,43,36], [3,4,4,4])
	print("Original ambient loops generated: PASS")
	quit(0)
