extends Node3D
## Builds a maze of RoomModule instances on a grid via randomized depth-first
## carving (a perfect maze: every room reachable, no loops), then places the
## exit at the cell farthest from spawn and drops the player in.

const CELL_SIZE := 4.0
const ROOM_SCENE := preload("res://scenes/RoomModule.tscn")
const PLAYER_SCENE := preload("res://scenes/Player.tscn")

@export var grid_size := Vector2i(5, 5)
@export var randomize_layout := false
@export var fixed_seed := 1337

var _cells := []
var _exit_cell := Vector2i.ZERO
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = randi() if randomize_layout else fixed_seed
	_generate_maze()
	_build_rooms()
	_spawn_player()

func _generate_maze() -> void:
	_cells.clear()
	for x in grid_size.x:
		var col := []
		for y in grid_size.y:
			col.append({"n": true, "s": true, "e": true, "w": true, "visited": false})
		_cells.append(col)

	var stack: Array[Vector2i] = [Vector2i(0, 0)]
	_cells[0][0]["visited"] = true
	while stack.size() > 0:
		var current: Vector2i = stack[-1]
		var neighbors := _unvisited_neighbors(current)
		if neighbors.is_empty():
			stack.pop_back()
			continue
		var next: Vector2i = neighbors[_rng.randi_range(0, neighbors.size() - 1)]
		_carve(current, next)
		_cells[next.x][next.y]["visited"] = true
		stack.append(next)

func _unvisited_neighbors(cell: Vector2i) -> Array:
	var result := []
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for d in directions:
		var n: Vector2i = cell + d
		if n.x >= 0 and n.x < grid_size.x and n.y >= 0 and n.y < grid_size.y and not _cells[n.x][n.y]["visited"]:
			result.append(n)
	return result

func _carve(a: Vector2i, b: Vector2i) -> void:
	var diff := b - a
	if diff == Vector2i(0, -1):
		_cells[a.x][a.y]["n"] = false
		_cells[b.x][b.y]["s"] = false
	elif diff == Vector2i(0, 1):
		_cells[a.x][a.y]["s"] = false
		_cells[b.x][b.y]["n"] = false
	elif diff == Vector2i(1, 0):
		_cells[a.x][a.y]["e"] = false
		_cells[b.x][b.y]["w"] = false
	elif diff == Vector2i(-1, 0):
		_cells[a.x][a.y]["w"] = false
		_cells[b.x][b.y]["e"] = false

func _dir_vector(d: String) -> Vector2i:
	match d:
		"n": return Vector2i(0, -1)
		"s": return Vector2i(0, 1)
		"e": return Vector2i(1, 0)
		"w": return Vector2i(-1, 0)
	return Vector2i.ZERO

## BFS to the farthest reachable cell — gives a satisfying, non-trivial exit distance.
func _farthest_cell(from: Vector2i) -> Vector2i:
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	var farthest := from
	var idx := 0
	while idx < queue.size():
		var current: Vector2i = queue[idx]
		idx += 1
		for d_name in ["n", "s", "e", "w"]:
			if not _cells[current.x][current.y][d_name]:
				var n: Vector2i = current + _dir_vector(d_name)
				if n.x >= 0 and n.x < grid_size.x and n.y >= 0 and n.y < grid_size.y and not dist.has(n):
					dist[n] = dist[current] + 1
					queue.append(n)
					if dist[n] > dist[farthest]:
						farthest = n
	return farthest

func _build_rooms() -> void:
	_exit_cell = _farthest_cell(Vector2i(0, 0))
	for x in grid_size.x:
		for y in grid_size.y:
			var room := ROOM_SCENE.instantiate()
			add_child(room)
			room.position = Vector3(x * CELL_SIZE, 0, y * CELL_SIZE)
			var c: Dictionary = _cells[x][y]
			room.build({"n": not c["n"], "s": not c["s"], "e": not c["e"], "w": not c["w"]})
			if Vector2i(x, y) == _exit_cell:
				room.mark_as_exit()

func _spawn_player() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	player.position = Vector3(0, 0.1, 0)
