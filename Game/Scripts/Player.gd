extends KinematicBody2D

export var MOTION_SPEED = 100;

var RAYNODE
func _ready():
	set_fixed_process(true)
	
	RAYNODE=get_node("RayCast2D")
	
func _fixed_process(delta):
	var MOTION=Vector2()
	
	if (Input.is_action_pressed("ui_up")):
		MOTION += Vector2(0,-1)
		RAYNODE.set_rotd(180)
	
	if (Input.is_action_pressed("ui_down")):
		MOTION += Vector2(0, 1)
		RAYNODE.set_rotd(0)
	
	if (Input.is_action_pressed("ui_left")):
		MOTION += Vector2(-1, 0)
		RAYNODE.set_rotd(-90)
	
	if (Input.is_action_pressed("ui_right")):
		MOTION += Vector2(1, 0)
		RAYNODE.set_rotd(90)
	
	MOTION=MOTION.normalized()*MOTION_SPEED*delta
	move(MOTION)
