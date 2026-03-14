## HUD.gd
## =======
## Space-themed Heads-Up Display for Planet Waves.
## Neon aesthetics with real-time formula input and sector info.
class_name HUD
extends CanvasLayer

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player submits a formula from the HUD input.
signal formula_submitted(formula: String)

## Emitted when the player changes the domain bounds.
signal domain_changed(min_x: float, max_x: float)

## Emitted when the Theory button is pressed.
signal theory_requested

## Emitted when the Hint button is pressed.
signal hint_requested

# ---------------------------------------------------------------------------
# Node References (wired in _ready via $Path syntax)
# ---------------------------------------------------------------------------

@onready var _formula_input: LineEdit = $HUDPanel/VBox/FormulaRow/FormulaInput
@onready var _plot_button: Button = $HUDPanel/VBox/FormulaRow/PlotButton
@onready var _domain_min_spin: SpinBox = $HUDPanel/VBox/DomainRow/DomainMinSpin
@onready var _domain_max_spin: SpinBox = $HUDPanel/VBox/DomainRow/DomainMaxSpin
@onready var _sector_label: Label = $TopBar/SectorLabel
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _feedback_label: Label = $FeedbackLabel
@onready var _theory_button: Button = $HUDPanel/VBox/ButtonRow/TheoryButton
@onready var _hint_button: Button = $HUDPanel/VBox/ButtonRow/HintButton
@onready var _feedback_timer: Timer = $FeedbackTimer

# ---------------------------------------------------------------------------
# Exported Properties
# ---------------------------------------------------------------------------

@export var neon_color: Color = Color(0.0, 1.0, 0.8, 1.0)
@export var warning_color: Color = Color(1.0, 0.4, 0.0, 1.0)
@export var error_color: Color = Color(1.0, 0.2, 0.2, 1.0)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_plot_button.pressed.connect(_on_plot_pressed)
	_theory_button.pressed.connect(theory_requested.emit)
	_hint_button.pressed.connect(hint_requested.emit)
	_domain_min_spin.value_changed.connect(_on_domain_changed)
	_domain_max_spin.value_changed.connect(_on_domain_changed)
	_formula_input.text_submitted.connect(_on_formula_submitted)
	_feedback_timer.timeout.connect(_clear_feedback)

	GameManager.answer_validated.connect(_on_answer_validated)
	GameManager.sector_changed.connect(_on_sector_changed)
	GameManager.challenge_completed.connect(_on_challenge_completed)

	_update_sector_display(GameManager.current_sector)
	_update_score_display()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Sets the formula text in the input box (e.g. to show a hint).
func set_formula_hint(text: String) -> void:
	_formula_input.placeholder_text = text


## Displays a temporary feedback message.
func show_feedback(message: String, feedback_type: String = "info") -> void:
	_feedback_label.text = message
	match feedback_type:
		"success":
			_feedback_label.add_theme_color_override("font_color", neon_color)
		"error":
			_feedback_label.add_theme_color_override("font_color", error_color)
		"warning":
			_feedback_label.add_theme_color_override("font_color", warning_color)
		_:
			_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.visible = true
	_feedback_timer.start(3.0)


## Returns the current formula string from the input box.
func get_formula() -> String:
	return _formula_input.text.strip_edges()


## Returns the current domain as [min, max].
func get_domain() -> Array[float]:
	return [_domain_min_spin.value, _domain_max_spin.value]


## Locks or unlocks the input controls.
func set_controls_enabled(enabled: bool) -> void:
	_formula_input.editable = enabled
	_plot_button.disabled = not enabled
	_domain_min_spin.editable = enabled
	_domain_max_spin.editable = enabled


# ---------------------------------------------------------------------------
# Private Handlers
# ---------------------------------------------------------------------------

func _on_plot_pressed() -> void:
	var formula: String = get_formula()
	if formula.is_empty():
		show_feedback("Please enter a formula first.", "warning")
		return
	formula_submitted.emit(formula)


func _on_formula_submitted(formula: String) -> void:
	formula_submitted.emit(formula.strip_edges())


func _on_domain_changed(_value: float) -> void:
	var min_x: float = _domain_min_spin.value
	var max_x: float = _domain_max_spin.value
	if min_x < max_x:
		domain_changed.emit(min_x, max_x)


func _on_answer_validated(correct: bool, feedback: String) -> void:
	show_feedback(feedback, "success" if correct else "error")
	_update_score_display()


func _on_sector_changed(sector_index: int) -> void:
	_update_sector_display(sector_index)


func _on_challenge_completed(_sector: int, _challenge: int) -> void:
	_update_score_display()


func _update_sector_display(sector_index: int) -> void:
	if sector_index < 1 or sector_index > GameManager.SECTORS.size():
		return
	var data: Dictionary = GameManager.SECTORS[sector_index - 1]
	_sector_label.text = "Sector %d: %s" % [sector_index, data["name"]]
	_sector_label.add_theme_color_override("font_color", data["color"])


func _update_score_display() -> void:
	_score_label.text = "Score: %d" % GameManager.get_score()


func _clear_feedback() -> void:
	_feedback_label.visible = false
