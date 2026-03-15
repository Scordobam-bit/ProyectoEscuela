## Sector1AsteroidBelt.gd
## =======================
## Sector 1: Cinturón de Asteroides — Introducción a Funciones, Líneas (y=mx+b), Dominio y Rango
##
## Pedagogía
## ---------
## Los estudiantes aprenden que una función mapea entradas a salidas. Las funciones lineales son el
## caso no trivial más sencillo: f(x) = mx + b. La pendiente m codifica la tasa de cambio
## y b codifica el valor inicial. Los desafíos del cinturón de asteroides requieren que el estudiante
## navegue por puntos de referencia especificando la trayectoria lineal correcta.
##
## Desafíos
## --------
## 1. Trazar una línea a través de dos puntos de referencia de asteroides dados.
## 2. Identificar e ingresar una función con una pendiente y ordenada al origen específicas.
## 3. Jefe: Encontrar la línea que evita todos los cúmulos de asteroides (dominio restringido).
class_name Sector1AsteroidBelt
extends SectorBase

# ---------------------------------------------------------------------------
# Marcadores de Puntos de Referencia (creados proceduralmente)
# ---------------------------------------------------------------------------

var _waypoint_markers: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Override: Configurar Desafíos
# ---------------------------------------------------------------------------

func _setup_challenges() -> void:
	sector_index = 1
	background_color = Color(0.02, 0.04, 0.12, 1.0)

	_challenges = [
		{
			"instruction": "Desafío 1: Traza la línea que pasa por los puntos A(−4, −3) y B(4, 5).\nPista: Halla la pendiente m = (y₂−y₁)/(x₂−x₁), luego b = y₁ − m·x₁",
			"hint": "y = m*x + b",
			"expected_formula": "x + 1",
			"feedback_correct": "¡Trayectoria perfecta! ¡Superaste el cinturón de asteroides!",
			"feedback_wrong": "Esa línea no pasa por los puntos. Recalcula la pendiente y la ordenada al origen.",
			"solution_hint": "pendiente = (5−(−3))/(4−(−4)) = 1,  b = −3 − 1·(−4) = 1",
			"score": 150,
			"waypoints": [Vector2(-4, -3), Vector2(4, 5)],
		},
		{
			"instruction": "Desafío 2: Ingresa una función con pendiente −2 y ordenada al origen 3.",
			"hint": "-2*x + 3",
			"expected_formula": "-2*x + 3",
			"feedback_correct": "¡Pendiente y ordenada al origen correctas! Navegación bloqueada.",
			"feedback_wrong": "Verifica tu pendiente (coeficiente de x) y tu ordenada al origen (término constante).",
			"solution_hint": "f(x) = −2x + 3",
			"score": 100,
			"waypoints": [],
		},
		{
			"instruction": "JEFE: El vector de escape pasa por (0, −5) y tiene pendiente 3/2.\n¡Ingresa la función lineal completa para salir del cinturón de asteroides!",
			"hint": "1.5*x - 5",
			"expected_formula": "1.5*x - 5",
			"feedback_correct": "¡SECTOR DESPEJADO! Saltando a los Pozos Gravitatorios…",
			"feedback_wrong": "La trayectoria está bloqueada. Pendiente = 3/2, pasa por (0,−5).",
			"solution_hint": "b = −5 (ordenada al origen), m = 3/2 = 1.5",
			"score": 300,
			"waypoints": [Vector2(0, -5), Vector2(4, 1)],
		},
	]


# ---------------------------------------------------------------------------
# Override: Inicio de Desafío
# ---------------------------------------------------------------------------

func _on_challenge_begin(challenge_index: int) -> void:
	_clear_waypoints()
	var ch: Dictionary = _challenges[challenge_index]
	var waypoints: Array = ch.get("waypoints", [])
	for wp in waypoints:
		_spawn_waypoint_marker(wp)

	# Establecer dominio del graficador
	if _plotter:
		_plotter.domain_min = -10.0
		_plotter.domain_max = 10.0
		_plotter.scale_factor = 40.0


# ---------------------------------------------------------------------------
# Override: Obstáculos del Sector
# ---------------------------------------------------------------------------

## Genera los obstáculos (asteroides) para cada desafío del Cinturón de Asteroides.
func _setup_obstacles_for_challenge(challenge_index: int) -> void:
	if not _obstacle_manager:
		return
	var T: int = GestorObstaculos.TipoObstaculo.ASTEROIDE
	match challenge_index:
		0:
			# Desafío 1: y = x + 1  (los asteroides flanquean el pasillo correcto)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  4.0), 1.0, "Asteroide Alfa-1", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -2.0), 1.0, "Asteroide Alfa-2", T)
			_obstacle_manager.add_obstacle(Vector2( 5.0,  3.0), 1.0, "Asteroide Alfa-3", T)
			_obstacle_manager.add_obstacle(Vector2(-5.0,  0.0), 1.0, "Asteroide Alfa-4", T)
		1:
			# Desafío 2: y = -2x + 3
			_obstacle_manager.add_obstacle(Vector2( 2.0,  1.0), 1.0, "Asteroide Beta-1", T)
			_obstacle_manager.add_obstacle(Vector2(-2.0, -3.0), 1.0, "Asteroide Beta-2", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  6.0), 1.0, "Asteroide Beta-3", T)
			_obstacle_manager.add_obstacle(Vector2( 1.0, -1.0), 1.0, "Asteroide Beta-4", T)
		2:
			# Jefe: y = 1.5x - 5
			_obstacle_manager.add_obstacle(Vector2( 0.0, -1.0), 1.0, "Asteroide Gamma-1", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -9.0), 1.0, "Asteroide Gamma-2", T)
			_obstacle_manager.add_obstacle(Vector2( 4.0,  5.0), 1.0, "Asteroide Gamma-3", T)
			_obstacle_manager.add_obstacle(Vector2(-4.0, -7.0), 1.0, "Asteroide Gamma-4", T)


# ---------------------------------------------------------------------------
# Override: Envío de Fórmula
# ---------------------------------------------------------------------------

func _on_formula_submitted_sector(formula: String) -> void:
	# Analizar la fórmula del estudiante antes de validar
	if _hud and MathEngine.is_valid_formula(formula):
		var info: Dictionary = MathEngine.get_slope_and_intercept(formula)
		var slope_str: String = MathEngine.format_float(info["slope"])
		var intercept_str: String = MathEngine.format_float(info["intercept"])
		_hud.show_feedback(
			"Detectado: pendiente = %s, ordenada al origen = %s" % [slope_str, intercept_str], "info"
		)
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Auxiliares de Puntos de Referencia
# ---------------------------------------------------------------------------

func _spawn_waypoint_marker(math_pos: Vector2) -> void:
	if not _plotter:
		return
	var marker: Node2D = Node2D.new()
	marker.name = "Waypoint"

	# Visual: pequeño círculo luminoso usando una aproximación con Line2D
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
