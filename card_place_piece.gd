extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

# Qué pieza coloca este botón. Valores: "Pawn", "Bishop", "Rook", "Knight", "Queen", "King"
@export var PieceType: String = "Pawn"
# 0 = blanco, 1 = negro
@export var PieceColor: int = 0

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var Selecting: bool = false
var BaseText: String = ""

func _ready():
	BaseText = _build_label()
	text = BaseText
	_load_icon()
	custom_minimum_size = Vector2(0, 22)
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func _load_icon():
	var prefix = "W" if PieceColor == 0 else "B"
	var path = "res://ChessTextures/" + prefix + PieceType + ".svg"
	var texture = ResourceLoader.load(path)
	if texture == null:
		return
	var image = texture.get_image()
	image.resize(16, 16, Image.INTERPOLATE_LANCZOS)
	icon = ImageTexture.create_from_image(image)

func _build_label() -> String:
	var color_name = "Blanco" if PieceColor == 0 else "Negro"
	var piece_name = ""
	match PieceType:
		"Pawn": piece_name = "Peón"
		"Bishop": piece_name = "Alfil"
		"Rook": piece_name = "Torre"
		"Knight": piece_name = "Caballo"
		"Queen": piece_name = "Dama"
		"King": piece_name = "Rey"
		_: piece_name = PieceType
	return piece_name + " " + color_name

func _on_pressed():
	Selecting = !Selecting
	if Selecting:
		text = "Elegí dónde colocar..."
	else:
		text = BaseText

func _on_tile_clicked(Location: String):
	if not Selecting:
		return
	
	var cell = Flow.get_node(Location)
	
	# Si la tile está destruida, la revivimos automáticamente
	if Board.DestroyedTiles.has(Location):
		Board.DestroyedTiles.erase(Location)
		cell.modulate = Board.ActiveTileColor
	
	# No se puede colocar si ya hay pieza
	if cell.get_child_count() != 0:
		return
	
	# Instanciar la pieza desde el Flow (que tiene las PackedScene exportadas)
	var scene: PackedScene = _get_piece_scene()
	if scene == null:
		push_error("No se encontró la escena para: " + PieceType)
		return
	
	var piece = scene.instantiate()
	piece.Spawned(PieceColor)
	piece.position = Vector2(Flow.TileXSize / 2, Flow.TileYSize / 2)
	cell.add_child(piece)
	
	# Volver al estado base (no se gasta)
	Selecting = false
	text = BaseText

func _get_piece_scene() -> PackedScene:
	# Reusamos las PackedScene que ya están exportadas en el Flow (generator.gd)
	match PieceType:
		"Pawn": return Flow.Pawn
		"Bishop": return Flow.Bishop
		"Rook": return Flow.Rook
		"Knight": return Flow.Knight
		"Queen": return Flow.Queen
		"King": return Flow.King
	return null
