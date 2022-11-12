extends Node

enum Position{OTHER, ABOVE_HEAD, TOP_LEFT, TOP_RIGHT, HAT, FOREHEAD, EYES, NOSE, MOUTH, BACK, NECK, TORSO, POCKET_LEFT, POCKET_RIGHT, SKIN, TAIL, ACCESSORY_LEFT, ACCESSORY_RIGHT}
enum Priority{VERY_LOW, LOW, MEDIUM, HIGH, VERY_HIGH}

const herbloader_path = "user://herbloader"
const character_path = "user://herbloader/characters"

var new_characters = []

func _ready():
	var dir = Directory.new()
	var directory_exists = dir.dir_exists(herbloader_path)
	if not directory_exists:
		var err = dir.make_dir(herbloader_path)
		
		if err != OK:
			printerr("Could not create the directory %s. Error code: %s" % 
			[herbloader_path, err])
			return 
	directory_exists = dir.dir_exists(character_path)
	if not directory_exists:
		var err = dir.make_dir(character_path)
		
		if err != OK:
			printerr("Could not create the directory %s. Error code: %s" % 
			[character_path, err])
			return 
	for folder in list_files_in_directory(character_path):
		var character_data = CharacterData.new()
		character_data.starting_weapons = []
		character_data.item_appearances = []
		character_data.effects = []
		var character_folder = "user://herbloader/characters/" + folder
		character_data.my_id = "character_" + folder
		character_data.unlocked_by_default = true
		for file in list_files_in_directory("user://herbloader/characters/" + folder):
			match file:
				"character.json":
					var json_file = File.new()
					if json_file.file_exists(character_folder + "/character.json"):
						json_file.open(character_folder + "/character.json", File.READ)
						var content = json_file.get_as_text()
						var dictionary = parse_json(content)
						print(dictionary)
						json_file.close()
						character_data.name = dictionary.name
						for weapon in dictionary.starting_weapons:
							character_data.starting_weapons.append(add_weapon(weapon))
						var stats = dictionary.stats
						for stat in stats:
							if stats.get(stat) != 0:
								var new_effect = Effect.new()
								new_effect.key = "stat_" + str(stat)
								new_effect.value = stats.get(stat)
								character_data.effects.append(new_effect)
						var weapon_slots = dictionary.weapon_slots
						var new_replace_effect = ReplaceEffect.new()
						new_replace_effect.key = "weapon_slot"
						new_replace_effect.text_key = "EFFECT_MAX_WEAPONS"
						new_replace_effect.value = weapon_slots
						character_data.effects.append(new_replace_effect)
						var effects = dictionary.effects
						for effect in effects:
							var effect_dictionary = effects.get(effect)
							var new_effect = Effect.new()
							new_effect.key = effect_dictionary.get("key")
							new_effect.text_key = effect_dictionary.get("text_key")
							new_effect.value = effect_dictionary.get("value")
							new_effect.effect_sign = effect_dictionary.get("effect_sign")
							character_data.effects.append(new_effect)
				"icon.png":
					character_data.icon = load_image(character_folder + "/icon.png", 96, 96)
				"eyes.png":
					create_tem_appearance("eyes",Position.EYES,Priority.VERY_LOW,500,character_folder,character_data)
				"mouth.png":
					create_tem_appearance("mouth",Position.MOUTH,Priority.MEDIUM,550,character_folder,character_data)
				"hair.png":
					create_tem_appearance("hair",Position.HAT,Priority.VERY_LOW,1000,character_folder,character_data)
				"torso.png":
					create_tem_appearance("torso",Position.TORSO,Priority.VERY_LOW,320,character_folder,character_data)
				"nose.png":
					create_tem_appearance("nose",Position.NOSE,Priority.MEDIUM,550,character_folder,character_data)
		if character_data.starting_weapons != []:
			ItemService.characters.append(character_data)

func add_weapon(weapon):
	var melee_weapons = list_files_in_directory("res://weapons/melee/")
	var ranged_weapons = list_files_in_directory("res://weapons/ranged/")
	if ranged_weapons.find(weapon) != - 1:
		var weapon_load = null
		var tier = 0
		while weapon_load == null:
			tier += 1
			var extra = ""
			if tier != 1:
				extra = "_" + str(tier)
			weapon_load = load("res://weapons/ranged/" + weapon + "/" + str(tier) + "/" + weapon + extra + "_data.tres")
		print(weapon_load)
		return weapon_load
	elif melee_weapons.find(weapon) != - 1:
		var weapon_load = null
		var tier = 0
		while weapon_load == null:
			tier += 1
			var extra = ""
			if tier != 1:
				extra = "_" + str(tier)
			weapon_load = load("res://weapons/melee/" + weapon + "/" + str(tier) + "/" + weapon + extra + "_data.tres")
		return weapon_load

func create_tem_appearance(item_name,pos,prio,depth,character_folder,character_data):
	var item = ItemAppearanceData.new()
	item.sprite = load_image(character_folder + "/"+ item_name +".png", 150, 150)
	item.position = pos
	item.display_priority = prio
	item.depth = depth
	character_data.item_appearances.append(item)

func load_image(path, x = 0, y = 0):
	var image = Image.new()
	image.load(path)
	if x > 0 and y > 0:
		image.resize(x, y)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files
