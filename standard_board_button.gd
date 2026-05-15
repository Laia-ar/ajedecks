extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

func _ready():
	text = "♜ Standard"
	pressed.connect(_on_pressed)

func _on_pressed():
	var offset_x = (Flow.BoardXSize - 8) / 2
	var offset_y = (Flow.BoardYSize - 8) / 2
	
	# Limpiar piezas existentes
	for tile in Flow.get_children():
		if tile.get_child_count() > 0:
			tile.get_child(0).queue_free()
	
	# Revivir tiles del área 8x8 centrada
	for x in range(8):
		for y in range(8):
			var loc = str(offset_x + x) + "-" + str(offset_y + y)
			Board.DestroyedTiles.erase(loc)
			var tile = Flow.get_node_or_null(loc)
			if tile != null:
				tile.modulate = Board.ActiveTileColor
	
	# Colocar piezas standard
	Flow.RegularGame()
