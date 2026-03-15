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

@onready var _plotter: FunctionPlotter = $FunctionPlotter
@onready var _ship: ShipController = $Ship
@onready var _hud: HUD = $HUD
@onready var _theory_panel: TheoryPanel = $HUD/TheoryPanel

# ---------------------------------------------------------------------------
# Estado de Desafíos
# ---------------------------------------------------------------------------

var _current_challenge: int = 0
var _challenges: Array = []   # Arreglo de Diccionarios, rellenado por las subclases

## Gestor de obstáculos del sector (instanciado programáticamente).
var _obstacle_manager: GestorObstaculos = null

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
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

	for _i in range(star_count):
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
func _on_challenge_begin(challenge_index: int) -> void:
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
	challenge_started.emit(index)

	# Limpiar obstáculos previos y generar los del nuevo desafío
	if _obstacle_manager:
		_obstacle_manager.clear_obstacles()
		if _plotter:
			_obstacle_manager.setup(_plotter)
		_setup_obstacles_for_challenge(index)

	# Limpiar línea de referencia previa
	if _plotter:
		_plotter.reset_line_style()

	if _hud:
		var ch: Dictionary = _challenges[index]
		_hud.set_formula_hint(ch.get("hint", "Ingresa la fórmula…"))
		_hud.show_feedback(ch.get("instruction", ""), "info")

	# Mostrar briefing de misión antes del desafío
	_show_mission_briefing_for_challenge(index)

	_on_challenge_begin(index)


func _show_mission_briefing_for_challenge(challenge_index: int) -> void:
	if not _theory_panel:
		return
	var key: String = "s%d_c%d" % [sector_index, challenge_index]
	if TheoryPanel.MISSION_BRIEFINGS.has(key):
		_theory_panel.show_mission_briefing(key)


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
			"¡Sector %d Completado! Saltando al siguiente sector…" % sector_index, "success"
		)
	await get_tree().create_timer(2.0).timeout
	var next_sector: int = sector_index + 1
	if next_sector <= GameManager.SECTORS.size():
		GameManager.go_to_sector(next_sector)
	else:
		# Sector final completado → volver al menú principal
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# Conexiones HUD y Graficador
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

	# Verificar colisión con obstáculos antes de validar la fórmula
	if _obstacle_manager and _plotter and _plotter.is_plot_valid():
		var trajectory_points: PackedVector2Array = _plotter.get_screen_points()
		if _obstacle_manager.check_trajectory_collision(trajectory_points):
			var hit_name: String = _obstacle_manager.get_last_hit_name()
			if _hud:
				_hud.show_mission_failed(hit_name)
			if _ship:
				_ship.reset()
			return  # No validar la fórmula si impacta un obstáculo

	_on_formula_submitted_sector(formula)


func _on_domain_changed(min_x: float, max_x: float) -> void:
	if _plotter:
		_plotter.domain_min = min_x
		_plotter.domain_max = max_x


func _on_plot_failed(error_message: String) -> void:
	if _hud:
		_hud.show_feedback("Error al graficar: " + error_message, "error")


func _on_theory_requested() -> void:
	if _theory_panel:
		_theory_panel.show_sector_theory(sector_index)


func _on_hint_requested() -> void:
	if _current_challenge < _challenges.size():
		var hint: String = _challenges[_current_challenge].get("solution_hint", "Sin pista disponible.")
		if _hud:
			_hud.show_feedback("Pista: " + hint, "warning")
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
		if _hud and not expected.is_empty():
			_hud.show_auto_error_explanation(player_formula, expected)

