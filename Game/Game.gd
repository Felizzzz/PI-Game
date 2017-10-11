extends Node2D

var score = 0
var startgame = false

func _ready():
	set_fixed_process(true)
	
#get_node("player").set_gravity_scale(0)


func _set_fixed_process(delta):
	print(score)
	print(startgame)
	
#	if startgame 

func _on_startbutton_pressed():
	get_node("Start/startbutton").hide()
	startgame = true

func _on_Point_pressed():
	score += 1
