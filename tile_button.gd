extends Button

var Board
var Flow

func _ready():
	pressed.connect(func(): Flow.SendLocation.emit(str(name)))
	mouse_entered.connect(_on_mouse_entered)

func SetTileColor(color: Color):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	set("theme_override_styles/normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.08)
	set("theme_override_styles/hover", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.08)
	set("theme_override_styles/pressed", pressed_style)

	var focus_style = StyleBoxEmpty.new()
	set("theme_override_styles/focus", focus_style)

func _on_mouse_entered():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Board.PlayMode and not get_viewport().gui_is_dragging():
		Flow.SendLocation.emit(str(name))

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

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		accept_event()
		Board._on_tile_right_clicked(name)
