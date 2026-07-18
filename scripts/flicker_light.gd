@tool
extends OmniLight3D
## Randomized fluorescent flicker + a procedurally generated low buzz hum.
## Attach to an OmniLight3D that already has an AudioStreamPlayer3D child named "HumPlayer".

@export var base_energy := 0.5
@export var flicker_intensity := 0.2
@export var min_flicker_interval := 0.05
@export var max_flicker_interval := 0.6
@export var hum_frequency := 160.0

@onready var hum_player: AudioStreamPlayer3D = $HumPlayer
@onready var panel: MeshInstance3D = $LightPanel

const _MIX_RATE := 22050.0
const _PANEL_EMISSION_SCALE := 2.5
## How long the hum takes to fade to silence before we stop the player, so the
## cutoff doesn't chop the waveform mid-cycle and click.
const _HUM_FADE_TIME := 0.15
## How long the hum's amplitude takes to slide to a new target, so flicker-driven
## jumps (e.g. snapping to light_energy == 0) ramp instead of clicking.
const _AMPLITUDE_RAMP_TIME := 0.03
const _AMPLITUDE_RANGE := 0.15
const _AMPLITUDE_STEP := _AMPLITUDE_RANGE / (_MIX_RATE * _AMPLITUDE_RAMP_TIME)
## Per-instance pitch variation, so hums from adjacent lights beat/chorus
## instead of phase-locking into one louder tone when they overlap.
const _HUM_FREQUENCY_JITTER := 5.0

var _flicker_timer := 0.0
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _flicker_enabled := true
var _hum_volume := 1.0
var _hum_fade_time_left := -1.0
var _current_amplitude := 0.0

func _ready() -> void:
	light_energy = base_energy
	_sync_panel()
	if Engine.is_editor_hint():
		return
	hum_frequency += randf_range(-_HUM_FREQUENCY_JITTER, _HUM_FREQUENCY_JITTER)
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
	if _flicker_enabled:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			_flicker_timer = randf_range(min_flicker_interval, max_flicker_interval)
			if randf() < 0.15:
				light_energy = 0.0
			else:
				light_energy = base_energy + randf_range(-flicker_intensity, flicker_intensity)
			_sync_panel()
	if _hum_fade_time_left >= 0.0:
		_hum_fade_time_left -= delta
		_hum_volume = clamp(_hum_fade_time_left / _HUM_FADE_TIME, 0.0, 1.0)
		if _hum_fade_time_left <= 0.0:
			_playback = null
			if hum_player:
				hum_player.stop()
			set_process(false)
			return
	if _playback:
		_fill_buffer()

func _fill_buffer() -> void:
	var to_fill := _playback.get_frames_available()
	var target_amplitude: float = 0.06 * (light_energy / max(base_energy, 0.01)) * _hum_volume
	for i in to_fill:
		_current_amplitude = move_toward(_current_amplitude, target_amplitude, _AMPLITUDE_STEP)
		var sample: float = sin(_phase * TAU) * _current_amplitude
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + hum_frequency / _MIX_RATE, 1.0)

## Smoothly fades the hum to silence, then stops the player. Avoids the
## click/pop from cutting the raw sine wave off mid-cycle with a hard stop().
func _stop_hum() -> void:
	_hum_fade_time_left = _HUM_FADE_TIME

## Keeps the ceiling light panel's glow matching the fixture's current flicker state.
func _sync_panel() -> void:
	if not panel or not panel.material_override:
		return
	var mat: StandardMaterial3D = panel.material_override
	mat.emission_energy_multiplier = max(light_energy, 0.0) * _PANEL_EMISSION_SCALE

## Every fixture (not just the exit) goes quiet once the player wins.
func _on_game_won() -> void:
	_flicker_enabled = false
	_stop_hum()

## Called by RoomModule when this room is the exit: steady green light, hum stops.
func set_exit_state() -> void:
	_flicker_enabled = false
	light_energy = base_energy * 2.0
	light_color = Color(0.4, 1.0, 0.5)
	_stop_hum()
	if panel and panel.material_override:
		var mat: StandardMaterial3D = panel.material_override
		mat.albedo_color = Color(0.4, 1.0, 0.5)
		mat.emission = Color(0.4, 1.0, 0.5)
	_sync_panel()
