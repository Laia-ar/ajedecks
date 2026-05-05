extends Control

const SQUARE_SIZE = 80
const BOARD_SIZE = 8 * SQUARE_SIZE

var engine = ChessEngine.new()
var selected_square = null
var legal_moves = []
var flipped = false

var light_color = Color(0.93, 0.82, 0.68)
var dark_color = Color(0.46, 0.26, 0.16)
var select_color = Color(0.5, 0.8, 0.5, 0.6)
var legal_color = Color(0.3, 0.6, 0.9, 0.5)
var legal_capture_color = Color(0.3, 0.6, 0.9, 0.7)
var check_color = Color(0.9, 0.2, 0.2, 0.5)
var last_move_color = Color(0.9, 0.9, 0.3, 0.3)

var piece_letters = {
	"wK": "K", "wQ": "Q", "wR": "R", "wB": "B", "wN": "N", "wP": "P",
	"bK": "K", "bQ": "Q", "bR": "R", "bB": "B", "bN": "N", "bP": "P"
}

var last_move_from = null
var last_move_to = null

var piece_font = null
var coord_font = null

signal state_changed(state_text)
signal move_made

func _ready():
	add_child(engine)
	engine.reset_board()
	_setup_fonts()
	update_display()

func _setup_fonts():
	var base_font = get_font("font")
	if base_font == null:
		var label = Label.new()
		base_font = label.get_font("font")
		label.free()

	if base_font is DynamicFont:
		piece_font = DynamicFont.new()
		piece_font.font_data = base_font.font_data
		piece_font.size = 48

		coord_font = DynamicFont.new()
		coord_font.font_data = base_font.font_data
		coord_font.size = 14
	else:
		piece_font = base_font
		coord_font = base_font

func _draw():
	# Draw squares
	for x in range(8):
		for y in range(8):
			var pos = Vector2(x, y)
			var screen_pos = board_to_screen(pos)
			var is_light = (x + y) % 2 == 0
			var color = light_color if is_light else dark_color

			if pos == last_move_from or pos == last_move_to:
				color = color.blend(last_move_color)

			draw_rect(Rect2(screen_pos, Vector2(SQUARE_SIZE, SQUARE_SIZE)), color)

	# Highlight selected
	if selected_square != null:
		var sp = board_to_screen(selected_square)
		draw_rect(Rect2(sp, Vector2(SQUARE_SIZE, SQUARE_SIZE)), select_color)

	# Highlight legal moves
	for move in legal_moves:
		var sp = board_to_screen(move)
		if engine.board.has(move):
			draw_rect(Rect2(sp, Vector2(SQUARE_SIZE, SQUARE_SIZE)), legal_capture_color)
		else:
			var center = sp + Vector2(SQUARE_SIZE / 2, SQUARE_SIZE / 2)
			draw_circle(center, 10, legal_color)

	# Highlight king in check
	if engine.game_state == engine.GameState.CHECK or engine.game_state == engine.GameState.CHECKMATE:
		var king_pos = engine.get_king_pos(engine.turn)
		var sp = board_to_screen(king_pos)
		draw_rect(Rect2(sp, Vector2(SQUARE_SIZE, SQUARE_SIZE)), check_color)

	# Draw pieces
	if piece_font != null:
		for pos in engine.board:
			var piece = engine.board[pos]
			var letter = piece_letters.get(piece, "?")
			var screen_pos = board_to_screen(pos)
			var center = screen_pos + Vector2(SQUARE_SIZE / 2, SQUARE_SIZE / 2)
			var is_white = piece[0] == 'w'

			var circle_color = Color.white if is_white else Color.black
			draw_circle(center, 28, circle_color)
			draw_arc(center, 28, 0, 2 * PI, 32, Color(0.5, 0.5, 0.5), 2)

			var text_color = Color.black if is_white else Color.white
			var text_size_vec = piece_font.get_string_size(letter)
			var text_pos = center - text_size_vec / 2
			text_pos.y -= text_size_vec.y / 4
			draw_string(piece_font, text_pos, letter, text_color)

	# Draw coordinates
	if coord_font != null:
		var coord_color = Color.white
		var files = "abcdefgh"
		for i in range(8):
			var file = files[i] if not flipped else files[7 - i]
			var x_pos = board_to_screen(Vector2(i, 7 if not flipped else 0)).x + SQUARE_SIZE / 2
			var top_y = board_to_screen(Vector2(i, 0 if not flipped else 7)).y - 5
			var bot_y = board_to_screen(Vector2(i, 7 if not flipped else 0)).y + SQUARE_SIZE + 15
			var fw = coord_font.get_string_size(file).x
			draw_string(coord_font, Vector2(x_pos - fw / 2, top_y), file, coord_color)
			draw_string(coord_font, Vector2(x_pos - fw / 2, bot_y), file, coord_color)

		for i in range(8):
			var rank = str(8 - i) if not flipped else str(i + 1)
			var y_pos = board_to_screen(Vector2(0 if not flipped else 7, i)).y + SQUARE_SIZE / 2
			var left_x = board_to_screen(Vector2(0, i)).x - 20
			var right_x = board_to_screen(Vector2(7, i)).x + SQUARE_SIZE + 5
			var rw = coord_font.get_string_size(rank).x
			draw_string(coord_font, Vector2(left_x - rw / 2, y_pos + 5), rank, coord_color)
			draw_string(coord_font, Vector2(right_x - rw / 2, y_pos + 5), rank, coord_color)

func board_to_screen(board_pos: Vector2) -> Vector2:
	if flipped:
		return Vector2(7 - board_pos.x, board_pos.y) * SQUARE_SIZE
	else:
		return Vector2(board_pos.x, 7 - board_pos.y) * SQUARE_SIZE

func screen_to_board(screen_pos: Vector2) -> Vector2:
	var bx = int(screen_pos.x / SQUARE_SIZE)
	var by = int(screen_pos.y / SQUARE_SIZE)
	if flipped:
		return Vector2(7 - bx, by)
	else:
		return Vector2(bx, 7 - by)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var board_pos = screen_to_board(event.position)
		if not engine.is_valid_pos(board_pos):
			return

		var piece = engine.get_piece(board_pos)

		if selected_square == null:
			if piece != "" and engine.get_color(piece) == engine.turn:
				selected_square = board_pos
				legal_moves = engine.get_legal_moves(board_pos)
				update_display()
		else:
			if board_pos in legal_moves:
				var moving_piece = engine.get_piece(selected_square)
				var promotion = "Q"
				if engine.get_type(moving_piece) == "P" and (board_pos.y == 0 or board_pos.y == 7):
					promotion = _ask_promotion()
				engine.make_move(selected_square, board_pos, promotion)
				last_move_from = selected_square
				last_move_to = board_pos
				selected_square = null
				legal_moves = []
				update_display()
				emit_signal("state_changed", engine.get_game_state_text())
				emit_signal("move_made")
			elif piece != "" and engine.get_color(piece) == engine.turn:
				selected_square = board_pos
				legal_moves = engine.get_legal_moves(board_pos)
				update_display()
			else:
				selected_square = null
				legal_moves = []
				update_display()

func _ask_promotion() -> String:
	return "Q"

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_R:
		reset_game()

func update_display():
	update()

func reset_game():
	engine.reset_board()
	selected_square = null
	legal_moves = []
	last_move_from = null
	last_move_to = null
	update_display()
	emit_signal("state_changed", engine.get_game_state_text())

func flip_board():
	flipped = not flipped
	update_display()
