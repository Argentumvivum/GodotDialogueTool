extends GraphNode

func _on_GraphNode_close_request():
	remove_connections(name)
	queue_free()

func _on_default_node_resize_request(new_minsize):
	rect_size = Vector2(new_minsize.x, 0)

func remove_connections(name):
	var graph = get_parent()
	var conversation_index = graph.conversations_list.get_selected_items()[0]
	var conversation = global.get_dictionary_entry(graph.conversations_list.conversations, 
			graph.conversations_list.get_item_text(conversation_index))
	
	for connection in graph.get_connection_list():
		if name in connection["from"] || name in connection["to"]:
			graph.disconnect_node(connection["from"], 
					connection["from_port"], 
					connection["to"], 
					connection["to_port"])
	
	#	update connections
	conversation["connections"] = graph.get_connection_list()
	
	#	update nodes
	conversation["nodes"] = global.remove_dictionary_entry(conversation["nodes"], name)
