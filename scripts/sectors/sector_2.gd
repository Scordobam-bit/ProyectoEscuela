## Sector2GravityWells.gd
## =======================
## Sector 2: Gravity Wells — Quadratic Functions, Vertices, and Roots
##
## Pedagogy
## ---------
## A quadratic f(x) = ax² + bx + c is a second-degree polynomial whose graph
## is a parabola. The vertex (h, k) = (−b/2a, f(−b/2a)) is the extremum.
## Roots are found via the quadratic formula: x = (−b ± √Δ) / 2a, Δ = b²−4ac.
## Gravity wells in the game represent parabolic gravitational potentials.
##
## Challenges
## ----------
## 1. Enter the parabola that passes through three given gravity points.
## 2. Find the vertex of a given quadratic (enter it as x-value).
## 3. BOSS: Find the roots of the gravitational potential to plot an escape.
class_name Sector2GravityWells
extends SectorBase

# ---------------------------------------------------------------------------
# Sector-specific state
# ---------------------------------------------------------------------------

var _reference_plotter: FunctionPlotter = null   # shows the "reference" curve
var _particle_markers: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Override: Setup Challenges
# ---------------------------------------------------------------------------

func _setup_challenges() -> void:
	sector_index = 2
	background_color = Color(0.05, 0.02, 0.12, 1.0)

	_challenges = [
		{
			"instruction": "Challenge 1: A gravity well follows f(x) = x² − 4.\nPlot this function to reveal the well's curvature.",
			"hint": "x^2 - 4",
			"expected_formula": "x^2 - 4",
			"feedback_correct": "Well mapped! The parabola is locked in.",
			"feedback_wrong": "Not quite. The well is quadratic: f(x) = ax² + c",
			"solution_hint": "f(x) = x² − 4  (a=1, b=0, c=−4)",
			"score": 150,
		},
		{
			"instruction": "Challenge 2: Find the vertex x-coordinate of f(x) = 2x² − 8x + 5.\nEnter as a constant function: just the x-value (e.g., '2').",
			"hint": "2",
			"expected_formula": "2",
			"feedback_correct": "Correct vertex! h = −b/(2a) = 8/4 = 2",
			"feedback_wrong": "Use the vertex formula: h = −b / (2a)",
			"solution_hint": "h = −(−8) / (2·2) = 8/4 = 2",
			"score": 200,
		},
		{
			"instruction": "BOSS: The gravitational potential is g(x) = x² − 5x + 4.\nFind the escape roots! Enter the smaller root as a constant.",
			"hint": "1",
			"expected_formula": "1",
			"feedback_correct": "ESCAPE VELOCITY ACHIEVED! Sector 2 cleared!",
			"feedback_wrong": "Apply the quadratic formula: x = (−b ± √(b²−4ac)) / 2a",
			"solution_hint": "Δ = 25−16 = 9, roots = (5±3)/2 → x=1 and x=4",
			"score": 350,
		},
	]


# ---------------------------------------------------------------------------
# Override: Challenge Begin
# ---------------------------------------------------------------------------

func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -6.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 45.0

	match challenge_index:
		0:
			if _theory_panel:
				_theory_panel.show_sector_theory(2)
			_spawn_gravity_well_visual()
		1:
			# Show the reference parabola so students can visualise the vertex
			_show_reference_curve("2*x^2 - 8*x + 5")
		2:
			_show_reference_curve("x^2 - 5*x + 4")
			_spawn_escape_markers()


# ---------------------------------------------------------------------------
# Override: Formula Submission
# ---------------------------------------------------------------------------

func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			1:
				# Show vertex info
				var vertex: Vector2 = MathEngine.find_vertex("2*x^2 - 8*x + 5", -5.0, 10.0)
				_hud.show_feedback(
					"Reference vertex at x = %s, y = %s" % [
						MathEngine.format_float(vertex.x),
						MathEngine.format_float(vertex.y)
					], "info"
				)
			2:
				# Show discriminant info
				var qf: Dictionary = MathEngine.quadratic_formula(1.0, -5.0, 4.0)
				_hud.show_feedback(
					"Δ = %s, roots: %s" % [
						MathEngine.format_float(qf["discriminant"]),
						str(qf["roots"])
					], "info"
				)
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _show_reference_curve(ref_formula: String) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -6.0
	_reference_plotter.domain_max = 6.0
	_reference_plotter.scale_factor = 45.0
	_reference_plotter.line_color = Color(0.8, 0.4, 1.0, 0.5)   # dim purple
	_reference_plotter.line_width = 1.5
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_particle_markers.append(_reference_plotter)


func _spawn_gravity_well_visual() -> void:
	# Draw a subtle radial "well" indicator at origin
	var well: Line2D = Line2D.new()
	well.width = 2.0
	well.default_color = Color(0.5, 0.2, 1.0, 0.4)
	var scale_f: float = 45.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(33):
		var angle: float = TAU * float(i) / 32.0
		pts.append(Vector2(cos(angle) * scale_f * 2.0, sin(angle) * scale_f * 2.0))
	well.points = pts
	well.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(well)
	_particle_markers.append(well)


func _spawn_escape_markers() -> void:
	# Mark the two roots at x=1 and x=4
	for root_x in [1.0, 4.0]:
		_spawn_marker_at_math(Vector2(root_x, 0.0), Color(1.0, 0.3, 0.1, 0.9))


func _spawn_marker_at_math(math_pos: Vector2, color: Color) -> void:
	if not _plotter:
		return
	var marker: Node2D = Node2D.new()
	var circle: Line2D = Line2D.new()
	circle.width = 3.0
	circle.default_color = color
	var radius: float = 10.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(33):
		var angle: float = TAU * float(i) / 32.0
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	circle.points = pts
	marker.add_child(circle)
	marker.position = _plotter.math_to_screen(math_pos) + _plotter.position
	add_child(marker)
	_particle_markers.append(marker)


func _clear_markers() -> void:
	for m in _particle_markers:
		if is_instance_valid(m):
			m.queue_free()
	_particle_markers.clear()
	_reference_plotter = null
