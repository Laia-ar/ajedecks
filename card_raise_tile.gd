extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath
# +1 para elevar, -1 para bajar
@export var Delta: int = 1

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var Selecting: bool = false
var BaseText: String = ""

func _ready():
	BaseText = "Elevar tile" if Delta > 0 else "Bajar tile"
	text = BaseText
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func Deactivate():
	Selecting = false
	text = BaseText

func _on_pressed():
	if not Selecting:
		Board.DeactivateAllPaletteTools()
	Selecting = !Selecting
	if Selecting:
		text = "Elegí una tile..."
	else:
		text = BaseText

func _on_tile_clicked(Location: String):
	if not Selecting:
		return
	# No se puede elevar una tile destruida
	if Board.DestroyedTiles.has(Location):
		return
	
	Board.ChangeHeight(Location, Delta)
	
	if Board.PlayMode:
		Board.EndTurn()
		Deactivate()
