extends Node2D

var main_scene:PackedScene = preload("res://main.tscn")

@export var grid_position:Vector2i = Vector2i.ZERO
@export var next_preview_position:Vector2i = Vector2i.ZERO
@export var cell_size:float = 8
@export var cell_margin:float = 2
var grid_height:int = 20
var grid_width:int = 10
var game_grid:Array[PackedByteArray]
const MAX_TICK_TIME = 0.85#aiming for 20 to be max level
const MIN_TICK_TIME = 0.05
const TICK_TIME_STEP = 0.04
const MAX_SOFT_TICK_TIME = 0.07
const MIN_SOFT_TICK_TIME = 0.025
const SOFT_TICK_TIME_STEP = 0.00225
var soft_tick_time = MAX_SOFT_TICK_TIME
var tick_time = MAX_TICK_TIME

var previous_time:int
var timer_clock:float = 0.0

var score:int = 0
var cleared_lines:int = 0
var level:int = 1
var combo:int = 1

enum PIECE_INDEX{O, I, L, J, S, Z, T}
var pieces:Dictionary[String, Array]={
	"o":[[1, 1], [1, 1]],
	"i":[[0, 0, 0, 0],[1, 1, 1, 1],[0, 0, 0 ,0],[0, 0, 0, 0]],
	"l":[[0, 0, 1], [1, 1, 1], [0, 0, 0]],
	"j":[[1, 0, 0], [1, 1, 1], [0, 0, 0]],
	"s":[[0, 1, 1], [1, 1, 0], [0, 0, 0]],
	"z":[[1, 1, 0], [0, 1, 1], [0, 0, 0]],
	"t":[[0, 1, 0], [1, 1, 1], [0, 0, 0]]
}
var piece_color_index:Dictionary[String, int]={
	"o":1,
	"i":2,
	"l":3,
	"j":4,
	"s":5,
	"z":6,
	"t":7
}
var piece_colors:Array[Color] = [Color.BLACK, Color.YELLOW, Color.CYAN ,Color.DARK_ORANGE, Color.DARK_BLUE, Color.GREEN, Color.RED, Color.REBECCA_PURPLE]
var current_piece:tetromino=null
var next_piece:tetromino=null
var piece_index:int=0
var bag_index:int=0
var bag:Array=[['o', 'i', 'l', 'j', 's', 'z', 't'], ['o', 'i', 'l', 'j', 's', 'z', 't']]
enum OVERLAP{NONE, WALL, FLOOR, PIECE}

func _ready():
	%GridNode.cell_margin = cell_margin / 2
	%GridNode.cell_size = cell_size
	%GridNode.grid_position = grid_position
	previous_time = Time.get_ticks_msec()
	randomize()
	fill_game_grid()
	for element:Array in bag:
		element.shuffle()
	if current_piece==null:
		spawn_piece()

func _draw():
	#draw commited pieces
	previous_time = Time.get_ticks_usec()
	for x in range(game_grid.size()):
		for y in range(game_grid[0].size()):
			if game_grid[x][y] != 0:
				draw_rect(Rect2(x * cell_size + grid_position.x, y * cell_size + grid_position.y, cell_size - cell_margin, cell_size - cell_margin), piece_colors[game_grid[x][y]], true, -1.0, false)
	#draw current piece
	for x in range(current_piece.cells.size()):
		for y in range(current_piece.cells.size()):
			if current_piece.cells[y][x] != 0:
				if current_piece.piece_position.y + y >= 0:
					draw_rect(Rect2((x + current_piece.piece_position.x) * cell_size + grid_position.x, (y + current_piece.piece_position.y) * cell_size + grid_position.y, cell_size - cell_margin, cell_size - cell_margin), piece_colors[current_piece.color_index], true, -1.0, false)
	#draw next piece
	for x in range(next_piece.cells.size()):
		for y in range(next_piece.cells.size()):
			if next_piece.cells[y][x] != 0:
				draw_rect(Rect2((x + next_piece.piece_position.x) * cell_size + next_preview_position.x + next_piece.preview_offset.x, (y+next_piece.piece_position.y) * cell_size + next_preview_position.y + next_piece.preview_offset.y, cell_size - cell_margin, cell_size - cell_margin), piece_colors[next_piece.color_index], true, -1.0, false)

func render():
	queue_redraw()

func _input(event):
	if event.is_action_pressed("left"):
		move_piece(Vector2i.LEFT)
		render()
	elif event.is_action_pressed("right"):
		move_piece(Vector2i.RIGHT)
		render()
	if event.is_action_pressed("rotate_left"):
		rotate_piece(COUNTERCLOCKWISE)
		render()
	elif event.is_action_pressed("rotate_right"):
		rotate_piece(CLOCKWISE)
		render()
	if event.is_action_pressed("up"):
		rotate_piece(CLOCKWISE)
		render()
	elif event.is_action_pressed("down"):
		%TickTimer.wait_time=soft_tick_time
		%TickTimer.start()
	elif event.is_action_released("down"):
		%TickTimer.wait_time=tick_time
	if event.is_action_pressed("drop_hard"):
		while(move_piece(Vector2i.DOWN) != "committed"):
			pass
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_cancel"):
		level_up()

func fill_game_grid():
	for x in range(grid_width):
		var row=PackedByteArray()
		row.resize(grid_height)
		row.fill(0)
		game_grid.append(row)

func spawn_piece():
	%TickTimer.start()
	var selected_piece:String = bag[bag_index][piece_index]
	if next_piece == null:
		current_piece = tetromino.new()
		current_piece.cells = pieces.get(selected_piece)
		current_piece.color_index = piece_color_index.get(selected_piece)
		current_piece.type = selected_piece
		cycle_bag()
		selected_piece = bag[bag_index][piece_index]
	else:
		current_piece = next_piece
	next_piece = tetromino.new()
	next_piece.cells = pieces.get(selected_piece)
	next_piece.color_index = piece_color_index.get(selected_piece)
	next_piece.type = selected_piece
	
	#set piece position
	if current_piece.type == "o" or current_piece.type == "i":
		current_piece.piece_position=Vector2i(grid_width / 2 - current_piece.cells.size() / 2, -1)
	else:
		current_piece.piece_position=Vector2i(grid_width / 2 - current_piece.cells.size() / 2 - 1, -1)
	if next_piece.type == "o":
		next_piece.preview_offset = Vector2i.RIGHT * cell_size
	elif next_piece.type == "i":
		next_piece.preview_offset = Vector2i.UP * cell_size / 2
	else:
		next_piece.preview_offset = Vector2i.RIGHT * cell_size / 2
	next_piece.piece_position = Vector2i.ZERO
	cycle_bag()

func cycle_bag():
	piece_index += 1
	if piece_index >= 7:
		piece_index = 0
		bag[bag_index].shuffle()
		bag_index += 1
		if bag_index >= 2:
			bag_index = 0

func get_next_piece()->String:
	var next_bag_index:int = bag_index
	var next_piece_index:int = piece_index + 1
	
	if next_piece_index >= pieces.size():
		next_piece_index = 0
		next_bag_index += 1
		if next_bag_index >= bag.size():
			next_bag_index = 0
	return bag[next_bag_index][next_piece_index]

##Returns "committed" if the move committed a piece
func move_piece(vec:Vector2i)->String:
	var return_value:String = "moved"
	var overlap:OVERLAP
	current_piece.piece_position += vec
	overlap = get_current_piece_overlap()
	if overlap != OVERLAP.NONE:
		current_piece.piece_position -= vec
		if overlap == OVERLAP.FLOOR:#overlap == OVERLAP.PIECE or overlap == OVERLAP.FLOOR:
			commit_current_piece()
			return_value = "committed"
		elif overlap == OVERLAP.PIECE and vec == Vector2i.DOWN:
			commit_current_piece()
			return_value = "committed"
		if overlap == OVERLAP.WALL:
			return_value = "walled"
	render()
	print("piece moved")
	current_piece.last_move = tetromino.MOVE_TYPE.MOVE
	return return_value

#ugly freaking function, too many lines brother
func rotate_piece(direction:int):
	var n:int = current_piece.cells.size()
	var result:Array[Array]
	var overlap:OVERLAP
	result.resize(n)
	for i in range(n):
		result[i].resize(n)
	if direction == COUNTERCLOCKWISE:
		for i in range(n):
			for j in range(n):
				result[n - j - 1][i] = current_piece.cells[i][j]
	if direction == CLOCKWISE:
		for i in range(n):
			for j in range(n):
				result[j][n - i - 1] = current_piece.cells[i][j]
	current_piece.cells=result
	overlap = get_current_piece_overlap()
	if overlap != OVERLAP.NONE:
		if overlap == OVERLAP.WALL:
			var move_result = "something"
			var distance:int = 1
			while move_result != "moved" and distance <= 2:
				if current_piece.piece_position.x < 5:
					move_result = move_piece(Vector2i.RIGHT * distance)#THIS might cause rendering bug, by calling render() inside move_piece()
				else:
					move_result = move_piece(Vector2i.LEFT * distance)
				distance += 1
	current_piece.last_move = tetromino.MOVE_TYPE.ROTATE

func get_current_piece_overlap()->OVERLAP:
	#check if piece is overllaping the map commited pieces.
	var piece_size:int = current_piece.cells.size()
	var cp_x=current_piece.piece_position.x
	var cp_y=current_piece.piece_position.y
	for x in range(piece_size):
		for y in range(piece_size):
			if current_piece.cells[y][x] != 0:
				if (cp_y + y >= 20):
					return OVERLAP.FLOOR
				elif (cp_x + x < 0 or cp_x + x >= 10):
					return OVERLAP.WALL
				elif (cp_y + y >=0):
					if (game_grid[cp_x + x][cp_y + y] != 0):
						return OVERLAP.PIECE
	return OVERLAP.NONE

func commit_current_piece():
	var commited_lines:Array=Array()
	var piece_size:int=current_piece.cells.size()
	for x in range(piece_size):
		for y in range(piece_size):
			if current_piece.cells[y][x] != 0:
				if not commited_lines.has(current_piece.piece_position.y + y):
					commited_lines.append(current_piece.piece_position.y + y)
				game_grid[current_piece.piece_position.x + x][current_piece.piece_position.y + y] = current_piece.color_index
				
	for y in commited_lines:
		if y <= 0:
			game_over()
	check_lines(commited_lines)
	spawn_piece()

func check_lines(lines:Array):
	var line_clear_queue:Array = Array()
	for y in lines:
		var count:int = 0
		for x in range(grid_width):
			if game_grid[x][y] != 0:
				count += 1
		if count == 10:
			line_clear_queue.append(y)
	var line_count:int = line_clear_queue.size()
	if line_count > 0:
		score_lines(line_clear_queue)
		combo += 1
	else:
		combo = 1
	clear_lines(line_clear_queue)
	squash_lines(line_clear_queue)

func score_lines(lines:Array):
	var line_count:int = lines.size()
	cleared_lines += line_count
	if cleared_lines >= level * 10:
		level_up()
	if current_piece.type == "t":#change this to check t spin instead of piece type="t"
		if current_piece.last_move == tetromino.MOVE_TYPE.ROTATE:
			var count:int = 0
			for x:int in [0, 2]:
				for y:int in [0, 2]:
					if game_grid[x][y] != 0:
						count += 1
			if count >= 3:
				if line_count == 1:
					score_update(400 * level, "T-Spin Single")
				else:
					score_update(1600 * level, "T-Sping Double")
		pass#check for tspin
	if line_count == 1:
		score_update(100 * level, "Single")
	elif line_count == 2:
		score_update(300 * level, "Double")
	elif line_count == 3:
		score_update(500 * level, "Triple")
	elif line_count == 4:
		score_update(800 * level, "Tetris")
	if combo > 1:
		score_update(50 * combo * level, "Combo " + str(combo) + "!")

func level_up():
	level += 1
	%Level.text = str(level)
	tick_time -= TICK_TIME_STEP
	%TickTimer.wait_time = tick_time
	soft_tick_time -= SOFT_TICK_TIME_STEP#need a cap here, for level, and tick time

func score_update(value:int, action:String):
	score += value
	%Score.text = str(score)
	%Lines.text = str(cleared_lines)
	print("scored -> " + str(action))

func clear_lines(lines:Array):#i started the array with columns first, so i cant clear whole lines... shame
	for line in lines:
		for x in range(grid_width):
			game_grid[x][line] = 0

#like clear_lines, if lines where arrays, i could clear them, and move them with less resource usage
func squash_lines(lines:Array):#squashing one at a time, might be improved later
	for line in lines:#this should start with topmost line.
		for x in range(grid_width):
			for y in range(line, 0, -1):
				game_grid[x][y] = game_grid[x][y - 1]



func print_game_grid():
	var final_string:String = ""
	for line in game_grid:
		final_string += "\n"
		for cell in line:
			final_string += " "
			final_string += str(cell)
	print(final_string)

func _on_tick_timer_timeout():
	#print("time passed is = " + str(Time.get_ticks_msec() - previous_time))
	#previous_time = Time.get_ticks_msec()
	move_piece(Vector2i.DOWN)

func game_over():
	#without call_deferred i was getting errors sometimes, possibly a godot bug?
	get_tree().call_deferred("change_scene_to_packed", main_scene)
