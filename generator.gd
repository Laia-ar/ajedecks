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
	var TileButtonScript = preload("res://tile_button.gd")
	# Crear los botones del tablero
	while NumberY != BoardYSize:
		self.size.y += TileYSize + 5
		self.size.x += TileXSize + 5
		while NumberX != BoardXSize:
			var temp = TileButtonScript.new()
			temp.set_custom_minimum_size(Vector2(TileXSize, TileYSize))
			temp.Board = Board
			temp.Flow = self
			temp.set_name(str(NumberX) + "-" + str(NumberY))
			add_child(temp)
			# Si arrancamos vacío, marcamos todas como destruidas
			if StartEmpty:
				Board.DestroyedTiles[temp.name] = true
				temp.modulate = Board.DestroyedTileColor
			NumberX += 1
		NumberY += 1
		NumberX = 0
	if PlayRegularGame == true:
		RegularGame()

# Esta función ya no se usa con StartEmpty=true, pero la dejamos por si querés
# volver al modo clásico cambiando los flags.
func RegularGame():
	var offset_x = (BoardXSize - 8) / 2
	var offset_y = (BoardYSize - 8) / 2
	
	var back_row_black = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
	for i in range(8):
		get_node(str(offset_x + i) + "-" + str(offset_y)).add_child(Summon(back_row_black[i], 1))
	
	for i in range(8):
		get_node(str(offset_x + i) + "-" + str(offset_y + 1)).add_child(Summon(Pawn, 1))
	
	for i in range(8):
		get_node(str(offset_x + i) + "-" + str(offset_y + 6)).add_child(Summon(Pawn, 0))
	
	var back_row_white = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
	for i in range(8):
		get_node(str(offset_x + i) + "-" + str(offset_y + 7)).add_child(Summon(back_row_white[i], 0))

func Summon(Scene: PackedScene, color: int):
	var Piece = Scene.instantiate()
	Piece.Spawned(color)
	Piece.position = Vector2(TileXSize / 2, TileYSize / 2)
	return Piece
