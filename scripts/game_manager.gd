extends Node
## Autoload singleton: tracks the sanity meter and win state for the whole game.

signal sanity_changed(value: float)
signal game_won()

const MAX_SANITY := 100.0
const DRAIN_RATE := 6.0
const RECOVER_RATE := 10.0
## Ceiling (in dB) the combined hum of every nearby light is allowed to hit,
## so several fixtures humming at once compress together instead of clipping.
const HUM_BUS_NAME := "Hum"
const HUM_BUS_CEILING_DB := -1.0

var sanity := MAX_SANITY
var has_won := false

func _ready() -> void:
	_setup_hum_bus()

func update_sanity(delta: float, is_lit: bool) -> void:
	if has_won:
		return
	if is_lit:
		sanity = min(MAX_SANITY, sanity + RECOVER_RATE * delta)
	else:
		sanity = max(0.0, sanity - DRAIN_RATE * delta)
	sanity_changed.emit(sanity)

func trigger_win() -> void:
	if has_won:
		return
	has_won = true
	game_won.emit()

## Every light's hum plays through this bus so a limiter can catch the combined
## volume when several fixtures are audible at once, instead of letting the
## summed signal distort.
func _setup_hum_bus() -> void:
	if AudioServer.get_bus_index(HUM_BUS_NAME) != -1:
		return
	var bus_idx := AudioServer.bus_count
	AudioServer.add_bus(bus_idx)
	AudioServer.set_bus_name(bus_idx, HUM_BUS_NAME)
	AudioServer.set_bus_send(bus_idx, "Master")
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = HUM_BUS_CEILING_DB
	AudioServer.add_bus_effect(bus_idx, limiter)
