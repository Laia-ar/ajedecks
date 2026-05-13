extends Button

@export var BoardPath: NodePath
@export var SaveDialogPath: NodePath  # un LineEdit + botón "Save" que vamos a crear

@onready var Board = get_node(BoardPath)
@onready var SaveDialog = get_node(SaveDialogPath)

const SAVE_DIR = "user://saves/"

func _ready():
	text = "💾 Save"
	pressed.connect(_on_pressed)
	# Asegurarse que existe la carpeta
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# Conectar el botón confirmar del diálogo
	SaveDialog.get_node("Confirm").pressed.connect(_on_confirm)

func _on_pressed():
	SaveDialog.visible = true
	SaveDialog.get_node("NameInput").text = ""
	SaveDialog.get_node("NameInput").grab_focus()

func _on_confirm():
	var save_name: String = SaveDialog.get_node("NameInput").text.strip_edges()
	if save_name == "":
		return
	
	# Sanitizar el nombre (sin barras ni caracteres raros)
	save_name = save_name.replace("/", "_").replace("\\", "_")
	
	var data = Board.SerializeBoard()
	var path = SAVE_DIR + save_name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir para escribir: " + path)
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	
	SaveDialog.visible = false
	print("Guardado: " + path)
