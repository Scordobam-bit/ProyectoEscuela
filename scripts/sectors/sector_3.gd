## Sector3PulsarTuner.gd
## ======================
## Sector 3: Pulsar Tuner — Function Types, Transformations (Shifts, Scaling, Reflections)
##
## Pedagogy
## ---------
## Transformations of functions are algebraic operations that systematically
## translate, scale, or reflect a base function:
##   Vertical shift   :  g(x) = f(x) + k
##   Horizontal shift :  g(x) = f(x − h)
##   Vertical scale   :  g(x) = a·f(x)
##   Horizontal scale :  g(x) = f(b·x)
##   X-axis reflect   :  g(x) = −f(x)
##   Y-axis reflect   :  g(x) = f(−x)
##
## Challenges
## ----------
## 1. Shift sin(x) right by π and up by 2.
## 2. Vertically compress cos(x) by factor 0.5 and reflect over x-axis.
## 3. BOSS: Match a mystery waveform by applying the correct transformation chain.
class_name Sector3PulsarTuner
extends SectorBase

var _reference_plotter: FunctionPlotter = null
var _mystery_formula: String = ""
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 3
	background_color = Color(0.04, 0.02, 0.08, 1.0)

	_mystery_formula = "2 * sin(2 * x) - 1"

	_challenges = [
		{
			"instruction": "Challenge 1: Shift sin(x) RIGHT by π and UP by 2.\n" +
				"Recall: f(x−h)+k shifts right by h and up by k.",
			"hint": "sin(x - PI) + 2",
			"expected_formula": "sin(x - PI) + 2",
			"feedback_correct": "Pulsar frequency locked! Perfect phase shift.",
			"feedback_wrong": "Check your shift. Horizontal shifts use (x − h) inside the function.",
			"solution_hint": "sin(x − π) + 2",
			"score": 200,
		},
		{
			"instruction": "Challenge 2: Take cos(x), compress it vertically by 0.5, then reflect over the x-axis.\n" +
				"g(x) = −(0.5·cos(x))",
			"hint": "-0.5 * cos(x)",
			"expected_formula": "-0.5 * cos(x)",
			"feedback_correct": "Signal inverted and compressed. Pulsar tuned!",
			"feedback_wrong": "Vertical scale: multiply by 0.5. Reflection: negate the whole thing.",
			"solution_hint": "g(x) = −0.5·cos(x)",
			"score": 200,
		},
		{
			"instruction": "BOSS: Match the mystery pulsar waveform shown in purple!\n" +
				"It's a transformed sin function. Analyse its amplitude, period and shift.",
			"hint": "2 * sin(2*x) - 1",
			"expected_formula": "2 * sin(2*x) - 1",
			"feedback_correct": "PULSAR SYNCHRONISED! Sector 3 complete!",
			"feedback_wrong": "Study the purple waveform: amplitude, period (2π/b), and vertical shift.",
			"solution_hint": "Amplitude=2, period=π (b=2), vertical shift=−1",
			"score": 400,
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -2.0 * PI
		_plotter.domain_max = 2.0 * PI
		_plotter.scale_factor = 50.0

	match challenge_index:
		0:
			if _theory_panel:
				_theory_panel.show_sector_theory(3)
			_show_reference("sin(x)", Color(0.4, 0.8, 1.0, 0.4))
		1:
			_show_reference("cos(x)", Color(0.4, 0.8, 1.0, 0.4))
		2:
			_show_reference(_mystery_formula, Color(0.8, 0.2, 1.0, 0.7))


func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		# Show evaluated comparison at a test point
		var sample_x: float = 1.0
		var player_y: float = MathEngine.evaluate(formula, sample_x)
		_hud.show_feedback(
			"At x=1: your f(1) = %s" % MathEngine.format_float(player_y), "info"
		)
	_validate_formula_against_current(formula)


func _show_reference(ref_formula: String, color: Color) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -2.0 * PI
	_reference_plotter.domain_max = 2.0 * PI
	_reference_plotter.scale_factor = 50.0
	_reference_plotter.line_color = color
	_reference_plotter.line_width = 1.5
	_reference_plotter.show_axes = false
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_markers.append(_reference_plotter)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
	_reference_plotter = null
