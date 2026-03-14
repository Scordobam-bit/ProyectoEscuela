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
			"feedback_correct": "🌟 ¡HORIZONTE DE SUCESOS ESCAPADO! ¡Planet Waves completado! 🌟",
			"feedback_wrong": "Si f(x) = eˣ − 2, invierte: y = eˣ−2 → x = ln(y+2) → f⁻¹(y) = ln(y+2)",
			"solution_hint": "f⁻¹(x) = ln(x + 2)  → Godot: log(x + 2)",
			"score": 500,
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
			if _theory_panel:
				_theory_panel.show_sector_theory(5)
			_show_reference("x^3", Color(0.6, 0.8, 1.0, 0.5))
		1:
			_show_reference("2*x + 4", Color(0.6, 0.8, 1.0, 0.5))
			_show_symmetry_line()
		2:
			# Mostrar eˣ − 2 y su inversa log(x+2) por separado
			_show_reference("exp(x) - 2", Color(1.0, 0.5, 0.2, 0.5))
			_show_symmetry_line()
		3:
			# JEFE: mostrar la fórmula gravitacional
			_show_reference("exp(x) - 2", Color(1.0, 0.2, 0.2, 0.8))
			_show_symmetry_line()
			_spawn_event_horizon_ring()


func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			1:
				# Mostrar verificación de inyectividad
				var inj: Dictionary = MathEngine.check_injectivity("2*x + 4")
				_hud.show_feedback(
					"Inyectividad de 2x+4: %s (creciente: %s)" % [
						str(inj["injective"]), str(inj["monotone_increasing"])
					], "info"
				)
			2, 3:
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
	_validate_formula_against_current(formula)


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


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
	_reference_plotter = null
	_inverse_plotter = null
	_symmetry_line = null
