extends Button

@export var raise_tile_button: Button
@export var lower_tile_button: Button

var _hidden: bool = true

func _ready():
	pressed.connect(_on_pressed)
	tooltip_text = "Mostrar u ocultar las herramientas de altura"
	_update_button_visibility()
	_update_text()

func _on_pressed():
	_hidden = not _hidden
	_update_button_visibility()
	_update_text()

func _update_button_visibility():
	if raise_tile_button != null:
		raise_tile_button.visible = not _hidden
	if lower_tile_button != null:
		lower_tile_button.visible = not _hidden

func _update_text():
	if _hidden:
		text = "Mostrar alturas"
	else:
		text = "Ocultar alturas"
