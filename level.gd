extends Node2D

var main_scene:PackedScene = preload("res://main.tscn")
var cell_size:int = 8
var cell_margin:int = 2
var grid_height:int = 20
var grid_width:int = 10
var game_grid:Array[PackedByteArray]
const MAX_TICK_TIME = 1.0
const MIN_TICK_TIME = 0.05
const DROP_TICK_TIME = 0.05
var tick_time = MAX_TICK_TIME

var previous_time:int
var timer_clock:float = 0.0

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
var next_piece:tetromino=null
var piece_index:int=0
var bag_index:int=0
var bag:Array=[['o', 'i', 'l', 'j', 's', 'z', 't'], ['o', 'i', 'l', 'j', 's', 'z', 't']]

func _ready():
	previous_time = Time.get_ticks_msec()
	randomize()
	fill_game_grid()
	for element:Array in bag:
		element.shuffle()
	if current_piece==null:
		spawn_piece()

#func _process(delta):
	#timer_clock += delta
	#print("processing loop")
	#if timer_clock > MIN_TICK_TIME:
		#process_timer_timeout()
		#timer_clock = 0

func _draw():
	#draw commited pieces
	for x in range(game_grid.size()):
		for y in range(game_grid[0].size()):
			if game_grid[x][y] != 0:
				draw_rect(Rect2(x * cell_size, y * cell_size, cell_size - cell_margin, cell_size - cell_margin), Color.DARK_BLUE, true, -1.0, true)
	#draw current piece
	for x in range(current_piece.cells.size()):
		for y in range(current_piece.cells.size()):
			if current_piece.cells[y][x] != 0:
				draw_rect(Rect2((x+current_piece.piece_position.x) * cell_size, (y+current_piece.piece_position.y) * cell_size, cell_size - cell_margin, cell_size - cell_margin), Color.RED, true, -1.0, true)
	#draw next piece
	for x in range(next_piece.cells.size()):
		for y in range(next_piece.cells.size()):
			if next_piece.cells[y][x] != 0:
				print("drawing next at (" + str(next_piece.piece_position.x + x) +", " + str(next_piece.piece_position.y + y) + ")")
				draw_rect(Rect2((x+next_piece.piece_position.x) * cell_size, (y+next_piece.piece_position.y) * cell_size, cell_size - cell_margin, cell_size - cell_margin), Color.RED, true, -1.0, true)


func render():
	queue_redraw()

func _input(event):
	if event.is_action_pressed("left"):
		move_piece(Vector2.LEFT)
		render()
	elif event.is_action_pressed("right"):
		move_piece(Vector2.RIGHT)
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
		%TickTimer.wait_time=DROP_TICK_TIME
		%TickTimer.start()
	elif event.is_action_released("down"):
		%TickTimer.wait_time=tick_time
	if event.is_action_pressed("drop_hard"):
		while(move_piece(Vector2.DOWN) != "committed"):
			pass
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_cancel"):
		print_game_grid()

func fill_game_grid():
	for x in range(grid_width):
		var row=PackedByteArray()
		row.resize(grid_height)
		row.fill(0)
		game_grid.append(row)

func spawn_piece():
	#instance the piece
	var selected_piece:String = bag[bag_index][piece_index]
	if next_piece == null:
		current_piece = tetromino.new()
		current_piece.cells = pieces.get(selected_piece)
		current_piece.type = selected_piece
		cycle_bag()
		selected_piece = bag[bag_index][piece_index]
	else:
		current_piece = next_piece
	next_piece = tetromino.new()
	next_piece.cells = pieces.get(selected_piece)
	next_piece.type = selected_piece
	
	#set piece position
	if (current_piece.type == "o" or current_piece.type == "i"):
		current_piece.piece_position=Vector2i(grid_width / 2 - current_piece.cells.size() / 2, -1)
	else:
		current_piece.piece_position=Vector2i(grid_width / 2 - current_piece.cells.size() / 2 - 1, -1)
	next_piece.piece_position = Vector2i(200, 50) / 8
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
func move_piece(vec:Vector2)->String:
	var return_value:String = "moved"
	#add tests before applying position
	#print("------------------------")
	#print("piece_position 1 - "+str(current_piece.piece_position))
	current_piece.piece_position += vec
	#print("piece_position 1 - "+str(current_piece.piece_position))
	if is_current_piece_overlapping():
		current_piece.piece_position -= vec
		#print("piece_position 1 - "+str(current_piece.piece_position))
		if vec==Vector2.DOWN:
			commit_current_piece()
			return_value = "committed"
	render()
	return return_value

func rotate_piece(direction:int):
	#add tests before applying rotation
	var n:int = current_piece.cells.size()
	var result:Array[Array]
	var temp:Array
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
	
	temp=current_piece.cells
	current_piece.cells=result
	if is_current_piece_overlapping():#Implement kicking here????? maybe???
		current_piece.cells=temp
	

func is_current_piece_overlapping()->bool:
	#check if piece is overllaping the map commited pieces.
	var piece_size:int = current_piece.cells.size()
	var cp_x=current_piece.piece_position.x
	var cp_y=current_piece.piece_position.y
	for x in range(piece_size):
		for y in range(piece_size):
			if current_piece.cells[y][x] != 0:
				if (cp_y + y >= 20):
					return true
				if (cp_x + x < 0 or cp_x + x >= 10):
					return true
				if (cp_y + y >=0):#this is still slightly weird, look into it later, why is it overlapping on different positions
					if (game_grid[cp_x + x][cp_y + y] != 0):
						return true
	return false

func check_lines(lines:Array):
	var line_clear_queue:Array = Array()
	for y in lines:
		var count:int = 0
		for x in range(grid_width):
			if game_grid[x][y] != 0:
				count += 1
		if count == 10:
			line_clear_queue.append(y)
	print("line clear queue = " + str(line_clear_queue))
	clear_lines(line_clear_queue)
	squash_lines(line_clear_queue)

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


func commit_current_piece():
	var commited_lines:Array=Array()
	var piece_size:int=current_piece.cells.size()
	print("------------------------------")
	for x in range(piece_size):
		for y in range(piece_size):
			if current_piece.cells[y][x] != 0:
				if not commited_lines.has(current_piece.piece_position.y + y):
					commited_lines.append(current_piece.piece_position.y + y)
				print("commiting line -> " + str(current_piece.piece_position.y + y))
				game_grid[current_piece.piece_position.x + x][current_piece.piece_position.y + y] = 1
	for y in commited_lines:
		if y <= 0:
			game_over()
	check_lines(commited_lines)
	spawn_piece()

func print_game_grid():
	var final_string:String
	for line in game_grid:
		final_string += "\n"
		for cell in line:
			final_string += " "
			final_string += str(cell)
	print(final_string)

func _on_tick_timer_timeout():
	print("time passed is = " + str(Time.get_ticks_msec() - previous_time))
	previous_time = Time.get_ticks_msec()
	move_piece(Vector2.DOWN)

func game_over():
	#without call_deferred i was getting errors sometimes, possibly a godot bug?
	get_tree().call_deferred("change_scene_to_packed", main_scene)
