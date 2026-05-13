@tool
extends Node

var lock_opened: bool = false
var is_candle_puzzle_solved: bool = false
var is_chess_puzzle_solved: bool = false
var is_elements_puzzle_solved: bool = false
var is_rat_hunt_unlocked: bool = false
var is_final_puzzle_solved: bool = false
var is_talisman_puzzle_solved: bool = false
var is_diary_read: bool = false
var rat_singing_enabled: bool = true
var singing_rats_count: int = 0
var is_ink_puzzle_solved: bool = false
var is_coin_puzzle_solved: bool = false


var is_player_inside: bool = false
var is_raining: bool = true

func reset_state():
	lock_opened = false
	is_candle_puzzle_solved = false
	is_chess_puzzle_solved = false
	is_elements_puzzle_solved = false
	is_rat_hunt_unlocked = false
	is_final_puzzle_solved = false
	is_talisman_puzzle_solved = false
	is_diary_read = false
	rat_singing_enabled = true
	singing_rats_count = 0
	is_ink_puzzle_solved = false
	is_coin_puzzle_solved = false
	is_player_inside = false
	is_raining = true
	print("[GameState] All states have been reset.")
