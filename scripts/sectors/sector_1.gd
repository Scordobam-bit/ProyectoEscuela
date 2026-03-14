## Sector1AsteroidBelt.gd
## =======================
## Sector 1: Asteroid Belt — Introduction to Functions, Lines (y=mx+b), Domain & Range
##
## Pedagogy
## ---------
## Students learn that a function maps inputs to outputs. Linear functions are the
## simplest non-trivial case: f(x) = mx + b. The slope m encodes rate of change
## and b encodes the initial value. The asteroid belt challenges require the student
## to navigate waypoints by specifying the correct linear trajectory.
##
## Challenges
## ----------
## 1. Plot a line through two given asteroid waypoints.
## 2. Identify and enter a function with a specific slope and y-intercept.
## 3. Boss: Find the line that avoids all asteroid clusters (restricted domain).
class_name Sector1AsteroidBelt
extends SectorBase

# ---------------------------------------------------------------------------
# Waypoint Markers (created procedurally)
# ---------------------------------------------------------------------------

var _waypoint_markers: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Override: Setup Challenges
# ---------------------------------------------------------------------------

func _setup_challenges() -> void:
	sector_index = 1
	background_color = Color(0.02, 0.04, 0.12, 1.0)

	_challenges = [
		{
			"instruction": "Challenge 1: Plot the line through points A(−4, −3) and B(4, 5).\nHint: Find slope m = (y₂−y₁)/(x₂−x₁), then b = y₁ − m·x₁",
			"hint": "y = m*x + b",
			"expected_formula": "x + 1",
			"feedback_correct": "Perfect trajectory! You cleared the asteroid belt!",
			"feedback_wrong": "That line misses the waypoints. Recalculate slope and intercept.",
			"solution_hint": "slope = (5−(−3))/(4−(−4)) = 1,  b = −3 − 1·(−4) = 1",
			"score": 150,
			"waypoints": [Vector2(-4, -3), Vector2(4, 5)],
		},
		{
			"instruction": "Challenge 2: Enter a function with slope −2 and y-intercept 3.",
			"hint": "-2*x + 3",
			"expected_formula": "-2*x + 3",
			"feedback_correct": "Correct slope and intercept! Navigation locked.",
			"feedback_wrong": "Check your slope (coefficient of x) and intercept (constant term).",
			"solution_hint": "f(x) = −2x + 3",
			"score": 100,
			"waypoints": [],
		},
		{
			"instruction": "BOSS: The escape vector passes through (0, −5) and has slope 3/2.\nEnter the complete linear function to exit the asteroid belt!",
			"hint": "1.5*x - 5",
			"expected_formula": "1.5*x - 5",
			"feedback_correct": "SECTOR CLEARED! Warping to Gravity Wells…",
			"feedback_wrong": "The trajectory is blocked. Slope = 3/2, passes through (0,−5).",
			"solution_hint": "b = −5 (y-intercept), m = 3/2 = 1.5",
			"score": 300,
			"waypoints": [Vector2(0, -5), Vector2(4, 1)],
		},
	]


# ---------------------------------------------------------------------------
# Override: Challenge Begin
# ---------------------------------------------------------------------------

func _on_challenge_begin(challenge_index: int) -> void:
	_clear_waypoints()
	var ch: Dictionary = _challenges[challenge_index]
	var waypoints: Array = ch.get("waypoints", [])
	for wp in waypoints:
		_spawn_waypoint_marker(wp)

	# Set plotter domain and show theory for challenge 0
	if _plotter:
		_plotter.domain_min = -10.0
		_plotter.domain_max = 10.0
		_plotter.scale_factor = 40.0

	if challenge_index == 0 and _theory_panel:
		_theory_panel.show_sector_theory(1)


# ---------------------------------------------------------------------------
# Override: Formula Submission
# ---------------------------------------------------------------------------

func _on_formula_submitted_sector(formula: String) -> void:
	# Analyse the student's formula before validating
	if _hud and MathEngine.is_valid_formula(formula):
		var info: Dictionary = MathEngine.get_slope_and_intercept(formula)
		var slope_str: String = MathEngine.format_float(info["slope"])
		var intercept_str: String = MathEngine.format_float(info["intercept"])
		_hud.show_feedback(
			"Detected: slope = %s, y-intercept = %s" % [slope_str, intercept_str], "info"
		)
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Waypoint Helpers
# ---------------------------------------------------------------------------

func _spawn_waypoint_marker(math_pos: Vector2) -> void:
	if not _plotter:
		return
	var marker: Node2D = Node2D.new()
	marker.name = "Waypoint"

	# Visual: small glowing circle using a Line2D approximation
	var circle: Line2D = Line2D.new()
	circle.width = 3.0
	circle.default_color = Color(1.0, 0.8, 0.0, 0.9)
	var radius: float = 8.0
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(33):
		var angle: float = TAU * float(i) / 32.0
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	circle.points = points
	marker.add_child(circle)

	var screen_pos: Vector2 = _plotter.math_to_screen(math_pos)
	marker.position = screen_pos + _plotter.position
	add_child(marker)
	_waypoint_markers.append(marker)


func _clear_waypoints() -> void:
	for m in _waypoint_markers:
		m.queue_free()
	_waypoint_markers.clear()
