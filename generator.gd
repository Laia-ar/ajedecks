extends FlowContainer

@export var BoardXSize = 20
@export var BoardYSize = 20

@export var TileXSize: float = 25
@export var TileYSize: float = 25

# Lo dejamos en false: arrancamos sin piezas y sin tiles activas
@export var PlayRegularGame: bool = false

# Si está en true, todas las tiles arrancan "destruidas" (modo herramienta)
@export var StartEmpty: bool = true

signal SendLocation(Location: String)

@export var Pawn: PackedScene
@export var Bishop: PackedScene
@export var Rook: PackedScene
@export var Knight: PackedScene
@export var Queen: PackedScene
@export var King: PackedScene

# Referencia al Board (para acceder a DestroyedTiles)
@onready var Board = get_parent()

func _ready():
	if BoardXSize < 0 || BoardYSize < 0:
		return
	var NumberX: int = 0
	var NumberY: int = 0
	# Crear los botones del tablero
	while NumberY != BoardYSize:
		self.size.y += TileYSize + 5
		self.size.x += TileXSize + 5
		while NumberX != BoardXSize:
			var temp = Button.new()
			temp.set_custom_minimum_size(Vector2(TileXSize, TileYSize))
			temp.connect("pressed", func():
				SendLocation.emit(temp.name))
			temp.set_name(str(NumberX) + "-" + str(NumberY))
			add_child(temp)
			# Si arrancamos vacío, marcamos todas como destruidas
			if StartEmpty:
				Board.DestroyedTiles[temp.name] = true
				temp.modulate = Color(0.1, 0.1, 0.1, 0.5)
			NumberX += 1
		NumberY += 1
		NumberX = 0
	if PlayRegularGame == true:
		RegularGame()

# Esta función ya no se usa con StartEmpty=true, pero la dejamos por si querés
# volver al modo clásico cambiando los flags.
func RegularGame():
	get_node("0-0").add_child(Summon(Rook, 1))
	get_node("1-0").add_child(Summon(Knight, 1))
	get_node("2-0").add_child(Summon(Bishop, 1))
	get_node("3-0").add_child(Summon(Queen, 1))
	get_node("4-0").add_child(Summon(King, 1))
	get_node("5-0").add_child(Summon(Bishop, 1))
	get_node("6-0").add_child(Summon(Knight, 1))
	get_node("7-0").add_child(Summon(Rook, 1))
	
	get_node("0-1").add_child(Summon(Pawn, 1))
	get_node("1-1").add_child(Summon(Pawn, 1))
	get_node("2-1").add_child(Summon(Pawn, 1))
	get_node("3-1").add_child(Summon(Pawn, 1))
	get_node("4-1").add_child(Summon(Pawn, 1))
	get_node("5-1").add_child(Summon(Pawn, 1))
	get_node("6-1").add_child(Summon(Pawn, 1))
	get_node("7-1").add_child(Summon(Pawn, 1))
	
	get_node("0-6").add_child(Summon(Pawn, 0))
	get_node("1-6").add_child(Summon(Pawn, 0))
	get_node("2-6").add_child(Summon(Pawn, 0))
	get_node("3-6").add_child(Summon(Pawn, 0))
	get_node("4-6").add_child(Summon(Pawn, 0))
	get_node("5-6").add_child(Summon(Pawn, 0))
	get_node("6-6").add_child(Summon(Pawn, 0))
	get_node("7-6").add_child(Summon(Pawn, 0))
	
	get_node("0-7").add_child(Summon(Rook, 0))
	get_node("1-7").add_child(Summon(Knight, 0))
	get_node("2-7").add_child(Summon(Bishop, 0))
	get_node("3-7").add_child(Summon(Queen, 0))
	get_node("4-7").add_child(Summon(King, 0))
	get_node("5-7").add_child(Summon(Bishop, 0))
	get_node("6-7").add_child(Summon(Knight, 0))
	get_node("7-7").add_child(Summon(Rook, 0))

func Summon(Scene: PackedScene, color: int):
	var Piece = Scene.instantiate()
	Piece.Spawned(color)
	Piece.position = Vector2(TileXSize / 2, TileYSize / 2)
	return Piece
