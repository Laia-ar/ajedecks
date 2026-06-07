extends Button

@export var LoadButtonPath: NodePath
@export var Direction := 1

@onready var LoadButton = get_node(LoadButtonPath)

func _ready():
	text = ">" if Direction >= 0 else "<"
	tooltip_text = "Cargar siguiente puzzle guardado" if Direction >= 0 else "Cargar puzzle guardado anterior"
	pressed.connect(_on_pressed)

func _on_pressed():
	LoadButton.load_relative_save(1 if Direction >= 0 else -1)
