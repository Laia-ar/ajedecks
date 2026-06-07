class_name BlackKingAI
extends RefCounted

const BLACK := 1
const DIRECTIONS = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0),                    Vector2i(1, 0),
	Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
]

func choose_move(board) -> Dictionary:
	var source = _find_black_king(board)
	if source.is_empty():
		return {}

	var source_tile = board.Flow.get_node(source)
	var king = source_tile.get_child(0)
	var source_position = _parse_location(source)
	var legal_moves = []

	for direction in DIRECTIONS:
		var target_position = source_position + direction
		var target = str(target_position.x) + "-" + str(target_position.y)
		var target_tile = board.Flow.get_node_or_null(target)
		if target_tile == null or board.DestroyedTiles.has(target):
			continue
		if not board.CanReach(source, target, king):
			continue
		if target_tile.get_child_count() > 0 and target_tile.get_child(0).PieceColor == BLACK:
			continue
		if target_tile.get_child_count() > 0 and target_tile.get_child(0).name == "King":
			continue
		if not _is_legal_after_simulation(board, source_tile, target_tile, king):
			continue

		legal_moves.append({
			"from": source,
			"to": target,
			"is_capture": target_tile.get_child_count() > 0
		})

	if legal_moves.is_empty():
		return {}

	legal_moves.sort_custom(func(a, b): return int(a.is_capture) > int(b.is_capture))
	return legal_moves[0]

func _find_black_king(board) -> String:
	for tile in board.Flow.get_children():
		if tile.get_child_count() == 0:
			continue
		var piece = tile.get_child(0)
		if piece.name == "King" and piece.PieceColor == BLACK:
			return str(tile.name)
	return ""

func _is_legal_after_simulation(board, source_tile, target_tile, king) -> bool:
	var captured = null
	if target_tile.get_child_count() > 0:
		captured = target_tile.get_child(0)
		target_tile.remove_child(captured)

	source_tile.remove_child(king)
	target_tile.add_child(king)
	var remains_in_check = board._is_king_in_check_raw(BLACK)
	target_tile.remove_child(king)
	source_tile.add_child(king)

	if captured != null:
		target_tile.add_child(captured)

	return not remains_in_check

func _parse_location(location: String) -> Vector2i:
	var parts = location.split("-")
	return Vector2i(int(parts[0]), int(parts[1]))
