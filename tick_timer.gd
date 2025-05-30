extends Node

var wait_time:float = 1.0
var timer:SceneTreeTimer = null
signal timeout

func _ready():
	timer = get_tree().create_timer(wait_time, true, false,false)
	timer.connect("timeout", timer_trigger)

func timer_trigger():
	emit_signal("timeout")
	timer = get_tree().create_timer(0.05, true, false, false)
	timer.connect("timeout", timer_trigger)

func restart():
	timer = get_tree().create_timer(0.05, true, false, false)
	timer.connect("timeout", timer_trigger)
