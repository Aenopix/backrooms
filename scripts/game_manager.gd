extends Node
## Autoload singleton: tracks the sanity meter and win state for the whole game.

signal sanity_changed(value: float)
signal game_won()

const MAX_SANITY := 100.0
const DRAIN_RATE := 6.0
const RECOVER_RATE := 10.0

var sanity := MAX_SANITY
var has_won := false

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
