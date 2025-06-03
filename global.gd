extends Node

var resolutions:Array[Vector2i] = [Vector2i(320, 180), Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
var scale_factors:PackedFloat32Array = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
var default_resolution:Vector2 = resolutions[0]
var default_scale_factor:float = scale_factors[0]

func _ready():
	var screen_size = DisplayServer.screen_get_size()
	for i in range(resolutions.size()):
		if resolutions[i].x < screen_size.x and resolutions[i].y < screen_size.y:
			default_resolution = resolutions[i]
			default_scale_factor = scale_factors[i]
	DisplayServer.window_set_size(default_resolution)
	DisplayServer.window_set_position(Vector2i(0, DisplayServer.window_get_title_size("tetris_clone_v2").y))
	DisplayServer.screen_get_scale()
	get_window().content_scale_factor = default_scale_factor
	print("set resolution")
