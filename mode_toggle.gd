extends Button

@export var BoardPath: NodePath
# Herramientas de piezas (se deshabilitan en modo Play)
@export var PaletteButtons: Array[NodePath]
# Herramientas de tiles (permanecen habilitadas en modo Play)
@export var TilePaletteButtons: Array[NodePath]

@onready var Board = get_node(BoardPath)

func _ready():
	text = "Jugar"
	tooltip_text = "Probar el puzzle con las reglas de juego"
	pressed.connect(_on_pressed)

func _on_pressed():
	Board.PlayMode = not Board.PlayMode
	if Board.PlayMode:
		text = "Editar"
		_set_palette_enabled(false)
		Board.StartPlaySession()
		Board.UpdateStatusLabel()
		Board._schedule_black_turn()
	else:
		text = "Jugar"
		_set_palette_enabled(true)
		Board.AIThinking = false
		Board.ClearSelectedTile()
		if Board.GameResult != null:
			Board.GameResult.hide_result()
		if Board.StatusLabel != null:
			Board.StatusLabel.visible = false

func _set_palette_enabled(enabled: bool):
	# Piezas: deshabilitar en Play
	for path in PaletteButtons:
		var btn = get_node_or_null(path)
		if btn != null:
			btn.disabled = not enabled
			if not enabled:
				if btn.has_method("Deactivate"):
					btn.Deactivate()
				elif "Selecting" in btn:
					btn.Selecting = false
				elif "SelectingTile" in btn:
					btn.SelectingTile = false
	
	# Tiles: solo desactivar selección al pasar a Play, nunca deshabilitar
	if not enabled:
		for path in TilePaletteButtons:
			var btn = get_node_or_null(path)
			if btn != null:
				if btn.has_method("Deactivate"):
					btn.Deactivate()
				elif "Selecting" in btn:
					btn.Selecting = false
				elif "SelectingTile" in btn:
					btn.SelectingTile = false
