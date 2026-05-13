extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var Selecting: bool = false

func _ready():
	text = "Borrar pieza"
	pressed.connect(_on_pressed)
	Flow.SendLocation.connect(_on_tile_clicked)

func _on_pressed():
	Selecting = !Selecting
	if Selecting:
		text = "Elegí una pieza para borrar..."
	else:
		text = "Borrar pieza"

func _on_tile_clicked(Location: String):
	if not Selecting:
		return
	
	var cell = Flow.get_node(Location)
	if cell.get_child_count() == 0:
		return  # No hay pieza
	
	cell.get_child(0).queue_free()
	
	Selecting = false
	text = "Borrar pieza"
