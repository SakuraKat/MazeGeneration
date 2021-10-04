extends Node2D

onready var tile_map: TileMap = $TileMap
onready var fake_depth: TileMap = $FakeDepth

const TILESET: Array = [
	Vector2(4, 4),
	Vector2(1, 5),
	Vector2(2, 5),
	Vector2(5, 3),
	Vector2(2, 6),
	Vector2(4, 5),
	Vector2(5, 5),
	Vector2(3, 6),
	Vector2(1, 6),
	Vector2(3, 3),
	Vector2(3, 4),
	Vector2(2, 4),
	Vector2(3, 5),
	Vector2(0, 5),
	Vector2(1, 7),
	Vector2(1, 1)
]

const CHECK_HORIZONTAL_DICTIONARY: Dictionary = {
	Vector2(4, 4): false,
	Vector2(1, 5): false,
	Vector2(2, 5): false,
	Vector2(5, 3): false,
	Vector2(2, 6): true,
	Vector2(4, 5): true,
	Vector2(5, 5): true,
	Vector2(3, 6): true,
	Vector2(1, 6): false,
	Vector2(3, 3): false,
	Vector2(3, 4): false,
	Vector2(2, 4): false,
	Vector2(3, 5): true,
	Vector2(0, 5): true,
	Vector2(1, 7): true,
	Vector2(1, 1): false
}

const HORIZONTAL_CONNECTOR: Vector2 = TILESET[5]
const VERTICAL_CONNECTOR: Vector2 = TILESET[10]

const N: int = 0b0001
const E: int = 0b0010
const S: int = 0b0100
const W: int = 0b1000

var spacing: int = 2

var cell_walls: Dictionary = {
	Vector2( 0, -1) * spacing: N,
	Vector2( 1,  0) * spacing: E,
	Vector2( 0,  1) * spacing: S,
	Vector2(-1,  0) * spacing: W
}

var maze_generating = true

signal base_maze_generation_done
signal erase_walls_from_maze_done
signal add_depth_to_maze_done
signal maze_completed

var tile_size: int = 32
var width: int = 59
var height: int = 32
var additional_walls_chance: float = 0.05
export var instant_mode: bool = true

func _ready() -> void:
	randomize()
	make_maze()

func _input(_event: InputEvent) -> void:
	if not maze_generating:
		if Input.is_action_just_pressed("remake_maze"):
# warning-ignore:return_value_discarded
			get_tree().reload_current_scene()

func check_neighbors(cell: Vector2, unvisited: Array) -> Array:
	var list: Array = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list

func make_maze() -> void:
	maze_generating = true
	
	var unvisited: Array = []
	var stack: Array = []
	
	tile_map.clear()
	for x in range(width):
		for y in range(height):
			tile_map.set_cell(x, y, 0, false, false, false, TILESET[N|E|S|W])
	
	for x in range(0, width, spacing):
		for y in range(0, height, spacing):
			unvisited.append(Vector2(x, y))
	
	var current: Vector2 = Vector2.ZERO
	unvisited.erase(current)
	
	while unvisited:
		var neighbors: Array = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next: Vector2 = neighbors[randi() % neighbors.size()]
			stack.append(current)
			
			var direction: Vector2 = next - current
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			var current_walls: int = TILESET.find(tile_map.get_cell_autotile_coord(current.x, current.y)) - cell_walls[direction]
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			var next_walls: int = TILESET.find(tile_map.get_cell_autotile_coord(next.x, next.y)) - cell_walls[-direction]
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			tile_map.set_cell(current.x, current.y, 0, false, false, false, TILESET[current_walls])
#			if is_horizontal(current_walls):
#				depth_tile_map.set_cell(current.x, current.y, 1)
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			tile_map.set_cell(next.x, next.y, 0, false, false, false, TILESET[next_walls])
			
			for i in range(1, spacing):
				if direction.x != 0:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					tile_map.set_cell(current.x + i * direction.normalized().x, current.y, 0, false, false, false, HORIZONTAL_CONNECTOR)
				else:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					tile_map.set_cell(current.x, current.y + i  * direction.normalized().y, 0, false, false, false, VERTICAL_CONNECTOR)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()
		if not instant_mode:
			yield(get_tree(), "idle_frame")
	
	emit_signal("base_maze_generation_done")

func erase_walls() -> void:
	for _i in range(int(width * height * additional_walls_chance)):
# warning-ignore:integer_division
		var x: int = int(rand_range(spacing, width/spacing)) * spacing
# warning-ignore:integer_division
		var y: int = int(rand_range(spacing, height/spacing)) * spacing
		var cell: Vector2 = Vector2(x, y)
		var neighbor: Vector2 = cell_walls.keys()[randi() % cell_walls.size()]
		if TILESET.find(tile_map.get_cell_autotile_coord(x, y)) & cell_walls[neighbor]:
			var walls: int = TILESET.find(tile_map.get_cell_autotile_coord(x, y)) - cell_walls[neighbor]
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			var neighbour_walls: int = TILESET.find(tile_map.get_cell_autotile_coord(x + neighbor.x, y + neighbor.y)) - cell_walls[-neighbor]
			tile_map.set_cell(x, y, 0, false, false, false, TILESET[walls])
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
			tile_map.set_cell(x + neighbor.x, y + neighbor.y, 0, false, false, false, TILESET[neighbour_walls])
			for i in range(1, spacing):
				if neighbor.x != 0:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					tile_map.set_cell(cell.x + i * neighbor.normalized().x, cell.y, 0, false, false, false, HORIZONTAL_CONNECTOR)
				else:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					tile_map.set_cell(cell.x, cell.y + i  * neighbor.normalized().y, 0, false, false, false, VERTICAL_CONNECTOR)
		if not instant_mode:
			yield(get_tree(), "idle_frame")
	emit_signal("erase_walls_from_maze_done")

func add_depth() -> void:
	for x in range(width):
		for y in range(height):
			var current_tile_walls: Vector2 = tile_map.get_cell_autotile_coord(x, y)
			if CHECK_HORIZONTAL_DICTIONARY[current_tile_walls]:
				fake_depth.set_cell(x, y, 1)
			elif current_tile_walls == Vector2(1, 1):
				tile_map.set_cell(x, y, -1)
	emit_signal("add_depth_to_maze_done")

func _on_Maze_base_maze_generation_done() -> void:
	erase_walls()

func _on_Maze_erase_walls_from_maze_done() -> void:
	add_depth() if spacing > 2 else emit_signal("maze_completed")

func _on_Maze_add_depth_to_maze_done() -> void:
	emit_signal("maze_completed")

func _on_Maze_maze_completed() -> void:
	maze_generating = false
