extends Node2D

var grid_height:int=20
var grid_width:int=10
var game_grid:Array[PackedByteArray]
const MAX_TICK_TIME=1.0
const MIN_TICK_TIME=0.05
const DROP_TICK_TIME=0.05
var tick_time=1.0

var pieces:Dictionary[String, Array]={
	"o":[[1, 1], [1, 1]],
	"i":[[0, 0, 0, 0],[1, 1, 1, 1],[0, 0, 0 ,0],[0, 0, 0, 0]],
	"l":[[0, 0, 1], [1, 1, 1], [0, 0, 0]],
	"j":[[1, 0, 0], [1, 1, 1], [0, 0, 0]],
	"s":[[0, 1, 1], [1, 1, 0], [0, 0, 0]],
	"z":[[1, 1, 0], [0, 1, 1], [0, 0, 0]],
	"t":[[0, 1, 0], [1, 1, 1], [0, 0, 0]]
}
var current_piece:tetromino=null
var piece_index:int=0
var bag_index:int=0
var bag:Array=[['o', 'i', 'l', 'j', 's', 'z', 't'], ['o', 'i', 'l', 'j', 's', 'z', 't']]

func _ready():
	randomize()
	fill_game_grid()
	for element:Array in bag:
		element.shuffle()
	if current_piece==null:
		spawn_piece()

func _draw():
	for x in range(game_grid.size()):
		for y in range(game_grid[0].size()):
			if game_grid[x][y] != 0:
				draw_rect(Rect2(x*4, y*4, 2, 2), Color.DARK_BLUE, true, -1.0, true)
	for x in range(current_piece.cells.size()):
		for y in range(current_piece.cells.size()):
			if current_piece.cells[y][x] != 0:
				draw_rect(Rect2((x+current_piece.piece_position.x)*4, (y+current_piece.piece_position.y)*4, 2, 2), Color.RED, true, -1.0, true)

func render():
	#inside the delayed clock timer
	
	queue_redraw()
	#spawn piece into game grid
	#maintain control using "func _input" and "gravity"
	#commit the piece when it cant move anymore, check collisoins
	#REPEAT
	
	#MISSING A WAY TO REDUCE TRIGGER TIME for example when pressin down button

func _input(event):
	if event.is_action_pressed("left"):
		move_piece(Vector2.LEFT)
		render()
	elif event.is_action_pressed("right"):
		move_piece(Vector2.RIGHT)
		render()
	if event.is_action_pressed("up"):
		rotate_piece(CLOCKWISE)
		render()
	elif event.is_action_pressed("down"):
		%TickTimer.wait_time=DROP_TICK_TIME
		%TickTimer.start()
	elif event.is_action_released("down"):
		%TickTimer.wait_time=tick_time
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_cancel"):
		commit_current_piece()

func fill_game_grid():
	for x in range(grid_width):
		var row=PackedByteArray()
		row.resize(grid_height)
		row.fill(0)
		game_grid.append(row)

func spawn_piece():
	if current_piece != null:
		current_piece.queue_free()
	current_piece=tetromino.new()
	current_piece.cells=pieces.get(bag[bag_index][piece_index])
	current_piece.piece_position=Vector2(0, -2)
	piece_index += 1
	if piece_index >= 7:
		piece_index = 0
		bag_index += 1
		if bag_index >= 2:
			bag_index = 0

func move_piece(vec:Vector2):
	current_piece.piece_position+=vec
	render()

func rotate_piece(direction:int):
	var n:int = current_piece.cells.size()
	print("rotate")
	var result:Array[Array]
	result.resize(n)
	for i in range(n):
		result[i].resize(n)
	for i in range(n):
		for j in range(n):
			result[n - j - 1][i] = current_piece.cells[i][j];
	current_piece.cells=result

func commit_current_piece():
	var piece_size:int=current_piece.cells.size()
	for x in range(piece_size):
		for y in range(piece_size):
			if current_piece.cells[y][x] != 0:
				game_grid[current_piece.piece_position.x + x][current_piece.piece_position.y + y] = 1
	spawn_piece()

func _on_gravity_timer_timeout():
	move_piece(Vector2.DOWN)
