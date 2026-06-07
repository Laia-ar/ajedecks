extends Node

const PANEL_WIDTH := 220.0
const PANEL_PADDING := 14.0
const BUTTON_HEIGHT := 42.0
const BUTTON_GAP := 10.0

@onready var Board = get_parent()
@onready var Flow: Control = Board.get_node("Flow")
@onready var Background: ColorRect = Board.get_node("Background")
@onready var DialogBackdrop: ColorRect = Board.get_node("DialogBackdrop")
@onready var TopToolbar: Panel = Board.get_node("TopToolbar")
@onready var LeftPanel: Panel = Board.get_node("LeftToolPanel")
@onready var RightPanel: Panel = Board.get_node("RightToolPanel")
@onready var StatusLabel: Label = Board.get_node("StatusLabel")

func _ready():
	get_viewport().size_changed.connect(_layout)
	call_deferred("_initialize_ui")

func _initialize_ui():
	_apply_styles()
	_layout()

func _layout():
	var viewport_size = get_viewport().get_visible_rect().size
	Background.size = viewport_size
	DialogBackdrop.size = viewport_size

	var board_rect = Rect2(Flow.position, Flow.size)
	TopToolbar.position = Vector2(board_rect.position.x, maxf(16.0, board_rect.position.y - 68.0))
	TopToolbar.size = Vector2(board_rect.size.x, 54.0)

	var left_x = maxf(16.0, board_rect.position.x - PANEL_WIDTH - 20.0)
	var right_x = minf(viewport_size.x - PANEL_WIDTH - 16.0, board_rect.end.x + 20.0)
	LeftPanel.position = Vector2(left_x, board_rect.position.y + 36.0)
	LeftPanel.size = Vector2(PANEL_WIDTH, 258.0)
	RightPanel.position = Vector2(right_x, board_rect.position.y + 36.0)
	RightPanel.size = Vector2(PANEL_WIDTH, 158.0)

	_layout_top_buttons()
	_layout_side_panel(LeftPanel, [
		Board.get_node("StandardButton"),
		Board.get_node("RandomButton"),
		Board.get_node("PuzzleGenerator")
	])
	_layout_side_panel(RightPanel, [
		Board.get_node("ReviveTileCard"),
		Board.get_node("DestroyTileCard")
	])

	StatusLabel.position = Vector2(
		board_rect.position.x + (board_rect.size.x - 300.0) / 2.0,
		board_rect.end.y + 14.0
	)
	StatusLabel.size = Vector2(300.0, 32.0)

	_center_dialog(Board.get_node("SaveDialog"), Vector2(520.0, 360.0), viewport_size)
	_center_dialog(Board.get_node("LoadDialog"), Vector2(460.0, 360.0), viewport_size)

func _layout_top_buttons():
	var buttons = [
		Board.get_node("ModeToggle"),
		Board.get_node("ResetButton"),
		Board.get_node("SaveButton"),
		Board.get_node("LoadButton"),
		Board.get_node("DeleteButton")
	]
	var available_width = TopToolbar.size.x - PANEL_PADDING * 2.0
	var width = (available_width - BUTTON_GAP * (buttons.size() - 1)) / buttons.size()
	for index in buttons.size():
		var button: Button = buttons[index]
		_prepare_control(button)
		button.position = TopToolbar.position + Vector2(
			PANEL_PADDING + index * (width + BUTTON_GAP),
			6.0
		)
		button.size = Vector2(width, BUTTON_HEIGHT)

func _layout_side_panel(panel: Panel, buttons: Array):
	var y = 50.0
	for button in buttons:
		_prepare_control(button)
		button.position = panel.position + Vector2(PANEL_PADDING, y)
		button.size = Vector2(PANEL_WIDTH - PANEL_PADDING * 2.0, BUTTON_HEIGHT)
		y += BUTTON_HEIGHT + BUTTON_GAP

func _apply_styles():
	var panel_style = _style(Color("#222831"), Color("#39424e"), 10, 1)
	TopToolbar.add_theme_stylebox_override("panel", panel_style)
	LeftPanel.add_theme_stylebox_override("panel", panel_style)
	RightPanel.add_theme_stylebox_override("panel", panel_style)

	var normal = _style(Color("#303946"), Color("#465262"), 8, 1)
	var hover = _style(Color("#3b4655"), Color("#68778a"), 8, 1)
	var pressed = _style(Color("#26303b"), Color("#8da2b8"), 8, 2)
	var disabled = _style(Color("#252b33"), Color("#343c47"), 8, 1)

	for node in Board.get_children():
		if node is Button:
			_style_button(node, normal, hover, pressed, disabled)

	for dialog_name in ["SaveDialog", "LoadDialog", "PiecePicker"]:
		var dialog: Panel = Board.get_node(dialog_name)
		dialog.add_theme_stylebox_override("panel", _style(Color("#222831"), Color("#596777"), 12, 1))
		for child in dialog.find_children("*", "Button", true, false):
			_style_button(child, normal, hover, pressed, disabled)

	for input in [
		Board.get_node("SaveDialog/NameInput"),
		Board.get_node("SaveDialog/InformationInput"),
		Board.get_node("LoadDialog/FileList")
	]:
		input.add_theme_font_size_override("font_size", 15)

	var primary: Button = Board.get_node("ModeToggle")
	primary.add_theme_stylebox_override("normal", _style(Color("#2f6f5e"), Color("#55a58c"), 8, 1))
	primary.add_theme_stylebox_override("hover", _style(Color("#398671"), Color("#76c3aa"), 8, 1))

	var danger: Button = Board.get_node("DeleteButton")
	danger.add_theme_stylebox_override("normal", _style(Color("#66343b"), Color("#9a525c"), 8, 1))
	danger.add_theme_stylebox_override("hover", _style(Color("#7b3c45"), Color("#c06a76"), 8, 1))

	for label in [LeftPanel.get_node("Title"), RightPanel.get_node("Title")]:
		label.add_theme_color_override("font_color", Color("#e8edf2"))
		label.add_theme_font_size_override("font_size", 17)

	StatusLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StatusLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prepare_control(StatusLabel)
	StatusLabel.add_theme_color_override("font_color", Color("#dce4ec"))
	StatusLabel.add_theme_stylebox_override("normal", _style(Color("#222831"), Color("#39424e"), 8, 1))

func _style_button(button: Button, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox):
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#f3f5f7"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#7d8793"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _prepare_control(control: Control):
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.grow_horizontal = Control.GROW_DIRECTION_END
	control.grow_vertical = Control.GROW_DIRECTION_END

func _center_dialog(dialog: Control, dialog_size: Vector2, viewport_size: Vector2):
	_prepare_control(dialog)
	dialog.size = dialog_size
	dialog.position = (viewport_size - dialog_size) / 2.0

func _style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
