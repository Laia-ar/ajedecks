extends Panel

@export var BoardPath: NodePath

@onready var Board = get_node(BoardPath)
@onready var Title: Label = $Title
@onready var Detail: Label = $Detail
@onready var RestartButton: Button = $Restart

func _ready():
	RestartButton.pressed.connect(_on_restart_pressed)
	visible = false

func show_result(title: String, detail: String):
	Title.text = title
	Detail.text = detail
	visible = true

func hide_result():
	visible = false

func _on_restart_pressed():
	Board.RestartPlaySession()
