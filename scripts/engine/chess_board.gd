# chess_board.gd - Board state representation, move generation, and validation
class_name ChessBoard
extends Reference

# Board representation: 64-element array
var squares: Array = []
var current_turn: int = ChessPiece.PieceColor.WHITE

# Castling rights
var white_king_moved: bool = false
var black_king_moved: bool = false
var white_rook_a_moved: bool = false
var white_rook_h_moved: bool = false
var black_rook_a_moved: bool = false
var black_rook_h_moved: bool = false

# En passant target square (-1 if none)
var en_passant_target: int = -1

# Move history for undo
var move_history: Array = []

# ------------------- Coordinates -------------------

static func coords_to_index(file, rank):
	return rank * 8 + file

static func index_to_coords(index):
	return {"file": index % 8, "rank": index / 8}

static func is_inside(file, rank):
	return file >= 0 and file < 8 and rank >= 0 and rank < 8

static func square_name(index):
	var coords = index_to_coords(index)
	var file_char = char(97 + coords.file)
	var rank_str = str(8 - coords.rank)
	return file_char + rank_str

# ------------------- Initialization -------------------

func _init():
	reset()

func reset():
	squares.clear()
	for i in range(64):
		squares.append({"type": ChessPiece.Type.NONE, "color": -1})
	
	setup_default_position()
	current_turn = ChessPiece.PieceColor.WHITE
	en_passant_target = -1
	white_king_moved = false
	black_king_moved = false
	white_rook_a_moved = false
	white_rook_h_moved = false
	black_rook_a_moved = false
	black_rook_h_moved = false
	move_history.clear()

func setup_default_position():
	var piece_order = [
		ChessPiece.Type.ROOK,
		ChessPiece.Type.KNIGHT,
		ChessPiece.Type.BISHOP,
		ChessPiece.Type.QUEEN,
		ChessPiece.Type.KING,
		ChessPiece.Type.BISHOP,
		ChessPiece.Type.KNIGHT,
		ChessPiece.Type.ROOK,
	]
	
	for file in range(8):
		set_piece(file, 7, piece_order[file], ChessPiece.PieceColor.WHITE)
		set_piece(file, 6, ChessPiece.Type.PAWN, ChessPiece.PieceColor.WHITE)
		set_piece(file, 0, piece_order[file], ChessPiece.PieceColor.BLACK)
		set_piece(file, 1, ChessPiece.Type.PAWN, ChessPiece.PieceColor.BLACK)

func set_piece(file, rank, type, color):
	squares[coords_to_index(file, rank)] = {"type": type, "color": color}

func get_piece(file, rank):
	return squares[coords_to_index(file, rank)]

func get_piece_at(index):
	return squares[index]

func is_empty(file, rank):
	return squares[coords_to_index(file, rank)].type == ChessPiece.Type.NONE

func is_empty_at(index):
	return squares[index].type == ChessPiece.Type.NONE

func is_enemy_at(index, my_color):
	var p = squares[index]
	return p.type != ChessPiece.Type.NONE and p.color != my_color

# ------------------- Move Representation -------------------

static func create_move(from_idx, to_idx, piece_type, piece_color):
	return {
		"from": from_idx,
		"to": to_idx,
		"piece_type": piece_type,
		"piece_color": piece_color,
		"captured": null,
		"is_castle": null,
		"is_en_passant": false,
		"is_promotion": -1,
		"prev_en_passant_target": -1,
		"prev_castling": {},
	}

# ------------------- Move Generation -------------------

func generate_legal_moves(color):
	var moves = generate_pseudo_legal_moves(color)
	var legal = []
	for move in moves:
		var saved_state = save_state()
		make_move(move, false)
		if not is_in_check(color):
			legal.append(move)
		restore_state(saved_state)
	return legal

func generate_pseudo_legal_moves(color):
	var moves = []
	for idx in range(64):
		var piece = squares[idx]
		if piece.color != color:
			continue
		var coords = index_to_coords(idx)
		match piece.type:
			ChessPiece.Type.PAWN:
				_generate_pawn_moves(moves, idx, coords, color)
			ChessPiece.Type.KNIGHT:
				_generate_knight_moves(moves, idx, coords, color)
			ChessPiece.Type.BISHOP:
				_generate_sliding_moves(moves, idx, coords, color, [
					[1, 1], [1, -1], [-1, 1], [-1, -1]
				])
			ChessPiece.Type.ROOK:
				_generate_sliding_moves(moves, idx, coords, color, [
					[1, 0], [-1, 0], [0, 1], [0, -1]
				])
			ChessPiece.Type.QUEEN:
				_generate_sliding_moves(moves, idx, coords, color, [
					[1, 0], [-1, 0], [0, 1], [0, -1],
					[1, 1], [1, -1], [-1, 1], [-1, -1]
				])
			ChessPiece.Type.KING:
				_generate_king_moves(moves, idx, coords, color)
	return moves

func _generate_pawn_moves(moves, idx, coords, color):
	var direction = -1 if color == ChessPiece.PieceColor.WHITE else 1
	var start_rank = 6 if color == ChessPiece.PieceColor.WHITE else 1
	var promo_rank = 0 if color == ChessPiece.PieceColor.WHITE else 7
	
	# Single push
	var one_ahead = coords_to_index(coords.file, coords.rank + direction)
	if is_inside(coords.file, coords.rank + direction) and is_empty_at(one_ahead):
		if coords.rank + direction == promo_rank:
			for promo_type in [ChessPiece.Type.QUEEN, ChessPiece.Type.ROOK, ChessPiece.Type.BISHOP, ChessPiece.Type.KNIGHT]:
				var m = create_move(idx, one_ahead, ChessPiece.Type.PAWN, color)
				m.is_promotion = promo_type
				moves.append(m)
		else:
			moves.append(create_move(idx, one_ahead, ChessPiece.Type.PAWN, color))
		
		# Double push from starting rank
		var two_ahead = coords_to_index(coords.file, coords.rank + 2 * direction)
		if coords.rank == start_rank and is_empty_at(two_ahead):
			moves.append(create_move(idx, two_ahead, ChessPiece.Type.PAWN, color))
	
	# Captures
	for dc in [-1, 1]:
		var cf = coords.file + dc
		var cr = coords.rank + direction
		if not is_inside(cf, cr):
			continue
		var target_idx = coords_to_index(cf, cr)
		
		if is_enemy_at(target_idx, color):
			if cr == promo_rank:
				for promo_type in [ChessPiece.Type.QUEEN, ChessPiece.Type.ROOK, ChessPiece.Type.BISHOP, ChessPiece.Type.KNIGHT]:
					var m = create_move(idx, target_idx, ChessPiece.Type.PAWN, color)
					m.is_promotion = promo_type
					m.captured = squares[target_idx]
					moves.append(m)
			else:
				var m = create_move(idx, target_idx, ChessPiece.Type.PAWN, color)
				m.captured = squares[target_idx]
				moves.append(m)
		
		# En passant
		if target_idx == en_passant_target:
			var m = create_move(idx, target_idx, ChessPiece.Type.PAWN, color)
			m.is_en_passant = true
			var ep_capture_rank = cr - direction
			var ep_idx = coords_to_index(cf, ep_capture_rank)
			m.captured = squares[ep_idx]
			moves.append(m)

func _generate_knight_moves(moves, idx, coords, color):
	var offsets = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]]
	for off in offsets:
		var nf = coords.file + off[0]
		var nr = coords.rank + off[1]
		if not is_inside(nf, nr):
			continue
		var target = coords_to_index(nf, nr)
		if is_empty_at(target) or is_enemy_at(target, color):
			var m = create_move(idx, target, ChessPiece.Type.KNIGHT, color)
			if not is_empty_at(target):
				m.captured = squares[target]
			moves.append(m)

func _generate_sliding_moves(moves, idx, coords, color, directions):
	for dir in directions:
		var nf = coords.file + dir[0]
		var nr = coords.rank + dir[1]
		while is_inside(nf, nr):
			var target = coords_to_index(nf, nr)
			if is_empty_at(target):
				moves.append(create_move(idx, target, squares[idx].type, color))
			else:
				if is_enemy_at(target, color):
					var m = create_move(idx, target, squares[idx].type, color)
					m.captured = squares[target]
					moves.append(m)
				break
			nf += dir[0]
			nr += dir[1]

func _generate_king_moves(moves, idx, coords, color):
	var offsets = [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]]
	for off in offsets:
		var nf = coords.file + off[0]
		var nr = coords.rank + off[1]
		if not is_inside(nf, nr):
			continue
		var target = coords_to_index(nf, nr)
		if is_empty_at(target) or is_enemy_at(target, color):
			var m = create_move(idx, target, ChessPiece.Type.KING, color)
			if not is_empty_at(target):
				m.captured = squares[target]
			moves.append(m)
	
	# Castling
	var back_rank = 7 if color == ChessPiece.PieceColor.WHITE else 0
	var king_moved = white_king_moved if color == ChessPiece.PieceColor.WHITE else black_king_moved
	var rook_a_moved = white_rook_a_moved if color == ChessPiece.PieceColor.WHITE else black_rook_a_moved
	var rook_h_moved = white_rook_h_moved if color == ChessPiece.PieceColor.WHITE else black_rook_h_moved
	
	if king_moved:
		return
	
	if is_square_attacked(idx, ChessPiece.opposite_color(color)):
		return
	
	# Kingside castling
	var kingside_rook_idx = coords_to_index(7, back_rank)
	var kingside_rook = squares[kingside_rook_idx]
	if not rook_h_moved and kingside_rook.type == ChessPiece.Type.ROOK and kingside_rook.color == color:
		var f1 = coords_to_index(5, back_rank)
		var g1 = coords_to_index(6, back_rank)
		if is_empty_at(f1) and is_empty_at(g1):
			if not is_square_attacked(f1, ChessPiece.opposite_color(color)) and not is_square_attacked(g1, ChessPiece.opposite_color(color)):
				var m = create_move(idx, g1, ChessPiece.Type.KING, color)
				m.is_castle = {"type": "kingside", "rook_from": kingside_rook_idx, "rook_to": f1}
				moves.append(m)
	
	# Queenside castling
	var queenside_rook_idx = coords_to_index(0, back_rank)
	var queenside_rook = squares[queenside_rook_idx]
	if not rook_a_moved and queenside_rook.type == ChessPiece.Type.ROOK and queenside_rook.color == color:
		var d1 = coords_to_index(3, back_rank)
		var c1 = coords_to_index(2, back_rank)
		var b1 = coords_to_index(1, back_rank)
		if is_empty_at(d1) and is_empty_at(c1) and is_empty_at(b1):
			if not is_square_attacked(d1, ChessPiece.opposite_color(color)) and not is_square_attacked(c1, ChessPiece.opposite_color(color)):
				var m = create_move(idx, c1, ChessPiece.Type.KING, color)
				m.is_castle = {"type": "queenside", "rook_from": queenside_rook_idx, "rook_to": d1}
				moves.append(m)

# ------------------- Attack Detection -------------------

func is_square_attacked(index, by_color):
	var coords = index_to_coords(index)
	
	# Check pawn attacks
	var pawn_dir = 1 if by_color == ChessPiece.PieceColor.WHITE else -1
	for dc in [-1, 1]:
		var pf = coords.file + dc
		var pr = coords.rank + pawn_dir
		if is_inside(pf, pr):
			var p = get_piece(pf, pr)
			if p.type == ChessPiece.Type.PAWN and p.color == by_color:
				return true
	
	# Check knight attacks
	var knight_offsets = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]]
	for off in knight_offsets:
		var nf = coords.file + off[0]
		var nr = coords.rank + off[1]
		if is_inside(nf, nr):
			var p = get_piece(nf, nr)
			if p.type == ChessPiece.Type.KNIGHT and p.color == by_color:
				return true
	
	# Check king attacks
	var king_offsets = [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]]
	for off in king_offsets:
		var nf = coords.file + off[0]
		var nr = coords.rank + off[1]
		if is_inside(nf, nr):
			var p = get_piece(nf, nr)
			if p.type == ChessPiece.Type.KING and p.color == by_color:
				return true
	
	# Check diagonals (bishop/queen)
	for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
		var nf = coords.file + dir[0]
		var nr = coords.rank + dir[1]
		while is_inside(nf, nr):
			var p = get_piece(nf, nr)
			if p.type != ChessPiece.Type.NONE:
				if p.color == by_color and (p.type == ChessPiece.Type.BISHOP or p.type == ChessPiece.Type.QUEEN):
					return true
				break
			nf += dir[0]
			nr += dir[1]
	
	# Check orthogonals (rook/queen)
	for dir in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var nf = coords.file + dir[0]
		var nr = coords.rank + dir[1]
		while is_inside(nf, nr):
			var p = get_piece(nf, nr)
			if p.type != ChessPiece.Type.NONE:
				if p.color == by_color and (p.type == ChessPiece.Type.ROOK or p.type == ChessPiece.Type.QUEEN):
					return true
				break
			nf += dir[0]
			nr += dir[1]
	
	return false

# ------------------- Check / Checkmate / Stalemate -------------------

func is_in_check(color):
	var king_pos = find_king(color)
	if king_pos == -1:
		return false
	return is_square_attacked(king_pos, ChessPiece.opposite_color(color))

func find_king(color):
	for i in range(64):
		var p = squares[i]
		if p.type == ChessPiece.Type.KING and p.color == color:
			return i
	return -1

func is_checkmate(color):
	return is_in_check(color) and generate_legal_moves(color).empty()

func is_stalemate(color):
	return not is_in_check(color) and generate_legal_moves(color).empty()

# ------------------- Make / Unmake Move -------------------

func save_state():
	return {
		"squares": squares.duplicate(true),
		"current_turn": current_turn,
		"en_passant_target": en_passant_target,
		"white_king_moved": white_king_moved,
		"black_king_moved": black_king_moved,
		"white_rook_a_moved": white_rook_a_moved,
		"white_rook_h_moved": white_rook_h_moved,
		"black_rook_a_moved": black_rook_a_moved,
		"black_rook_h_moved": black_rook_h_moved,
		"move_history": move_history.duplicate(),
	}

func restore_state(state):
	squares = state.squares
	current_turn = state.current_turn
	en_passant_target = state.en_passant_target
	white_king_moved = state.white_king_moved
	black_king_moved = state.black_king_moved
	white_rook_a_moved = state.white_rook_a_moved
	white_rook_h_moved = state.white_rook_h_moved
	black_rook_a_moved = state.black_rook_a_moved
	black_rook_h_moved = state.black_rook_h_moved
	move_history = state.move_history

func make_move(move, switch_turn = true):
	move.prev_en_passant_target = en_passant_target
	move.prev_castling = {
		"white_king_moved": white_king_moved,
		"black_king_moved": black_king_moved,
		"white_rook_a_moved": white_rook_a_moved,
		"white_rook_h_moved": white_rook_h_moved,
		"black_rook_a_moved": black_rook_a_moved,
		"black_rook_h_moved": black_rook_h_moved,
	}
	
	var piece = squares[move.from]
	squares[move.to] = piece.duplicate()
	squares[move.from] = {"type": ChessPiece.Type.NONE, "color": -1}
	
	en_passant_target = -1
	if move.is_en_passant:
		var ep_capture_rank = move.from / 8
		var ep_capture_file = move.to % 8
		var ep_idx = coords_to_index(ep_capture_file, ep_capture_rank)
		squares[ep_idx] = {"type": ChessPiece.Type.NONE, "color": -1}
	
	if move.is_castle != null:
		var rook = squares[move.is_castle.rook_from].duplicate()
		squares[move.is_castle.rook_to] = rook
		squares[move.is_castle.rook_from] = {"type": ChessPiece.Type.NONE, "color": -1}
	
	if move.is_promotion >= 0:
		squares[move.to].type = move.is_promotion
	
	if piece.type == ChessPiece.Type.PAWN and abs(move.to - move.from) == 16:
		en_passant_target = (move.from + move.to) / 2
	
	if piece.type == ChessPiece.Type.KING:
		if piece.color == ChessPiece.PieceColor.WHITE:
			white_king_moved = true
		else:
			black_king_moved = true
	elif piece.type == ChessPiece.Type.ROOK:
		var from_coords = index_to_coords(move.from)
		if piece.color == ChessPiece.PieceColor.WHITE and from_coords.rank == 7:
			if from_coords.file == 0:
				white_rook_a_moved = true
			elif from_coords.file == 7:
				white_rook_h_moved = true
		elif piece.color == ChessPiece.PieceColor.BLACK and from_coords.rank == 0:
			if from_coords.file == 0:
				black_rook_a_moved = true
			elif from_coords.file == 7:
				black_rook_h_moved = true
	
	if move.captured != null and move.captured.type == ChessPiece.Type.ROOK:
		var to_coords = index_to_coords(move.to)
		if move.captured.color == ChessPiece.PieceColor.WHITE and to_coords.rank == 7:
			if to_coords.file == 0:
				white_rook_a_moved = true
			elif to_coords.file == 7:
				white_rook_h_moved = true
		elif move.captured.color == ChessPiece.PieceColor.BLACK and to_coords.rank == 0:
			if to_coords.file == 0:
				black_rook_a_moved = true
			elif to_coords.file == 7:
				black_rook_h_moved = true
	
	move_history.append(move)
	
	if switch_turn:
		current_turn = ChessPiece.opposite_color(current_turn)

func unmake_move(move):
	var piece = squares[move.to]
	squares[move.from] = piece.duplicate()
	
	if move.is_promotion >= 0:
		squares[move.from].type = ChessPiece.Type.PAWN
	
	if move.captured != null:
		if move.is_en_passant:
			var ep_capture_rank = move.from / 8
			var ep_capture_file = move.to % 8
			var ep_idx = coords_to_index(ep_capture_file, ep_capture_rank)
			squares[ep_idx] = move.captured.duplicate()
		else:
			squares[move.to] = move.captured.duplicate()
	else:
		squares[move.to] = {"type": ChessPiece.Type.NONE, "color": -1}
	
	if move.is_castle != null:
		var rook = squares[move.is_castle.rook_to]
		squares[move.is_castle.rook_from] = rook.duplicate()
		squares[move.is_castle.rook_to] = {"type": ChessPiece.Type.NONE, "color": -1}
	
	en_passant_target = move.prev_en_passant_target
	white_king_moved = move.prev_castling.white_king_moved
	black_king_moved = move.prev_castling.black_king_moved
	white_rook_a_moved = move.prev_castling.white_rook_a_moved
	white_rook_h_moved = move.prev_castling.white_rook_h_moved
	black_rook_a_moved = move.prev_castling.black_rook_a_moved
	black_rook_h_moved = move.prev_castling.black_rook_h_moved
	
	if not move_history.empty():
		move_history.pop_back()
	
	current_turn = ChessPiece.opposite_color(current_turn)