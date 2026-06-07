extends Panel

const PIECES = {
	"PawnWhite": ["WPawn", "Peón blanco"],
	"RookWhite": ["WRook", "Torre blanca"],
	"KnightWhite": ["WKnight", "Caballo blanco"],
	"BishopWhite": ["WBishop", "Alfil blanco"],
	"QueenWhite": ["WQueen", "Dama blanca"],
	"KingWhite": ["WKing", "Rey blanco"],
	"PawnBlack": ["BPawn", "Peón negro"],
	"RookBlack": ["BRook", "Torre negra"],
	"KnightBlack": ["BKnight", "Caballo negro"],
	"BishopBlack": ["BBishop", "Alfil negro"],
	"QueenBlack": ["BQueen", "Dama negra"],
	"KingBlack": ["BKing", "Rey negro"]
}

func _ready():
	for button_name in PIECES:
		var button: Button = get_node("GridContainer/" + button_name)
		var piece_data: Array = PIECES[button_name]
		button.text = ""
		button.icon = load("res://ChessTextures/" + piece_data[0] + ".svg")
		button.tooltip_text = piece_data[1]
		button.expand_icon = true
		button.custom_minimum_size = Vector2(56, 56)
