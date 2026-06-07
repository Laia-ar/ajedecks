extends Button

var Board
var Flow
var BaseColor := Color.WHITE
var IsSelected := false
var IsHovered := false

func _ready():
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func(): Flow.SendLocation.emit(str(name)))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func SetTileColor(color: Color):
	BaseColor = color
	_update_style()

func SetSelected(selected: bool):
	IsSelected = selected
	_update_style()
	_update_piece_feedback()

func _update_style():
	var normal_style = _make_style(BaseColor, Color.TRANSPARENT, 0)
	var hover_style = _make_style(BaseColor.lightened(0.12), Color("#f4f7fb"), 3)
	var pressed_style = _make_style(BaseColor.darkened(0.08), Color("#ffffff"), 3)

	if IsSelected:
		var selected_style = _make_style(BaseColor.lightened(0.08), Color("#ffd166"), 4)
		set("theme_override_styles/normal", selected_style)
		set("theme_override_styles/hover", selected_style)
		set("theme_override_styles/pressed", selected_style)
	else:
		set("theme_override_styles/normal", normal_style)
		set("theme_override_styles/hover", hover_style)
		set("theme_override_styles/pressed", pressed_style)
	set("theme_override_styles/focus", StyleBoxEmpty.new())

func _on_mouse_entered():
	IsHovered = true
	_update_style()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Board.PlayMode and not get_viewport().gui_is_dragging():
		Flow.SendLocation.emit(str(name))

func _on_mouse_exited():
	IsHovered = false
	_update_style()

func _update_piece_feedback():
	if get_child_count() == 0:
		return
	var piece = get_child(0)
	piece.modulate = Color("#ffe29a") if IsSelected else Color.WHITE

func _make_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	return style

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
