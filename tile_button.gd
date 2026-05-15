extends Button

var Board
var Flow

func _ready():
	pressed.connect(func(): Flow.SendLocation.emit(str(name)))

func _get_drag_data(at_position):
	if Board.PlayMode:
		return null
	if get_child_count() == 0:
		return null
	var piece = get_child(0)
	var preview = Control.new()
	var dup = piece.duplicate()
	dup.position = piece.get_rect().size / 2
	preview.add_child(dup)
	preview.custom_minimum_size = piece.get_rect().size
	set_drag_preview(preview)
	return {"piece": piece, "from": name}

func _can_drop_data(at_position, data):
	if Board.PlayMode:
		return false
	if not data is Dictionary or not data.has("piece"):
		return false
	if Board.DestroyedTiles.has(name):
		return false
	if get_child_count() != 0:
		return false
	return true

func _drop_data(at_position, data):
	var piece = data.piece
	piece.reparent(self)
	piece.position = Vector2(Flow.TileXSize / 2, Flow.TileYSize / 2)
