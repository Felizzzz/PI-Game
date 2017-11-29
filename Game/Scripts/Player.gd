extends KinematicBody2D

onready var gameover = get_node("/root/World/Gameover")
onready var level = get_node("/root/World/Level")

export var id = 1
export var char = "goblin-brown" 

var dead = false 

var active_bombs = [] 
var collision_exceptions = []

var old_motion = Vector2() 
var anim = "down_idle" 

var lives 
var speed = 10 
var bomb_quota = 3 
var bomb_range = 2 
var kick = false 
var invincible = false 
var confusion = false 
var tmp_powerup = null 
var tmp_anim = null 

func _ready():
	get_node("CharSprite").set_sprite_frames(load("res://sprites/" + char + ".tres"))
	lives = global.nb_lives

	set_fixed_process(true)

func _fixed_process(delta):
	process_movement(delta)
	process_actions()
	if not invincible:
		process_explosions()
	process_gameover()

	for bomb in collision_exceptions:
		if (self.get_pos().x < (bomb.get_cell_pos().x - 0.5)*global.TILE_SIZE \
				or self.get_pos().x > (bomb.get_cell_pos().x + 1.5)*global.TILE_SIZE \
				or self.get_pos().y < (bomb.get_cell_pos().y - 0.5)*global.TILE_SIZE \
				or self.get_pos().y > (bomb.get_cell_pos().y + 1.5)*global.TILE_SIZE):
			remove_collision_exception_with(bomb.get_node("StaticBody2D"))
			collision_exceptions.erase(bomb)

func process_movement(delta):
	var motion = Vector2(0, 0)

	if Input.is_action_pressed(str(id) + "_move_up"):
		motion += Vector2(0, -1)
	if Input.is_action_pressed(str(id) + "_move_down"):
		motion += Vector2(0, 1)
	if Input.is_action_pressed(str(id) + "_move_left"):
		motion += Vector2(-1, 0)
	if Input.is_action_pressed(str(id) + "_move_right"):
		motion += Vector2(1, 0)

	if confusion:
		motion = -motion

	motion = motion.normalized()*speed*0.5*global.TILE_SIZE*delta
	move(motion)

	if kick and is_colliding() and get_collider().get_parent() in level.bomb_manager.get_children():
		var bomb = get_collider().get_parent()

		if motion.normalized() != bomb.slide_dir.normalized():
			bomb.push_dir(bomb.get_cell_pos() - self.get_cell_pos())

	var slide_attempts = 1
	while is_colliding() and slide_attempts > 0:
		motion = get_collision_normal().slide(motion)
		move(motion)
		slide_attempts -= 1

	if old_motion == motion:
		return

	old_motion = motion
	if motion == Vector2(0, 0):
		anim += "_idle"
	elif abs(motion.x) > 0:
		get_node("CharSprite").set_flip_h(motion.x < 0)
		anim = "side"
	elif motion.y > 0:
		anim = "down"
	elif motion.y < 0:
		anim = "up"

	get_node("ActionAnimations").play(anim)

func process_actions():
	if Input.is_action_pressed(str(id) + "_drop_bomb") and active_bombs.size() < bomb_quota:
		for bomb in collision_exceptions:
			if bomb.get_cell_pos() == self.get_cell_pos():
				return
		place_bomb()

func process_explosions():
	for trigger_bomb in level.exploding_bombs:
		for bomb in [trigger_bomb] + trigger_bomb.chained_bombs:
			if self.get_cell_pos() == bomb.get_cell_pos():
				self.die()
				return
			for cell_dict in bomb.flame_cells:
				if self.get_cell_pos() == cell_dict.pos:
					self.die()
					return

func process_gameover():
	if gameover.is_visible() and Input.is_action_pressed("ui_accept"):
		get_tree().change_scene_to(global.menu_scene)

func place_bomb():
	var bomb = global.bomb_scene.instance()
	level.bomb_manager.add_child(bomb)
	bomb.set_pos_and_update(level.tile_center_pos(self.get_pos()))
	bomb.player = self
	bomb.bomb_range = self.bomb_range
	for player in level.player_manager.get_children():
		if player.get_cell_pos() == bomb.get_cell_pos():
			player.add_collision_exception_with(bomb.get_node("StaticBody2D"))
			player.collision_exceptions.append(bomb)
	active_bombs.append(bomb)
	level.get_node("SamplePlayer").play("bombdrop")

func die():
	set_fixed_process(false)
	get_node("CharSprite").hide()
	get_node("ActionAnimations").play("death")
	level.play_sound("death")
	lives -= 1
	if lives == 0:
		for bomb in level.bomb_manager.get_children():
			bomb.player = null
		dead = true
		var players = level.player_manager.get_children()
		if players.size() == 2:
			var winner
			if self != players[0]:
				winner = 0
			else:
				winner = 1
			gameover.get_node("Label").set_text("Player " + str(players[winner].id) + " wins!")
			gameover.show()
	else:
		get_node("TimerRespawn").start()
func _on_TimerPowerup_timeout():
	if tmp_powerup == null:
		print("ERROR: empty tmp_powerup at end of timer")
		return

	if tmp_anim != null:
		get_node("StatusAnimations").get_animation(tmp_anim).set_loop(false)
		tmp_anim = null
	set(tmp_powerup, false)
	tmp_powerup = null

func _on_TimerRespawn_timeout():
	set_pos(level.map_to_world(global.PLAYER_DATA[id - 1].tile_pos))
	get_node("CharSprite").show()
	set_fixed_process(true)
	level.play_sound("respawn" + str(randi() % 2 + 1))
	for bomb in level.bomb_manager.get_children():
		add_collision_exception_with(bomb.get_node("StaticBody2D"))
	set_tmp_powerup("invincible", 3, "blink")

func _on_ActionAnimations_finished():
	if dead:
		self.queue_free()

func get_cell_pos():
	return level.world_to_map(self.get_pos())

func set_tmp_powerup(powerup_type, duration = 5, status_anim = null):
	if tmp_powerup != null:
		set(tmp_powerup, false)
	tmp_powerup = powerup_type
	set(tmp_powerup, true)
	get_node("TimerPowerup").set_wait_time(duration)
	get_node("TimerPowerup").start()

	if status_anim != null and status_anim != tmp_anim:
		if tmp_anim != null:
			get_node("StatusAnimations").stop(true)
		get_node("StatusAnimations").get_animation(status_anim).set_loop(true)
		get_node("StatusAnimations").play(status_anim)
		tmp_anim = status_anim
