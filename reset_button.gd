extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath
@export var ModeTogglePath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)
@onready var ModeToggle = get_node(ModeTogglePath)

func _ready():
	text = "Reiniciar"
	tooltip_text = "Vaciar el tablero y volver al modo edición"
	pressed.connect(_on_pressed)

func _on_pressed():
	# Sacar todas las piezas
	Board.TileHeights.clear()
	for tile in Flow.get_children():
		if tile.get_child_count() > 0:
			tile.get_child(0).queue_free()
	
	# Marcar todas las tiles como destruidas (estado inicial)
	for tile in Flow.get_children():
		Board.DestroyedTiles[tile.name] = true
		Board.UpdateTileVisual(tile.name)
	
	# Volver a modo Edit
	if Board.PlayMode:
		ModeToggle._on_pressed()  # togglea a Edit y reactiva paleta
	
	# Resetear turno
	Board.Turn = 0
	Board.ClearSelectedTile()
	Board.Areas.clear()
	Board.SpecialArea.clear()
	Board.CheckmateDetected = false
	Board.DrawDetected = false
	Board.PromotionEndsTurn = false
	Board.PlayStartState.clear()
	Board.get_node("Promotion").visible = false
	if Board.GameResult != null:
		Board.GameResult.hide_result()
