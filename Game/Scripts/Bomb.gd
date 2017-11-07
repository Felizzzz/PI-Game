extends Area2D
const IDLE_SPEED=10
var MOTION=Vector2()
var BombanimNode
var anim=""



func _ready():
	set_fixed_process(true)
	BombanimNode = get_node("AnimatedSprite")

func start_at(MOTION):
	set_pos(MOTION)
	
func _fixed_process(delta):
	set_pos(get_pos())
	
	anim="Bomb_anim"
	BombanimNode.play(anim)


func _on_Timer_timeout():
	queue_free()
