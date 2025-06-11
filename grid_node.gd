extends Node2D

var cell_size:float = 8
var cell_margin:float = 1
var grid_position:Vector2i = Vector2i.ZERO
@export var ui_nine_patch_rects:Array[NinePatchRect]
@export var ui_nine_margin:int = 0

func _draw():
	#draw tetris grid
	for x in range(10):
		for y in range(20):# the 2 should be changed to half of the margin on the level.gd
			draw_rect(Rect2(x * cell_size - cell_margin + grid_position.x, y * cell_size - cell_margin + grid_position.y, cell_size, cell_size), Color("#aaaaaa"), false, 0.5, false)
	for nine_patch:NinePatchRect in ui_nine_patch_rects:
		var patch_rect:Rect2i = Rect2i(nine_patch.position, nine_patch.size).grow(-ui_nine_margin)
		draw_rect(patch_rect, Color("#e9e9e9"), false, 0.5, true)
