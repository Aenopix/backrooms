extends OmniLight3D
## Randomized fluorescent flicker + a procedurally generated low buzz hum.
## Attach to an OmniLight3D that already has an AudioStreamPlayer3D child named "HumPlayer".

@export var base_energy := 0.5
@export var flicker_intensity := 0.2
@export var min_flicker_interval := 0.05
@export var max_flicker_interval := 0.6
@export var hum_frequency := 90.0

@onready var hum_player: AudioStreamPlayer3D = $HumPlayer

const _MIX_RATE := 22050.0

var _flicker_timer := 0.0
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0

func _ready() -> void:
	add_to_group("room_lights")
	light_energy = base_energy
	_start_hum()

func _start_hum() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _MIX_RATE
	gen.buffer_length = 0.2
	hum_player.stream = gen
	hum_player.play()
	_playback = hum_player.get_stream_playback()
	_fill_buffer()

func _process(delta: float) -> void:
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(min_flicker_interval, max_flicker_interval)
		if randf() < 0.15:
			light_energy = 0.0
		else:
			light_energy = base_energy + randf_range(-flicker_intensity, flicker_intensity)
	if _playback:
		_fill_buffer()

func _fill_buffer() -> void:
	var to_fill := _playback.get_frames_available()
	var amplitude: float = 0.06 * (light_energy / max(base_energy, 0.01))
	for i in to_fill:
		var sample: float = sin(_phase * TAU) * amplitude
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + hum_frequency / _MIX_RATE, 1.0)

## Called by RoomModule when this room is the exit: steady green light, hum stops.
func set_exit_state() -> void:
	set_process(false)
	light_energy = base_energy * 2.0
	light_color = Color(0.4, 1.0, 0.5)
	hum_player.stop()
