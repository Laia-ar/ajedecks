extends Control

onready var board = $CenterContainer/ChessBoard
onready var status_label = $VBoxContainer/StatusLabel
onready var reset_btn = $VBoxContainer/ResetButton
onready var flip_btn = $VBoxContainer/FlipButton
onready var ai_check = $VBoxContainer/AICheckBox

var ai_timer = null
var ai_enabled = false

func _ready():
	status_label.text = board.engine.get_game_state_text()
	board.connect("state_changed", self, "_on_state_changed")
	board.connect("move_made", self, "_on_move_made")
	
	ai_timer = Timer.new()
	ai_timer.wait_time = 0.5
	ai_timer.one_shot = true
	ai_timer.connect("timeout", self, "_on_ai_turn")
	add_child(ai_timer)

func _on_state_changed(text):
	status_label.text = text

func _on_ResetButton_pressed():
	board.reset_game()
	status_label.text = board.engine.get_game_state_text()

func _on_FlipButton_pressed():
	board.flip_board()

func _on_AICheckBox_toggled(button_pressed):
	ai_enabled = button_pressed
	if ai_enabled and board.engine.turn == "black" and board.engine.game_state == board.engine.GameState.PLAYING:
		ai_timer.start()

func _on_move_made():
	if ai_enabled and board.engine.turn == "black" and board.engine.game_state == board.engine.GameState.PLAYING:
		ai_timer.start()

func _on_ai_turn():
	if not ai_enabled or board.engine.turn != "black":
		return
	if board.engine.game_state != board.engine.GameState.PLAYING and board.engine.game_state != board.engine.GameState.CHECK:
		return

	var all_moves = []
	for pos in board.engine.board:
		if board.engine.get_color(board.engine.get_piece(pos)) == "black":
			var moves = board.engine.get_legal_moves(pos)
			for m in moves:
				all_moves.append({"from": pos, "to": m})

	if all_moves.size() > 0:
		# Simple AI: prioritize captures and checks, otherwise random
		var best_moves = []
		var capture_moves = []
		var other_moves = []
		
		for move in all_moves:
			if board.engine.board.has(move.to):
				capture_moves.append(move)
			else:
				other_moves.append(move)
		
		if capture_moves.size() > 0:
			best_moves = capture_moves
		else:
			best_moves = other_moves
		
		var chosen = best_moves[randi() % best_moves.size()]
		var promotion = "Q"
		if board.engine.get_type(board.engine.get_piece(chosen.from)) == "P" and (chosen.to.y == 0 or chosen.to.y == 7):
			promotion = "Q"
		
		board.engine.make_move(chosen.from, chosen.to, promotion)
		board.last_move_from = chosen.from
		board.last_move_to = chosen.to
		board.selected_square = null
		board.legal_moves = []
		board.update_display()
		status_label.text = board.engine.get_game_state_text()
