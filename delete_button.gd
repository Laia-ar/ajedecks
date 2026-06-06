extends Button

@export var BoardPath: NodePath
@export var LoadDialogPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var LoadDialog = get_node(LoadDialogPath)

const SAVE_DIR = "res://saves/"

func _ready():
	text = "🗑 Delete"
	pressed.connect(_on_pressed)
	LoadDialog.get_node("Delete").pressed.connect(_on_delete_confirm)
	LoadDialog.get_node("Cancel").pressed.connect(_on_cancel)

func _on_pressed():
	var list: ItemList = LoadDialog.get_node("FileList")
	list.clear()
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".json"):
			list.add_item(filename.trim_suffix(".json"))
		filename = dir.get_next()
	
	LoadDialog.visible = true

func _on_delete_confirm():
	var list: ItemList = LoadDialog.get_node("FileList")
	var selected = list.get_selected_items()
	if selected.is_empty():
		return
	
	var save_name = list.get_item_text(selected[0])
	var path = SAVE_DIR + save_name + ".json"
	
	DirAccess.remove_absolute(path)
	list.remove_item(selected[0])
	print("Borrado: " + path)

func _on_cancel():
	LoadDialog.visible = false
