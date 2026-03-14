## SectorBase.gd
## ==============
## Abstract base class for all Planet Waves sectors.
## Each sector scene's root node should extend this class.
class_name SectorBase
extends Node2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when all challenges in this sector are completed.
signal sector_complete(sector_index: int)

## Emitted when a single challenge is completed.
signal challenge_done(challenge_index: int)

## Emitted when a new challenge starts.
signal challenge_started(challenge_index: int)

# ---------------------------------------------------------------------------
# Exported Properties
# ---------------------------------------------------------------------------

@export var sector_index: int = 1

## Background color for the sector's space environment.
@export var background_color: Color = Color(0.02, 0.02, 0.1, 1.0)

# ---------------------------------------------------------------------------
# Node References (subclasses should have these in their scenes)
# ---------------------------------------------------------------------------

@onready var _plotter: FunctionPlotter = $FunctionPlotter
@onready var _ship: ShipController = $Ship
@onready var _hud: HUD = $HUD
@onready var _theory_panel: TheoryPanel = $HUD/TheoryPanel

# ---------------------------------------------------------------------------
# Challenge State
# ---------------------------------------------------------------------------

var _current_challenge: int = 0
var _challenges: Array = []   # Array of Dictionaries, populated by subclasses

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	RenderingServer.set_default_clear_color(background_color)
	_setup_challenges()
	_connect_hud()
	_connect_plotter()
	_start_challenge(0)


# ---------------------------------------------------------------------------
# Abstract Methods (override in subclasses)
# ---------------------------------------------------------------------------

## Populate _challenges array with challenge data.
func _setup_challenges() -> void:
	push_warning("SectorBase: _setup_challenges() not overridden in %s" % name)


## Called when a new challenge begins.  Override to set up visuals.
func _on_challenge_begin(challenge_index: int) -> void:
	pass


## Called when the player submits a formula.
## Override to add sector-specific validation logic.
func _on_formula_submitted_sector(formula: String) -> void:
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Challenge Management
# ---------------------------------------------------------------------------

func _start_challenge(index: int) -> void:
	if index < 0 or index >= _challenges.size():
		return
	_current_challenge = index
	challenge_started.emit(index)

	if _hud:
		var ch: Dictionary = _challenges[index]
		_hud.set_formula_hint(ch.get("hint", "Enter formula…"))
		_hud.show_feedback(ch.get("instruction", ""), "info")

	_on_challenge_begin(index)


func _advance_challenge() -> void:
	var next: int = _current_challenge + 1
	if next >= _challenges.size():
		_on_sector_complete()
	else:
		_start_challenge(next)


func _on_sector_complete() -> void:
	sector_complete.emit(sector_index)
	GameManager.complete_challenge(sector_index, _current_challenge)
	if _hud:
		_hud.show_feedback(
			"Sector %d Complete! Warping to next sector…" % sector_index, "success"
		)
	await get_tree().create_timer(2.0).timeout
	var next_sector: int = sector_index + 1
	if next_sector <= GameManager.SECTORS.size():
		GameManager.go_to_sector(next_sector)
	else:
		# Final sector done → go to main menu
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# HUD & Plotter Connections
# ---------------------------------------------------------------------------

func _connect_hud() -> void:
	if not _hud:
		return
	_hud.formula_submitted.connect(_on_formula_submitted_hud)
	_hud.domain_changed.connect(_on_domain_changed)
	_hud.theory_requested.connect(_on_theory_requested)
	_hud.hint_requested.connect(_on_hint_requested)


func _connect_plotter() -> void:
	if not _plotter:
		return
	_plotter.plot_failed.connect(_on_plot_failed)
	if _ship:
		_ship.attach_to_plotter(_plotter)


func _on_formula_submitted_hud(formula: String) -> void:
	if _plotter:
		_plotter.formula = formula
	_on_formula_submitted_sector(formula)


func _on_domain_changed(min_x: float, max_x: float) -> void:
	if _plotter:
		_plotter.domain_min = min_x
		_plotter.domain_max = max_x


func _on_plot_failed(error_message: String) -> void:
	if _hud:
		_hud.show_feedback("Plot error: " + error_message, "error")


func _on_theory_requested() -> void:
	if _theory_panel:
		_theory_panel.show_sector_theory(sector_index)


func _on_hint_requested() -> void:
	if _current_challenge < _challenges.size():
		var hint: String = _challenges[_current_challenge].get("solution_hint", "No hint available.")
		if _hud:
			_hud.show_feedback("Hint: " + hint, "warning")
		GameManager.hints_used += 1


# ---------------------------------------------------------------------------
# Formula Validation
# ---------------------------------------------------------------------------

func _validate_formula_against_current(player_formula: String) -> void:
	if _current_challenge >= _challenges.size():
		return
	var ch: Dictionary = _challenges[_current_challenge]
	var expected: String = ch.get("expected_formula", "")
	if expected.is_empty():
		return

	var correct: bool = GameManager.submit_answer(
		player_formula, expected,
		ch.get("feedback_correct", "Correct! Well done!"),
		ch.get("feedback_wrong", "Not quite. Check your formula and try again.")
	)
	if correct:
		GameManager.complete_challenge(sector_index, _current_challenge, ch.get("score", 100))
		challenge_done.emit(_current_challenge)
		await get_tree().create_timer(1.5).timeout
		_advance_challenge()
