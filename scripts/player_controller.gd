extends CharacterBody3D
## First-person controller: WASD move, mouse look, flashlight toggle, footsteps.

const SPEED := 3.2
const MOUSE_SENSITIVITY := 0.0025
const GRAVITY := 9.8
const FOOTSTEP_INTERVAL := 0.45

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer

var _can_move := true
var _footstep_timer := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F:
			flashlight.visible = not flashlight.visible
		elif event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

## Called by GameManager to freeze the player once the exit is reached.
func set_movement_enabled(enabled: bool) -> void:
	_can_move = enabled

func _physics_process(delta: float) -> void:
	if not _can_move:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()
	var direction := (transform.basis * input_dir).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	_handle_footsteps(delta, direction)

func _handle_footsteps(delta: float, direction: Vector3) -> void:
	if direction.length() > 0.1 and is_on_floor():
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = FOOTSTEP_INTERVAL
			if footstep_player.stream:
				footstep_player.play()
	else:
		_footstep_timer = 0.0

func _process(delta: float) -> void:
	GameManager.update_sanity(delta, _is_lit())

## Sanity recovers near a fluorescent light that is currently bright, drains otherwise.
func _is_lit() -> bool:
	for light in get_tree().get_nodes_in_group("room_lights"):
		if light is OmniLight3D and global_position.distance_to(light.global_position) < light.omni_range and light.light_energy > 0.5:
			return true
	return false
