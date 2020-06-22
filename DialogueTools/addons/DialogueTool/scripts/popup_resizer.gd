extends Control

func _on_PanelContainer_resized():
	var node_popup = get_parent()
	node_popup.set_size(get_size())
