extends Node

const TILE_SIZE = 32
const TILE_OFFSET = Vector2(0.5, 0.5)*TILE_SIZE
const MAX_BOMBS = 8 
const MAX_FLAMERANGE = 8 
const MAX_SPEED = 20
const COLLECTIBLE_RATE = 25 

const PLAYER_DATA = [ {'char': "goblin-blue", 'tile_pos': Vector2(1, 1)} ]
const INPUT_ACTIONS = ["move_up", "move_down", "move_left", "move_right", "drop_bomb"]

const menu_scene = preload("res://scenes/menu.tscn")
const world_scene = preload("res://scenes/world.tscn")
const level_scene = preload("res://scenes/level.tscn")
const player_scene = preload("res://scenes/player.tscn")
const bomb_scene = preload("res://scenes/bomb.tscn")
const collectible_scene = preload("res://scenes/collectible.tscn")

const player_script = preload("res://scripts/player.gd")
const collectible_script = preload("res://scripts/collectible.gd")

const settings_filename = "user://settings.cfg"

var width = 960 
var height = 832 
var fullscreen = false 

var music = true
var music_volume = 1
var sfx = true
var sfx_volume = 1

var nb_players = 1 
var nb_lives = 1 
var collectibles = { 'types': ["bomb_increase", "flame_increase", "speed_increase", "speed_decrease", "confusion", "life_increase", "kick_skill"],
                     'freq': [100, 100, 70, 50, 30, 5*nb_lives, 30] }
func _ready():
	randomize()
	load_config()
	OS.set_window_size(Vector2(width, height))
	OS.set_window_fullscreen(fullscreen)
	get_tree().connect("screen_resized", self, "save_screen_size")

	collectibles.sum_freq = 0
	for freq in collectibles.freq:
		collectibles.sum_freq += freq

func load_config():
	var config = ConfigFile.new()
	var err = config.load(settings_filename)
	if err:

		config.set_value("display", "width", width)
		config.set_value("display", "height", height)
		config.set_value("display", "fullscreen", fullscreen)

		config.set_value("audio", "music", music)
		config.set_value("audio", "music_volume", music_volume)
		config.set_value("audio", "sfx", sfx)
		config.set_value("audio", "sfx_volume", sfx_volume)
		
		config.set_value("gameplay", "nb_players", nb_players)
		config.set_value("gameplay", "nb_lives", nb_lives)

		var action_name
		for i in range(1, 5):
			for action in INPUT_ACTIONS:
				action_name = str(i) + "_" + action
				config.set_value("input", action_name, OS.get_scancode_string(InputMap.get_action_list(action_name)[0].scancode))

		config.save(settings_filename)
	else:
		set_from_cfg(config, "display", "width")
		set_from_cfg(config, "display", "height")
		set_from_cfg(config, "display", "fullscreen")

		set_from_cfg(config, "audio", "music")
		set_from_cfg(config, "audio", "music_volume")
		set_from_cfg(config, "audio", "sfx")
		set_from_cfg(config, "audio", "sfx_volume")

		set_from_cfg(config, "gameplay", "nb_players")
		set_from_cfg(config, "gameplay", "nb_lives")

		var scancode
		var event
		for action in config.get_section_keys("input"):
			scancode = OS.find_scancode_from_string(config.get_value("input", action))
			event = InputEvent()
			event.type = InputEvent.KEY
			event.scancode = scancode
			for old_event in InputMap.get_action_list(action):
				if old_event.type == InputEvent.KEY:
					InputMap.action_erase_event(action, old_event)
			InputMap.action_add_event(action, event)

func set_from_cfg(config, section, key):
	if config.has_section_key(section, key):
		set(key, config.get_value(section, key))
	else:
		print("Warning: '" + key + "' missing from '" + section + "' section in the config file, default value has been added.")
		save_to_config(section, key, get(key))

func save_to_config(section, key, value):
	var config = ConfigFile.new()
	var err = config.load(settings_filename)
	if err:
		print("Error code when loading config file: ", err)
	else:
		config.set_value(section, key, value)
		config.save(settings_filename)

func save_screen_size():
	var screen_size = OS.get_window_size()
	width = int(screen_size.x)
	height = int(screen_size.y)
	save_to_config("display", "width", width)
	save_to_config("display", "height", height)
