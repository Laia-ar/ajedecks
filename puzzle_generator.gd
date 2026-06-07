extends Button

# ============================================================
# Generador de puzzles 3x3 con mecánica de tiles
# - Rey negro quieto (objetivo)
# - 1 o 2 piezas blancas atacantes
# - El puzzle DEBE requerir agregar/quitar tiles para resolverse
# ============================================================

@export var BoardPath: NodePath
@onready var Board = get_node(BoardPath)

# El puzzle ocupa un cuadrado 3x3 dentro del tablero grande.
# Definí acá en qué offset del tablero 20x20 lo querés centrado.
@export var OffsetX: int = 8
@export var OffsetY: int = 8

# Cuántas acciones de tile tiene el jugador para resolver
const TILE_ACTIONS: int = 2
# Profundidad máxima de búsqueda (turnos del jugador)
const MAX_TURNS: int = 3
# Piezas candidatas (la dama queda afuera por dominante en 3x3)
const PIECE_TYPES = ["Rook", "Bishop", "Knight"]

func _ready():
	text = "Generar puzzle 3x3"
	tooltip_text = "Generar un puzzle experimental de tiles"
	pressed.connect(_on_pressed)

func _on_pressed():
	var puzzle = _generate_until_valid(2000)
	if puzzle == null:
		print("No se encontró un puzzle válido (subí los intentos)")
		return
	_load_puzzle(puzzle)

# ============================================================
# COORDENADAS LOCALES (0..2) <-> GLOBALES (offset)
# El solver trabaja en coordenadas locales 0-0 a 2-2.
# Al cargar, se traducen al tablero real con el offset.
# ============================================================

func _local_to_global(loc: String) -> String:
	var p = loc.split("-")
	return str(int(p[0]) + OffsetX) + "-" + str(int(p[1]) + OffsetY)

# ============================================================
# MODELO DE ESTADO (abstracto, no usa nodos)
# state = {
#   "tiles": { "x-y": true, ... },     # tiles activas
#   "white": [ {"pos": "x-y", "type": "Rook"}, ... ],
#   "king": "x-y",
#   "tile_left": int                    # acciones de tile restantes
# }
# ============================================================

func _all_cells() -> Array:
	var cells = []
	for x in range(3):
		for y in range(3):
			cells.append(str(x) + "-" + str(y))
	return cells

func _clone_state(s: Dictionary) -> Dictionary:
	var nw = []
	for p in s.white:
		nw.append({"pos": p.pos, "type": p.type})
	return {
		"tiles": s.tiles.duplicate(),
		"white": nw,
		"king": s.king,
		"tile_left": s.tile_left
	}

# ============================================================
# MOVIMIENTOS LEGALES de una pieza blanca, sobre el set de tiles dado.
# Devuelve un array de casillas destino "x-y".
# ============================================================

func _piece_moves(piece: Dictionary, tiles: Dictionary, others: Array) -> Array:
	var moves = []
	var parts = piece.pos.split("-")
	var px = int(parts[0])
	var py = int(parts[1])
	
	match piece.type:
		"Rook":
			moves += _slide(px, py, tiles, others, [[1,0],[-1,0],[0,1],[0,-1]])
		"Bishop":
			moves += _slide(px, py, tiles, others, [[1,1],[-1,1],[1,-1],[-1,-1]])
		"Knight":
			var jumps = [[1,2],[2,1],[-1,2],[-2,1],[1,-2],[2,-1],[-1,-2],[-2,-1]]
			for j in jumps:
				var nx = px + j[0]
				var ny = py + j[1]
				var loc = str(nx) + "-" + str(ny)
				if _in_bounds(nx, ny) and tiles.has(loc) and not _occupied_by_white(loc, others):
					moves.append(loc)
	return moves

func _slide(px: int, py: int, tiles: Dictionary, others: Array, dirs: Array) -> Array:
	var result = []
	for d in dirs:
		var step = 1
		while true:
			var nx = px + d[0] * step
			var ny = py + d[1] * step
			var loc = str(nx) + "-" + str(ny)
			if not _in_bounds(nx, ny):
				break
			if not tiles.has(loc):
				break  # tile faltante bloquea la línea
			if _occupied_by_white(loc, others):
				break  # no se puede capturar pieza propia ni pasar por ella
			result.append(loc)
			step += 1
	return result

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < 3 and y >= 0 and y < 3

func _occupied_by_white(loc: String, others: Array) -> bool:
	for p in others:
		if p.pos == loc:
			return true
	return false

# ============================================================
# GENERAR ACCIONES DEL JUGADOR desde un estado.
# Cada acción es un diccionario que describe qué hacer.
# Tipos de acción:
#   {"tile_op": "none"/"add"/"remove", "tile_at": "x-y", "move_piece": idx, "move_to": "x-y", "order": "tile_first"/"move_first"}
# Para mantenerlo manejable, generamos: solo-mover, y tile+mover en ambos órdenes.
# allow_tiles=false desactiva las acciones de tile (para el filtro).
# ============================================================

func _player_actions(s: Dictionary, allow_tiles: bool) -> Array:
	var actions = []
	
	# 1) Solo mover (sin tocar tile)
	for i in range(s.white.size()):
		var others = _others(s.white, i)
		for dest in _piece_moves(s.white[i], s.tiles, others):
			actions.append({"tile_op": "none", "move_piece": i, "move_to": dest})
	
	if not allow_tiles or s.tile_left <= 0:
		return actions
	
	# 2) Tile primero, después mover
	for cell in _all_cells():
		# Agregar tile donde no hay
		if not s.tiles.has(cell):
			var s2 = _clone_state(s)
			s2.tiles[cell] = true
			for i in range(s2.white.size()):
				var others = _others(s2.white, i)
				for dest in _piece_moves(s2.white[i], s2.tiles, others):
					actions.append({"tile_op": "add", "tile_at": cell, "move_piece": i, "move_to": dest, "order": "tile_first"})
		# Quitar tile (si no tiene pieza ni rey encima)
		elif _can_remove_tile(s, cell):
			var s2 = _clone_state(s)
			s2.tiles.erase(cell)
			for i in range(s2.white.size()):
				var others = _others(s2.white, i)
				for dest in _piece_moves(s2.white[i], s2.tiles, others):
					actions.append({"tile_op": "remove", "tile_at": cell, "move_piece": i, "move_to": dest, "order": "tile_first"})
	
	# 3) Mover primero, después tile (la tile no afecta este movimiento,
	#    pero puede cambiar el tablero para turnos futuros / cortar huida del rey).
	#    Como el rey está quieto, mover-luego-tile rara vez aporta algo distinto a solo-mover,
	#    así que lo omitimos para acotar el árbol. (Se puede agregar si se hace mover al rey.)
	
	return actions

func _others(white: Array, exclude_idx: int) -> Array:
	var result = []
	for i in range(white.size()):
		if i != exclude_idx:
			result.append(white[i])
	return result

func _can_remove_tile(s: Dictionary, cell: String) -> bool:
	if not s.tiles.has(cell):
		return false
	if cell == s.king:
		return false
	for p in s.white:
		if p.pos == cell:
			return false
	return true

# ============================================================
# APLICAR una acción del jugador. Devuelve [nuevo_estado, capturo_rey].
# ============================================================

func _apply(s: Dictionary, a: Dictionary) -> Array:
	var ns = _clone_state(s)
	# Aplicar tile (siempre es tile_first en nuestra generación)
	if a.tile_op == "add":
		ns.tiles[a.tile_at] = true
		ns.tile_left -= 1
	elif a.tile_op == "remove":
		ns.tiles.erase(a.tile_at)
		ns.tile_left -= 1
	# Mover la pieza
	var dest = a.move_to
	ns.white[a.move_piece].pos = dest
	# Captura?
	var captured = (dest == ns.king)
	return [ns, captured]

# ============================================================
# SOLVER (rey quieto): ¿captura en <= turns turnos?
# Devuelve true/false. Con rey quieto es búsqueda simple (solo MAX).
# ============================================================

func _state_key(s: Dictionary) -> String:
	var wkeys = []
	for p in s.white:
		wkeys.append(p.type + "@" + p.pos)
	wkeys.sort()
	var tkeys = s.tiles.keys()
	tkeys.sort()
	return "|".join(tkeys) + "##" + "|".join(wkeys) + "##K" + s.king + "##" + str(s.tile_left)

func _can_capture(s: Dictionary, turns: int, allow_tiles: bool, memo: Dictionary) -> bool:
	if turns <= 0:
		return false
	var key = _state_key(s) + "##t" + str(turns) + "##a" + str(allow_tiles)
	if memo.has(key):
		return memo[key]
	
	for a in _player_actions(s, allow_tiles):
		var res = _apply(s, a)
		var ns = res[0]
		var captured = res[1]
		if captured:
			memo[key] = true
			return true
		# rey quieto: simplemente seguimos con un turno menos
		if _can_capture(ns, turns - 1, allow_tiles, memo):
			memo[key] = true
			return true
	
	memo[key] = false
	return false

# ============================================================
# GENERADOR DE CANDIDATOS
# ============================================================

func _random_candidate() -> Dictionary:
	var cells = _all_cells()
	cells.shuffle()
	
	# Cuántas tiles activas iniciales (entre 4 y 8, dejamos al menos 1 hueco)
	var n_tiles = randi_range(4, 8)
	var tiles = {}
	for i in range(n_tiles):
		tiles[cells[i]] = true
	
	var active = tiles.keys()
	active.shuffle()
	
	# Rey en una tile activa
	var king = active[0]
	
	# 1 o 2 piezas blancas en tiles activas distintas
	var n_white = randi_range(1, 2)
	var white = []
	var used = [king]
	for i in range(n_white):
		# buscar una celda activa libre
		var placed = false
		for c in active:
			if c in used:
				continue
			white.append({"pos": c, "type": PIECE_TYPES[randi() % PIECE_TYPES.size()]})
			used.append(c)
			placed = true
			break
		if not placed:
			break
	
	if white.size() == 0:
		return {}  # candidato inválido
	
	return {
		"tiles": tiles,
		"white": white,
		"king": king,
		"tile_left": TILE_ACTIONS
	}

# ============================================================
# FILTROS: el puzzle debe (a) resolverse CON tiles
#                          (b) NO resolverse SIN tiles
# ============================================================

func _is_interesting(s: Dictionary) -> bool:
	# No debe estar ya capturado ni ser capturable en 0
	# (a) resoluble usando tiles
	var memo_with = {}
	var solvable_with = _can_capture(_clone_state(s), MAX_TURNS, true, memo_with)
	if not solvable_with:
		return false
	
	# (b) NO resoluble sin tiles
	var memo_without = {}
	var solvable_without = _can_capture(_clone_state(s), MAX_TURNS, false, memo_without)
	if solvable_without:
		return false  # se puede sin tiles -> no usa la mecánica -> descartar
	
	return true

func _generate_until_valid(max_attempts: int):
	for attempt in range(max_attempts):
		var cand = _random_candidate()
		if cand.is_empty():
			continue
		# El rey no puede estar ya adyacente-capturable trivialmente:
		# lo dejamos pasar, el filtro (b) se encarga de la trivialidad sin-tiles.
		if _is_interesting(cand):
			print("Puzzle encontrado en intento ", attempt + 1)
			return cand
	return null

# ============================================================
# CARGAR el puzzle en el tablero real usando DeserializeBoard
# ============================================================

func _load_puzzle(s: Dictionary):
	var active_tiles = []
	for loc in s.tiles.keys():
		active_tiles.append(_local_to_global(loc))
	
	var pieces = []
	# Rey negro
	pieces.append({"location": _local_to_global(s.king), "type": "King", "color": 1})
	# Piezas blancas
	for p in s.white:
		pieces.append({"location": _local_to_global(p.pos), "type": p.type, "color": 0})
	
	var data = {
		"version": 1,
		"board_x": 20,
		"board_y": 20,
		"turn": 0,
		"active_tiles": active_tiles,
		"pieces": pieces,
		"tile_heights": {}
	}
	
	Board.DeserializeBoard(data)
	print("Puzzle cargado. Tiles activas: ", active_tiles.size(), " | Piezas blancas: ", s.white.size())
