@tool
extends OmniLight3D
## Randomized fluorescent flicker + a procedurally generated low buzz hum.
## Attach to an OmniLight3D that already has an AudioStreamPlayer3D child named "HumPlayer".

@export var base_energy := 0.5
@export var flicker_intensity := 0.2
@export var min_flicker_interval := 0.05
@export var max_flicker_interval := 0.6
@export var hum_frequency := 90.0

@onready var hum_player: AudioStreamPlayer3D = $HumPlayer
@onready var panel: MeshInstance3D = $LightPanel

const _MIX_RATE := 22050.0
const _PANEL_EMISSION_SCALE := 2.5
## Caps samples synthesized per frame so a stall (e.g. shader compile) can't
## snowball: an underrun should mean a brief glitch, not every light's hum
## racing to refill its whole buffer in one giant blocking frame.
const _MAX_FILL_PER_CALL := 1024

var _flicker_timer := 0.0
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0

func _ready() -> void:
	light_energy = base_energy
	_sync_panel()
	if Engine.is_editor_hint():
		return
	add_to_group("room_lights")
	_start_hum()
	GameManager.game_won.connect(_on_game_won)

func _start_hum() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _MIX_RATE
	gen.buffer_length = 0.2
	hum_player.stream = gen
	hum_player.play()
	_playback = hum_player.get_stream_playback()
	_fill_buffer()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(min_flicker_interval, max_flicker_interval)
		if randf() < 0.15:
			light_energy = 0.0
		else:
			light_energy = base_energy + randf_range(-flicker_intensity, flicker_intensity)
		_sync_panel()
	if _playback:
		_fill_buffer()

func _fill_buffer() -> void:
	var to_fill: int = mini(_playback.get_frames_available(), _MAX_FILL_PER_CALL)
	var amplitude: float = 0.06 * (light_energy / max(base_energy, 0.01))
	for i in to_fill:
		var sample: float = sin(_phase * TAU) * amplitude
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + hum_frequency / _MIX_RATE, 1.0)

## Keeps the ceiling light panel's glow matching the fixture's current flicker state.
func _sync_panel() -> void:
	if not panel or not panel.material_override:
		return
	var mat: StandardMaterial3D = panel.material_override
	mat.emission_energy_multiplier = max(light_energy, 0.0) * _PANEL_EMISSION_SCALE

## Every fixture (not just the exit) goes quiet once the player wins.
func _on_game_won() -> void:
	set_process(false)
	if hum_player:
		hum_player.stop()

## Called by RoomModule when this room is the exit: steady green light, hum stops.
func set_exit_state() -> void:
	set_process(false)
	light_energy = base_energy * 2.0
	light_color = Color(0.4, 1.0, 0.5)
	if hum_player:
		hum_player.stop()
	if panel and panel.material_override:
		var mat: StandardMaterial3D = panel.material_override
		mat.albedo_color = Color(0.4, 1.0, 0.5)
		mat.emission = Color(0.4, 1.0, 0.5)
	_sync_panel()
