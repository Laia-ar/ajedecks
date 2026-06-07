extends Button

@export var BoardPath: NodePath
@export var SaveDialogPath: NodePath  # un LineEdit + botón "Save" que vamos a crear

@onready var Board = get_node(BoardPath)
@onready var SaveDialog = get_node(SaveDialogPath)
@onready var DialogBackdrop = SaveDialog.get_parent().get_node("DialogBackdrop")

const SAVE_DIR = "res://saves/"
const CATEGORY_OPTIONS := ["Fácil", "Mediana", "Difícil"]

func _ready():
	text = "Guardar"
	tooltip_text = "Guardar el puzzle actual"
	pressed.connect(_on_pressed)
	_setup_category_options()
	# Los puzzles se guardan dentro del proyecto para poder versionarlos.
	var error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	if error != OK:
		push_error("No se pudo crear el directorio de guardado: " + SAVE_DIR)
	# Conectar el botón confirmar del diálogo
	SaveDialog.get_node("Confirm").pressed.connect(_on_confirm)
	SaveDialog.get_node("Cancel").pressed.connect(_on_cancel)

func _on_pressed():
	DialogBackdrop.visible = true
	SaveDialog.visible = true
	SaveDialog.get_node("NameInput").text = ""
	SaveDialog.get_node("InformationInput").text = ""
	SaveDialog.get_node("DifficultyInput").selected = 0
	SaveDialog.get_node("ComplexityInput").selected = 0
	SaveDialog.get_node("NameInput").grab_focus()

func _on_confirm():
	var save_name: String = SaveDialog.get_node("NameInput").text.strip_edges()
	if save_name == "":
		return
	
	# Sanitizar el nombre (sin barras ni caracteres raros)
	save_name = save_name.replace("/", "_").replace("\\", "_")
	
	var data = Board.SerializeBoard()
	data["information"] = SaveDialog.get_node("InformationInput").text.strip_edges()
	data["difficulty"] = SaveDialog.get_node("DifficultyInput").get_item_text(SaveDialog.get_node("DifficultyInput").selected)
	data["complexity"] = SaveDialog.get_node("ComplexityInput").get_item_text(SaveDialog.get_node("ComplexityInput").selected)
	var path = SAVE_DIR + save_name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir para escribir: " + path)
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	
	SaveDialog.visible = false
	DialogBackdrop.visible = false
	print("Guardado: " + path)

func _on_cancel():
	SaveDialog.visible = false
	DialogBackdrop.visible = false

func _setup_category_options():
	for node_name in ["DifficultyInput", "ComplexityInput"]:
		var input: OptionButton = SaveDialog.get_node(node_name)
		input.clear()
		for option in CATEGORY_OPTIONS:
			input.add_item(option)
		input.selected = 0
