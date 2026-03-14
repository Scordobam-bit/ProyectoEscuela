## Sector5EventHorizon.gd
## =======================
## Sector 5: Event Horizon — Injectivity, Inverses (f⁻¹), Exponentials (e),
##           Logarithms (ln), and Inverse Trigonometry
##
## Pedagogy
## ---------
## The Event Horizon is the boundary of no return for a black hole — mathematically
## analogous to the domain boundary where a function loses injectivity. To escape,
## students must master:
##   1. Injectivity (horizontal line test)
##   2. Finding inverse functions analytically
##   3. Properties of eˣ and ln(x) as mutual inverses
##   4. Inverse trig: arcsin, arccos, arctan and their principal value ranges
##
## Boss Battle
## -----------
## The black hole's gravitational formula is f(x) = eˣ − 2.
## To escape: input its inverse f⁻¹(x) = ln(x + 2).
class_name Sector5EventHorizon
extends SectorBase

var _reference_plotter: FunctionPlotter = null
var _inverse_plotter: FunctionPlotter = null
var _symmetry_line: Line2D = null
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 5
	background_color = Color(0.06, 0.01, 0.02, 1.0)

	_challenges = [
		{
			"instruction": "Challenge 1: Is f(x) = x³ injective? Enter '1' for Yes or '0' for No.",
			"hint": "1",
			"expected_formula": "1",
			"feedback_correct": "Correct! x³ is strictly increasing → injective.",
			"feedback_wrong": "Recall the horizontal line test. Does every horizontal line hit x³ at most once?",
			"solution_hint": "Yes (1). x³ is monotone increasing everywhere.",
			"score": 150,
		},
		{
			"instruction": "Challenge 2: Find the inverse of f(x) = 2x + 4.\n" +
				"Steps: y = 2x+4 → x = (y−4)/2 → f⁻¹(x) = (x−4)/2",
			"hint": "(x - 4) / 2",
			"expected_formula": "(x - 4) / 2",
			"feedback_correct": "Inverse found! f⁻¹(x) = (x−4)/2",
			"feedback_wrong": "Swap x and y: if y = 2x+4, solve for x in terms of y.",
			"solution_hint": "f⁻¹(x) = (x − 4) / 2",
			"score": 250,
		},
		{
			"instruction": "Challenge 3: Enter the natural logarithm of (x + 2).\n" +
				"This is the inverse of eˣ − 2.",
			"hint": "log(x + 2)",
			"expected_formula": "log(x + 2)",
			"feedback_correct": "ln(x+2) confirmed. Exponential and log are perfect inverses!",
			"feedback_wrong": "ln is the inverse of eˣ. If f(x) = eˣ−2, then f⁻¹(x) = ln(x+2).",
			"solution_hint": "ln(x+2) → in Godot: log(x+2)",
			"score": 300,
		},
		{
			"instruction": "⚡ FINAL BOSS: The black hole gravity formula is f(x) = eˣ − 2.\n" +
				"INPUT ITS INVERSE to break free from the Event Horizon!",
			"hint": "log(x + 2)",
			"expected_formula": "log(x + 2)",
			"feedback_correct": "🌟 EVENT HORIZON ESCAPED! Planet Waves complete! 🌟",
			"feedback_wrong": "If f(x) = eˣ − 2, reverse it: y = eˣ−2 → x = ln(y+2) → f⁻¹(y) = ln(y+2)",
			"solution_hint": "f⁻¹(x) = ln(x + 2)  → Godot: log(x + 2)",
			"score": 500,
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -4.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 55.0
		_plotter.y_clamp = 10.0

	match challenge_index:
		0:
			if _theory_panel:
				_theory_panel.show_sector_theory(5)
			_show_reference("x^3", Color(0.6, 0.8, 1.0, 0.5))
		1:
			_show_reference("2*x + 4", Color(0.6, 0.8, 1.0, 0.5))
			_show_symmetry_line()
		2:
			# Show eˣ − 2 and its inverse log(x+2) separately
			_show_reference("exp(x) - 2", Color(1.0, 0.5, 0.2, 0.5))
			_show_symmetry_line()
		3:
			# BOSS: show the gravitational formula
			_show_reference("exp(x) - 2", Color(1.0, 0.2, 0.2, 0.8))
			_show_symmetry_line()
			_spawn_event_horizon_ring()


func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			1:
				# Show injectivity check
				var inj: Dictionary = MathEngine.check_injectivity("2*x + 4")
				_hud.show_feedback(
					"Injectivity of 2x+4: %s (increasing: %s)" % [
						str(inj["injective"]), str(inj["monotone_increasing"])
					], "info"
				)
			2, 3:
				# Show the plotted inverse alongside f to confirm symmetry over y=x
				if _inverse_plotter:
					_inverse_plotter.queue_free()
				_inverse_plotter = FunctionPlotter.new()
				_inverse_plotter.formula = formula
				_inverse_plotter.domain_min = -2.0
				_inverse_plotter.domain_max = 10.0
				_inverse_plotter.scale_factor = 55.0
				_inverse_plotter.y_clamp = 10.0
				_inverse_plotter.line_color = Color(0.0, 1.0, 0.5, 0.9)
				_inverse_plotter.line_width = 2.5
				_inverse_plotter.show_axes = false
				_inverse_plotter.position = _plotter.position if _plotter else Vector2.ZERO
				add_child(_inverse_plotter)
				_markers.append(_inverse_plotter)
	_validate_formula_against_current(formula)


func _show_reference(ref_formula: String, color: Color) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -4.0
	_reference_plotter.domain_max = 6.0
	_reference_plotter.scale_factor = 55.0
	_reference_plotter.y_clamp = 10.0
	_reference_plotter.line_color = color
	_reference_plotter.line_width = 2.0
	_reference_plotter.show_axes = false
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_markers.append(_reference_plotter)


func _show_symmetry_line() -> void:
	# Draw the line y=x to visualise inverse symmetry
	if _symmetry_line:
		_symmetry_line.queue_free()
	_symmetry_line = Line2D.new()
	_symmetry_line.width = 1.0
	_symmetry_line.default_color = Color(0.8, 0.8, 0.8, 0.3)
	var s: float = 55.0
	var ext: float = 6.0
	_symmetry_line.add_point(Vector2(-ext * s, ext * s))     # math (-6, -6) → screen
	_symmetry_line.add_point(Vector2(ext * s, -ext * s))     # math (6, 6) → screen
	_symmetry_line.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_symmetry_line)
	_markers.append(_symmetry_line)


func _spawn_event_horizon_ring() -> void:
	var ring: Line2D = Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.1, 0.1, 0.6)
	var radius: float = 180.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(65):
		var angle: float = TAU * float(i) / 64.0
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring.points = pts
	ring.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(ring)
	_markers.append(ring)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
	_reference_plotter = null
	_inverse_plotter = null
	_symmetry_line = null
