extends Node2D

const dir = { "up": Vector2(0, -1),
              "down": Vector2(0, 1),
              "left": Vector2(-1, 0),
              "right": Vector2(1, 0) }
const FLAME_SOURCE = 8
const FLAME_SMALL = 9
const FLAME_LONG_MIDDLE = 10
const FLAME_LONG_END = 11
const SLIDE_SPEED = 8


onready var level = get_node("/root/World/Level")
var player

var cell_pos = Vector2() 
var bomb_range 
var counter = 1 

var exploding = false 
var chained_bombs = [] 
var anim_ranges = {} 
var flame_cells = [] 
var destruct_cells = []
var indestruct_cells = [] 

var slide_dir = Vector2() 
var target_cell = Vector2() 

func _fixed_process(delta):
	var new_pos = get_pos() + slide_dir*SLIDE_SPEED*0.5*global.TILE_SIZE*delta

	if slide_dir.dot(level.map_to_world(target_cell) - new_pos) < 0:
		set_pos_and_update(level.map_to_world(target_cell))


		var space_state = level.get_world_2d().get_direct_space_state()
		var raycast = space_state.intersect_ray(level.map_to_world(get_cell_pos()), level.map_to_world(get_cell_pos() + slide_dir), [ get_node("StaticBody2D") ])

		if raycast.empty():
			target_cell = get_cell_pos() + slide_dir
		else:
			set_fixed_process(false)
			return
	else:
		set_pos(new_pos)


	for trigger_bomb in level.exploding_bombs:
		for bomb in [trigger_bomb] + trigger_bomb.chained_bombs:
			for cell_dict in bomb.flame_cells:
				if self.get_cell_pos() == cell_dict.pos:
					get_node("AnimatedSprite/TimerIdle").stop()
					get_node("AnimatedSprite/AnimationPlayer").stop()
					trigger_explosion()
					return

func _on_TimerIdle_timeout():
	self.get_node("AnimatedSprite/AnimationPlayer").play("countdown")

func _on_TimerAnim_timeout():
	if counter < 5:
		update_animation()
		counter += 1
		get_node("AnimatedSprite/TimerAnim").start()
	else:
		stop_animation()
		level.exploding_bombs.erase(self)
		for bomb in self.chained_bombs:
			if bomb.player != null:
				bomb.player.collision_exceptions.erase(bomb)
			bomb.queue_free()
		if self.player != null:
			self.player.collision_exceptions.erase(self)
		self.queue_free()

func push_dir(direction):
	var space_state = level.get_world_2d().get_direct_space_state()
	var raycast = space_state.intersect_ray(level.map_to_world(get_cell_pos()), level.map_to_world(get_cell_pos() + direction), [ get_node("StaticBody2D") ])

	if raycast.empty():
		slide_dir = direction
		target_cell = get_cell_pos() + slide_dir
		set_fixed_process(true)
		level.play_sound("push" + str(randi() % 2 + 1))

func find_chain_and_collisions(trigger_bomb, exceptions = []):
	var space_state = level.get_world_2d().get_direct_space_state()
	if exceptions.empty():
		exceptions.append(trigger_bomb.get_node("StaticBody2D"))
		exceptions += level.player_manager.get_children()
	var new_bombs = []

	for key in dir:
		var raycast = space_state.intersect_ray(self.get_pos(), self.get_pos() + dir[key]*self.bomb_range*global.TILE_SIZE, exceptions, 2147483647, 31)

		while (!raycast.empty() and raycast.collider.get_parent() in level.bomb_manager.get_children()):
			var bomb_found = raycast.collider.get_parent()
			if not bomb_found.exploding:
				trigger_bomb.chained_bombs.append(bomb_found)
				new_bombs.append(bomb_found)
				bomb_found.get_node("AnimatedSprite/TimerIdle").stop()
				bomb_found.get_node("AnimatedSprite/AnimationPlayer").stop()
			exceptions.append(raycast.collider)
			raycast = space_state.intersect_ray(self.get_pos(), self.get_pos() + dir[key]*self.bomb_range*global.TILE_SIZE, exceptions, 2147483647, 15)

		if raycast.empty():
			self.anim_ranges[key] = self.bomb_range
		else:
			var target_cell_pos = level.world_to_map(raycast.position + dir[key]*global.TILE_SIZE*0.5)
			var distance_rel = target_cell_pos - get_cell_pos()
			self.anim_ranges[key] = dir[key].x*distance_rel.x + dir[key].y*distance_rel.y - 1

			if target_cell_pos in trigger_bomb.destruct_cells or target_cell_pos in trigger_bomb.indestruct_cells:
				continue

			if raycast.collider == level.tilemap_destr:
				trigger_bomb.destruct_cells.append(target_cell_pos)
			elif raycast.collider == level.tilemap_indestr:
				trigger_bomb.indestruct_cells.append(target_cell_pos)
			elif raycast.collider extends global.collectible_script:
				raycast.collider.destroy()
			else:
				print("Warning: Unexpected collision with '", raycast.collider, "' for the bomb explosion.")
	for bomb in new_bombs:
		bomb.find_chain_and_collisions(trigger_bomb, exceptions)

func trigger_explosion():
	set_fixed_process(false)
	find_chain_and_collisions(self)
	for bomb in self.chained_bombs + [self]:
		if bomb.player != null:
			bomb.player.active_bombs.erase(bomb)
		for any_player in level.player_manager.get_children():
			if bomb in any_player.collision_exceptions:
				any_player.remove_collision_exception_with(self.get_node("StaticBody2D"))
				any_player.collision_exceptions.erase(bomb)
	level.exploding_bombs.append(self)
	start_animation()

func start_animation():
	for bomb in [self] + self.chained_bombs:
		for key in dir:
			if bomb.anim_ranges[key] != 0:
				var xflip = dir[key].x > 0
				var yflip = dir[key].x + dir[key].y > 0
				var transpose = dir[key].y != 0
				if bomb.anim_ranges[key] == 1:
					var pos = bomb.get_cell_pos() + dir[key]
					bomb.flame_cells.append({'pos': pos, 'tile': FLAME_SMALL, 'xflip': xflip, 'yflip': yflip, 'transpose': transpose})
					level.tilemap_destr.set_cell(pos.x, pos.y, FLAME_SMALL, xflip, yflip, transpose)
				else:
					for i in range(1, bomb.anim_ranges[key] + 1):
						var pos = bomb.get_cell_pos() + i*dir[key]
						var tile_index
						if i == bomb.anim_ranges[key]:
							tile_index = FLAME_LONG_END
						else:
							tile_index = FLAME_LONG_MIDDLE
						bomb.flame_cells.append({'pos': pos, 'tile': tile_index, 'xflip': xflip, 'yflip': yflip, 'transpose': transpose})
						level.tilemap_destr.set_cell(pos.x, pos.y, tile_index, xflip, yflip, transpose)

	for pos in self.destruct_cells:
		level.tilemap_destr.set_cell(pos.x, pos.y, level.tilemap_destr.get_cell(pos.x, pos.y) + 1)
	for bomb in [self] + self.chained_bombs:
		bomb.get_node("AnimatedSprite").hide()
		bomb.exploding = true
		level.tilemap_destr.set_cell(bomb.get_cell_pos().x, bomb.get_cell_pos().y, FLAME_SOURCE)

	level.play_sound("explosion" + str(randi() % 2 + 1))

	self.get_node("AnimatedSprite/TimerAnim").start()

func update_animation():
	var index = 4*(self.counter % 3)

	for bomb in [self] + self.chained_bombs:
		for cell_dict in bomb.flame_cells:
			level.tilemap_destr.set_cell(cell_dict.pos.x, cell_dict.pos.y, cell_dict.tile + index, cell_dict.xflip, cell_dict.yflip, cell_dict.transpose)

	for bomb in [self] + self.chained_bombs:
		level.tilemap_destr.set_cell(bomb.get_cell_pos().x, bomb.get_cell_pos().y, FLAME_SOURCE + index)

func stop_animation():
	for bomb in [self] + self.chained_bombs:
		for cell_dict in bomb.flame_cells:
			level.tilemap_destr.set_cell(cell_dict.pos.x, cell_dict.pos.y, -1)
		level.tilemap_destr.set_cell(bomb.get_cell_pos().x, bomb.get_cell_pos().y, -1)

		for pos in bomb.destruct_cells:
			if randi() % 100 < global.COLLECTIBLE_RATE:
				var collectible = global.collectible_scene.instance()
				var index = randi() % global.collectibles.sum_freq
				var sum = global.collectibles.freq[0]
				for i in range(global.collectibles.types.size()):
					if index <= sum:
						index = i
						break
					sum += global.collectibles.freq[i + 1]
				collectible.effect = global.collectibles.types[index]
				collectible.set_pos(level.map_to_world(pos))
				level.collectible_manager.add_child(collectible)
			level.tilemap_destr.set_cell(pos.x, pos.y, -1)

func get_cell_pos():
	return cell_pos

func update_cell_pos():
	cell_pos = level.world_to_map(self.get_pos())

func set_pos_and_update(abs_pos):
	set_pos(abs_pos)
	update_cell_pos()