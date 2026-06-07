class_name BlackAI
extends RefCounted

const BLACK := 1

func choose_move(board) -> Dictionary:
	var legal_moves = collect_legal_moves(board, BLACK)
	if legal_moves.is_empty():
		return {}

	var captures = legal_moves.filter(func(move): return move.is_capture)
	var choices = captures if not captures.is_empty() else legal_moves
	return choices.pick_random()

func collect_legal_moves(board, color: int) -> Array:
	var saved_state = _save_board_selection(board)
	var legal_moves = []

	for source_tile in board.Flow.get_children():
		if source_tile.get_child_count() == 0:
			continue
		var piece = source_tile.get_child(0)
		if piece.PieceColor != color:
			continue

		var source = str(source_tile.name)
		board.SelectedNode = source
		board._update_location_vars(source)
		board.GetMovableAreas()

		for target in board.Areas.duplicate():
			var target_tile = board.Flow.get_node_or_null(target)
			if target_tile == null or board.DestroyedTiles.has(target):
				continue
			if target_tile.get_child_count() > 0:
				var target_piece = target_tile.get_child(0)
				if target_piece.PieceColor == color or target_piece.name == "King":
					continue
			if not _is_legal_after_simulation(board, source_tile, target_tile, piece, color):
				continue

			legal_moves.append({
				"from": source,
				"to": target,
				"piece_type": piece.name,
				"is_capture": target_tile.get_child_count() > 0
			})

	_restore_board_selection(board, saved_state)
	return legal_moves

func _is_legal_after_simulation(board, source_tile, target_tile, piece, color: int) -> bool:
	var captured = null
	if target_tile.get_child_count() > 0:
		captured = target_tile.get_child(0)
		target_tile.remove_child(captured)

	source_tile.remove_child(piece)
	target_tile.add_child(piece)
	var remains_in_check = board._is_king_in_check_raw(color)
	target_tile.remove_child(piece)
	source_tile.add_child(piece)

	if captured != null:
		target_tile.add_child(captured)

	return not remains_in_check

func _save_board_selection(board) -> Dictionary:
	return {
		"selected": board.SelectedNode,
		"areas": board.Areas.duplicate(),
		"special": board.SpecialArea.duplicate(),
		"x": board.LocationX,
		"y": board.LocationY,
		"xi": board.LocationXInt,
		"yi": board.LocationYInt
	}

func _restore_board_selection(board, state: Dictionary):
	board.SelectedNode = state.selected
	board.Areas = state.areas
	board.SpecialArea = state.special
	board.LocationX = state.x
	board.LocationY = state.y
	board.LocationXInt = state.xi
	board.LocationYInt = state.yi
