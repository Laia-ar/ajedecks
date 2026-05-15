extends Control

signal GameWin

# Selected node is the button pressed before the one you just pressed.
var SelectedNode = ""
# If you don't have a good solution, do your promotions with another variable~
var SavedNode = ""
var Turn = 0

# Location on which node was clicked.
# Ints are here to reduce the size of some lines.
var LocationX: String
var LocationY: String
var LocationXInt: int
var LocationYInt: int

# Modo actual: false = Edit, true = Play
var PlayMode: bool = false

var TileHeights: Dictionary = {}

# This is the board buttons.
@export_node_path("FlowContainer") var BoardPath
@onready var Flow = get_node(BoardPath)

@onready var pos: Vector2 = Vector2(self.get_child(0).TileXSize / 2, self.get_child(0).TileYSize / 2)
# Areas where the player can move
var Areas: PackedStringArray
# this is seperate the Areas for special circumstances, like castling.

# Tiles destruidas por cartas. Las piezas no pueden moverse a estas casillas.
var DestroyedTiles: Dictionary = {}

# Colores de tiles para el editor
var ActiveTileColor: Color = Color(0.78, 0.82, 0.86, 1.0)
var DestroyedTileColor: Color = Color(0.18, 0.18, 0.20, 0.6)

var SpecialArea: PackedStringArray

func _on_flow_send_location(Location: String):
	# En modo edición, el tablero no juega ajedrez
	if not PlayMode:
		return
	
	# Don't update ANYTHING if you still need to promote!
	if get_node("Promotion").visible == true:
		return
	
	# variables for later
	var number = 0
	var cell = Flow.get_node(Location)
	# This is to try and grab the X and Y coordinates from the board
	LocationX = ""
	LocationY = ""
	while Location.substr(number, 1) != "-":
		LocationX += Location.substr(number, 1)
		number += 1
	LocationY = Location.substr(number + 1)
	LocationXInt = int(LocationX)
	LocationYInt = int(LocationY)
	# Now... we need to figure out how to select the pieces. If there is a valid move, do stuff.
	# If we re-select, just go to that other piece
	if SelectedNode == "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn:
		SelectedNode = Location
		GetMovableAreas()
	# Castling
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn && cell.get_child(0).name == "Rook":
		for i in Areas:
			if i == cell.name:
				var king = Flow.get_node(SelectedNode).get_child(0)
				var rook = cell.get_child(0)
				# Using a seperate array because Areas wouldn't be really consistant...
				king.reparent(Flow.get_node(SpecialArea[1]))
				rook.reparent(Flow.get_node(SpecialArea[0]))
				king.position = pos
				rook.position = pos
				# We have to get the parent because it will break lmao.
				UpdateGame(cell)
	# En Passant
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor != Turn && cell.get_child(0).name == "Pawn" && SpecialArea.size() != 0 && SpecialArea[0] == cell.name && cell.get_child(0).EnPassant == true:
		for i in SpecialArea:
			if i == cell.name:
				var pawn = Flow.get_node(SelectedNode).get_child(0)
				cell.get_child(0).free()
				pawn.reparent(Flow.get_node(SpecialArea[1]))
				pawn.position = pos
				UpdateGame(cell)
	# Re-select
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn:
		SelectedNode = Location
		GetMovableAreas()
	# Taking over a piece
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor != Turn:
		for i in Areas:
			if i == cell.name:
				var Piece = Flow.get_node(SelectedNode).get_child(0)
				# Win conditions
				if cell.get_child(0).name == "King":
					GameWin.emit()
				cell.get_child(0).free()
				SavedNode = Location
				Piece.reparent(cell)
				Piece.position = pos
				UpdateGame(cell)
	# Moving a piece
	elif SelectedNode != "" && cell.get_child_count() == 0:
		for i in Areas:
			if i == cell.name:
				var Piece = Flow.get_node(SelectedNode).get_child(0)
				SavedNode = Location
				Piece.reparent(cell)
				Piece.position = pos
				UpdateGame(cell)

func UpdateGame(cell):
	SelectedNode = ""
	var things = Flow.get_children()
	# get the en-passantable pieces and undo them
	for i in things:
		if i.get_child_count() != 0 && i.get_child(0).name == "Pawn" && i.get_child(0).PieceColor == Turn && i.get_child(0).EnPassant == true:
			i.get_child(0).EnPassant = false
		# This changes the color to regular white. For kings.
		elif i.get_child_count() != 0:
			i.get_child(0).modulate = Color(1, 1, 1, 1)
	
	# Remove and add the abilities once they are either used or not used
	if cell.get_child(0).name == "Pawn":
		PawnPromotion(cell.get_child(0))
		if cell.get_child(0).DoubleStart == true:
			cell.get_child(0).EnPassant = true
		cell.get_child(0).DoubleStart = false
	if cell.get_child(0).name == "King":
		cell.get_child(0).Castling = false
	if cell.get_child(0).name == "Rook":
		cell.get_child(0).Castling = false
	
	# King checking.
	CheckKing(things)
	SelectedNode = ""
	
	if Turn == 0:
		Turn = 1
	else:
		Turn = 0

# Below is the movement that is used for the pieces
func GetMovableAreas():
	# Clearing the arrays
	Areas.clear()
	SpecialArea.clear()
	var Piece = Flow.get_node(SelectedNode).get_child(0)
	# For the selected piece that we have, we can get the movement that we need here.
	if Piece.name == "Pawn":
		GetPawn(Piece)
	elif Piece.name == "Bishop":
		GetDiagonals()
	elif Piece.name == "King":
		GetAround(Piece)
	elif Piece.name == "Queen":
		GetDiagonals()
		GetRows()
	elif Piece.name == "Rook":
		GetRows()
	elif Piece.name == "Knight":
		GetHorse()

func PawnPromotion(Piece):
	# This is for going from the bottom to the top, also known as the white pawns.
	if IsNull(LocationX + "-" + str(LocationYInt - 1)) && Piece.PieceColor == 0:
		get_node("Promotion").visible = true
	elif IsNull(LocationX + "-" + str(LocationYInt + 1)) && Piece.PieceColor == 1:
		get_node("Promotion").visible = true

# TODO: Make this less crap
func FinalizePromotion(Selection):
	var Piece = Flow.get_node(SavedNode).get_child(0)
	var NewPiece
	if Selection == "Bishop":
		var thing = ResourceLoader.load("res://ChessScenes/bishop.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Queen":
		var thing = ResourceLoader.load("res://ChessScenes/queen.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Rook":
		var thing = ResourceLoader.load("res://ChessScenes/rook.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Knight":
		var thing = ResourceLoader.load("res://ChessScenes/knight.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	Piece.free()
	get_node("Promotion").visible = false

func GetPawn(Piece):
	var from_loc = SelectedNode
	# Helper para chequear si la pieza puede entrar a una tile dada
	var can_go = func(target): return CanReach(from_loc, target, Piece)

	# White pawns (suben, o sea Y disminuye)
	if Piece.PieceColor == 0:
		# Avance simple
		var forward = LocationX + "-" + str(LocationYInt - 1)
		if not IsNull(forward) and Flow.get_node(forward).get_child_count() == 0 and can_go.call(forward):
			Areas.append(forward)

		# Doble paso
		var double = LocationX + "-" + str(LocationYInt - 2)
		if not IsNull(double) and Piece.DoubleStart == true \
				and Flow.get_node(double).get_child_count() == 0 \
				and Flow.get_node(forward).get_child_count() == 0 \
				and can_go.call(forward) and can_go.call(double):
			Areas.append(double)

		# Capturas en diagonal
		var diag_left = str(LocationXInt - 1) + "-" + str(LocationYInt - 1)
		if not IsNull(diag_left) and Flow.get_node(diag_left).get_child_count() == 1 and can_go.call(diag_left):
			Areas.append(diag_left)
		var diag_right = str(LocationXInt + 1) + "-" + str(LocationYInt - 1)
		if not IsNull(diag_right) and Flow.get_node(diag_right).get_child_count() == 1 and can_go.call(diag_right):
			Areas.append(diag_right)

		# En passant izquierda
		var side_left = str(LocationXInt - 1) + "-" + LocationY
		var ep_left_target = str(LocationXInt - 1) + "-" + str(LocationYInt - 1)
		if not IsNull(side_left) and not IsNull(ep_left_target):
			if Flow.get_node(side_left).get_child_count() == 1 \
					and Flow.get_node(ep_left_target).get_child_count() != 1 \
					and can_go.call(ep_left_target):
				SpecialArea.append(side_left)
				SpecialArea.append(ep_left_target)

		# En passant derecha
		var side_right = str(LocationXInt + 1) + "-" + LocationY
		var ep_right_target = str(LocationXInt + 1) + "-" + str(LocationYInt - 1)
		if not IsNull(side_right) and not IsNull(ep_right_target):
			if Flow.get_node(side_right).get_child_count() == 1 \
					and Flow.get_node(ep_right_target).get_child_count() != 1 \
					and can_go.call(ep_right_target):
				SpecialArea.append(side_right)
				SpecialArea.append(ep_right_target)

	# Black pawns (bajan, o sea Y aumenta)
	else:
		# Avance simple
		var forward = LocationX + "-" + str(LocationYInt + 1)
		if not IsNull(forward) and Flow.get_node(forward).get_child_count() == 0 and can_go.call(forward):
			Areas.append(forward)

		# Doble paso
		var double = LocationX + "-" + str(LocationYInt + 2)
		if not IsNull(double) and Piece.DoubleStart == true \
				and Flow.get_node(double).get_child_count() == 0 \
				and Flow.get_node(forward).get_child_count() == 0 \
				and can_go.call(forward) and can_go.call(double):
			Areas.append(double)

		# Capturas en diagonal
		var diag_left = str(LocationXInt - 1) + "-" + str(LocationYInt + 1)
		if not IsNull(diag_left) and Flow.get_node(diag_left).get_child_count() == 1 and can_go.call(diag_left):
			Areas.append(diag_left)
		var diag_right = str(LocationXInt + 1) + "-" + str(LocationYInt + 1)
		if not IsNull(diag_right) and Flow.get_node(diag_right).get_child_count() == 1 and can_go.call(diag_right):
			Areas.append(diag_right)

		# En passant izquierda
		var side_left = str(LocationXInt - 1) + "-" + LocationY
		var ep_left_target = str(LocationXInt - 1) + "-" + str(LocationYInt + 1)
		if not IsNull(side_left) and not IsNull(ep_left_target):
			if Flow.get_node(side_left).get_child_count() == 1 \
					and Flow.get_node(ep_left_target).get_child_count() != 1 \
					and can_go.call(ep_left_target):
				SpecialArea.append(side_left)
				SpecialArea.append(ep_left_target)

		# En passant derecha
		var side_right = str(LocationXInt + 1) + "-" + LocationY
		var ep_right_target = str(LocationXInt + 1) + "-" + str(LocationYInt + 1)
		if not IsNull(side_right) and not IsNull(ep_right_target):
			if Flow.get_node(side_right).get_child_count() == 1 \
					and Flow.get_node(ep_right_target).get_child_count() != 1 \
					and can_go.call(ep_right_target):
				SpecialArea.append(side_right)
				SpecialArea.append(ep_right_target)

func GetAround(Piece):
	var from_loc = SelectedNode
	var candidates = [
		LocationX + "-" + str(LocationYInt + 1),
		LocationX + "-" + str(LocationYInt - 1),
		str(LocationXInt + 1) + "-" + LocationY,
		str(LocationXInt - 1) + "-" + LocationY,
		str(LocationXInt + 1) + "-" + str(LocationYInt + 1),
		str(LocationXInt - 1) + "-" + str(LocationYInt + 1),
		str(LocationXInt + 1) + "-" + str(LocationYInt - 1),
		str(LocationXInt - 1) + "-" + str(LocationYInt - 1),
	]
	for target in candidates:
		if not IsNull(target) and CanReach(from_loc, target, Piece):
			Areas.append(target)
	if Piece.Castling == true:
		Castle()

func GetRows():
	var from_loc = SelectedNode
	var piece = Flow.get_node(from_loc).get_child(0)
	print("=== GetRows desde ", from_loc, " (altura ", GetHeight(from_loc), ") ===")
	var AddX = 1
	# Horizontal derecha
	while not IsNull(str(LocationXInt + AddX) + "-" + LocationY):
		var target = str(LocationXInt + AddX) + "-" + LocationY
		# Si la tile en el camino es más alta, se bloquea ANTES de pisarla
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
	AddX = 1
	# Horizontal izquierda
	while not IsNull(str(LocationXInt - AddX) + "-" + LocationY):
		var target = str(LocationXInt - AddX) + "-" + LocationY
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
	var AddY = 1
	# Vertical abajo
	while not IsNull(LocationX + "-" + str(LocationYInt + AddY)):
		var target = LocationX + "-" + str(LocationYInt + AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddY += 1
	AddY = 1
	# Vertical arriba
	while not IsNull(LocationX + "-" + str(LocationYInt - AddY)):
		var target = LocationX + "-" + str(LocationYInt - AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddY += 1
	
func GetDiagonals():
	var from_loc = SelectedNode
	var piece = Flow.get_node(from_loc).get_child(0)
	var AddX = 1
	var AddY = 1
	while not IsNull(str(LocationXInt + AddX) + "-" + str(LocationYInt + AddY)):
		var target = str(LocationXInt + AddX) + "-" + str(LocationYInt + AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt - AddX) + "-" + str(LocationYInt + AddY)):
		var target = str(LocationXInt - AddX) + "-" + str(LocationYInt + AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt + AddX) + "-" + str(LocationYInt - AddY)):
		var target = str(LocationXInt + AddX) + "-" + str(LocationYInt - AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt - AddX) + "-" + str(LocationYInt - AddY)):
		var target = str(LocationXInt - AddX) + "-" + str(LocationYInt - AddY)
		if not CanReach(from_loc, target, piece):
			break
		Areas.append(target)
		if Flow.get_node(target).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1

func GetHorse():
	var TheX = 2
	var TheY = 1
	var number = 0
	while number != 8:
		# So this one is interesting. This is most likely the cleanest code here.
		# Get the numbers, replace the numbers, and loop until it stops.
		if not IsNull(str(LocationXInt + TheX) + "-" + str(LocationYInt + TheY)):
			Areas.append(str(LocationXInt + TheX) + "-" + str(LocationYInt + TheY))
		number += 1
		match number:
			1:
				TheX = 1
				TheY = 2
			2:
				TheX = -2
				TheY = 1
			3:
				TheX = -1
				TheY = 2
			4:
				TheX = 2
				TheY = -1
			5:
				TheX = 1
				TheY = -2
			6:
				TheX = -2
				TheY = -1
			7:
				TheX = -1
				TheY = -2

func Castle():
	# This is the castling section right here, used if a person wants to castle.
	var CounterX = 1
	# These are very similar to gathering a row, except we want free tiles and a rook
	# Counting up
	while not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child_count() == 0:
		CounterX += 1
	if not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).name == "Rook":
		if Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).Castling == true:
			Areas.append(str(LocationXInt + CounterX) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt + 1) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt + 2) + "-" + LocationY)
	# Counting down
	CounterX = -1
	while not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child_count() == 0:
		CounterX -= 1
	if not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).name == "Rook":
		if Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).Castling == true:
			Areas.append(str(LocationXInt + CounterX) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt - 1) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt - 2) + "-" + LocationY)

func IsNull(Location):
	if Flow.get_node_or_null(Location) == null:
		return true
	# Si la tile fue destruida por una carta, se trata como inexistente
	if DestroyedTiles.has(Location):
		return true
	IsKing(Location)
	return false

# Checking for a king.
func CheckKing(Children):
	for i in Children:
		if i.get_child_count() != 0:
			SelectedNode = str(i.name)
			GetMovableAreas()

# Helper function
func IsKing(Location):
	var TheNode = Flow.get_node_or_null(Location)
	if TheNode != null && TheNode.get_child_count() != 0 && TheNode.get_child(0).PieceColor != Turn && TheNode.get_child(0).name == "King":
		TheNode.get_child(0).modulate = Color(1, 0, 0, 1)
		
# ====================================================================
# Save / Load
# ====================================================================

func SerializeBoard() -> Dictionary:
	var data = {
		"version": 1,
		"board_x": Flow.BoardXSize,
		"board_y": Flow.BoardYSize,
		"turn": Turn,
		"active_tiles": [],
		"pieces": []
	}
	
	data["tile_heights"] = TileHeights.duplicate()

	for tile in Flow.get_children():
		# Tile activa = no está en DestroyedTiles
		if not DestroyedTiles.has(tile.name):
			data.active_tiles.append(tile.name)
		# Pieza en la tile
		if tile.get_child_count() > 0:
			var piece = tile.get_child(0)
			data.pieces.append({
				"location": tile.name,
				"type": piece.name,  # "Pawn", "Rook", etc.
				"color": piece.PieceColor
			})
	
	return data

func DeserializeBoard(data: Dictionary):
	# 1. Limpiar el tablero actual
	for tile in Flow.get_children():
		if tile.get_child_count() > 0:
			tile.get_child(0).queue_free()
		DestroyedTiles[tile.name] = true
		tile.modulate = DestroyedTileColor

	TileHeights.clear()
	
	# 2. Activar las tiles del save
	for loc in data.active_tiles:
		var tile = Flow.get_node_or_null(loc)
		if tile != null:
			DestroyedTiles.erase(loc)
			tile.modulate = ActiveTileColor

	for loc in data.get("tile_heights", {}):
		TileHeights[loc] = data.tile_heights[loc]
		_update_tile_visual(loc)

	
	# 3. Poner las piezas
	for piece_data in data.pieces:
		var tile = Flow.get_node_or_null(piece_data.location)
		if tile == null:
			continue
		var scene: PackedScene = _get_piece_scene(piece_data.type)
		if scene == null:
			continue
		var piece = scene.instantiate()
		piece.Spawned(piece_data.color)
		piece.position = Vector2(Flow.TileXSize / 2, Flow.TileYSize / 2)
		tile.add_child(piece)
	
	# 4. Restaurar turno
	Turn = data.get("turn", 0)
	SelectedNode = ""
	Areas.clear()
	SpecialArea.clear()

func _get_piece_scene(piece_type: String) -> PackedScene:
	match piece_type:
		"Pawn": return Flow.Pawn
		"Bishop": return Flow.Bishop
		"Rook": return Flow.Rook
		"Knight": return Flow.Knight
		"Queen": return Flow.Queen
		"King": return Flow.King
	return null

	# ====================================================================
# Sistema de alturas
# ====================================================================

const MIN_HEIGHT = -5
const MAX_HEIGHT = 5

func GetHeight(Location: String) -> int:
	return TileHeights.get(Location, 0)

func SetHeight(Location: String, value: int):
	value = clamp(value, MIN_HEIGHT, MAX_HEIGHT)
	if value == 0:
		TileHeights.erase(Location)
	else:
		TileHeights[Location] = value
	_update_tile_visual(Location)

func ChangeHeight(Location: String, delta: int):
	SetHeight(Location, GetHeight(Location) + delta)

func _update_tile_visual(Location: String):
	var tile = Flow.get_node_or_null(Location)
	if tile == null:
		return
	var h = GetHeight(Location)
	var color: Color
	if DestroyedTiles.has(Location):
		color = Color(0.1, 0.1, 0.1, 0.5)
	elif h == 0:
		color = Color(1, 1, 1, 1)
	elif h > 0:
		var t = float(h) / float(MAX_HEIGHT)
		color = Color(1, 1, 1 - t * 0.7, 1)
	else:
		var t = float(-h) / float(-MIN_HEIGHT)
		color = Color(1 - t * 0.6, 1 - t * 0.4, 1, 1)
	tile.modulate = color
	tile.text = str(h) if h != 0 else ""

	# Devuelve true si la pieza en From puede entrar/capturar en la tile To,
# considerando alturas. El caballo está exento.
func CanReach(FromLoc: String, ToLoc: String, Piece) -> bool:
	if Piece.name == "Knight":
		return true
	var h_from = GetHeight(FromLoc)
	var h_to = GetHeight(ToLoc)
	var result = h_to <= h_from
	print("CanReach ", Piece.name, " ", FromLoc, "(h=", h_from, ") -> ", ToLoc, "(h=", h_to, ") = ", result)
	return result
