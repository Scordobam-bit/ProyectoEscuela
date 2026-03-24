## SectorBase.gd
## ==============
## Clase base abstracta para todos los sectores de Planet Waves.
## El nodo raíz de cada escena de sector debe extender esta clase.
class_name SectorBase
extends Node2D

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando todos los desafíos de este sector se completan.
signal sector_complete(sector_index: int)
signal level_completed(sector_index: int)
signal challenge_completed

## Emitida cuando un único desafío se completa.
signal challenge_done(challenge_index: int)

## Emitida cuando comienza un nuevo desafío.
signal challenge_started(challenge_index: int)

# ---------------------------------------------------------------------------
# Propiedades Exportadas
# ---------------------------------------------------------------------------

@export var sector_index: int = 1

## Color de fondo para el entorno espacial del sector.
@export var background_color: Color = Color(0.02, 0.02, 0.1, 1.0)

# ---------------------------------------------------------------------------
# Referencias de Nodos (las subclases deben tenerlas en sus escenas)
# ---------------------------------------------------------------------------

@onready var _plotter: FunctionPlotter = get_node_or_null("%FunctionPlotter") if has_node("%FunctionPlotter") else get_node_or_null("FunctionPlotter")
@onready var _ship: ShipController = get_node_or_null("%Ship") if has_node("%Ship") else get_node_or_null("Ship")
@onready var _meta_area: Area2D = get_node_or_null("%MetaArea") if has_node("%MetaArea") else get_node_or_null("MetaArea")
@export var hud_node: HUD
@export var theory_panel_node: TheoryPanel

# ---------------------------------------------------------------------------
# Estado de Desafíos
# ---------------------------------------------------------------------------

var _current_challenge: int = 0
var _challenges: Array = []   # Arreglo de Diccionarios, rellenado por las subclases
var _goal_triggered: bool = false
var _sector_ready_for_portal: bool = false

## Gestor de obstáculos del sector (instanciado programáticamente).
var _obstacle_manager: GestorObstaculos = null
const _RESTART_AFTER_RESET: bool = false
const _DEFAULT_PLOT_FORMULA: String = "x"
const _HUD_PLOT_BUTTON_PATH: String = "%BtnEjecutar"
const _HUD_THEORY_BUTTON_PATH: String = "%BtnTeoria"
const _HUD_HINT_BUTTON_PATH: String = "%BtnPista"
const _MIN_HUD_LAYER: int = 20
const _THEORY_HINT_Z_OFFSET: int = 80

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	if not has_node("/root/GameManager") or not has_node("/root/MathEngine"):
		await get_tree().process_frame
		if not has_node("/root/GameManager") or not has_node("/root/MathEngine"):
			push_warning("SectorBase: servicios globales no listos (GameManager/MathEngine).")
			return
	await get_tree().process_frame
	# Garantiza que paneles informativos (Teoría/Pista) del HUD no queden
	# ocultos detrás del fondo/parallax en escenas de sector.
	if is_instance_valid(hud_node) and hud_node.layer < _MIN_HUD_LAYER:
		hud_node.layer = _MIN_HUD_LAYER
	_connect_hud_buttons_in_code()
	_connect_goal_area()
	_connect_mission_obstacle_areas()
	_force_cartesian_axes_visible()
	RenderingServer.set_default_clear_color(background_color)
	_setup_world_environment()
	_setup_parallax_stars()
	_setup_obstacles_manager()
	_setup_challenges()
	_connect_hud()
	_connect_plotter()
	_start_challenge(0)


# ---------------------------------------------------------------------------
# Configuración del Entorno Visual
# ---------------------------------------------------------------------------

## Crea y añade un WorldEnvironment con resplandor (glow) para las líneas neón.
func _setup_world_environment() -> void:
	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env_res: Environment = load("res://resources/entorno.tres")
	if env_res:
		env_node.environment = env_res
	add_child(env_node)
	move_child(env_node, 0)


## Genera un campo de estrellas paraláctico animado mediante código.
func _setup_parallax_stars() -> void:
	var parallax_bg: ParallaxBackground = ParallaxBackground.new()
	parallax_bg.name = "ParallaxBackground"
	add_child(parallax_bg)
	move_child(parallax_bg, 1)

	# Capa 1: estrellas lejanas (movimiento lento)
	_create_star_layer(parallax_bg, Vector2(0.05, 0.0), 80, 1.0, 1.5)
	# Capa 2: estrellas medias
	_create_star_layer(parallax_bg, Vector2(0.12, 0.0), 40, 1.5, 2.5)
	# Capa 3: estrellas cercanas (movimiento rápido)
	_create_star_layer(parallax_bg, Vector2(0.22, 0.0), 20, 2.0, 3.5)

	# Mover suavemente el paralaje con el tiempo (sin cámara física)
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(parallax_bg, "scroll_offset", Vector2(3000.0, 0.0), 120.0)


## Crea una capa de estrellas (ParallaxLayer) con movimiento proporcional a [motion_scale].
## Se generan [star_count] puntos distribuidos aleatoriamente con radio entre
## [min_radius] y [max_radius] píxeles.
func _create_star_layer(
		parent: ParallaxBackground,
		motion_scale: Vector2,
		star_count: int,
		min_radius: float,
		max_radius: float) -> void:
	var layer: ParallaxLayer = ParallaxLayer.new()
	layer.motion_scale = motion_scale
	parent.add_child(layer)

	var stars_node: Node2D = Node2D.new()
	layer.add_child(stars_node)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(motion_scale.x * 1000) + star_count

	for _star_index in range(star_count):
		var star: Polygon2D = Polygon2D.new()
		var r: float = rng.randf_range(min_radius, max_radius)
		star.polygon = PackedVector2Array([
			Vector2(0.0, -r), Vector2(r * 0.3, r * 0.3),
			Vector2(-r * 0.3, r * 0.3)
		])
		var brightness: float = rng.randf_range(0.5, 1.0)
		star.color = Color(brightness, brightness, brightness, 0.8)
		star.position = Vector2(
			rng.randf_range(-200.0, 1480.0),
			rng.randf_range(-200.0, 920.0)
		)
		stars_node.add_child(star)


# ---------------------------------------------------------------------------
# Gestión de Obstáculos
# ---------------------------------------------------------------------------

## Crea el nodo GestorObstaculos y lo añade a la escena.
func _setup_obstacles_manager() -> void:
	_obstacle_manager = GestorObstaculos.new()
	_obstacle_manager.name = "GestorObstaculos"
	add_child(_obstacle_manager)


## Sobrescribir en subclases para registrar los obstáculos de cada desafío.
## Se llama al inicio de cada desafío (después de limpiar los obstáculos previos).
func _setup_obstacles_for_challenge(_challenge_index: int) -> void:
	pass


# ---------------------------------------------------------------------------
# Métodos Abstractos (sobrescribir en subclases)
# ---------------------------------------------------------------------------

## Rellena el arreglo _challenges con los datos de los desafíos.
func _setup_challenges() -> void:
	push_warning("SectorBase: _setup_challenges() no fue sobrescrito en %s" % name)


## Llamado cuando comienza un nuevo desafío. Sobrescribir para configurar visuales.
func _on_challenge_begin(_challenge_index: int) -> void:
	pass


## Llamado cuando el jugador envía una fórmula.
## Sobrescribir para añadir lógica de validación específica del sector.
func _on_formula_submitted_sector(formula: String) -> void:
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Gestión de Desafíos
# ---------------------------------------------------------------------------

func _start_challenge(index: int) -> void:
	if index < 0 or index >= _challenges.size():
		return
	_current_challenge = index
	_goal_triggered = false
	_sector_ready_for_portal = false
	challenge_started.emit(index)

	# Limpiar obstáculos previos y generar los del nuevo desafío
	if _obstacle_manager:
		_obstacle_manager.clear_obstacles()
		if _plotter:
			_obstacle_manager.setup(_plotter)
		_setup_obstacles_for_challenge(index)

	# Limpiar línea de referencia previa
	if _plotter:
		_plotter.clear_plot()
		_plotter.reset_line_style()

	if is_instance_valid(hud_node):
		var ch: Dictionary = _challenges[index]
		hud_node.set_formula_hint(ch.get("hint", "Ingresa la fórmula…"))
		hud_node.show_feedback(ch.get("instruction", ""), "info")
		hud_node.set_mission_text(
			"Objetivo - Desafío %d" % (index + 1),
			ch.get("instruction", "")
		)
		hud_node.set_controls_enabled(false)
	if _ship:
		_ship.stop()

	# Mostrar briefing inicial de misión antes del primer desafío
	if index == 0:
		await _show_mission_briefing_for_challenge(index)
	if is_instance_valid(hud_node):
		hud_node.set_controls_enabled(true)

	_on_challenge_begin(index)


func _show_mission_briefing_for_challenge(challenge_index: int) -> void:
	if not is_instance_valid(theory_panel_node):
		return
	var prev_mode: Node.ProcessMode = theory_panel_node.process_mode
	theory_panel_node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	# Permitir que cada desafío defina su propia clave de briefing, con la convención
	# "s{sector}_c{challenge}" como valor por defecto.
	var default_key: String = "s%d_c%d" % [sector_index, challenge_index]
	var key: String = default_key
	if challenge_index < _challenges.size():
		key = _challenges[challenge_index].get("briefing_key", default_key)
	if TheoryPanel.MISSION_BRIEFINGS.has(key):
		theory_panel_node.show_mission_briefing(key)
		await theory_panel_node.panel_closed
	get_tree().paused = false
	theory_panel_node.process_mode = prev_mode


func _advance_challenge() -> void:
	var next: int = _current_challenge + 1
	if next >= _challenges.size():
		_sector_ready_for_portal = true
		if _meta_area == null:
			challenge_completed.emit()
			_on_sector_complete()
			return
		if is_instance_valid(hud_node):
			hud_node.show_feedback("¡Desafíos completados! Navega al portal para cerrar el sector.", "success")
	else:
		_start_challenge(next)


func _on_sector_complete() -> void:
	sector_complete.emit(sector_index)
	level_completed.emit(sector_index)

	# Puntaje del desafío activo que activó el cierre del sector (se persiste atómicamente).
	var active_challenge_score: int = 0
	if _current_challenge >= 0 and _current_challenge < _challenges.size():
		active_challenge_score = int(_challenges[_current_challenge].get("score", 0))
	GameManager.process_sector_victory_atomic(sector_index, _current_challenge, active_challenge_score)

	# Calcular puntuación acumulada del sector para el panel de resultados.
	var score_earned: int = active_challenge_score
	if GameManager.completed_challenges.has(sector_index):
		score_earned = 0
		for ci: int in GameManager.completed_challenges[sector_index]:
			if ci < _challenges.size():
				score_earned += _challenges[ci].get("score", 100)

	# Mostrar panel de "¡Misión Cumplida!" con resumen pedagógico
	var panel: MissionCompletePanel = MissionCompletePanel.new()
	add_child(panel)
	panel.show_results(
		sector_index,
		score_earned,
		GameManager.completed_challenges.get(sector_index, [])
	)

	# Esperar a que el jugador presione "Continuar"
	await panel.continue_pressed

	var next_sector: int = sector_index + 1
	if next_sector <= GameManager.get_last_sector_index():
		GameManager.go_to_sector(next_sector)
	else:
		# Sector final completado → volver al menú principal con fundido
		SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# Conexiones HUD y Graficador
# ---------------------------------------------------------------------------

func _connect_hud() -> void:
	if not is_instance_valid(hud_node):
		return
	if hud_node.formula_submitted.is_connected(_on_formula_submitted_hud):
		hud_node.formula_submitted.disconnect(_on_formula_submitted_hud)
	if hud_node.request_plot.is_connected(plot_formula):
		hud_node.request_plot.disconnect(plot_formula)
	if not hud_node.request_plot.is_connected(_on_hud_request_plot):
		hud_node.request_plot.connect(_on_hud_request_plot)
	if sector_index >= 1 and is_instance_valid(_plotter):
		var line_edit: LineEdit = hud_node.get_node_or_null("HUDPanel/Margin/VBox/FormulaRow/FormulaInput")
		if is_instance_valid(line_edit) and not line_edit.text_submitted.is_connected(_on_formula_text_submitted):
			line_edit.text_submitted.connect(_on_formula_text_submitted)
	hud_node.domain_changed.connect(_on_domain_changed)
	hud_node.theory_requested.connect(_on_theory_requested)
	hud_node.hint_requested.connect(_on_hint_requested)


func _connect_hud_buttons_in_code() -> void:
	if not is_instance_valid(hud_node):
		return
	if not hud_node.is_node_ready():
		await hud_node.ready
	var plot_button: Button = hud_node.get_node_or_null(_HUD_PLOT_BUTTON_PATH)
	if plot_button and not plot_button.pressed.is_connected(hud_node._on_plot_pressed):
		plot_button.pressed.connect(hud_node._on_plot_pressed)
	var theory_button: Button = hud_node.get_node_or_null(_HUD_THEORY_BUTTON_PATH)
	if theory_button and not theory_button.pressed.is_connected(hud_node._on_theory_pressed):
		theory_button.pressed.connect(hud_node._on_theory_pressed)
	if theory_button:
		theory_button.z_index = _MIN_HUD_LAYER + _THEORY_HINT_Z_OFFSET
		_force_button_parent_ignore(theory_button)
	var hint_button: Button = hud_node.get_node_or_null(_HUD_HINT_BUTTON_PATH)
	if hint_button and not hint_button.pressed.is_connected(hud_node._on_hint_pressed):
		hint_button.pressed.connect(hud_node._on_hint_pressed)
	if hint_button:
		hint_button.z_index = _MIN_HUD_LAYER + _THEORY_HINT_Z_OFFSET
		_force_button_parent_ignore(hint_button)


func _force_button_parent_ignore(button: Control) -> void:
	# Evita que contenedores no interactivos del HUD intercepten clics sobre Teoría/Pista.
	var parent_node: Node = button.get_parent()
	while parent_node and parent_node != hud_node:
		if parent_node is Control:
			(parent_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent_node = parent_node.get_parent()


func _connect_plotter() -> void:
	if not is_instance_valid(_plotter):
		return
	if sector_index >= 1 and _plotter.formula.strip_edges().is_empty():
		_plotter.formula = "x"
	_plotter.plot_failed.connect(_on_plot_failed)
	if is_instance_valid(_ship):
		_ship.attach_to_plotter(_plotter)
		if not _ship.trajectory_completed.is_connected(_on_ship_trajectory_completed):
			_ship.trajectory_completed.connect(_on_ship_trajectory_completed)


func _connect_goal_area() -> void:
	if not _meta_area:
		return
	if not _meta_area.body_entered.is_connected(_on_meta_area_body_entered):
		_meta_area.body_entered.connect(_on_meta_area_body_entered)


func _connect_mission_obstacle_areas() -> void:
	var connected_obstacles: Dictionary = {}
	var obstacle_groups: PackedStringArray = ["mission_obstacle", "Obstaculos"]
	for group_name: String in obstacle_groups:
		var obstacles: Array[Node] = get_tree().get_nodes_in_group(group_name)
		for obstacle_node: Node in obstacles:
			if not (obstacle_node is Area2D):
				continue
			var obstacle_area: Area2D = obstacle_node as Area2D
			if connected_obstacles.has(obstacle_area.get_instance_id()):
				continue
			connected_obstacles[obstacle_area.get_instance_id()] = true
			if obstacle_area.get_tree() != get_tree():
				continue
			if not is_ancestor_of(obstacle_area):
				continue
			if not obstacle_area.body_entered.is_connected(_on_mission_obstacle_body_entered):
				obstacle_area.body_entered.connect(_on_mission_obstacle_body_entered)


func _on_meta_area_body_entered(body: Node) -> void:
	if _goal_triggered or body == null or not body.is_in_group("player_ship"):
		return
	if not _sector_ready_for_portal:
		if is_instance_valid(hud_node):
			hud_node.show_feedback("Completa todos los desafíos antes de entrar al portal.", "warning")
		return
	_goal_triggered = true
	if is_instance_valid(_ship):
		_ship.reached_goal.emit()
	challenge_completed.emit()
	_on_sector_complete()


func _on_formula_submitted_hud(formula: String) -> void:
	print("[SECTOR] Botón Ejecutar recibido en sector %d. Fórmula: %s" % [sector_index, formula])
	# Validar la sintaxis antes de graficar — mostrar mensaje educativo si falla
	if not MathEngine.is_valid_formula(formula):
		if is_instance_valid(hud_node):
			var detailed_error: String = MathEngine.get_friendly_error_message(formula)
			hud_node.show_feedback("¡Comando inválido! " + detailed_error, "error")
		return

	if is_instance_valid(_plotter):
		if is_instance_valid(hud_node):
			var domain: Array[float] = hud_node.get_domain()
			if domain.size() >= 2:
				_plotter.domain_min = domain[0]
				_plotter.domain_max = domain[1]
		_plotter.set_formula_and_plot(formula)

	# Verificar colisión con obstáculos antes de validar la fórmula
	if _obstacle_manager and is_instance_valid(_plotter) and _plotter.is_plot_valid():
		var trajectory_points: PackedVector2Array = _plotter.get_screen_points()
		if _obstacle_manager.check_trajectory_collision(trajectory_points):
			var hit_name: String = _obstacle_manager.get_last_hit_name()
			_on_mission_failed(hit_name)
			return  # No validar la fórmula si impacta un obstáculo

	if _ship and is_instance_valid(_plotter) and _plotter.is_plot_valid():
		var path_length: float = 0.0
		var generated_path: Path2D = _plotter.build_path2d()
		if generated_path and generated_path.curve:
			path_length = generated_path.curve.get_baked_length()
		_ship.reset(_RESTART_AFTER_RESET)
		if path_length > 0.0:
			_ship.start()
		elif is_instance_valid(hud_node):
			hud_node.show_feedback("No se pudo generar una trayectoria válida.", "error")

	_on_formula_submitted_sector(formula)


func plot_formula(formula: String) -> void:
	_on_hud_request_plot(formula)


func _on_hud_request_plot(formula: String) -> void:
	var sanitized_formula: String = formula.strip_edges()
	if sanitized_formula.is_empty():
		sanitized_formula = _DEFAULT_PLOT_FORMULA
	_on_formula_submitted_hud(sanitized_formula)


func _on_formula_text_submitted(formula: String) -> void:
	if not is_instance_valid(_plotter):
		return
	var sanitized: String = formula.strip_edges()
	if sanitized.is_empty():
		return
	if is_instance_valid(hud_node):
		var domain: Array[float] = hud_node.get_domain()
		if domain.size() >= 2:
			_plotter.domain_min = domain[0]
			_plotter.domain_max = domain[1]
	_plotter.set_formula_and_plot(sanitized)


func _on_domain_changed(min_x: float, max_x: float) -> void:
	if _plotter:
		_plotter.domain_min = min_x
		_plotter.domain_max = max_x
	GameManager.notify_inspector_values_changed(sector_index, min_x, max_x)
	if is_instance_valid(_ship):
		var domain_span: float = max_x - min_x
		_ship.speed = clampf(0.04 + domain_span * 0.006, 0.04, 0.2)


func _force_cartesian_axes_visible() -> void:
	var axis_x: CanvasItem = get_node_or_null("CartesianPlane/AxisX")
	if is_instance_valid(axis_x):
		axis_x.visible = true
	var axis_y: CanvasItem = get_node_or_null("CartesianPlane/AxisY")
	if is_instance_valid(axis_y):
		axis_y.visible = true


func _on_plot_failed(error_message: String) -> void:
	if is_instance_valid(hud_node):
		hud_node.show_feedback("⚠ " + error_message, "error")


func _get_sector_tutorial_key() -> String:
	return "s%d_tutorial" % sector_index


func _on_theory_requested() -> void:
	var sector_theory: String = SectorDataManager.get_theory_text(sector_index)
	if is_instance_valid(hud_node) and not sector_theory.is_empty():
		hud_node.set_mission_text("Teoría", sector_theory)
	if is_instance_valid(theory_panel_node):
		var prev_mode: Node.ProcessMode = theory_panel_node.process_mode
		theory_panel_node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		var was_paused: bool = get_tree().paused
		get_tree().paused = true
		var tutorial_key: String = _get_sector_tutorial_key()
		if TheoryPanel.MISSION_BRIEFINGS.has(tutorial_key):
			theory_panel_node.show_mission_briefing(tutorial_key)
		else:
			theory_panel_node.show_sector_theory(sector_index)
		await theory_panel_node.panel_closed
		get_tree().paused = was_paused
		theory_panel_node.process_mode = prev_mode


func _on_hint_requested() -> void:
	var sector_hint: String = SectorDataManager.get_hint_text(sector_index)
	if is_instance_valid(hud_node) and not sector_hint.is_empty():
		hud_node.set_mission_text("Pista", sector_hint)
	if _current_challenge < _challenges.size():
		var hint: String = _challenges[_current_challenge].get("solution_hint", "Sin pista disponible.")
		if is_instance_valid(hud_node):
			hud_node.show_feedback("Pista: " + hint, "warning")
		if is_instance_valid(theory_panel_node):
			var prev_mode: Node.ProcessMode = theory_panel_node.process_mode
			theory_panel_node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
			var was_paused: bool = get_tree().paused
			get_tree().paused = true
			var tutorial_key: String = _get_sector_tutorial_key()
			if TheoryPanel.MISSION_BRIEFINGS.has(tutorial_key):
				theory_panel_node.show_mission_briefing(tutorial_key)
				await theory_panel_node.panel_closed
			get_tree().paused = was_paused
			theory_panel_node.process_mode = prev_mode
		GameManager.hints_used += 1


# ---------------------------------------------------------------------------
# Validación de Fórmulas
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
		ch.get("feedback_correct", "¡Correcto! ¡Bien hecho!"),
		ch.get("feedback_wrong", "No es correcto. Revisa tu fórmula e inténtalo de nuevo.")
	)
	if correct:
		# Respuesta correcta: restaurar estilo de línea
		if _plotter:
			_plotter.reset_line_style()
		GameManager.complete_challenge(sector_index, _current_challenge, ch.get("score", 100))
		challenge_done.emit(_current_challenge)
		await get_tree().create_timer(1.5).timeout
		_advance_challenge()
	else:
		# Respuesta incorrecta: mostrar Línea Fantasma con la solución correcta
		if _plotter and not expected.is_empty():
			_plotter.mark_as_error()
			_plotter.show_reference_line(expected, Color(0.0, 1.0, 0.3, 0.7))
		# Generar explicación automática del error
		if is_instance_valid(hud_node) and not expected.is_empty():
			hud_node.show_auto_error_explanation(player_formula, expected)


func _on_ship_trajectory_completed() -> void:
	if _goal_triggered:
		return
	if is_instance_valid(hud_node):
		hud_node.show_feedback("Trayectoria Fallida", "error")
	if is_instance_valid(_ship):
		_ship.reset()


func _on_mission_obstacle_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player_ship"):
		return
	_on_mission_failed("Obstáculo")


func _on_mission_failed(obstacle_name: String = "") -> void:
	_goal_triggered = false
	_sector_ready_for_portal = false
	if is_instance_valid(_ship):
		_ship.stop()
		_ship.reset()
	if is_instance_valid(hud_node):
		if obstacle_name.is_empty():
			hud_node.show_feedback("⚠ MISIÓN FALLIDA — Impacto detectado.", "mission_failed")
		else:
			hud_node.show_mission_failed(obstacle_name)
