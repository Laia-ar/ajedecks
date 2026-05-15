extends Button

@export var BoardPath: NodePath
@export var FlowPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Flow = get_node(FlowPath)

var piece_types = ["Pawn", "Rook", "Knight", "Bishop", "Queen", "King"]
var piece_scenes: Dictionary

func _ready():
	text = "🎲 Random"
	pressed.connect(_on_pressed)
	piece_scenes = {
		"Pawn": Flow.Pawn,
		"Rook": Flow.Rook,
		"Knight": Flow.Knight,
		"Bishop": Flow.Bishop,
		"Queen": Flow.Queen,
		"King": Flow.King
	}

func _on_pressed():
	# Limpiar piezas existentes
	for tile in Flow.get_children():
		if tile.get_child_count() > 0:
			tile.get_child(0).queue_free()
	
	for tile in Flow.get_children():
		if Board.DestroyedTiles.has(tile.name):
			continue
		if randf() < 0.12:
			var type = piece_types[randi() % piece_types.size()]
			var color = randi() % 2
			var scene = piece_scenes[type]
			var piece = scene.instantiate()
			piece.Spawned(color)
			piece.position = Vector2(Flow.TileXSize / 2, Flow.TileYSize / 2)
			tile.add_child(piece)
