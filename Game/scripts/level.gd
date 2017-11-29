extends Node2D

onready var map_manager = get_node("MapManager")
onready var player_manager = get_node("PlayerManager")
onready var bomb_manager = get_node("BombManager")
onready var collectible_manager = get_node("CollectibleManager")
onready var tilemap_destr = map_manager.get_node("Destructible")
onready var tilemap_indestr = map_manager.get_node("Indestructible")

var exploding_bombs = [] # Array of bombs that are currently exploding

func _ready():
	var player
	for i in range(global.nb_players):
		player = global.player_scene.instance()
		player.id = i+1
		player.char = global.PLAYER_DATA[i].char
		player.set_pos(map_to_world(global.PLAYER_DATA[i].tile_pos))
		player_manager.add_child(player)

	if global.music:
		get_node("StreamPlayer").play()
	get_node("StreamPlayer").set_volume(global.music_volume)
	get_node("SamplePlayer").set_default_volume(global.sfx_volume)

	set_process_input(true)

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to(global.menu_scene)

func map_to_world(map_pos):
	return tilemap_destr.map_to_world(map_pos) + global.TILE_OFFSET

func world_to_map(world_pos):
	return tilemap_destr.world_to_map(world_pos)

func tile_center_pos(absolute_pos):
	return map_to_world(world_to_map(absolute_pos))

func play_sound(sound):
	if global.sfx:
		get_node("SamplePlayer").play(sound)
