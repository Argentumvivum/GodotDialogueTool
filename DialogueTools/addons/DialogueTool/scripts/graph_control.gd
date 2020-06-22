extends GraphEdit

const Graph_Node = preload("res://addons/DialogueTool/scenes/graph_node.tscn")
onready var node_modal = get_node("../../../../NodePopup")
onready var conversations_list = get_node("../ListsContainer/ConversationsList")
onready var actors_list = get_node("../ListsContainer/ActorsList")
onready var scenes_list = get_node("../ListsContainer/ScenesList")

var initial_position = Vector2(40, 40)
var node_modal_add_button = null
var node_modal_cancel_button = null
#var timer = null

func _ready():
	node_modal_add_button = node_modal.find_node("Accept")
	node_modal_add_button.connect("pressed", self, "_node_modal_add_button_pressed")
	node_modal_cancel_button = node_modal.find_node("Cancel")
	node_modal_cancel_button.connect("pressed", self, "_node_modal_cancel_button_pressed")
	get_tree().set_auto_accept_quit(false)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_everything()
		get_tree().quit()

func _node_modal_add_button_pressed():
	var node = Graph_Node.instance()
	var conversation_index = conversations_list.get_selected_items()[0]
	var actor_index = actors_list.get_selected_items()[0]
	
	configure_node(conversation_index, actor_index, node)
	
	add_child(node, true)
	
	var type = pick_node_type(node, actor_index)
	var conversation = global.get_dictionary_entry(conversations_list.conversations, 
			conversations_list.get_item_text(conversation_index))
	var children = []
	
	for child in get_children():
		if child is GraphNode:
			children.append(child)
			
	var choice_count = int(node_modal.find_node("ChoicesNumber").get_line_edit().text)
	
	add_node_to_conversation(conversation, 
			children[len(children) - 1].name,
			actors_list.get_item_text(actor_index),
			actors_list.get_item_custom_fg_color(actor_index).to_html(), 
			node.offset.x, 
			node.offset.y,
			choice_count,
			type)
	
	node_modal.hide()

func add_node_to_conversation(conversation, node_name, actor_name, color, x, y, choice_count, node_type):
	var data = []
	
	if node_type == "choice":
		var count = 0
		while count < choice_count:
			data.append("")
			count += 1
	
	if node_type == "normal":
		data.append("")
	
	conversation["nodes"].append({ "name" : node_name,
			"actor_name" : actor_name,
			"color" : color,
			"offset" : Vector2(x, y),
			"type" : node_type,
			"choice_count": choice_count,
			"data" : data})
	
func _node_modal_cancel_button_pressed():
	node_modal.hide()

func _on_AddNode_pressed():
	if actors_list.is_anything_selected() && conversations_list.is_anything_selected():
		var actor_index = actors_list.get_selected_items()[0]
		#set defult settings
		node_modal.find_node("ActorName").text = actors_list.get_item_text(actor_index)
		node_modal.find_node("ActorColor").color = actors_list.get_item_custom_fg_color(actor_index)
		node_modal.find_node("ColorCode").text = "#" + actors_list.get_item_custom_fg_color(actor_index).to_html(false)
		node_modal.find_node("ChoiceButton").pressed = false
		node_modal.find_node("AnimationButton").pressed = false
		#show modal
		node_modal.popup_centered()

func _on_SaveConversation_pressed():
	save_everything()

func save_everything():
	global.saveData(scenes_list.scenes, actors_list.actors)
	pass

func _on_GraphArea_connection_request(from, from_slot, to, to_slot):
	connect_node(from, from_slot, to, to_slot)
	var conversation_index = conversations_list.get_selected_items()[0]
	var conversation = global.get_dictionary_entry(conversations_list.conversations, 
			conversations_list.get_item_text(conversation_index))
	
	conversation["connections"] = get_connection_list()

func _on_GraphArea_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	var conversation_index = conversations_list.get_selected_items()[0]
	var conversation = global.get_dictionary_entry(conversations_list.conversations, 
			conversations_list.get_item_text(conversation_index))
	
	conversation["connections"] = get_connection_list()

func configure_node(conversation_index, actor_index, node):
	var conversation_name = conversations_list.get_item_text(conversation_index)
	var conversation = global.get_dictionary_entry(conversations_list.conversations, conversation_name)
	
	node.offset += initial_position + (len(conversation["nodes"]) * Vector2(20, 20))
	node.title = actors_list.get_item_text(actor_index)
	node.name = actors_list.get_item_text(actor_index) + "_" + global.v4()
	
	node.set("custom_styles/frame", set_node_style(false, actor_index))
	node.set("custom_styles/selectedframe", set_node_style(true, actor_index))

func set_node_style(selected, actor_index):
	var node_style = global.default_style_node()
	
	node_style.border_color = actors_list.get_item_custom_fg_color(actor_index)
	node_style.set_corner_radius_all(5)
	
	if selected:
		node_style.shadow_size = 5
	else:
		node_style.shadow_size = 0
	
	return node_style

func pick_node_type(node, actor_index):
	var choice_button = node_modal.find_node("ChoiceButton")
	var choice_count = int(node_modal.find_node("ChoicesNumber").get_line_edit().text)
	var animation_button = node_modal.find_node("AnimationButton")
	
	if animation_button.pressed && choice_button.pressed:
		animation_button.pressed = false
		choice_button.pressed = false
		setup_normal_node(node, actor_index)
		return "normal"
	elif animation_button.pressed:
		setup_animation_node(node, actor_index)
		return "animation"
	elif choice_button.pressed:
		setup_choice_node(node, choice_count, actor_index)
		return "choice"
	else:
		setup_normal_node(node, actor_index)
		return "normal"

func setup_normal_node(node, actor_index):
	var text_area = TextEdit.new()
	global.configure_textedit(text_area, 80)
	text_area.connect("text_changed",self,"save_node_data")
	
	node.title += " - Normal Node"
	node.add_child(text_area)
	
	node.set_slot(0,
			true, 0,
			Color(1, 1, 1, 1),
			true, 0,
			actors_list.get_item_custom_fg_color(actor_index))

func setup_animation_node(node, actor_index):
	var dropdown = OptionButton.new()
	dropdown.set_text_align(Button.ALIGN_CENTER)
	
	node.title += " - Animation Node"
	node.add_child(dropdown)
	
	node.set_slot(0,
			true, 0,
			Color(1, 1, 1, 1),
			true, 0,
			actors_list.get_item_custom_fg_color(actor_index))

func setup_choice_node(node, choice_count, actor_index):
	var count = 0
	
	node.title += " - Choice Node"
	
	while count < choice_count:
		var text_area = TextEdit.new()
		var separator = HSeparator.new()
		text_area.connect("text_changed",self,"save_node_data")
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
					actors_list.get_item_custom_fg_color(actor_index))
		if count == choice_count - 1:
			if count % 2 == 0:
				node.set_slot(count,
					true, 0,
					Color(1, 1, 1, 1),
					true, 0,
					actors_list.get_item_custom_fg_color(actor_index))
			else:
				node.set_slot(count,
					true, 0,
					Color(1, 1, 1, 1),
					false, 0,
					actors_list.get_item_custom_fg_color(actor_index))
		count += 1

func _on_GraphArea__end_node_move():
	#	save conversation nodes positions for every node
	var conversation_index = conversations_list.get_selected_items()[0]
	var conversation = global.get_dictionary_entry(conversations_list.conversations, 
			conversations_list.get_item_text(conversation_index))
	
	for child in get_children():
		if child is GraphNode:
			for node in conversation["nodes"]:
				if node["name"] == child.name:
					node["offset"] = child.offset
					pass

func save_node_data():
	var conversation_index = conversations_list.get_selected_items()[0]
	var conversation = global.get_dictionary_entry(conversations_list.conversations, 
			conversations_list.get_item_text(conversation_index))
	
	for child in get_children():
		if child is GraphNode:
			var count = 0
			for item in child.get_children():
				if item is TextEdit:
					for node in conversation["nodes"]:
						if node["name"] == child.name:
							node["data"][count] = item.text
							count += 1


func _on_ExportConversation_pressed():
	global.exportData(scenes_list.scenes)
