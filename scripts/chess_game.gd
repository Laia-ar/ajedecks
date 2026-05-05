# chess_game.gd - Main game controller handling the UI and player interaction
extends Control

var board: ChessBoard
var selected_square: int = -1
var legal_moves_for_selected: Array = []
var game_over: bool = false
var game_result: String = ""
var is_player_white: bool = true
var promotion_pending: Dictionary = {}
var show_promotion_ui: bool = false
var promotion_square_index: int = -1

# Board constants
const BOARD_OFFSET: int = 40
const SQUARE_SIZE: int = 70
const BOARD_SIZE: int = SQUARE_SIZE * 8

# Colors (as Color rgbf values)
const LIGHT_SQUARE = Color(0.941, 0.851, 0.71)
const DARK_SQUARE = Color(0.71, 0.533, 0.388)
const SELECTED_COLOR = Color(0.51, 0.592, 0.412)
const LAST_MOVE_COLOR = Color(0.804, 0.824, 0.416, 0.5)
const CHECK_COLOR = Color(1.0, 0.0, 0.0, 0.5)

# Piece labels (Control nodes)
var piece_nodes: Array = []

# UI elements
var status_label: Label
var new_game_button: Button
var promotion_popup: Control
var promotion_buttons: Array = []

# Last move highlight
var last_move_from: int = -1
var last_move_to: int = -1

func _ready():
	setup_ui()
	board = ChessBoard.new()
	new_game()

func setup_ui():
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	margin_left = -(BOARD_SIZE + BOARD_OFFSET * 2 + 200) / 2.0
	margin_top = -(BOARD_SIZE + BOARD_OFFSET * 2 + 60) / 2.0
	margin_right = (BOARD_SIZE + BOARD_OFFSET * 2 + 200) / 2.0
	margin_bottom = (BOARD_SIZE + BOARD_OFFSET * 2 + 60) / 2.0
	
	# Status label
	status_label = Label.new()
	status_label.rect_position = Vector2(10, 10)
	status_label.rect_size = Vector2(BOARD_SIZE + BOARD_OFFSET * 2 + 180, 40)
	status_label.add_font_override("font", get_font(""))
	add_child(status_label)
	
	# New Game button
	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.rect_position = Vector2(BOARD_SIZE + BOARD_OFFSET * 2 + 20, BOARD_OFFSET + 10)
	new_game_button.rect_size = Vector2(160, 40)
	new_game_button.connect("pressed", self, "_on_new_game_pressed")
	add_child(new_game_button)
	
	# Welcome message
	var info_label = Label.new()
	info_label.text = "Click a piece to select it,\nthen click destination square."
	info_label.rect_position = Vector2(BOARD_SIZE + BOARD_OFFSET * 2 + 20, BOARD_OFFSET + 60)
	info_label.rect_size = Vector2(160, 60)
	info_label.add_color_override("font_color", Color(0.4, 0.4, 0.4))
	add_child(info_label)
	
	# Promotion popup
	create_promotion_popup()
	
	set_process_input(true)

func create_promotion_popup():
	promotion_popup = Control.new()
	promotion_popup.visible = false
	promotion_popup.anchor_left = 0.5
	promotion_popup.anchor_right = 0.5
	promotion_popup.anchor_top = 0.5
	promotion_popup.anchor_bottom = 0.5
	promotion_popup.margin_left = -140
	promotion_popup.margin_top = -50
	promotion_popup.margin_right = 140
	promotion_popup.margin_bottom = 50
	
	var bg = ColorRect.new()
	bg.color = Color(0.176, 0.176, 0.176)
	bg.rect_size = Vector2(280, 100)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	promotion_popup.add_child(bg)
	
	var label = Label.new()
	label.text = "Choose promotion:"
	label.rect_position = Vector2(10, 10)
	label.rect_size = Vector2(260, 20)
	label.add_color_override("font_color", Color.white)
	promotion_popup.add_child(label)
	
	var promo_pieces = [
		{"type": ChessPiece.Type.QUEEN, "name": "Queen"},
		{"type": ChessPiece.Type.ROOK, "name": "Rook"},
		{"type": ChessPiece.Type.BISHOP, "name": "Bishop"},
		{"type": ChessPiece.Type.KNIGHT, "name": "Knight"},
	]
	
	for i in range(promo_pieces.size()):
		var btn = Button.new()
		btn.text = promo_pieces[i].name
		btn.rect_position = Vector2(10 + i * 68, 40)
		btn.rect_size = Vector2(60, 40)
		btn.connect("pressed", self, "_on_promotion_chosen", [promo_pieces[i].type])
		promotion_popup.add_child(btn)
		promotion_buttons.append(btn)
	
	add_child(promotion_popup)

func new_game():
	board.reset()
	game_over = false
	game_result = ""
	selected_square = -1
	legal_moves_for_selected.clear()
	last_move_from = -1
	last_move_to = -1
	promotion_pending = {}
	show_promotion_ui = false
	promotion_popup.visible = false
	redraw_board()
	update_status()

func redraw_board():
	for node in piece_nodes:
		if is_instance_valid(node):
			node.queue_free()
	piece_nodes.clear()
	
	update()
	
	for i in range(64):
		var piece = board.get_piece_at(i)
		if piece.type == ChessPiece.Type.NONE:
			continue
		
		var coords = ChessBoard.index_to_coords(i)
		var display_file = coords.file
		var display_rank = coords.rank
		
		var label = Label.new()
		label.text = ChessPiece.SYMBOLS[piece.color][piece.type]
		label.rect_position = Vector2(
			BOARD_OFFSET + display_file * SQUARE_SIZE,
			BOARD_OFFSET + display_rank * SQUARE_SIZE
		)
		label.rect_size = Vector2(SQUARE_SIZE, SQUARE_SIZE)
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		
		var font = DynamicFont.new()
		font.size = int(SQUARE_SIZE * 0.65)
		label.add_font_override("font", font)
		
		label.modulate = Color(0.067, 0.067, 0.067) if piece.color == ChessPiece.PieceColor.BLACK else Color.white
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		piece_nodes.append(label)

func update_status():
	var turn_text = "White's turn" if board.current_turn == ChessPiece.PieceColor.WHITE else "Black's turn"
	if game_over:
		turn_text = game_result
	
	if not game_over and board.is_in_check(board.current_turn):
		turn_text += " - CHECK!"
	
	status_label.text = turn_text

func _draw():
	for rank in range(8):
		for file in range(8):
			var is_light = (file + rank) % 2 == 0
			var base_color = LIGHT_SQUARE if is_light else DARK_SQUARE
			var color = base_color
			
			var rect = Rect2(
				Vector2(BOARD_OFFSET + file * SQUARE_SIZE, BOARD_OFFSET + rank * SQUARE_SIZE),
				Vector2(SQUARE_SIZE, SQUARE_SIZE)
			)
			
			var sq_idx = ChessBoard.coords_to_index(file, rank)
			
			if sq_idx == selected_square and not game_over:
				color = SELECTED_COLOR
			elif sq_idx == last_move_from or sq_idx == last_move_to:
				color = LAST_MOVE_COLOR
			
			if board.is_in_check(board.current_turn):
				var king_pos = board.find_king(board.current_turn)
				if sq_idx == king_pos:
					color = CHECK_COLOR
			
			draw_rect(rect, color)
			draw_rect(rect, Color.black, false, 1.0)
			
			for move in legal_moves_for_selected:
				if move.to == sq_idx:
					if board.get_piece_at(sq_idx).type != ChessPiece.Type.NONE:
						var center = rect.position + rect.size / 2
						draw_circle(center, SQUARE_SIZE * 0.35, Color(1.0, 0.0, 0.0, 0.5))
					else:
						var center = rect.position + rect.size / 2
						draw_circle(center, SQUARE_SIZE * 0.12, Color(0.0, 0.0, 0.0, 0.2))
	
	var coord_font = DynamicFont.new()
	coord_font.size = 12
	for i in range(8):
		var file_char = char(97 + i)
		draw_string(coord_font, 
			Vector2(BOARD_OFFSET + i * SQUARE_SIZE + SQUARE_SIZE / 2 - 4, BOARD_OFFSET + 8 * SQUARE_SIZE + 15),
			file_char, Color.black)
		var rank_str = str(8 - i)
		draw_string(coord_font,
			Vector2(BOARD_OFFSET - 18, BOARD_OFFSET + i * SQUARE_SIZE + SQUARE_SIZE / 2 + 4),
			rank_str, Color.black)

func _input(event):
	if game_over:
		if show_promotion_ui:
			return
		return
	
	if show_promotion_ui:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var click_pos = get_global_mouse_position() - rect_global_position
		
		if click_pos.x >= BOARD_OFFSET and click_pos.x < BOARD_OFFSET + BOARD_SIZE and \
		   click_pos.y >= BOARD_OFFSET and click_pos.y < BOARD_OFFSET + BOARD_SIZE:
			
			var screen_file = int((click_pos.x - BOARD_OFFSET) / SQUARE_SIZE)
			var screen_rank = int((click_pos.y - BOARD_OFFSET) / SQUARE_SIZE)
			var sq_idx = ChessBoard.coords_to_index(screen_file, screen_rank)
			
			handle_square_click(sq_idx)

func handle_square_click(sq_idx):
	var clicked_piece = board.get_piece_at(sq_idx)
	
	if selected_square == -1:
		if clicked_piece.type != ChessPiece.Type.NONE and clicked_piece.color == board.current_turn:
			selected_square = sq_idx
			var all_legal = board.generate_legal_moves(board.current_turn)
			legal_moves_for_selected.clear()
			for move in all_legal:
				if move.from == sq_idx:
					legal_moves_for_selected.append(move)
	else:
		if sq_idx == selected_square:
			selected_square = -1
			legal_moves_for_selected.clear()
		elif clicked_piece.type != ChessPiece.Type.NONE and clicked_piece.color == board.current_turn:
			selected_square = sq_idx
			var all_legal = board.generate_legal_moves(board.current_turn)
			legal_moves_for_selected.clear()
			for move in all_legal:
				if move.from == sq_idx:
					legal_moves_for_selected.append(move)
		else:
			var chosen_move = null
			for move in legal_moves_for_selected:
				if move.to == sq_idx:
					chosen_move = move
					break
			
			if chosen_move != null:
				if chosen_move.is_promotion >= 0:
					promotion_pending = chosen_move
					show_promotion_ui = true
					promotion_popup.visible = true
					promotion_square_index = sq_idx
				else:
					execute_move(chosen_move)
			else:
				selected_square = -1
				legal_moves_for_selected.clear()
	
	update()

func _on_promotion_chosen(promo_type):
	var move = promotion_pending
	move.is_promotion = promo_type
	
	show_promotion_ui = false
	promotion_popup.visible = false
	promotion_pending = {}
	
	execute_move(move)

func execute_move(move):
	last_move_from = move.from
	last_move_to = move.to
	board.make_move(move)
	selected_square = -1
	legal_moves_for_selected.clear()
	
	_check_game_end()
	
	redraw_board()
	update_status()

func _check_game_end():
	var current = board.current_turn
	if board.is_checkmate(current):
		game_over = true
		var winner = "Black" if current == ChessPiece.PieceColor.WHITE else "White"
		game_result = "Checkmate! " + winner + " wins!"
	elif board.is_stalemate(current):
		game_over = true
		game_result = "Stalemate! It's a draw."

func _on_new_game_pressed():
	new_game()
