extends Button

# Referencia al nodo Board (que tiene game.gd)
@export var BoardPath: NodePath
# Referencia al Flow (donde están los 64 botones de las tiles)
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

# Estamos esperando que el jugador elija una tile?
var SelectingTile: bool = false
# La carta ya fue usada?
var Used: bool = false

func _ready():
	text = "Destruir tile"
	pressed.connect(_on_pressed)
	# Conectarse a la señal del Flow para enterarse cuando se clickea una tile
	Flow.SendLocation.connect(_on_tile_clicked)

func _on_pressed():
	if Used:
		return
	SelectingTile = !SelectingTile  # Toggle: si la apretás de nuevo, cancelás
	if SelectingTile:
		text = "Elegí una tile vacía..."
	else:
		text = "Destruir tile"

func _on_tile_clicked(Location: String):
	if not SelectingTile or Used:
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
	cell.modulate = Color(0.1, 0.1, 0.1, 0.5)  # gris oscuro semitransparente
	cell.disabled = true
	cell.focus_mode = Control.FOCUS_NONE
	
	# Marcar la carta como usada
	Used = true
	SelectingTile = false
	text = "Carta usada"
	disabled = true
