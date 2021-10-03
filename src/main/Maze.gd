extends Node2D

onready var tile_map: TileMap = $TileMap

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
const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8

var cell_walls: Dictionary = {
	Vector2( 0, -1): N,
	Vector2( 1,  0): E,
	Vector2( 0,  1): S,
	Vector2(-1,  0): W
}

var tile_size: int = 32
var width: int = 59
var height: int = 32

func _ready() -> void:
	randomize()
	
	make_maze()

func check_neighbors(cell, unvisited) -> Array:
	var list: Array = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list

func make_maze() -> void:
	var unvisited: Array = []
	var stack: Array = []
	
	tile_map.clear()
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2(x, y))
			tile_map.set_cell(x, y, 0, false, false, false, TILESET[N|E|S|W])
	
	var current: Vector2 = Vector2.ZERO
	unvisited.erase(current)
	
	if true:
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
	# warning-ignore:narrowing_conversion
	# warning-ignore:narrowing_conversion
				tile_map.set_cell(next.x, next.y, 0, false, false, false, TILESET[next_walls])
				current = next
				unvisited.erase(current)
			elif stack:
				current = stack.pop_back()
			yield(get_tree(), "idle_frame")
