extends Button

@export var BoardPath: NodePath
@export var LoadDialogPath: NodePath  # un Panel con un ItemList y botones
@export var PuzzleInfoPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var LoadDialog = get_node(LoadDialogPath)
@onready var PuzzleInfo = get_node(PuzzleInfoPath)
@onready var DialogBackdrop = LoadDialog.get_parent().get_node("DialogBackdrop")

const SAVE_DIR = "res://saves/"

var SaveNames: Array[String] = []
var CurrentSaveIndex := -1

func _ready():
	text = "Cargar"
	tooltip_text = "Cargar un puzzle guardado"
	pressed.connect(_on_pressed)
	LoadDialog.get_node("Confirm").pressed.connect(_on_confirm)
	LoadDialog.get_node("Cancel").pressed.connect(_on_cancel)

func _on_pressed():
	_refresh_save_list()
	LoadDialog.get_node("Label").text = "Cargar puzzle"
	LoadDialog.get_node("Confirm").visible = true
	LoadDialog.get_node("Delete").visible = false
	DialogBackdrop.visible = true
	LoadDialog.visible = true

func _refresh_save_list():
	var list: ItemList = LoadDialog.get_node("FileList")
	list.clear()
	SaveNames = _get_save_names()
	for save_name in SaveNames:
		list.add_item(save_name)
	if CurrentSaveIndex >= 0 and CurrentSaveIndex < SaveNames.size():
		list.select(CurrentSaveIndex)

func _on_confirm():
	var list: ItemList = LoadDialog.get_node("FileList")
	var selected = list.get_selected_items()
	if selected.is_empty():
		return
	
	var save_name = list.get_item_text(selected[0])
	load_save(save_name)
	LoadDialog.visible = false
	DialogBackdrop.visible = false

func load_relative_save(direction: int):
	SaveNames = _get_save_names()
	if SaveNames.is_empty():
		return
	if CurrentSaveIndex < 0 or CurrentSaveIndex >= SaveNames.size():
		CurrentSaveIndex = 0 if direction >= 0 else SaveNames.size() - 1
	else:
		CurrentSaveIndex = wrapi(CurrentSaveIndex + direction, 0, SaveNames.size())
	load_save(SaveNames[CurrentSaveIndex])

func load_save(save_name: String):
	var path = SAVE_DIR + save_name + ".json"
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir: " + path)
		return
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data == null:
		push_error("JSON inválido en: " + path)
		return
	
	Board.DeserializeBoard(data)
	SaveNames = _get_save_names()
	CurrentSaveIndex = SaveNames.find(save_name)
	PuzzleInfo.set_information(
		str(data.get("information", "")),
		str(data.get("difficulty", "")),
		str(data.get("complexity", ""))
	)
	Board.SetLoadedSaveName(save_name)
	print("Cargado: " + path)

func _on_cancel():
	LoadDialog.visible = false
	DialogBackdrop.visible = false

func _get_save_names() -> Array[String]:
	var save_names: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return save_names
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".json"):
			save_names.append(filename.trim_suffix(".json"))
		filename = dir.get_next()
	save_names.sort()
	return save_names
