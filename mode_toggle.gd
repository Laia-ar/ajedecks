extends Button

@export var BoardPath: NodePath
# Lista de botones de la paleta que se bloquean en modo Play
@export var PaletteButtons: Array[NodePath]

@onready var Board = get_node(BoardPath)

func _ready():
	text = "▶ Play"
	pressed.connect(_on_pressed)

func _on_pressed():
	Board.PlayMode = not Board.PlayMode
	if Board.PlayMode:
		text = "✎ Edit"
		_set_palette_enabled(false)
	else:
		text = "▶ Play"
		_set_palette_enabled(true)

func _set_palette_enabled(enabled: bool):
	for path in PaletteButtons:
		var btn = get_node_or_null(path)
		if btn != null:
			btn.disabled = not enabled
			# Cancelar cualquier modo de selección activo
			if not enabled:
				if btn.has_method("Deactivate"):
					btn.Deactivate()
				elif "Selecting" in btn:
					btn.Selecting = false
				elif "SelectingTile" in btn:
					btn.SelectingTile = false
