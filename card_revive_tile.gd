extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var SelectingTile: bool = false

func _ready():
	text = "Agregar tile"
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func Deactivate():
	SelectingTile = false
	text = "Agregar tile"

func _on_pressed():
	if not SelectingTile:
		Board.DeactivateAllPaletteTools()
	SelectingTile = !SelectingTile
	if SelectingTile:
		text = "Elegí dónde agregar una tile..."
	else:
		text = "Agregar tile"

func _on_tile_clicked(Location: String):
	if Board.CheckmateDetected:
		return
	if not SelectingTile:
		return
	
	# Solo se puede resucitar si está destruida
	if not Board.DestroyedTiles.has(Location):
		return
	
	var cell = Flow.get_node(Location)
	
	# Resucitar la tile
	Board.DestroyedTiles.erase(Location)
	cell.modulate = Board.ActiveTileColor
	
	if Board.PlayMode:
		Board.EndTurn()
		Deactivate()
