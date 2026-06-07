class_name PGNParser
extends RefCounted

const PIECE_NAMES = {
	"P": "Pawn",
	"N": "Knight",
	"B": "Bishop",
	"R": "Rook",
	"Q": "Queen",
	"K": "King"
}

var _board: Dictionary = {}
var _turn := 0
var _castling := "KQkq"
var _en_passant := "-"
var _headers: Dictionary = {}

func parse(pgn: String) -> Dictionary:
	_headers = _parse_headers(pgn)
	var setup_error = _setup_position(str(_headers.get("FEN", "")))
	if setup_error != "":
		return {"ok": false, "error": setup_error}

	var tokens = _move_tokens(pgn)
	for index in tokens.size():
		var error = _apply_san(tokens[index])
		if error != "":
			return {
				"ok": false,
				"error": "Movimiento %d (%s): %s" % [index + 1, tokens[index], error]
			}

	return {
		"ok": true,
		"headers": _headers,
		"turn": _turn,
		"pieces": _export_pieces(),
		"moves": tokens.size()
	}

func _parse_headers(pgn: String) -> Dictionary:
	var headers := {}
	var regex = RegEx.new()
	regex.compile("\\[([A-Za-z0-9_]+)\\s+\"((?:\\\\.|[^\"])*)\"\\]")
	for result in regex.search_all(pgn):
		headers[result.get_string(1)] = result.get_string(2).replace("\\\"", "\"")
	return headers

func _setup_position(fen: String) -> String:
	_board.clear()
	if fen.is_empty():
		fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
	var fields = fen.split(" ")
	if fields.size() < 4:
		return "FEN inválido"
	var ranks = fields[0].split("/")
	if ranks.size() != 8:
		return "FEN inválido: deben existir 8 filas"
	for rank_index in 8:
		var file_index := 0
		for character in ranks[rank_index]:
			if character.is_valid_int():
				file_index += int(character)
				continue
			var upper = character.to_upper()
			if not PIECE_NAMES.has(upper) or file_index >= 8:
				return "FEN inválido"
			var square = char(97 + file_index) + str(8 - rank_index)
			_board[square] = {
				"type": upper,
				"color": 0 if character == upper else 1
			}
			file_index += 1
		if file_index != 8:
			return "FEN inválido: fila incompleta"
	_turn = 0 if fields[1] == "w" else 1
	_castling = fields[2]
	_en_passant = fields[3]
	return ""

func _move_tokens(pgn: String) -> Array[String]:
	var body = pgn
	var header_regex = RegEx.new()
	header_regex.compile("(?m)^\\s*\\[[^\\n]*\\]\\s*$")
	body = header_regex.sub(body, " ", true)

	var comment_regex = RegEx.new()
	comment_regex.compile("(?s)\\{.*?\\}")
	body = comment_regex.sub(body, " ", true)

	var line_comment_regex = RegEx.new()
	line_comment_regex.compile("(?m);[^\\n]*")
	body = line_comment_regex.sub(body, " ", true)
	body = _remove_variations(body)
	body = body.replace("\r", " ").replace("\n", " ").replace("\t", " ")

	var tokens: Array[String] = []
	for raw_token in body.split(" ", false):
		var token = raw_token.strip_edges()
		if token.is_empty() or token.begins_with("$") or token.to_lower() in ["e.p.", "ep"]:
			continue
		var move_number_regex = RegEx.new()
		move_number_regex.compile("^\\d+\\.(\\.\\.)?")
		token = move_number_regex.sub(token, "")
		if token.is_empty() or token in ["1-0", "0-1", "1/2-1/2", "*"]:
			continue
		tokens.append(token)
	return tokens

func _remove_variations(text: String) -> String:
	var result := ""
	var depth := 0
	for character in text:
		if character == "(":
			depth += 1
		elif character == ")":
			depth = maxi(0, depth - 1)
		elif depth == 0:
			result += character
	return result

func _apply_san(raw_san: String) -> String:
	var san = raw_san.replace("0-0-0", "O-O-O").replace("0-0", "O-O")
	while not san.is_empty() and san[-1] in ["+", "#", "!", "?"]:
		san = san.left(-1)

	if san in ["O-O", "O-O-O"]:
		return _apply_castle(san == "O-O")

	var regex = RegEx.new()
	regex.compile("^([KQRBN])?([a-h])?([1-8])?(x)?([a-h][1-8])(?:=([QRBN]))?$")
	var match = regex.search(san)
	if match == null:
		return "notación SAN no reconocida"

	var piece_type = match.get_string(1)
	if piece_type.is_empty():
		piece_type = "P"
	var file_hint = match.get_string(2)
	var rank_hint = match.get_string(3)
	var is_capture = not match.get_string(4).is_empty()
	var target = match.get_string(5)
	var promotion = match.get_string(6)

	var candidates: Array[String] = []
	for square in _board:
		var piece: Dictionary = _board[square]
		if piece.color != _turn or piece.type != piece_type:
			continue
		if not file_hint.is_empty() and square[0] != file_hint:
			continue
		if not rank_hint.is_empty() and square[1] != rank_hint:
			continue
		if _can_move(square, target, piece_type, is_capture) and _move_keeps_king_safe(square, target, promotion):
			candidates.append(square)

	if candidates.is_empty():
		return "no existe una pieza legal para ese movimiento"
	if candidates.size() > 1:
		return "movimiento ambiguo"

	_execute_move(candidates[0], target, promotion)
	_turn = 1 - _turn
	return ""

func _can_move(source: String, target: String, piece_type: String, is_capture: bool) -> bool:
	if source == target:
		return false
	var source_pos = _square_to_pos(source)
	var target_pos = _square_to_pos(target)
	var dx = target_pos.x - source_pos.x
	var dy = target_pos.y - source_pos.y
	var target_piece = _board.get(target, {})
	if not target_piece.is_empty() and target_piece.color == _turn:
		return false

	match piece_type:
		"P":
			var direction = 1 if _turn == 0 else -1
			var start_rank = 1 if _turn == 0 else 6
			if is_capture:
				return abs(dx) == 1 and dy == direction and (
					(not target_piece.is_empty() and target_piece.color != _turn)
					or target == _en_passant
				)
			if dx != 0 or not target_piece.is_empty():
				return false
			if dy == direction:
				return true
			if source_pos.y == start_rank and dy == direction * 2:
				return not _board.has(_pos_to_square(source_pos + Vector2i(0, direction)))
			return false
		"N":
			return Vector2i(abs(dx), abs(dy)) in [Vector2i(1, 2), Vector2i(2, 1)]
		"B":
			return abs(dx) == abs(dy) and _path_clear(source_pos, target_pos)
		"R":
			return (dx == 0 or dy == 0) and _path_clear(source_pos, target_pos)
		"Q":
			return (dx == 0 or dy == 0 or abs(dx) == abs(dy)) and _path_clear(source_pos, target_pos)
		"K":
			return abs(dx) <= 1 and abs(dy) <= 1
	return false

func _path_clear(source: Vector2i, target: Vector2i) -> bool:
	var step = Vector2i(signi(target.x - source.x), signi(target.y - source.y))
	var current = source + step
	while current != target:
		if _board.has(_pos_to_square(current)):
			return false
		current += step
	return true

func _move_keeps_king_safe(source: String, target: String, promotion: String) -> bool:
	var board_before = _board.duplicate(true)
	var castling_before = _castling
	var en_passant_before = _en_passant
	_execute_move(source, target, promotion)
	var safe = not _king_in_check(_turn)
	_board = board_before
	_castling = castling_before
	_en_passant = en_passant_before
	return safe

func _execute_move(source: String, target: String, promotion: String):
	var piece: Dictionary = _board[source]
	var source_pos = _square_to_pos(source)
	var target_pos = _square_to_pos(target)
	if piece.type == "P" and target == _en_passant and not _board.has(target):
		_board.erase(_pos_to_square(Vector2i(target_pos.x, source_pos.y)))

	_update_castling_rights(source, target)
	_board.erase(source)
	if not promotion.is_empty():
		piece.type = promotion
	_board[target] = piece

	_en_passant = "-"
	if piece.type == "P" and abs(target_pos.y - source_pos.y) == 2:
		_en_passant = _pos_to_square(Vector2i(source_pos.x, (source_pos.y + target_pos.y) / 2))

func _apply_castle(king_side: bool) -> String:
	var rank = "1" if _turn == 0 else "8"
	var right = ("K" if king_side else "Q") if _turn == 0 else ("k" if king_side else "q")
	if not _castling.contains(right):
		return "el enroque no está disponible"
	var king_source = "e" + rank
	var king_target = ("g" if king_side else "c") + rank
	var rook_source = ("h" if king_side else "a") + rank
	var rook_target = ("f" if king_side else "d") + rank
	if not _board.has(king_source) or not _board.has(rook_source):
		return "faltan piezas para enrocar"
	var through = [("f" if king_side else "d") + rank, king_target]
	for square in through:
		if _board.has(square) or _square_attacked(square, 1 - _turn):
			return "el enroque atraviesa una casilla ocupada o atacada"
	if not king_side and _board.has("b" + rank):
		return "el enroque largo está bloqueado"
	if _king_in_check(_turn):
		return "no se puede enrocar estando en jaque"
	_board[king_target] = _board[king_source]
	_board[rook_target] = _board[rook_source]
	_board.erase(king_source)
	_board.erase(rook_source)
	_update_castling_rights(king_source, king_target)
	_en_passant = "-"
	_turn = 1 - _turn
	return ""

func _king_in_check(color: int) -> bool:
	for square in _board:
		var piece: Dictionary = _board[square]
		if piece.color == color and piece.type == "K":
			return _square_attacked(square, 1 - color)
	return false

func _square_attacked(target: String, attacker_color: int) -> bool:
	var saved_turn = _turn
	_turn = attacker_color
	for source in _board:
		var piece: Dictionary = _board[source]
		if piece.color != attacker_color:
			continue
		if piece.type == "P":
			var source_pos = _square_to_pos(source)
			var target_pos = _square_to_pos(target)
			var direction = 1 if attacker_color == 0 else -1
			if abs(target_pos.x - source_pos.x) == 1 and target_pos.y - source_pos.y == direction:
				_turn = saved_turn
				return true
		elif _can_move(source, target, piece.type, not not _board.get(target, {}).is_empty()):
			_turn = saved_turn
			return true
	_turn = saved_turn
	return false

func _update_castling_rights(source: String, target: String):
	var squares = {
		"e1": "KQ", "h1": "K", "a1": "Q",
		"e8": "kq", "h8": "k", "a8": "q"
	}
	for square in [source, target]:
		for right in str(squares.get(square, "")):
			_castling = _castling.replace(right, "")

func _export_pieces() -> Array:
	var pieces = []
	for square in _board:
		var piece: Dictionary = _board[square]
		pieces.append({
			"square": square,
			"type": PIECE_NAMES[piece.type],
			"color": piece.color
		})
	return pieces

func _square_to_pos(square: String) -> Vector2i:
	return Vector2i(square.unicode_at(0) - 97, int(square.substr(1)) - 1)

func _pos_to_square(position: Vector2i) -> String:
	return char(97 + position.x) + str(position.y + 1)
