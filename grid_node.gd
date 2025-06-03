extends Node2D

var cell_size:int = 8
var cell_margin:int = 1

func _draw():
	#draw tetris grid
	for x in range(10):
		for y in range(20):# the 2 should be changed to half of the margin on the level.gd
			draw_rect(Rect2(x * cell_size - cell_margin, y * cell_size - cell_margin, cell_size, cell_size), Color.BLACK, false, -1.0, false)
