## Sector4DockingStation.gd
## =========================
## Sector 4: Docking Station — Function Operations (Sum, Sub, Div) and Composition
##
## Pedagogy
## ---------
## Two functions f and g can be combined:
##   (f+g)(x) = f(x)+g(x)    domain: D_f ∩ D_g
##   (f−g)(x) = f(x)−g(x)    domain: D_f ∩ D_g
##   (f/g)(x) = f(x)/g(x)    domain: D_f ∩ D_g \ {g(x)=0}
##   (f∘g)(x) = f(g(x))      domain: {x∈D_g : g(x)∈D_f}
##
## Challenges
## ----------
## 1. Compute and plot (f+g)(x) where f(x)=x² and g(x)=3x−1.
## 2. Compute (f/g)(x) and identify the asymptote.
## 3. BOSS: Find the composition (f∘g)(x) and enter it to unlock the airlock.
class_name Sector4DockingStation
extends SectorBase

var _f_formula: String = "x^2"
var _g_formula: String = "3*x - 1"
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 4
	background_color = Color(0.02, 0.06, 0.04, 1.0)

	_challenges = [
		{
			"instruction": "Challenge 1: f(x) = x²  and  g(x) = 3x − 1.\n" +
				"Compute and plot (f + g)(x).",
			"hint": "x^2 + 3*x - 1",
			"expected_formula": "x^2 + 3*x - 1",
			"feedback_correct": "Sum computed correctly! Docking approach vector aligned.",
			"feedback_wrong": "Sum: (f+g)(x) = f(x) + g(x) = x² + 3x − 1",
			"solution_hint": "(f+g)(x) = x² + (3x − 1) = x² + 3x − 1",
			"score": 200,
		},
		{
			"instruction": "Challenge 2: f(x) = x + 1  and  g(x) = x − 1.\n" +
				"Enter (f/g)(x). Note: there is a vertical asymptote!",
			"hint": "(x + 1) / (x - 1)",
			"expected_formula": "(x + 1) / (x - 1)",
			"feedback_correct": "Quotient correct! Asymptote at x=1 noted in navigation log.",
			"feedback_wrong": "(f/g)(x) = (x+1)/(x−1). Beware division by zero at x=1.",
			"solution_hint": "(f/g)(x) = (x+1)/(x−1)",
			"score": 250,
		},
		{
			"instruction": "BOSS CHALLENGE: f(x) = √x  and  g(x) = x² − 4.\n" +
				"Compute (f∘g)(x) = f(g(x)) and enter the composed formula.\n" +
				"Remember the domain restriction: g(x) ≥ 0.",
			"hint": "sqrt(x^2 - 4)",
			"expected_formula": "sqrt(x^2 - 4)",
			"feedback_correct": "AIRLOCK UNLOCKED! Composition mastered! Sector 4 complete!",
			"feedback_wrong": "(f∘g)(x) = f(g(x)) = √(x²−4). Replace x in f(x)=√x with g(x).",
			"solution_hint": "f(g(x)) = √(g(x)) = √(x² − 4)",
			"score": 400,
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -6.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 45.0
		_plotter.y_clamp = 15.0

	match challenge_index:
		0:
			if _theory_panel:
				_theory_panel.show_sector_theory(4)
			# Show f and g reference curves
			_show_ref_curve(_f_formula, Color(0.2, 0.6, 1.0, 0.4))
			_show_ref_curve(_g_formula, Color(1.0, 0.6, 0.2, 0.4))
		1:
			_show_ref_curve("x + 1", Color(0.2, 0.6, 1.0, 0.4))
			_show_ref_curve("x - 1", Color(1.0, 0.6, 0.2, 0.4))
		2:
			_show_ref_curve("x^2 - 4", Color(0.8, 0.4, 1.0, 0.4))


func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			0:
				var expected: String = MathEngine.operation_sum(_f_formula, _g_formula)
				_hud.show_feedback(
					"MathEngine sum: %s" % expected, "info"
				)
			1:
				_hud.show_feedback(
					"Quotient domain excludes x = 1 (division by zero)", "warning"
				)
			2:
				var composed: String = MathEngine.compose("sqrt(x)", "x^2 - 4")
				_hud.show_feedback(
					"Composition f∘g: %s" % composed, "info"
				)
	_validate_formula_against_current(formula)


func _show_ref_curve(ref_formula: String, color: Color) -> void:
	var ref: FunctionPlotter = FunctionPlotter.new()
	ref.formula = ref_formula
	ref.domain_min = -6.0
	ref.domain_max = 6.0
	ref.scale_factor = 45.0
	ref.y_clamp = 15.0
	ref.line_color = color
	ref.line_width = 1.5
	ref.show_axes = false
	ref.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(ref)
	_markers.append(ref)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
