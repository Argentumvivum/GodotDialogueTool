extends ItemList

onready var modal = get_node("../../../../../Popup")
onready var graph = get_node("../../GraphArea")
onready var scenes_list = get_node("../ScenesList")

var old_name
var conversations = []

"""
	_on_Popup_button_pressed() 				- adds conversation to list of conversations
	_on_RemoveConversation_pressed() 		- removes the selected conversation from the list of conversations
	_on_EditConversation_pressed() 			- shows popup for editing of conversation from the list
	add_conversation() 						- appends conversations[] with new conversation
	update_conversation() 					- updates data of a chosen conversation
	_on_ConversationsList_item_selected()	- manages changing of selection on conversation list
	clean_list()							- removes all items from list
	populate_list()							- populates list of conversations  with items from conversations[]
	clean_graph()							- removes connections and nodes from the GraphArea
	populate_graph()						- adds existing items to GraphArea from conversation
	get_node_style()						- used to set node style
	build_node() 							- builds node from data provided
"""
func _on_Popup_button_pressed():
	#	adding new conversation
	if modal.conversation && !modal.editing:
		if global.is_entry_in_dictionary(conversations, modal.text_edit.text):
			pass
		else:
			var conversation = add_conversation(modal.text_edit.text, 
					modal.description.text, 
					modal.color_button.color.to_html(), 
					[], 
					[])
			add_item(modal.text_edit.text)
			select(get_item_count() - 1)
			var item_index = get_selected_items()[0]
			
			set_item_custom_fg_color(item_index, Color(conversation["color"]))
			set_item_tooltip_enabled(item_index, true)
			set_item_tooltip(item_index, conversation["description"])
			
			clean_graph()
			modal.hide()
	
	#	editing the existing conversation
	elif modal.conversation && modal.editing:
		var conversation = update_conversation(modal.text_edit.text, 
				modal.description.text, 
				modal.color_button.color.to_html())
		
		var item_index = get_selected_items()[0]
		
		set_item_text(item_index, conversation["name"])
		set_item_custom_fg_color(item_index, Color(conversation["color"]))
		set_item_tooltip_enabled(item_index, true)
		set_item_tooltip(item_index, conversation["description"])
		
		modal.hide()
		modal.editing = false

func _on_RemoveConversation_pressed():
	if is_anything_selected():
		var item_index = get_selected_items()[0]
		global.remove_dictionary_entry(conversations, get_item_text(item_index))
		remove_item(item_index)

func _on_EditConversation_pressed():
	if is_anything_selected():
		modal.editing = true
		modal.conversation = true
		var name = get_item_text(get_selected_items()[0])
		var description =  get_item_tooltip(get_selected_items()[0])
		var color = get_item_custom_fg_color(get_selected_items()[0])
		old_name = name
		modal.text_edit.text = name
		modal.description.text = description
		modal.color_button.color = color
		modal.popup_centered()

func add_conversation(name, description, color, nodes, connections):
	var conversation = { "name" : name,
			"description" : description,
			"color" : color,
			"nodes" : nodes,
			"connections" : connections}
	
	conversations.append(conversation)
	return conversation

func update_conversation(name, description, color):
	var conversation_index = conversations.find(global.get_dictionary_entry(conversations, old_name))
	var new_conversation = { "name" : name,
			"description" : description,
			"color" : color,
			"nodes" : conversations[conversation_index]["nodes"],
			"connections" : conversations[conversation_index]["connections"]}
	
	conversations[conversation_index] = new_conversation
	return new_conversation

func _on_ConversationsList_item_selected(index):
	clean_graph()
	
	var conversation = global.get_dictionary_entry(conversations, get_item_text(index))
	populate_graph(conversation)

func clean_list():
	clean_graph()
	unselect_all()
	clear()

func populate_list():
	var count = 0
	if conversations != null:
		for conversation in conversations:
			add_item(conversation["name"])
			set_item_custom_fg_color(count, Color(conversation["color"]))
			set_item_tooltip_enabled(count, true)
			set_item_tooltip(count, conversation["description"])
			count += 1
	
	if conversations == null:
		conversations = []

func clean_graph():
	
	var connections = graph.get_connection_list()
	for connection in connections:
		graph.disconnect_node(connection["from"], 
				connection["from_port"], 
				connection["to"], 
				connection["to_port"])
	
	for child in graph.get_children():
		if child is GraphNode:
			child.queue_free()

func populate_graph(conversation):
	
	for node in conversation["nodes"]:
		var graph_node = graph.Graph_Node.instance()
		
		graph_node.offset = node["offset"]
		graph_node.title = node["actor_name"]
		graph_node.name = node["name"]
		
		graph_node.set("custom_styles/frame", get_node_style(false, node["color"]))
		graph_node.set("custom_styles/selectedframe", get_node_style(true, node["color"]))
		
		build_node(graph_node, node["color"], node["type"], node["data"], node["choice_count"])
		
		graph.add_child(graph_node)
	
	for connection in conversation["connections"]:
		graph.connect_node(connection["from"], 
				connection["from_port"], 
				connection["to"], 
				connection["to_port"])
"""
	"name" : node_name,
	"actor_name" : actor_name,
	"color" : color,
	"offset" : Vector2(x, y),
	"type" : node_type,
	"choice_count": choice_count,
	"data" : []
"""
func get_node_style(is_selected, node_color):
	var node_style = global.default_style_node()
	
	node_style.border_color = Color(node_color)
	node_style.set_corner_radius_all(5)
	
	if is_selected:
		node_style.shadow_size = 5
	else:
		node_style.shadow_size = 0
	
	return node_style

func _save_node_data():
	graph.save_node_data()

func build_node(node, node_color, node_type, node_data, choice_count = 2):
	
	if node_type == "normal":
		var text_area = TextEdit.new()
		text_area.connect("text_changed", self, "_save_node_data")
		
		if len(node_data) > 0:
			text_area.text = node_data[0]
		
		global.configure_textedit(text_area, 80)
		node.title += " - Normal Node"
		node.add_child(text_area)
	
		node.set_slot(0,
				true, 0,
				Color(1, 1, 1, 1),
				true, 0,
				Color(node_color))
	
	elif node_type == "choice":
		var count = 0
		
		while count < choice_count:
			var text_area = TextEdit.new()
			var separator = HSeparator.new()
			text_area.connect("text_changed", self, "save_node_data")
			
			if len(node_data) > 0:
				text_area.text = node_data[count]
			
			global.configure_textedit(text_area, 40)
			if count < choice_count - 1:
				node.add_child(text_area)
				node.add_child(separator)
			else:
				node.add_child(text_area)
			
			if (count * 2) % 2 == 0:
				node.set_slot(count * 2,
						false, 0,
						Color(1, 1, 1, 1),
						true, 0,
						Color(node_color))
			
			if count == choice_count - 1:
				if count % 2 == 0:
					node.set_slot(count,
							true, 0,
							Color(1, 1, 1, 1),
							true, 0,
							Color(node_color))
				else:
					node.set_slot(count,
							true, 0,
							Color(1, 1, 1, 1),
							false, 0,
							Color(node_color))
			
			count += 1
		
		node.title += " - Choice Node"
	
	elif node_type == "animation":
		var dropdown = OptionButton.new()
		
		dropdown.set_text_align(Button.ALIGN_CENTER)
		#	add data to dropdown
		node.title += " - Animation Node"
		node.add_child(dropdown)
		
		node.set_slot(0,
			true, 0,
			Color(1, 1, 1, 1),
			true, 0,
			Color(node_color))
