extends Area2D
var MOTION=Vector2()


func _ready():
	set_fixed_process(true)

func start_at(MOTION):
	set_pos(MOTION)
	
func _fixed_process(delta):
	set_pos(get_pos())


func _on_Timer_timeout():
	queue_free()
