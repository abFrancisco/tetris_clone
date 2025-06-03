extends Node

var resolutions:Array[Vector2i] = [Vector2i(320, 180), Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
var scale_factors:PackedFloat32Array = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
var default_resolution:Vector2i = resolutions[0]
var default_scale_factor:float = scale_factors[0]
var sfx_volume:float = 0
var music_volume:float = 0

func _ready():
	var screen_size = DisplayServer.screen_get_size()
	
	#load file saved settings
	if load_settings() == ERR_FILE_NOT_FOUND:
		print("ERR FILE NOT FOUND, generating settings")
		for i in range(resolutions.size()):
			if resolutions[i].x < screen_size.x and resolutions[i].y < screen_size.y:
				default_resolution = resolutions[i]
				default_scale_factor = scale_factors[i]
	else:
		print("just loading from file")
	#change this to their own function, to be accessed during game
	#for example, when changing the settings in the menu
	DisplayServer.window_set_size(default_resolution)
	DisplayServer.window_set_position(Vector2i(0, DisplayServer.window_get_title_size("tetris_clone_v2").y))
	get_window().content_scale_factor = default_scale_factor
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume)
	
	save_settings()

## basically puts variables that need to be saved into a dict
func get_save_data()->Dictionary:
	var save_dict:Dictionary = {
		"default_resolution_x" : default_resolution.x,
		"default_resolution_y" : default_resolution.y,
		"default_scale_factor" : default_scale_factor,
		"sfx_volume" : sfx_volume,
		"music_volume" : music_volume
	}
	print("save data : \n" + str(save_dict))
	return save_dict

func save_settings():
	var save_file = FileAccess.open("user://game.settings", FileAccess.WRITE)
	var node_data = get_save_data()
	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(node_data)
	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)

func load_settings():
	if not FileAccess.file_exists("user://game.settings"):
		return ERR_FILE_NOT_FOUND
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://game.settings", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		# Creates the helper class to interact with JSON.
		var json = JSON.new()
		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		# Get the data from the JSON object.
		var node_data = json.data
		# Now we set the remaining variables.
		for i in node_data.keys():
			print("setting var " + str(i) + " to value = " + str(node_data[i]))
			set(i, node_data[i])
	return OK
