extends Node

const DIALOGUE_PATH = "res://dialogues.json"
const DIALOGUE_EXPORT_PATH = "res://dialogues_export.json"

var node_style_settings = { 
		"bg_color" : Color(0, 0, 0, 1),
		"border_width_left" : 6,
		"border_width_top" : 30,
		"border_width_right" : 6,
		"border_width_bottom" : 2,
		"shadow_color" : Color("#99ffffff"),
		"content_margin_left" : 8,
		"content_margin_right" : 8,
		"content_margin_top" : 32,
		"content_margin_bottom" : 4
		}

func is_entry_in_c_dictionary(list, cathegory, name):
	if list != null:
		for entry in list:
			if entry[cathegory] == name:
				return true
		return false

func get_dictionary_c_entry(list, cathegory, name):
	for entry in list:
		if entry[cathegory] == name:
			return entry
	return -1

func is_entry_in_dictionary(list, name):
	if list != null:
		for entry in list:
			if entry["name"] == name:
				return true
		return false

func get_dictionary_entry(list, name):
	for entry in list:
		if entry["name"] == name:
			return entry
	return -1

func remove_dictionary_entry(list, name):
	for entry in list:
		if entry["name"] == name:
			list.erase(entry)
	return list

func default_style_node():
	var node_style = StyleBoxFlat.new()
	
	for setting in node_style_settings:
		node_style.set(setting, node_style_settings[setting])
	
	return node_style

func configure_textedit(text_area, ysize):
	text_area.set_custom_minimum_size(Vector2( 0, ysize))
	text_area.set("wrap_enabled", true)
	text_area.set("context_menu_enabled", true)

static func getRandomInt(value):
	randomize()
	
	return randi() % value

static func randomBytes(n):
	var r = []
	
	for index in range (0, n):
		r.append(getRandomInt(256))
		
	return r

static func uuidbin():
	var b = randomBytes(16)
	
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return b

static func v4():
	var b = uuidbin()
	
	var low = '%02x%02x%02x%02x' % [b[0], b[1], b[2], b[3]]
	var mid = '%02x%02x' % [b[4], b[5]]
	var hi = '%02x%02x' % [b[6], b[7]]
	var clock = '%02x%02x' % [b[8], b[9]]
	var node = '%02x%02x%02x%02x%02x%02x' % [b[10], b[11], b[12], b[13], b[14], b[15]]
	
	return '%s-%s-%s-%s-%s' % [low, mid, hi, clock, node]

func exportData(scenes, path = DIALOGUE_EXPORT_PATH):
	var dir = Directory.new()
	
	if dir.file_exists(path):
		dir.remove(path)
		
	var save_dict = {}
	save_dict["Scenes"] = formatExportData(scenes)
	
	var save_file = File.new()
	save_file.open(path, File.WRITE)
	
	for item in save_dict:
		save_file.store_line(to_json(save_dict[item]))
	
	save_file.close()
	pass

func formatExportData(scenes):
	var exportScenes : Array
	"""
	After export:
	scenes:
	[{
		name:string,
		conversations: 
		[{
			name:string,
			dialogue:
			[{
				actor_name: string,
				data: 
				[{
					text:string,
					nextID:string
				}]
				type: string
			}]
		}]
	}]
	"""
	print("Exporting data...")
	for scene in scenes:
		var tempScene : Dictionary
		var tempConversation : Array
		print("\nProcessing Scene: ", scene["name"])
		tempScene["name"] = scene["name"]
		for conversation in scene["conversations"]:
			print("Processing Conversation: ", conversation["name"])
			var convers : Dictionary
			convers["name"] = conversation["name"]
			
			var startingNode
			var lastNodes
			var order = 0
			var dialogues : Array
			
			#find first node
			var tempNodes = conversation["nodes"].duplicate(true)
			for connection in conversation["connections"]:
				for i in range(0, len(conversation["nodes"])):
					if is_entry_in_dictionary(tempNodes, connection["to"]):
						tempNodes = remove_dictionary_entry(tempNodes, connection["to"])
			startingNode = tempNodes[0]
			#find last node
			tempNodes = conversation["nodes"].duplicate(true)
			for connection in conversation["connections"]:
				for i in range(0, len(conversation["nodes"])):
					if is_entry_in_dictionary(tempNodes, connection["from"]):
						tempNodes = remove_dictionary_entry(tempNodes, connection["from"])
			lastNodes = tempNodes
			#build dialogue tree
			for i in range(0, len(conversation["connections"]) - 1):
				if startingNode != null:
					if i == 0:
						var nextID : Array
						var text = startingNode["data"]
						var dialogue = {}
						
						for connection in conversation["connections"]:
							if connection["from"] == startingNode["name"]:
								nextID.append(connection["to"])
						var nodeData = {"text" : text, "nextID" : nextID}
						print("\n Processing node:")
						print("Actor name: ", startingNode["actor_name"])
						print("Text: ", text)
						dialogue["actor_name"] = startingNode["actor_name"]
						dialogue["data"] = nodeData
						dialogue["type"] = startingNode["type"]
						dialogue["ID"] = startingNode["name"]
						dialogues.append(dialogue)
						print("Node Finished")
					else:
						var nextID : Array
						var text
						var nodeData = {}
						var dialogue = {}
						
						for data in dialogues[i - 1]["data"]["nextID"]:
							if is_entry_in_c_dictionary(conversation["connections"], "from", data):
								for node in conversation["nodes"]:
									if node["name"] == data:
										print("\n Processing node:")
										print("Actor name: ", node["actor_name"])
										print("Text: ", node["data"])
										dialogue["actor_name"] = node["actor_name"]
										dialogue["type"] = node["type"]
										text = node["data"]
										dialogue["ID"] = node["name"]
								for connection in conversation["connections"]:
									if connection["from"] == data:
										nextID.append(connection["to"])
								nodeData = {"text" : text, "nextID": nextID}
								dialogue["data"] = nodeData
								dialogues.append(dialogue)
								print("Node Finished")
			if lastNodes != null:
				for node in lastNodes:
					var nextID : Array
					var text = node["data"]
					var dialogue = {}
					var nodeData = {"text" : text, "nextID" : nextID}
					print("\n Processing node:")
					print("Actor name: ", node["actor_name"])
					print("Text: ", text)
					dialogue["actor_name"] = node["actor_name"]
					dialogue["data"] = nodeData
					dialogue["type"] = node["type"]
					dialogue["ID"] = node["name"]
					dialogues.append(dialogue)
					print("Node Finished")
				
			convers["dialogue"] = dialogues
			tempConversation.append(convers)
			tempScene["conversations"] = tempConversation
			print("\nConversation " + conversation["name"] + " Finished")
		exportScenes.append(tempScene)
		print("Scene " + scene["name"] + " Finished")
	print("Export finished...")
	return exportScenes

func saveData(scenes, actors, path = DIALOGUE_PATH):
	var dir = Directory.new()
	
	if dir.file_exists(path):
		dir.remove(path)
		
	var save_dict = {}
	save_dict["Scenes"] = scenes
	save_dict["Actors"] = actors
	
	
	var save_file = File.new()
	save_file.open(path, File.WRITE)
	
	for item in save_dict:
		save_file.store_line(to_json(save_dict[item]))
	
	save_file.close()
	pass

func loadData(pick = true, path = DIALOGUE_PATH):
	var dir = Directory.new()
	var actors = null
	var scenes = null
	
	if dir.file_exists(path):
		var file = File.new()
		file.open(path, file.READ)
		
		var temp_scenes = file.get_line()
		var temp_actors = file.get_line()
		
		scenes = parse_json(temp_scenes)
		actors = parse_json(temp_actors)
		
		file.close()
	
		if pick:
			for scene in scenes:
				for conversation in scene["conversations"]:
					for node in conversation["nodes"]:
						node["offset"] = node["offset"].replace('(', '')
						node["offset"] = node["offset"].replace(')', '')
						node["offset"] = node["offset"].strip_edges(true, true)
						node["offset"] = node["offset"].split(',')
						var vector = Vector2(int(node["offset"][0]), int(node["offset"][1]))
						node["offset"] = vector
			return scenes
		else:
			return actors
