extends Node
## Pre-rendered music is presentation only; it never reads or advances gameplay RNG.

var player: AudioStreamPlayer
var phase = 0
var enabled = true
var tracks: Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless": return
	player = AudioStreamPlayer.new()
	player.volume_db = -25.0
	add_child(player)
	for number in [1, 2, 3]:
		var path = "res://assets/audio/phase_%d.wav" % number
		if not ResourceLoader.exists(path): continue
		var stream = load(path) as AudioStreamWAV
		if not stream: continue
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / (4 if stream.stereo else 2)
		tracks[number] = stream

func set_phase(value: int) -> void:
	var next = clampi(value, 1, 3)
	if next == phase: return
	phase = next
	_play_current()

func set_enabled(value: bool) -> void:
	if enabled == value: return
	enabled = value
	if not is_instance_valid(player): return
	if enabled: _play_current()
	else: player.stop()

func _play_current() -> void:
	if not enabled or not is_instance_valid(player): return
	if not tracks.has(phase): return
	player.stop()
	player.stream = tracks[phase]
	player.play()

func shutdown() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	tracks.clear()

func _exit_tree() -> void:
	shutdown()
