extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var SelectingTile: bool = false

func _ready():
	text = "Resucitar tile"
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func _on_pressed():
	SelectingTile = !SelectingTile
	if SelectingTile:
		text = "Elegí una tile destruida..."
	else:
		text = "Resucitar tile"

func _on_tile_clicked(Location: String):
	if not SelectingTile:
		return
	
	# Solo se puede resucitar si está destruida
	if not Board.DestroyedTiles.has(Location):
		return
	
	var cell = Flow.get_node(Location)
	
	# Resucitar la tile
	Board.DestroyedTiles.erase(Location)
	cell.modulate = Color(1, 1, 1, 1)
	
	SelectingTile = false
	text = "Reconstruir tile"
