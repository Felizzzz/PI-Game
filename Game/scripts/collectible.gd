extends Area2D

onready var level = get_node("/root/World/Level")

var effect = "bomb_increase" 
var pickable = true

func _ready():
	get_node("Sprite").set_texture(load("res://sprites/pickups/" + effect + ".png"))

func _on_body_enter(body):
	if pickable and body extends global.player_script:
		if effect == "bomb_increase" and body.bomb_quota < global.MAX_BOMBS:
			body.bomb_quota += 1
		elif effect == "flame_increase" and body.bomb_range < global.MAX_FLAMERANGE:
			body.bomb_range += 1
		elif effect == "speed_increase" and body.speed < global.MAX_SPEED:
			body.speed += 1
		elif effect == "speed_decrease" and body.speed > 0:
			body.speed -= 1
		elif effect == "confusion":
			body.set_tmp_powerup("confusion", 10, "modulate")
		elif effect == "life_increase":
			body.lives += 1
		elif effect == "kick_skill":
			body.kick = true
		get_node("AnimationPlayer").play("pickup")
		level.get_node("SamplePlayer").play("pickup")

func _on_AnimationPlayer_finished():
	self.queue_free()

func destroy():
	pickable = false
	get_node("AnimationPlayer").play("destroy")
