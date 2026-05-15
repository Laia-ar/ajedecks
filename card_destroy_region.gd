extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

enum State { IDLE, WAITING_FIRST, WAITING_SECOND }
var CurrentState: State = State.IDLE
var FirstCorner: String = ""

# Propiedad dummy para que ModeToggle pueda cancelar la selección al cambiar de modo
var SelectingTile: bool = false:
	set(value):
		if value == false and CurrentState != State.IDLE:
			_reset()
		SelectingTile = value

func _ready():
	text = "Sacar región"
	custom_minimum_size = Vector2(0, 22)
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func Deactivate():
	_reset()

func _on_pressed():
	if CurrentState == State.IDLE:
		Board.DeactivateAllPaletteTools()
	if CurrentState == State.IDLE:
		CurrentState = State.WAITING_FIRST
		text = "Elegí la primera esquina..."
	else:
		_reset()

func _on_tile_clicked(Location: String):
	if CurrentState == State.IDLE:
		return

	if CurrentState == State.WAITING_FIRST:
		FirstCorner = Location
		CurrentState = State.WAITING_SECOND
		text = "Elegí la segunda esquina..."
		return

	if CurrentState == State.WAITING_SECOND:
		_apply_region(FirstCorner, Location)
		FirstCorner = ""
		CurrentState = State.WAITING_FIRST
		text = "Elegí la primera esquina..."

func _apply_region(corner1: String, corner2: String):
	var coords1 = _parse_coords(corner1)
	var coords2 = _parse_coords(corner2)

	var min_x = mini(coords1.x, coords2.x)
	var max_x = maxi(coords1.x, coords2.x)
	var min_y = mini(coords1.y, coords2.y)
	var max_y = maxi(coords1.y, coords2.y)

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var loc = str(x) + "-" + str(y)
			var cell = Flow.get_node_or_null(loc)
			if cell == null:
				continue
			if cell.get_child_count() != 0:
				continue
			if Board.DestroyedTiles.has(loc):
				continue
			Board.DestroyedTiles[loc] = true
			cell.modulate = Board.DestroyedTileColor

func _parse_coords(loc: String) -> Vector2i:
	var parts = loc.split("-")
	return Vector2i(int(parts[0]), int(parts[1]))

func _reset():
	CurrentState = State.IDLE
	FirstCorner = ""
	text = "Sacar región"
