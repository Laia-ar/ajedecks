extends Button

@export var BoardPath: NodePath
@export var DialogPath: NodePath
@export var PuzzleInfoPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Dialog: Panel = get_node(DialogPath)
@onready var PuzzleInfo = get_node(PuzzleInfoPath)
@onready var DialogBackdrop = Dialog.get_parent().get_node("DialogBackdrop")

func _ready():
	text = "Importar PGN"
	tooltip_text = "Importar la posición final de una partida PGN"
	pressed.connect(_on_pressed)
	Dialog.get_node("Import").pressed.connect(_on_import)
	Dialog.get_node("Cancel").pressed.connect(_on_cancel)

func _on_pressed():
	Dialog.get_node("ErrorLabel").text = ""
	DialogBackdrop.visible = true
	Dialog.visible = true
	Dialog.get_node("PGNInput").grab_focus()

func _on_import():
	var pgn = Dialog.get_node("PGNInput").text.strip_edges()
	if pgn.is_empty():
		_show_error("Pegá un PGN antes de importar.")
		return

	var result = PGNParser.new().parse(pgn)
	if not result.ok:
		_show_error(result.error)
		return

	if Board.PlayMode:
		Board.get_node("ModeToggle")._on_pressed()
	Board.DeserializeBoard(_to_board_data(result))
	Board.SetLoadedSaveName("")
	PuzzleInfo.set_information(_build_information(result))
	Dialog.visible = false
	DialogBackdrop.visible = false

func _to_board_data(result: Dictionary) -> Dictionary:
	var offset_x = (Board.Flow.BoardXSize - 8) / 2
	var offset_y = (Board.Flow.BoardYSize - 8) / 2
	var active_tiles = []
	for y in 8:
		for x in 8:
			active_tiles.append(str(offset_x + x) + "-" + str(offset_y + y))

	var pieces = []
	for piece in result.pieces:
		var square: String = piece.square
		var file = square.unicode_at(0) - 97
		var rank = int(square.substr(1))
		pieces.append({
			"location": str(offset_x + file) + "-" + str(offset_y + 8 - rank),
			"type": piece.type,
			"color": piece.color
		})

	return {
		"version": 1,
		"board_x": Board.Flow.BoardXSize,
		"board_y": Board.Flow.BoardYSize,
		"turn": result.turn,
		"active_tiles": active_tiles,
		"pieces": pieces,
		"tile_heights": {}
	}

func _build_information(result: Dictionary) -> String:
	var headers: Dictionary = result.headers
	var lines = ["PGN importado: %d movimientos." % result.moves]
	for key in ["Event", "White", "Black", "Date", "Result"]:
		if headers.has(key) and not str(headers[key]).is_empty():
			lines.append("%s: %s" % [key, headers[key]])
	return "\n".join(lines)

func _show_error(message: String):
	Dialog.get_node("ErrorLabel").text = message

func _on_cancel():
	Dialog.visible = false
	DialogBackdrop.visible = false
