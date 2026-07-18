@tool
extends Node3D
## One reusable room "tile": floor, ceiling, up to 4 walls, a flickering light.
## Geometry is built procedurally so a single RoomModule.tscn can serve every cell.

const CELL_SIZE := 4.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.2

const WALL_MATERIAL := preload("res://assets/materials/wall_yellow.tres")
const FLOOR_MATERIAL := preload("res://assets/materials/carpet.tres")
const CEILING_MATERIAL := preload("res://assets/materials/ceiling.tres")
const LIGHT_PANEL_MATERIAL := preload("res://assets/materials/light_panel.tres")
const FLICKER_SCRIPT := preload("res://scripts/flicker_light.gd")
const LIGHT_PANEL_SIZE := 1.0

var is_exit := false

## open: Dictionary with keys "n"/"s"/"e"/"w" -> true if that side has a doorway.
## has_light: not every room gets a fixture — some sit in the dark between lit ones.
func build(open: Dictionary, has_light: bool = true) -> void:
	_build_floor()
	_build_ceiling()
	_build_wall("WallNorth", open.get("n", false), Vector3(0, WALL_HEIGHT / 2.0, -CELL_SIZE / 2.0), Vector3(CELL_SIZE, WALL_HEIGHT, WALL_THICKNESS))
	_build_wall("WallSouth", open.get("s", false), Vector3(0, WALL_HEIGHT / 2.0, CELL_SIZE / 2.0), Vector3(CELL_SIZE, WALL_HEIGHT, WALL_THICKNESS))
	_build_wall("WallEast", open.get("e", false), Vector3(CELL_SIZE / 2.0, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL_SIZE))
	_build_wall("WallWest", open.get("w", false), Vector3(-CELL_SIZE / 2.0, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL_SIZE))
	if has_light:
		_build_light()

func _build_floor() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE, 0.2, CELL_SIZE)
	mesh.material = FLOOR_MATERIAL
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Floor"
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, -0.1, 0)
	add_child(mesh_instance)

	var box := BoxShape3D.new()
	box.size = mesh.size
	var shape := CollisionShape3D.new()
	shape.shape = box
	var body := StaticBody3D.new()
	body.name = "FloorBody"
	body.position = mesh_instance.position
	body.add_child(shape)
	add_child(body)

func _build_ceiling() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE, 0.2, CELL_SIZE)
	mesh.material = CEILING_MATERIAL
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Ceiling"
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, WALL_HEIGHT + 0.1, 0)
	add_child(mesh_instance)

func _build_wall(wall_name: String, is_open: bool, local_pos: Vector3, size: Vector3) -> void:
	if is_open:
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = WALL_MATERIAL
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = wall_name
	mesh_instance.mesh = mesh
	mesh_instance.position = local_pos
	add_child(mesh_instance)

	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	var body := StaticBody3D.new()
	body.name = wall_name + "Body"
	body.position = local_pos
	body.add_child(shape)
	add_child(body)

func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "FluorescentLight"
	light.position = Vector3(0, WALL_HEIGHT - 0.3, 0)
	light.omni_range = CELL_SIZE * 0.9
	light.light_color = Color(1.0, 0.96, 0.78)
	light.shadow_enabled = true

	var hum := AudioStreamPlayer3D.new()
	hum.name = "HumPlayer"
	hum.max_distance = CELL_SIZE * 2.0
	hum.unit_size = 2.0
	light.add_child(hum)

	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(LIGHT_PANEL_SIZE, 0.05, LIGHT_PANEL_SIZE)
	var panel := MeshInstance3D.new()
	panel.name = "LightPanel"
	panel.mesh = panel_mesh
	panel.material_override = LIGHT_PANEL_MATERIAL.duplicate()
	panel.position = Vector3(0, 0.3, 0)
	light.add_child(panel)

	light.set_script(FLICKER_SCRIPT)
	add_child(light)

## Marks this room as the maze exit: adds a win trigger and recolors its light.
func mark_as_exit() -> void:
	is_exit = true
	var box := BoxShape3D.new()
	box.size = Vector3(CELL_SIZE * 0.6, WALL_HEIGHT, CELL_SIZE * 0.6)
	var shape := CollisionShape3D.new()
	shape.shape = box
	var area := Area3D.new()
	area.name = "ExitTrigger"
	area.position = Vector3(0, WALL_HEIGHT / 2.0, 0)
	area.add_child(shape)
	area.body_entered.connect(_on_exit_body_entered)
	add_child(area)

	var light := get_node_or_null("FluorescentLight")
	if not light:
		_build_light()
		light = get_node_or_null("FluorescentLight")
	if light and light.has_method("set_exit_state"):
		light.set_exit_state()

func _on_exit_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.trigger_win()
