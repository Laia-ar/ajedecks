extends Button

# Referencia al nodo Board (que tiene game.gd)
@export var BoardPath: NodePath
# Referencia al Flow (donde están los 64 botones de las tiles)
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

# Estamos esperando que el jugador elija una tile?
var SelectingTile: bool = false

func _ready():
	text = "Sacar tile"
	pressed.connect(_on_pressed)
	# Conectarse a la señal del Flow para enterarse cuando se clickea una tile
	Flow.SendLocation.connect(_on_tile_clicked)

func _on_pressed():
	SelectingTile = !SelectingTile  # Toggle: si la apretás de nuevo, cancelás
	if SelectingTile:
		text = "Elegí una tile para sacar..."
	else:
		text = "Sacar tile"

func _on_tile_clicked(Location: String):
	if not SelectingTile:
		return
	
	var cell = Flow.get_node(Location)
	# Solo se puede destruir si está vacía
	if cell.get_child_count() != 0:
		return
	# Y si no fue destruida ya
	if Board.DestroyedTiles.has(Location):
		return
	
	# Destruir la tile
	Board.DestroyedTiles[Location] = true
	Board.SetHeight(Location, 0)
	cell.modulate = Color(0.1, 0.1, 0.1, 0.5)
	cell.modulate = Board.DestroyedTileColor

	SelectingTile = false
	text = "Sacar tile"
