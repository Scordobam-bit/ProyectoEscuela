## GameManager.gd  (Autoload — accessible as GameManager from any script)
## =========================================================================
## Global state, progression, and event hub for Planet Waves.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player moves to a different sector.
signal sector_changed(sector_index: int)

## Emitted when a challenge in the current sector is completed.
signal challenge_completed(sector_index: int, challenge_index: int)

## Emitted when the player's formula answer is validated.
signal answer_validated(correct: bool, feedback: String)

## Emitted to request a theory panel update.
signal theory_requested(sector_index: int, topic_key: String)

# ---------------------------------------------------------------------------
# Sector Definitions
# ---------------------------------------------------------------------------

## Immutable data describing each curriculum sector.
const SECTORS: Array[Dictionary] = [
	{
		"index": 1,
		"name": "Asteroid Belt",
		"subtitle": "Lines & Functions",
		"scene": "res://scenes/sectors/sector_1_asteroid_belt.tscn",
		"color": Color(0.2, 0.8, 1.0),
		"topics": ["intro_functions", "linear_functions", "domain_range"]
	},
	{
		"index": 2,
		"name": "Gravity Wells",
		"subtitle": "Quadratic Functions",
		"scene": "res://scenes/sectors/sector_2_gravity_wells.tscn",
		"color": Color(1.0, 0.6, 0.0),
		"topics": ["quadratics", "vertex_form", "roots_discriminant"]
	},
	{
		"index": 3,
		"name": "Pulsar Tuner",
		"subtitle": "Types & Transformations",
		"scene": "res://scenes/sectors/sector_3_pulsar_tuner.tscn",
		"color": Color(0.8, 0.2, 1.0),
		"topics": ["function_types", "shifts", "scaling", "reflections"]
	},
	{
		"index": 4,
		"name": "Docking Station",
		"subtitle": "Operations & Composition",
		"scene": "res://scenes/sectors/sector_4_docking_station.tscn",
		"color": Color(0.2, 1.0, 0.4),
		"topics": ["sum_difference", "product_quotient", "composition"]
	},
	{
		"index": 5,
		"name": "Event Horizon",
		"subtitle": "Inverses, Logs & Trig",
		"scene": "res://scenes/sectors/sector_5_event_horizon.tscn",
		"color": Color(1.0, 0.2, 0.4),
		"topics": ["injectivity", "inverses", "exponentials", "logarithms", "inverse_trig"]
	},
]

# ---------------------------------------------------------------------------
# Player State
# ---------------------------------------------------------------------------

var current_sector: int = 1
var completed_challenges: Dictionary = {}   # sector_index → Array[int]
var total_score: int = 0
var hints_used: int = 0
var session_start_time: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_initialise_progress()


func _initialise_progress() -> void:
	for s in SECTORS:
		completed_challenges[s["index"]] = []


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

## Transitions to the specified sector scene.
func go_to_sector(sector_index: int) -> void:
	if sector_index < 1 or sector_index > SECTORS.size():
		push_warning("GameManager: invalid sector index %d" % sector_index)
		return
	current_sector = sector_index
	sector_changed.emit(sector_index)
	var scene_path: String = SECTORS[sector_index - 1]["scene"]
	get_tree().change_scene_to_file(scene_path)


## Returns the data dictionary for the current sector.
func get_current_sector_data() -> Dictionary:
	return SECTORS[current_sector - 1]


## Returns true if all challenges in a sector are completed.
func is_sector_complete(sector_index: int) -> bool:
	if not completed_challenges.has(sector_index):
		return false
	return completed_challenges[sector_index].size() >= 3  # 3 challenges per sector


# ---------------------------------------------------------------------------
# Challenge Management
# ---------------------------------------------------------------------------

## Records a completed challenge and emits the signal.
func complete_challenge(sector_index: int, challenge_index: int, score: int = 100) -> void:
	if not completed_challenges.has(sector_index):
		completed_challenges[sector_index] = []
	var list: Array = completed_challenges[sector_index]
	if challenge_index not in list:
		list.append(challenge_index)
		total_score += score
	challenge_completed.emit(sector_index, challenge_index)


## Validates a player's formula against an expected formula over a test range.
## Tolerance is the maximum allowed absolute difference at each test point.
func validate_formula(player_formula: String, expected_formula: String,
		x_min: float = -5.0, x_max: float = 5.0,
		test_points: int = 20, tolerance: float = 0.01) -> bool:
	var step: float = (x_max - x_min) / float(test_points - 1)
	for i in range(test_points):
		var x: float = x_min + step * float(i)
		var player_y: float = MathEngine.evaluate(player_formula, x)
		var expected_y: float = MathEngine.evaluate(expected_formula, x)
		if is_nan(player_y) or is_nan(expected_y):
			continue
		if absf(player_y - expected_y) > tolerance:
			return false
	return true


## Validates and emits feedback signal.
func submit_answer(player_formula: String, expected_formula: String,
		feedback_correct: String = "Correct! Well done.",
		feedback_wrong: String = "Not quite. Try again.") -> bool:
	var correct: bool = validate_formula(player_formula, expected_formula)
	answer_validated.emit(correct,
		feedback_correct if correct else feedback_wrong)
	return correct


# ---------------------------------------------------------------------------
# Session Utilities
# ---------------------------------------------------------------------------

## Returns elapsed session time in seconds.
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - session_start_time


## Returns the player's total score.
func get_score() -> int:
	return total_score
