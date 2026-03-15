## Sector5EventHorizon.gd
## =======================
## Sector 5: Horizonte de Sucesos — Inyectividad, Inversas (f⁻¹), Exponenciales (e),
##           Logaritmos (ln) y Trigonometría Inversa
##
## Pedagogía
## ---------
## El Horizonte de Sucesos es el límite de no retorno de un agujero negro — matemáticamente
## análogo al límite de dominio donde una función pierde su inyectividad. Para escapar,
## los estudiantes deben dominar:
##   1. Inyectividad (prueba de la línea horizontal)
##   2. Hallar funciones inversas analíticamente
##   3. Propiedades de eˣ y ln(x) como inversas mutuas
##   4. Trig inversa: arcsen, arccos, arctan y sus rangos de valores principales
##
## Batalla Final
## -------------
## La fórmula gravitacional del agujero negro es f(x) = eˣ − 2.
## Para escapar: ingresa su inversa f⁻¹(x) = ln(x + 2).
class_name Sector5EventHorizon
extends SectorBase

var _reference_plotter: FunctionPlotter = null
var _inverse_plotter: FunctionPlotter = null
var _symmetry_line: Line2D = null
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 5
	background_color = Color(0.06, 0.01, 0.02, 1.0)

	_challenges = [
		{
			"instruction": "Desafío 1: ¿Es f(x) = x³ inyectiva? Ingresa '1' para Sí o '0' para No.",
			"hint": "1",
			"expected_formula": "1",
			"feedback_correct": "¡Correcto! x³ es estrictamente creciente → inyectiva.",
			"feedback_wrong": "Recuerda la prueba de la línea horizontal. ¿Toda línea horizontal intersecta x³ a lo sumo una vez?",
			"solution_hint": "Sí (1). x³ es monótonamente creciente en todo su dominio.",
			"score": 150,
		},
		{
			"instruction": "Desafío 2: Halla la inversa de f(x) = 2x + 4.\n" +
				"Pasos: y = 2x+4 → x = (y−4)/2 → f⁻¹(x) = (x−4)/2",
			"hint": "(x - 4) / 2",
			"expected_formula": "(x - 4) / 2",
			"feedback_correct": "¡Inversa encontrada! f⁻¹(x) = (x−4)/2",
			"feedback_wrong": "Intercambia x e y: si y = 2x+4, despeja x en términos de y.",
			"solution_hint": "f⁻¹(x) = (x − 4) / 2",
			"score": 250,
		},
		{
			"instruction": "Desafío 3: Ingresa el logaritmo natural de (x + 2).\n" +
				"Esta es la inversa de eˣ − 2.",
			"hint": "log(x + 2)",
			"expected_formula": "log(x + 2)",
			"feedback_correct": "¡ln(x+2) confirmado. La exponencial y el logaritmo son inversas perfectas!",
			"feedback_wrong": "ln es la inversa de eˣ. Si f(x) = eˣ−2, entonces f⁻¹(x) = ln(x+2).",
			"solution_hint": "ln(x+2) → en Godot: log(x+2)",
			"score": 300,
		},
		{
			"instruction": "⚡ BATALLA FINAL: La fórmula gravitacional del agujero negro es f(x) = eˣ − 2.\n" +
				"¡INGRESA SU INVERSA para liberarte del Horizonte de Sucesos!",
			"hint": "log(x + 2)",
			"expected_formula": "log(x + 2)",
			"feedback_correct": "🌟 ¡Inversa hallada! Preparando secuencia de escape…",
			"feedback_wrong": "Si f(x) = eˣ − 2, invierte: y = eˣ−2 → x = ln(y+2) → f⁻¹(y) = ln(y+2)",
			"solution_hint": "f⁻¹(x) = ln(x + 2)  → Godot: log(x + 2)",
			"score": 500,
		},
		{
			"instruction": "🌌 FUNCIÓN COMPUESTA — ESTABILIZACIÓN FINAL:\n" +
				"f(x) = ln(x)  y  g(x) = eˣ + 2.\n" +
				"Calcula (f∘g)(x) = f(g(x)) e ingresa la fórmula resultante para estabilizar\n" +
				"el Horizonte de Sucesos y salvar la nave.",
			"hint": "log(exp(x) + 2)",
			"expected_formula": "log(exp(x) + 2)",
			"feedback_correct": "🌟 ¡HORIZONTE DE SUCESOS ESTABILIZADO! ¡Planet Waves completado! 🌟\n" +
				"f(g(x)) = ln(eˣ + 2) ✓  — ¡dominio de funciones compuestas confirmado!",
			"feedback_wrong": "Sustituye g(x) en f: f(g(x)) = ln(eˣ + 2).\n" +
				"En Godot: log(exp(x) + 2)",
			"solution_hint": "f(g(x)) = ln(eˣ + 2)  → en Godot: log(exp(x) + 2)",
			"score": 750,
			"briefing_key": "s5_c4",
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -4.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 55.0
		_plotter.y_clamp = 10.0

	match challenge_index:
		0:
			_show_reference("x^3", Color(0.6, 0.8, 1.0, 0.5))
		1:
			_show_reference("2*x + 4", Color(0.6, 0.8, 1.0, 0.5))
			_show_symmetry_line()
		2:
			# Mostrar eˣ − 2 y su inversa log(x+2) por separado
			_show_reference("exp(x) - 2", Color(1.0, 0.5, 0.2, 0.5))
			_show_symmetry_line()
		3:
			# Jefe parcial: mostrar la fórmula gravitacional
			_show_reference("exp(x) - 2", Color(1.0, 0.2, 0.2, 0.8))
			_show_symmetry_line()
			_spawn_event_horizon_ring()
		4:
			# FUNCIÓN COMPUESTA FINAL: f(x)=ln(x) y g(x)=eˣ+2 → f(g(x))=ln(eˣ+2)
			_show_reference("log(x)", Color(0.3, 1.0, 0.5, 0.7))
			_show_reference_secondary("exp(x) + 2", Color(1.0, 0.4, 0.1, 0.7))
			_show_symmetry_line()
			_spawn_event_horizon_ring()
			_spawn_composite_sequence_vfx()


# ---------------------------------------------------------------------------
# Override: Obstáculos del Sector
# ---------------------------------------------------------------------------

## Genera los obstáculos (púlsares del horizonte) para cada desafío del Sector 5.
func _setup_obstacles_for_challenge(challenge_index: int) -> void:
	if not _obstacle_manager:
		return
	var T: int = GestorObstaculos.TipoObstaculo.PULSAR
	match challenge_index:
		0:
			# Desafío 1: y = 1 (constante)
			_obstacle_manager.add_obstacle(Vector2( 3.0,  4.0), 0.7, "Singularidad Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(-2.0,  4.0), 0.7, "Singularidad Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -2.0), 0.7, "Singularidad Gamma", T)
		1:
			# Desafío 2: y = (x−4)/2
			_obstacle_manager.add_obstacle(Vector2( 0.0,  1.0), 0.7, "Horizonte Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -5.0), 0.7, "Horizonte Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 4.0,  3.5), 0.7, "Horizonte Gamma", T)
		2:
			# Desafío 3: y = log(x+2)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  2.5), 0.7, "Velo de Sucesos Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -1.5), 0.7, "Velo de Sucesos Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 3.0,  4.0), 0.7, "Velo de Sucesos Gamma", T)
		3:
			# Jefe parcial: y = log(x+2)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  3.0), 0.8, "Centinela del Horizonte Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -1.5), 0.8, "Centinela del Horizonte Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 4.0,  5.0), 0.8, "Centinela del Horizonte Gamma", T)
			_obstacle_manager.add_obstacle(Vector2(-1.0,  2.0), 0.8, "Centinela del Horizonte Delta", T)
		4:
			# FUNCIÓN COMPUESTA FINAL: y = x (identidad)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  3.0), 0.8, "Guardián de la Singularidad Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 3.0,  0.0), 0.8, "Guardián de la Singularidad Beta", T)
			_obstacle_manager.add_obstacle(Vector2(-2.0,  2.0), 0.8, "Guardián de la Singularidad Gamma", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -3.0), 0.8, "Guardián de la Singularidad Delta", T)


func _on_formula_submitted_sector(formula: String) -> void:
	if hud_node and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			1:
				# Mostrar verificación de inyectividad de la función de referencia
				var inj: Dictionary = MathEngine.check_injectivity("2*x + 4")
				hud_node.show_feedback(
					"Inyectividad de 2x+4: %s (creciente: %s)" % [
						str(inj["injective"]), str(inj["monotone_increasing"])
					], "info"
				)
				# Advertencia de inyectividad si la fórmula del jugador no es inyectiva
				_check_and_warn_injectivity(formula)
			2, 3:
				# Advertencia de inyectividad antes de mostrar la inversa
				if _check_and_warn_injectivity(formula):
					return   # Fórmula no inyectiva → no continuar con la validación

				# Mostrar la inversa graficada junto a f para confirmar simetría sobre y=x
				if _inverse_plotter:
					_inverse_plotter.queue_free()
				_inverse_plotter = FunctionPlotter.new()
				_inverse_plotter.formula = formula
				_inverse_plotter.domain_min = -2.0
				_inverse_plotter.domain_max = 10.0
				_inverse_plotter.scale_factor = 55.0
				_inverse_plotter.y_clamp = 10.0
				_inverse_plotter.line_color = Color(0.0, 1.0, 0.5, 0.9)
				_inverse_plotter.line_width = 2.5
				_inverse_plotter.show_axes = false
				_inverse_plotter.position = _plotter.position if _plotter else Vector2.ZERO
				add_child(_inverse_plotter)
				_markers.append(_inverse_plotter)
			4:
				# Mostrar la función compuesta evaluada en un punto de prueba
				var composed: String = MathEngine.compose("log(x)", "exp(x) + 2")
				hud_node.show_feedback(
					"Verificación f(g(x)): f(g(x)) = %s" % composed, "info"
				)
	_validate_formula_against_current(formula)


## Comprueba si la fórmula enviada es inyectiva en el dominio actual.
## Si no lo es, muestra el mensaje de Advertencia de Inyectividad y devuelve true.
func _check_and_warn_injectivity(formula: String) -> bool:
	var d_min: float = -5.0
	var d_max: float = 5.0
	if _plotter:
		d_min = _plotter.domain_min
		d_max = _plotter.domain_max
	var result: Dictionary = MathEngine.check_injectivity(formula, d_min, d_max)
	if not result["injective"]:
		if hud_node:
			hud_node.show_feedback(
				"⚠ Error de Simetría: La trayectoria actual no es inyectiva y "
				+ "no posee inversa en este dominio.\n"
				+ "Restrinja el dominio o use una función estrictamente monótona.",
				"error"
			)
		return true
	return false


func _show_reference(ref_formula: String, color: Color) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -4.0
	_reference_plotter.domain_max = 6.0
	_reference_plotter.scale_factor = 55.0
	_reference_plotter.y_clamp = 10.0
	_reference_plotter.line_color = color
	_reference_plotter.line_width = 2.0
	_reference_plotter.show_axes = false
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_markers.append(_reference_plotter)


func _show_symmetry_line() -> void:
	# Dibujar la línea y=x para visualizar la simetría de la inversa
	if _symmetry_line:
		_symmetry_line.queue_free()
	_symmetry_line = Line2D.new()
	_symmetry_line.width = 1.0
	_symmetry_line.default_color = Color(0.8, 0.8, 0.8, 0.3)
	var s: float = 55.0
	var ext: float = 6.0
	_symmetry_line.add_point(Vector2(-ext * s, ext * s))     # math (-6, -6) → pantalla
	_symmetry_line.add_point(Vector2(ext * s, -ext * s))     # math (6, 6) → pantalla
	_symmetry_line.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_symmetry_line)
	_markers.append(_symmetry_line)


func _spawn_event_horizon_ring() -> void:
	var ring: Line2D = Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.1, 0.1, 0.6)
	var radius: float = 180.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(65):
		var angle: float = TAU * float(i) / 64.0
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring.points = pts
	ring.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(ring)
	_markers.append(ring)


## Muestra una segunda curva de referencia para el desafío de función compuesta.
func _show_reference_secondary(ref_formula: String, color: Color) -> void:
	var sec: FunctionPlotter = FunctionPlotter.new()
	sec.formula = ref_formula
	sec.domain_min = -4.0
	sec.domain_max = 6.0
	sec.scale_factor = 55.0
	sec.y_clamp = 10.0
	sec.line_color = color
	sec.line_width = 1.8
	sec.show_axes = false
	sec.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(sec)
	_markers.append(sec)


## Genera efectos visuales adicionales para la secuencia de función compuesta final.
func _spawn_composite_sequence_vfx() -> void:
	# Dibujar doble anillo — exterior naranja, interior cian — que representa la composición
	for ring_data in [
		{"radius": 220.0, "color": Color(1.0, 0.5, 0.0, 0.4), "width": 3.0},
		{"radius": 140.0, "color": Color(0.0, 0.9, 1.0, 0.35), "width": 2.0},
	]:
		var ring: Line2D = Line2D.new()
		ring.width = ring_data["width"]
		ring.default_color = ring_data["color"]
		var pts: PackedVector2Array = PackedVector2Array()
		for i in range(65):
			var angle: float = TAU * float(i) / 64.0
			pts.append(Vector2(cos(angle) * ring_data["radius"], sin(angle) * ring_data["radius"]))
		ring.points = pts
		ring.position = _plotter.position if _plotter else Vector2.ZERO
		add_child(ring)
		_markers.append(ring)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
	_reference_plotter = null
	_inverse_plotter = null
	_symmetry_line = null
