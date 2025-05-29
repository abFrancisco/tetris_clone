extends Node

func _input(event):
	if event is InputEventKey:
		if not(event.keycode==KEY_ALT or event.keycode==KEY_TAB or event.keycode==KEY_CTRL):
			if event.is_pressed():
				get_tree().change_scene_to_file("res://level.tscn")
