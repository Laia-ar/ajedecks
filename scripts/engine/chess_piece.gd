# chess_piece.gd - Chess piece type definitions and utilities
class_name ChessPiece
extends Node

enum Type { KING = 0, QUEEN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, PAWN = 5, NONE = 6 }
enum PieceColor { WHITE = 0, BLACK = 1 }

# Unicode symbols for each piece
const SYMBOLS = {
	PieceColor.WHITE: {
		Type.KING: "♔",
		Type.QUEEN: "♕",
		Type.ROOK: "♖",
		Type.BISHOP: "♗",
		Type.KNIGHT: "♘",
		Type.PAWN: "♙",
	},
	PieceColor.BLACK: {
		Type.KING: "♚",
		Type.QUEEN: "♛",
		Type.ROOK: "♜",
		Type.BISHOP: "♝",
		Type.KNIGHT: "♞",
		Type.PAWN: "♟",
	}
}

static func opposite_color(c):
	return PieceColor.BLACK if c == PieceColor.WHITE else PieceColor.WHITE