extends Node
class_name ChessEngine

# Board: Dictionary with Vector2 keys (x:0-7 a-h, y:0-7 rank 8-1)
# Values: "wP", "wR", "wN", "wB", "wQ", "wK", "bP", "bR", "bN", "bB", "bQ", "bK"
var board := {}
var turn := "white"
var move_history := []
var halfmove_clock := 0
var fullmove_number := 1

var castling := {
	"white_kingside": true,
	"white_queenside": true,
	"black_kingside": true,
	"black_queenside": true
}

var en_passant_target = null

enum GameState { PLAYING, CHECK, CHECKMATE, STALE_DRAW, INSUFFICIENT }
var game_state = GameState.PLAYING

func _ready():
	reset_board()

func reset_board():
	board.clear()
	move_history.clear()
	turn = "white"
	halfmove_clock = 0
	fullmove_number = 1
	castling = {
		"white_kingside": true,
		"white_queenside": true,
		"black_kingside": true,
		"black_queenside": true
	}
	en_passant_target = null
	game_state = GameState.PLAYING

	var back_rank = ["R", "N", "B", "Q", "K", "B", "N", "R"]
	for x in range(8):
		board[Vector2(x, 0)] = "b" + back_rank[x]
		board[Vector2(x, 1)] = "bP"
		board[Vector2(x, 6)] = "wP"
		board[Vector2(x, 7)] = "w" + back_rank[x]

	update_game_state()

func get_piece(pos: Vector2) -> String:
	return board.get(pos, "")

func get_color(piece: String) -> String:
	if piece == "":
		return ""
	return "white" if piece[0] == 'w' else "black"

func get_type(piece: String) -> String:
	if piece == "":
		return ""
	return piece[1]

func is_valid_pos(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func get_king_pos(color: String) -> Vector2:
	var king = "wK" if color == "white" else "bK"
	for pos in board:
		if board[pos] == king:
			return pos
	return Vector2(-1, -1)

func is_square_attacked(pos: Vector2, by_color: String) -> bool:
	return is_square_attacked_with_board(pos, by_color, board)

func is_square_attacked_with_board(pos: Vector2, by_color: String, b: Dictionary) -> bool:
	for p in b:
		var piece = b[p]
		if get_color(piece) != by_color:
			continue
		var pt = get_type(piece)

		if pt == "P":
			var dir = 1 if by_color == "black" else -1
			if abs(p.x - pos.x) == 1 and pos.y == p.y + dir:
				return true
			continue

		if pt == "N":
			var dx = abs(p.x - pos.x)
			var dy = abs(p.y - pos.y)
			if dx * dy == 2 and dx + dy == 3:
				return true
			continue

		if pt == "K":
			if abs(p.x - pos.x) <= 1 and abs(p.y - pos.y) <= 1:
				return true
			continue

		var dx = pos.x - p.x
		var dy = pos.y - p.y
		var adx = abs(dx)
		var ady = abs(dy)

		if pt == "R" and (dx == 0 or dy == 0):
			if is_path_clear_with_board(p, pos, b):
				return true
		elif pt == "B" and adx == ady:
			if is_path_clear_with_board(p, pos, b):
				return true
		elif pt == "Q" and (dx == 0 or dy == 0 or adx == ady):
			if is_path_clear_with_board(p, pos, b):
				return true

	return false

func is_path_clear(from: Vector2, to: Vector2) -> bool:
	return is_path_clear_with_board(from, to, board)

func is_path_clear_with_board(from: Vector2, to: Vector2, b: Dictionary) -> bool:
	var dx = sign(to.x - from.x)
	var dy = sign(to.y - from.y)
	var pos = from + Vector2(dx, dy)
	while pos != to:
		if b.has(pos):
			return false
		pos += Vector2(dx, dy)
	return true

func get_pseudo_legal_moves(from: Vector2) -> Array:
	var piece = get_piece(from)
	if piece == "":
		return []

	var color = get_color(piece)
	var pt = get_type(piece)
	var moves = []

	match pt:
		"P":
			var dir = -1 if color == "white" else 1
			var start_rank = 6 if color == "white" else 1

			var one = from + Vector2(0, dir)
			if is_valid_pos(one) and not board.has(one):
				moves.append(one)
				var two = from + Vector2(0, dir * 2)
				if from.y == start_rank and not board.has(two):
					moves.append(two)

			for dx in [-1, 1]:
				var cap = from + Vector2(dx, dir)
				if is_valid_pos(cap):
					if cap == en_passant_target:
						moves.append(cap)
					elif board.has(cap) and get_color(get_piece(cap)) != color:
						moves.append(cap)

		"N":
			var offsets = [
				Vector2(1, 2), Vector2(2, 1), Vector2(2, -1), Vector2(1, -2),
				Vector2(-1, -2), Vector2(-2, -1), Vector2(-2, 1), Vector2(-1, 2)
			]
			for o in offsets:
				var to = from + o
				if is_valid_pos(to) and get_color(get_piece(to)) != color:
					moves.append(to)

		"K":
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var to = from + Vector2(dx, dy)
					if is_valid_pos(to) and get_color(get_piece(to)) != color:
						moves.append(to)

			var opp = "black" if color == "white" else "white"
			if color == "white" and from == Vector2(4, 7):
				if castling.white_kingside and not board.has(Vector2(5, 7)) and not board.has(Vector2(6, 7)):
					if not is_square_attacked(from, opp) and not is_square_attacked(Vector2(5, 7), opp) and not is_square_attacked(Vector2(6, 7), opp):
						moves.append(Vector2(6, 7))
				if castling.white_queenside and not board.has(Vector2(3, 7)) and not board.has(Vector2(2, 7)) and not board.has(Vector2(1, 7)):
					if not is_square_attacked(from, opp) and not is_square_attacked(Vector2(3, 7), opp) and not is_square_attacked(Vector2(2, 7), opp):
						moves.append(Vector2(2, 7))
			elif color == "black" and from == Vector2(4, 0):
				if castling.black_kingside and not board.has(Vector2(5, 0)) and not board.has(Vector2(6, 0)):
					if not is_square_attacked(from, opp) and not is_square_attacked(Vector2(5, 0), opp) and not is_square_attacked(Vector2(6, 0), opp):
						moves.append(Vector2(6, 0))
				if castling.black_queenside and not board.has(Vector2(3, 0)) and not board.has(Vector2(2, 0)) and not board.has(Vector2(1, 0)):
					if not is_square_attacked(from, opp) and not is_square_attacked(Vector2(3, 0), opp) and not is_square_attacked(Vector2(2, 0), opp):
						moves.append(Vector2(2, 0))

		"R", "B", "Q":
			var directions = []
			if pt == "R" or pt == "Q":
				directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
			if pt == "B" or pt == "Q":
				directions.append_array([Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)])

			for d in directions:
				var to = from + d
				while is_valid_pos(to):
					var target = get_piece(to)
					if target == "":
						moves.append(to)
					elif get_color(target) != color:
						moves.append(to)
						break
					else:
						break
					to += d

	return moves

func get_legal_moves(from: Vector2) -> Array:
	var piece = get_piece(from)
	if piece == "" or get_color(piece) != turn:
		return []

	var pseudo = get_pseudo_legal_moves(from)
	var legal = []
	var color = get_color(piece)

	for to in pseudo:
		if is_move_legal(from, to, color):
			legal.append(to)

	return legal

func is_move_legal(from: Vector2, to: Vector2, color: String) -> bool:
	var temp_board = board.duplicate()
	var piece = temp_board[from]

	temp_board.erase(from)
	temp_board[to] = piece

	if get_type(piece) == "P" and to == en_passant_target:
		temp_board.erase(Vector2(to.x, from.y))

	var king_pos = Vector2(-1, -1)
	var king_piece = "wK" if color == "white" else "bK"
	for pos in temp_board:
		if temp_board[pos] == king_piece:
			king_pos = pos
			break

	var opponent = "black" if color == "white" else "white"
	return not is_square_attacked_with_board(king_pos, opponent, temp_board)

func make_move(from: Vector2, to: Vector2, promotion_piece: String = "Q") -> bool:
	var piece = get_piece(from)
	if piece == "" or get_color(piece) != turn:
		return false

	var legal = get_legal_moves(from)
	if not to in legal:
		return false

	var pt = get_type(piece)
	var color = get_color(piece)
	var captured = board.get(to)

	if pt == "P" or captured != null:
		halfmove_clock = 0
	else:
		halfmove_clock += 1

	board.erase(from)

	if pt == "P" and (to.y == 0 or to.y == 7):
		board[to] = color[0] + promotion_piece
	else:
		board[to] = piece

	var ep_captured = null
	if pt == "P" and to == en_passant_target:
		ep_captured = board.get(Vector2(to.x, from.y))
		board.erase(Vector2(to.x, from.y))

	if pt == "P" and abs(to.y - from.y) == 2:
		en_passant_target = Vector2(from.x, (from.y + to.y) / 2)
	else:
		en_passant_target = null

	if pt == "K":
		if color == "white":
			castling.white_kingside = false
			castling.white_queenside = false
		else:
			castling.black_kingside = false
			castling.black_queenside = false
	elif pt == "R":
		if from == Vector2(0, 7):
			castling.white_queenside = false
		elif from == Vector2(7, 7):
			castling.white_kingside = false
		elif from == Vector2(0, 0):
			castling.black_queenside = false
		elif from == Vector2(7, 0):
			castling.black_kingside = false

	if captured and get_type(captured) == "R":
		if to == Vector2(0, 7):
			castling.white_queenside = false
		elif to == Vector2(7, 7):
			castling.white_kingside = false
		elif to == Vector2(0, 0):
			castling.black_queenside = false
		elif to == Vector2(7, 0):
			castling.black_kingside = false

	if pt == "K" and abs(to.x - from.x) == 2:
		if to.x == 6:
			board[Vector2(5, to.y)] = board[Vector2(7, to.y)]
			board.erase(Vector2(7, to.y))
		elif to.x == 2:
			board[Vector2(3, to.y)] = board[Vector2(0, to.y)]
			board.erase(Vector2(0, to.y))

	move_history.append({
		"from": from,
		"to": to,
		"piece": piece,
		"captured": captured,
		"ep_captured": ep_captured,
		"en_passant_target": en_passant_target,
		"castling": castling.duplicate()
	})

	turn = "black" if turn == "white" else "white"
	if turn == "white":
		fullmove_number += 1

	update_game_state()
	return true

func update_game_state():
	if halfmove_clock >= 100:
		game_state = GameState.STALE_DRAW
		return

	var color = turn
	var opponent = "black" if color == "white" else "white"
	var king_pos = get_king_pos(color)
	var in_check = is_square_attacked(king_pos, opponent)

	var has_moves = false
	for pos in board:
		if get_color(get_piece(pos)) == color:
			if get_legal_moves(pos).size() > 0:
				has_moves = true
				break

	if not has_moves:
		if in_check:
			game_state = GameState.CHECKMATE
		else:
			game_state = GameState.STALE_DRAW
	elif in_check:
		game_state = GameState.CHECK
	else:
		game_state = GameState.PLAYING

	if (game_state == GameState.PLAYING or game_state == GameState.CHECK) and is_insufficient_material():
		game_state = GameState.INSUFFICIENT

func is_insufficient_material() -> bool:
	var bishops = {"white": [], "black": []}
	var has_other = false
	var knights = 0

	for pos in board:
		var piece = board[pos]
		var pt = get_type(piece)
		var color = get_color(piece)
		if pt == "K":
			continue
		elif pt == "B":
			bishops[color].append((int(pos.x) + int(pos.y)) % 2)
		elif pt == "N":
			knights += 1
		else:
			has_other = true
			break

	if has_other:
		return false

	var num_minor = knights + bishops.white.size() + bishops.black.size()

	if num_minor == 0:
		return true

	if num_minor == 1:
		return true

	if num_minor == 2 and knights == 0:
		if bishops.white.size() == 1 and bishops.black.size() == 1:
			if bishops.white[0] == bishops.black[0]:
				return true
		if bishops.white.size() == 2 and bishops.white[0] == bishops.white[1]:
			return true
		if bishops.black.size() == 2 and bishops.black[0] == bishops.black[1]:
			return true

	return false

func get_game_state_text() -> String:
	match game_state:
		GameState.PLAYING:
			return turn.capitalize() + "'s turn"
		GameState.CHECK:
			return "Check! " + turn.capitalize() + "'s turn"
		GameState.CHECKMATE:
			var winner = "White" if turn == "black" else "Black"
			return "Checkmate! " + winner + " wins!"
		GameState.STALE_DRAW:
			return "Draw by stalemate / 50-move rule!"
		GameState.INSUFFICIENT:
			return "Draw by insufficient material!"
	return ""
