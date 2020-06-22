extends ItemList

onready var modal = get_node("../../../../../Popup")
onready var graph = get_node("../../GraphArea")
onready var conversations_list = get_node("../ConversationsList")

var old_name
var scenes = []
"""
	TO DO:
		1. Selecting scene fills the conversation list with conversations from that scene with conversation unselected
			Needed behaviours:
				Load scenes on startup to populate scenes_list - V
				Selecting item on a list populates conversations_list, clears the previous graph which forces
				you to chose conversation from the list/or selects firs available
		2. Save list of scenes with their conversations instead of just conversations
			Needed behaviours:
				Save scenes every time conversation graph is updated
		3. Load scenes and format conversations for them
		4. Propably some other stuff needs to be done but I can't think of anything at the moment
"""
func _ready():
	scenes = global.loadData()
	
	var count = 0
	if scenes != null:
		for scene in scenes:
			add_item(scene["name"])
			set_item_custom_fg_color(count, Color(scene["color"]))
			set_item_tooltip_enabled(count, true)
			set_item_tooltip(count, scene["description"])
			count += 1
	
	if scenes == null:
		scenes = []

func _on_Popup_button_pressed():
	#	adding new scene
	if modal.scene && !modal.editing:
		if global.is_entry_in_dictionary(scenes, modal.text_edit.text):
			pass
		else:
			#	add scene to list of dictionaries
			var scene = add_scene(modal.text_edit.text,
					modal.description.text,
					modal.color_button.color.to_html(),
					[])
			#	add scene to item list
			add_item(scene["name"])
			#	select added scene
			select(get_item_count() - 1)
			#	add data to selected item from the list of dictionaries
			var item_index = get_selected_items()[0]
			
			set_item_custom_fg_color(item_index, Color(scene["color"]))
			set_item_tooltip_enabled(item_index, true)
			set_item_tooltip(item_index, scene["description"])
			
			#hide popup
			modal.hide()
			
			
	elif modal.scene && modal.editing:
		#	update scene on the list
		var scene = update_scene(modal.text_edit.text, modal.description.text, modal.color_button.color.to_html())
		
		#	update nodes on graph
		#	update_nodes(scene)
		
		#	change data of selected item
		var item_index = get_selected_items()[0]
		
		set_item_text(item_index, scene["name"])
		set_item_custom_fg_color(item_index, Color(scene["color"]))
		set_item_tooltip_enabled(item_index, true)
		set_item_tooltip(item_index, scene["description"])
		
		#	hide popup
		modal.hide()
		modal.editing = false

func _on_RemoveScene_pressed():
	if is_anything_selected():
		var item_index = get_selected_items()[0]
		global.remove_dictionary_entry(scenes, get_item_text(item_index))
		conversations_list.clean_list()
		remove_item(item_index)

func _on_EditScene_pressed():
	if is_anything_selected():
		var item_index = get_selected_items()[0]
		modal.editing = true
		modal.scene = true
		var name = get_item_text(item_index)
		var description =  get_item_tooltip(item_index)
		var color = get_item_custom_fg_color(item_index)
		old_name = name
		modal.text_edit.text = name
		modal.description.text = description
		modal.color_button.color = color
		modal.popup_centered()

func add_scene(name, description, color, conversations):
	var scene = { "name" : name,
			"description" : description,
			"color" : color,
			"conversations": conversations}
			
	scenes.append(scene)
	return scene

func update_scene(name, description, color):
	var scene_index = scenes.find(global.get_dictionary_entry(scenes, old_name))
	var new_scene = {"name" : name,
			"description" : description,
			"color" : color}
			
	scenes[scene_index] = new_scene
	return new_scene

func _on_ScenesList_item_selected(index):
	var scene = global.get_dictionary_entry(scenes, get_item_text(index))
	conversations_list.clean_list()
	conversations_list.conversations = scene["conversations"]
	conversations_list.populate_list()
