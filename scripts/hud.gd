extends CanvasLayer
## Minimal HUD: crosshair, sanity bar, and the "You escaped" win screen.

const FADE_DURATION := 1.2

@onready var sanity_bar: ProgressBar = $SanityBar
@onready var win_screen: Control = $WinScreen
@onready var restart_button: Button = $WinScreen/RestartButton

func _ready() -> void:
	win_screen.visible = false
	win_screen.modulate.a = 0.0
	sanity_bar.max_value = GameManager.MAX_SANITY
	sanity_bar.value = GameManager.sanity
	GameManager.sanity_changed.connect(_on_sanity_changed)
	GameManager.game_won.connect(_on_game_won)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_sanity_changed(value: float) -> void:
	sanity_bar.value = value

func _on_game_won() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)

	win_screen.visible = true
	win_screen.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(win_screen, "modulate:a", 1.0, FADE_DURATION)

func _on_restart_pressed() -> void:
	GameManager.has_won = false
	GameManager.sanity = GameManager.MAX_SANITY
	get_tree().reload_current_scene()
