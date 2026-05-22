extends Button

@export var raise_tile_button: Button
@export var lower_tile_button: Button

var _hidden: bool = false

func _ready():
	pressed.connect(_on_pressed)
	_update_text()

func _on_pressed():
	_hidden = not _hidden
	if raise_tile_button != null:
		raise_tile_button.visible = not _hidden
	if lower_tile_button != null:
		lower_tile_button.visible = not _hidden
	_update_text()

func _update_text():
	if _hidden:
		text = "Mostrar tile up/down"
	else:
		text = "Esconder tile up/down"
