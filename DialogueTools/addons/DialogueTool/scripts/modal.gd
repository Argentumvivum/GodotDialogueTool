extends Popup

onready var scenes_list = get_node("../PanelContainer/VBoxContainer/GraphContainer/ListsContainer/ScenesList")

var label
var text_edit
var color_button
var default_text
var conversation
var actor
var scene
var add_button
var cancel_button
var description
var separator
var editing
signal button_pressed

func _ready():
	label = $PanelContainer/PopupContainer/PopupName
	text_edit = $PanelContainer/PopupContainer/Name
	color_button = $PanelContainer/PopupContainer/ColorPickerButton
	add_button = $PanelContainer/PopupContainer/AddButton
	add_button.connect("pressed", self, "_button_pressed")
	cancel_button = $PanelContainer/PopupContainer/CancelButton
	cancel_button.connect("pressed", self, "_cancelled")
	default_text = "Enter Name Here..."
	description = $PanelContainer/PopupContainer/Description
	separator = $PanelContainer/PopupContainer/HSeparator2

func _on_AddScene_pressed():
	scene = true
	actor = false
	conversation = false
	editing = false
	label.text = "Add Scene"
	text_edit.text = default_text
	description.text = "Description goes here..."
	popup_centered()

func _on_AddConversations_pressed():
	if scenes_list.is_anything_selected():
		scene = false
		actor = false
		conversation = true
		editing = false
		label.text = "Add Conversation"
		text_edit.text = default_text
		description.text = "Description goes here..."
		popup_centered()

func _on_AddActor_pressed():
	scene = false
	actor = true
	conversation = false
	editing = false
	label.text = "Add Actor"
	text_edit.text = default_text
	description.text = "Description goes here..."
	popup_centered()

func _button_pressed():
	emit_signal("button_pressed")

func _cancelled():
	editing = false
	hide()
