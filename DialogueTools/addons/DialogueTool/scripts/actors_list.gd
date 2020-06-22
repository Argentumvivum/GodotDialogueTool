extends ItemList

onready var modal = get_node("../../../../../Popup")
onready var graph = get_node("../../GraphArea")
onready var conversations_list = get_node("../ConversationsList")

var old_name
var actors = []

"""
	_on_Popup_button_pressed()				- adds actor to list of actors
	_on_RemoveActor_pressed()				- removes the selected actor from the list of actors
	_on_EditActor_pressed()					- shows popup for editing of actor from the list
	add_actor()								- appends actors[] with new actor
	update_actor()							- updates data of a chosen actor
	update_nodes()							- updates nodes in conversations[] and on graph
"""

func _ready():
	actors = global.loadData(false)
	
	var count = 0
	if actors != null:
		for actor in actors:
			add_item(actor["name"])
			set_item_custom_fg_color(count, Color(actor["color"]))
			set_item_tooltip_enabled(count, true)
			set_item_tooltip(count, actor["description"])
			count += 1
	
	if actors == null:
		actors = []

func _on_Popup_button_pressed():
	if modal.actor && !modal.editing:
		if global.is_entry_in_dictionary(actors, modal.text_edit.text):
			pass
		else:
			#	add actor to list of dictionaries
			var actor = add_actor(modal.text_edit.text, modal.description.text, modal.color_button.color.to_html())
			#	add actor to item list
			add_item(actor["name"])
			#	select added actor
			select(get_item_count() - 1)
			#	add data to selected item from the list of dictionaries
			var item_index = get_selected_items()[0]
			
			set_item_custom_fg_color(item_index, Color(actor["color"]))
			set_item_tooltip_enabled(item_index, true)
			set_item_tooltip(item_index, actor["description"])
			
			#	hide popup
			modal.hide()
		
		
	elif modal.actor && modal.editing:
		#	update actor on the list
		var actor = update_actor(modal.text_edit.text, modal.description.text, modal.color_button.color.to_html())
		
		#	update nodes on graph
		update_nodes(actor)
		
		#	change data of a selected item
		var item_index = get_selected_items()[0]
		
		set_item_text(item_index, actor["name"])
		set_item_custom_fg_color(item_index, Color(actor["color"]))
		set_item_tooltip_enabled(item_index, true)
		set_item_tooltip(item_index, actor["description"])
		
		#	hide popup
		modal.hide()
		modal.editing = false

func _on_RemoveActor_pressed():
	if is_anything_selected():
		var item_index = get_selected_items()[0]
		global.remove_dictionary_entry(actors, get_item_text(item_index))
		remove_item(item_index)

func _on_EditActor_pressed():
	if is_anything_selected():
		var item_index = get_selected_items()[0]
		modal.editing = true
		modal.actor = true
		var name = get_item_text(item_index)
		var description =  get_item_tooltip(item_index)
		var color = get_item_custom_fg_color(item_index)
		old_name = name
		modal.text_edit.text = name
		modal.description.text = description
		modal.color_button.color = color
		modal.popup_centered()

func add_actor(name, description, color):
	var actor = { "name" : name,
			"description" : description,
			"color" : color}
			
	actors.append(actor)
	return actor

func update_actor(name, description, color):
	var actor_index = actors.find(global.get_dictionary_entry(actors, old_name))
	var new_actor = {"name" : name,
			"description" : description,
			"color" : color}
			
	actors[actor_index] = new_actor
	return new_actor

func update_nodes(actor):
	var connections = graph.get_connection_list()
	var conversation_index = conversations_list.get_selected_items()[0]
	var conversation_name = conversations_list.get_item_text(conversation_index)
	var conversation_current = global.get_dictionary_entry(conversations_list.conversations, conversation_name)
	
	for connection in graph.get_connection_list():
		if old_name in connection["from"] || old_name in connection["to"]:
			graph.disconnect_node(connection["from"], connection["from_port"], connection["to"], connection["to_port"])
	
	for node in graph.get_children():
		if old_name in node.name:
			node.title = node.title.replace(old_name, actor["name"])
			node.name = node.name.replace(old_name, actor["name"])
			var frame = node.get("custom_styles/frame")
			var selected = node.get("custom_styles/selectedframe")
			frame.border_color = Color(actor["color"])
			selected.border_color = Color(actor["color"])
			var count = 0
			while count < node.get_child_count():
				node.set_slot(count,
						node.is_slot_enabled_left(count),
						node.get_slot_type_left(count),
						Color(1, 1, 1, 1),
						node.is_slot_enabled_right(count),
						node.get_slot_type_right(count),
						Color(actor["color"]))
				count += 1
	
	for conversation in conversations_list.conversations:
		for node in conversation["nodes"]:
			if old_name in node["name"]:
				node["name"] = node["name"].replace(old_name, actor["name"])
				node["color"] = actor["color"]
				node["actor_name"] = actor["name"]
	
		for connection in conversation["connections"]:
			for item in connection:
				if old_name in String(connection[item]):
					connection[item] = connection[item].replace(old_name, actor["name"])
	
	for connection in conversation_current["connections"]:
		graph.connect_node(connection["from"], 
				connection["from_port"], 
				connection["to"], 
				connection["to_port"])
	
	#conversation_current["connections"] = graph.get_connection_list()
