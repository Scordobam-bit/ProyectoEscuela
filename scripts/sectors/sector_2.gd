## Sector2GravityWells.gd
## =======================
## Sector 2: Pozos Gravitatorios — Funciones Cuadráticas, Vértices y Raíces
##
## Pedagogía
## ---------
## Una función cuadrática f(x) = ax² + bx + c es un polinomio de segundo grado cuya gráfica
## es una parábola. El vértice (h, k) = (−b/2a, f(−b/2a)) es el extremo.
## Las raíces se encuentran con la fórmula cuadrática: x = (−b ± √Δ) / 2a, Δ = b²−4ac.
## Los pozos gravitatorios en el juego representan potenciales gravitacionales parabólicos.
##
## Desafíos
## --------
## 1. Ingresar la parábola que pasa por tres puntos gravitacionales dados.
## 2. Hallar el vértice de una cuadrática dada (ingresar la coordenada x).
## 3. JEFE: Hallar las raíces del potencial gravitacional para trazar una trayectoria de escape.
class_name Sector2GravityWells
extends SectorBase

# ---------------------------------------------------------------------------
# Estado específico del sector
# ---------------------------------------------------------------------------

var _reference_plotter: FunctionPlotter = null   # muestra la curva de "referencia"
var _particle_markers: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Override: Configurar Desafíos
# ---------------------------------------------------------------------------

func _setup_challenges() -> void:
	sector_index = 2
	background_color = Color(0.05, 0.02, 0.12, 1.0)

	_challenges = [
		{
			"briefing_key": "s2_tutorial",
			"instruction": "Desafío 1: Un pozo gravitatorio sigue f(x) = x² − 4.\nGrafica esta función para revelar la curvatura del pozo.",
			"hint": "x^2 - 4",
			"expected_formula": "x^2 - 4",
			"feedback_correct": "¡Pozo mapeado! La parábola está bloqueada.",
			"feedback_wrong": "No es correcto. El pozo es cuadrático: f(x) = ax² + c",
			"solution_hint": "f(x) = x² − 4  (a=1, b=0, c=−4)",
			"score": 150,
		},
		{
			"instruction": "Desafío 2: Halla la coordenada x del vértice de f(x) = 2x² − 8x + 5.\nIngresala como función constante: solo el valor x (p. ej. '2').",
			"hint": "2",
			"expected_formula": "2",
			"feedback_correct": "¡Vértice correcto! h = −b/(2a) = 8/4 = 2",
			"feedback_wrong": "Usa la fórmula del vértice: h = −b / (2a)",
			"solution_hint": "h = −(−8) / (2·2) = 8/4 = 2",
			"score": 200,
		},
		{
			"instruction": "JEFE: El potencial gravitacional es g(x) = x² − 5x + 4.\n¡Halla las raíces de escape! Ingresa la raíz menor como constante.",
			"hint": "1",
			"expected_formula": "1",
			"feedback_correct": "¡VELOCIDAD DE ESCAPE ALCANZADA! ¡Sector 2 completado!",
			"feedback_wrong": "Aplica la fórmula cuadrática: x = (−b ± √(b²−4ac)) / 2a",
			"solution_hint": "Δ = 25−16 = 9, raíces = (5±3)/2 → x=1 y x=4",
			"score": 350,
		},
	]


# ---------------------------------------------------------------------------
# Override: Inicio de Desafío
# ---------------------------------------------------------------------------

func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -6.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 45.0

	match challenge_index:
		0:
			_spawn_gravity_well_visual()
		1:
			# Mostrar la parábola de referencia para que los estudiantes visualicen el vértice
			_show_reference_curve("2*x^2 - 8*x + 5")
		2:
			_show_reference_curve("x^2 - 5*x + 4")
			_spawn_escape_markers()


# ---------------------------------------------------------------------------
# Override: Obstáculos del Sector
# ---------------------------------------------------------------------------

## Genera los obstáculos (pozos gravitatorios) para cada desafío del Sector 2.
func _setup_obstacles_for_challenge(challenge_index: int) -> void:
	if not _obstacle_manager:
		return
	var T: int = GestorObstaculos.TipoObstaculo.POZO_GRAVITATORIO
	match challenge_index:
		0:
			# Desafío 1: y = x² − 4  (pasillo central libre)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -1.0), 0.8, "Pozo Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -7.0), 0.8, "Pozo Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 3.5,  2.0), 0.8, "Pozo Gamma", T)
			_obstacle_manager.add_obstacle(Vector2(-3.5,  2.0), 0.8, "Pozo Delta", T)
		1:
			# Desafío 2: y = 2 (constante)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  4.5), 0.8, "Pozo Épsilon", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -0.5), 0.8, "Pozo Zeta", T)
			_obstacle_manager.add_obstacle(Vector2( 3.0,  4.0), 0.8, "Pozo Eta", T)
		2:
			# Jefe: y = 1 (constante — raíz menor de x²−5x+4)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  3.0), 0.8, "Pozo Gravitatorio Theta", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -1.5), 0.8, "Pozo Gravitatorio Iota", T)
			_obstacle_manager.add_obstacle(Vector2( 2.0,  4.0), 0.8, "Pozo Gravitatorio Kappa", T)


# ---------------------------------------------------------------------------
# Override: Envío de Fórmula
# ---------------------------------------------------------------------------

func _on_formula_submitted_sector(formula: String) -> void:
	if hud_node and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			1:
				# Mostrar información del vértice
				var vertex: Vector2 = MathEngine.find_vertex("2*x^2 - 8*x + 5", -5.0, 10.0)
				hud_node.show_feedback(
					"Vértice de referencia en x = %s, y = %s" % [
						MathEngine.format_float(vertex.x),
						MathEngine.format_float(vertex.y)
					], "info"
				)
			2:
				# Mostrar información del discriminante
				var qf: Dictionary = MathEngine.quadratic_formula(1.0, -5.0, 4.0)
				hud_node.show_feedback(
					"Δ = %s, raíces: %s" % [
						MathEngine.format_float(qf["discriminant"]),
						str(qf["roots"])
					], "info"
				)
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Auxiliares
# ---------------------------------------------------------------------------

func _show_reference_curve(ref_formula: String) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -6.0
	_reference_plotter.domain_max = 6.0
	_reference_plotter.scale_factor = 45.0
	_reference_plotter.line_color = Color(0.8, 0.4, 1.0, 0.5)   # morado tenue
	_reference_plotter.line_width = 1.5
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_particle_markers.append(_reference_plotter)


func _spawn_gravity_well_visual() -> void:
	# Dibujar un indicador radial sutil del "pozo" en el origen
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
	# Marcar las dos raíces en x=1 y x=4
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
