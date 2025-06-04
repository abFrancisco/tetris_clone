extends Node

func _ready():
	for i in range(Global.resolutions.size()):
		%Resolution.add_item(str(Global.resolutions[i]), i)
	%Resolution.select(Global.resolutions.find(Global.default_resolution))
	
	%SFXSlider.value = Global.sfx_volume
	
	%MusicSlider.value = Global.music_volume


func _on_window_mode_selected(index):
	pass # Replace with function body.


func _on_resolution_selected(index):
	Global.update_window_size(index)

func _on_SFX_volume_changed(value):
	%SFXText.text = str(int(value))
	Global.update_audio_volume(value, -1)

func _on_music_volume_changed(value):
	%MusicText.text = str(int(value))
	Global.update_audio_volume(-1, value)

func _on_SFX_text_submitted(new_text):
	var value = new_text.to_int()
	if value >= 0 and value <= 100:
		%SFXSlider.value = value
	elif value > 100:
		%SFXText.text = "100"
		%SFXSlider.value = 100
	elif value < 0:
		%SFXText.text = "0"
		%SFXSlider.value = 0

func _on_music_text_submitted(new_text):
	var value = new_text.to_int()
	if value >= 0 and value <= 100:
		%MusicSlider.value = value
	elif value > 100:
		%MusicText.text = "100"
		%SFXSlider.value = 100
	elif value < 0:
		%MusicText.text = "0"
		%SFXSlider.value = 0
