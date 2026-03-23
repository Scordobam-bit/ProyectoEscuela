class_name Sector0Academia
extends SectorBase

const PLAYER_SHIP_GROUP: StringName = &"player_ship"

var _tutorial_manager: TutorialManager = null
@onready var _trajectory_path: Path2D = get_node_or_null("TrajectoryPath")
@onready var _path_follower: PathFollow2D = get_node_or_null("TrajectoryPath/PathFollower")
@onready var _goal_portal: Area2D = get_node_or_null("GoalPortal")
@onready var _ship_body: Node2D = get_node_or_null("TrajectoryPath/PathFollower/ShipBody")

@export_range(0.01, 1.0, 0.01) var path_follow_speed: float = 0.08

var _movement_active: bool = false
var _portal_triggered: bool = false


func _ready() -> void:
	await super._ready()
	if hud_node:
		if hud_node.formula_submitted.is_connected(_on_formula_submitted_hud):
			hud_node.formula_submitted.disconnect(_on_formula_submitted_hud)
		if not hud_node.request_plot.is_connected(_on_hud_request_plot):
			hud_node.request_plot.connect(_on_hud_request_plot)
	_connect_goal_portal()


func _process(delta: float) -> void:
	if not _movement_active or _path_follower == null:
		return
	_path_follower.progress_ratio = minf(_path_follower.progress_ratio + path_follow_speed * delta, 1.0)
	if _path_follower.progress_ratio >= 1.0:
		_movement_active = false


func _setup_challenges() -> void:
	sector_index = 0
	background_color = Color(0.01, 0.03, 0.1, 1.0)
	_challenges = [
		{
			"briefing_key": "s0_tutorial",
			"instruction":
				(
					"Para avanzar, escribe una función f(x) que trace tu ruta. Usa Backspace para corregir y el botón 'Graficar' para ejecutar tu vuelo.\n"
					+ "Llega al portal verde. Si el portal está a una altura de 5, prueba escribiendo simplemente '5'."
				),
			"hint": "5",
			"expected_formula": "5",
			"feedback_correct": "¡Academia completada! Sector 1 desbloqueado.",
			"feedback_wrong": "Intenta una función constante que pase por y = 5.",
			"solution_hint": "Escribe solo: 5",
			"score": 50,
			"waypoints": [],
		},
	]


func _on_challenge_begin(_challenge_index: int) -> void:
	_clear_trajectory_path()
	if _plotter:
		_plotter.domain_min = -10.0
		_plotter.domain_max = 10.0
		_plotter.scale_factor = 40.0
	if not GameManager.tutorial_completed:
		_setup_tutorial_manager()
		if _tutorial_manager:
			_tutorial_manager.start()


func _setup_obstacles_for_challenge(_challenge_index: int) -> void:
	pass


func _on_formula_submitted_sector(_formula: String) -> void:
	pass


func _on_hud_request_plot(formula: String) -> void:
	var normalized_formula: String = formula.strip_edges()
	if normalized_formula.is_empty():
		if hud_node:
			hud_node.show_feedback("Por favor ingresa una fórmula primero.", "warning")
		return
	if not MathEngine.is_valid_formula(normalized_formula):
		if hud_node:
			hud_node.show_feedback("¡Comando inválido! " + MathEngine.get_friendly_error_message(normalized_formula), "error")
		return
	if _plotter:
		_plotter.formula = normalized_formula
	var points: PackedVector2Array = _build_trajectory_points(normalized_formula)
	_apply_path_points(points)
	if points.size() < 2 and hud_node:
		hud_node.show_feedback("No se pudo generar una trayectoria válida.", "error")


func _build_trajectory_points(formula: String) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if _plotter == null:
		return points
	var trajectory_point_count: int = maxi(_plotter.sample_count, 2)
	var step: float = (_plotter.domain_max - _plotter.domain_min) / float(trajectory_point_count - 1)
	var use_y_clamp: bool = _plotter.y_clamp > 0.0
	for i in range(trajectory_point_count):
		var x: float = _plotter.domain_min + step * float(i)
		var result: Dictionary = MathEngine.evaluate(formula, x)
		if not result.get("ok", false):
			continue
		var y: float = float(result.get("value", NAN))
		if is_nan(y) or is_inf(y):
			continue
		if use_y_clamp and absf(y) > _plotter.y_clamp:
			continue
		points.append(_plotter.math_to_screen(Vector2(x, y)))
	return points


func _apply_path_points(points: PackedVector2Array) -> void:
	if _trajectory_path == null:
		return
	if _trajectory_path.curve == null:
		_trajectory_path.curve = Curve2D.new()
	_trajectory_path.curve.clear_points()
	for pt in points:
		_trajectory_path.curve.add_point(pt)
	if _path_follower:
		_path_follower.progress_ratio = 0.0
	_movement_active = points.size() >= 2


func _clear_trajectory_path() -> void:
	_movement_active = false
	_portal_triggered = false
	if _trajectory_path == null:
		return
	if _trajectory_path.curve == null:
		_trajectory_path.curve = Curve2D.new()
	_trajectory_path.curve.clear_points()
	if _path_follower:
		_path_follower.progress_ratio = 0.0
	if _ship_body:
		_ship_body.position = Vector2.ZERO


func _connect_goal_portal() -> void:
	if _goal_portal and not _goal_portal.body_entered.is_connected(_on_goal_portal_body_entered):
		_goal_portal.body_entered.connect(_on_goal_portal_body_entered)


func _on_goal_portal_body_entered(body: Node) -> void:
	if _portal_triggered or not body.is_in_group(PLAYER_SHIP_GROUP):
		return
	_portal_triggered = true
	_movement_active = false
	GameManager.unlock_next_level()


func _setup_tutorial_manager() -> void:
	if _tutorial_manager:
		return
	_tutorial_manager = TutorialManager.new()
	_tutorial_manager.name = "TutorialManager"
	add_child(_tutorial_manager)
	if hud_node:
		_tutorial_manager.setup(hud_node)
	_tutorial_manager.guide_completed.connect(_on_tutorial_guide_finished)
	_tutorial_manager.guide_skipped.connect(_on_tutorial_guide_finished)


func _on_tutorial_guide_finished() -> void:
	GameManager.tutorial_completed = true
