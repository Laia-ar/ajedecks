extends FlowContainer

@export var BoardXSize = 12
@export var BoardYSize = 12

@export var TileXSize: float = 42
@export var TileYSize: float = 42

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
	var board_size = Vector2(BoardXSize * TileXSize, BoardYSize * TileYSize)
	custom_minimum_size = board_size
	size = board_size
	var NumberX: int = 0
	var NumberY: int = 0
	var TileButtonScript = preload("res://tile_button.gd")
	# Crear los botones del tablero
	while NumberY != BoardYSize:
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
				temp.SetTileColor(Board.DestroyedTileColor)
			else:
				temp.SetTileColor(Board.GetTileColor(temp.name))
			NumberX += 1
		NumberY += 1
		NumberX = 0
	_center_board()
	get_viewport().size_changed.connect(_center_board)
	if PlayRegularGame == true:
		RegularGame()

func _center_board():
	position = (get_viewport_rect().size - size) / 2.0

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
