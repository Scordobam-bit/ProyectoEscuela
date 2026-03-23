class_name Sector0Academia
extends SectorBase

const PLAYER_SHIP_GROUP: StringName = &"player_ship"
const PORTAL_DEFAULT_COLOR: Color = Color(0.2, 1, 0.35, 0.8)
const PORTAL_SUCCESS_COLOR: Color = Color(0.0, 1.0, 1.0, 1.0)

var _tutorial_manager: TutorialManager = null
@onready var _trajectory_path: Path2D = get_node_or_null("TrajectoryPath")
@onready var _trajectory_line: Line2D = get_node_or_null("TrajectoryPath/TrajectoryLine")
@onready var _path_follower: PathFollow2D = get_node_or_null("TrajectoryPath/PathFollower")
@onready var _goal_portal: Area2D = get_node_or_null("GoalPortal")
@onready var _portal_visual: Polygon2D = get_node_or_null("GoalPortal/PortalVisual")
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
			"solution_hint": SectorDataManager.get_hint_text(0),
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
		_plotter.set_formula_and_plot(normalized_formula)
	var points: PackedVector2Array = _build_trajectory_points()
	_apply_path_points(points)
	_apply_trajectory_line(points)
	if points.size() < 2 and hud_node:
		hud_node.show_feedback("No se pudo generar una trayectoria válida.", "error")


func _build_trajectory_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if _plotter == null or not _plotter.is_plot_valid():
		return points
	points = _plotter.get_screen_points()
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
	_clear_trajectory_line()
	if _trajectory_path == null:
		return
	if _trajectory_path.curve == null:
		_trajectory_path.curve = Curve2D.new()
	_trajectory_path.curve.clear_points()
	if _path_follower:
		_path_follower.progress_ratio = 0.0
	if _ship_body:
		_ship_body.position = Vector2.ZERO
	if _portal_visual:
		_portal_visual.color = PORTAL_DEFAULT_COLOR


func _apply_trajectory_line(points: PackedVector2Array) -> void:
	if _trajectory_line == null:
		return
	_trajectory_line.clear_points()
	for pt in points:
		_trajectory_line.add_point(pt)


func _clear_trajectory_line() -> void:
	if _trajectory_line:
		_trajectory_line.clear_points()


func _connect_goal_portal() -> void:
	if _goal_portal and not _goal_portal.body_entered.is_connected(_on_goal_portal_body_entered):
		_goal_portal.body_entered.connect(_on_goal_portal_body_entered)


func _on_goal_portal_body_entered(body: Node) -> void:
	if _portal_triggered or not body.is_in_group(PLAYER_SHIP_GROUP):
		return
	_portal_triggered = true
	_movement_active = false
	_goal_triggered = true
	if _portal_visual:
		_portal_visual.color = PORTAL_SUCCESS_COLOR
	if hud_node:
		hud_node.show_feedback("¡Misión Cumplida! Portal asegurado.", "success")
	challenge_completed.emit()
	var score: int = 50
	if _current_challenge >= 0 and _current_challenge < _challenges.size():
		score = int(_challenges[_current_challenge].get("score", score))
	GameManager.complete_challenge(sector_index, _current_challenge, score)
	await get_tree().create_timer(0.6).timeout
	GameManager.unlock_next_level()


func _on_theory_requested() -> void:
	var theory_text: String = SectorDataManager.get_theory_text(0)
	if hud_node:
		hud_node.show_feedback(theory_text, "info")
		hud_node.set_mission_text("Teoría", theory_text)
	if theory_panel_node:
		theory_panel_node.show_mission_briefing("s0_tutorial")


func _on_hint_requested() -> void:
	var hint_text: String = SectorDataManager.get_hint_text(0)
	if hud_node:
		hud_node.show_feedback("Pista: " + hint_text, "warning")
		hud_node.set_mission_text("Pista", hint_text)
	GameManager.hints_used += 1


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
