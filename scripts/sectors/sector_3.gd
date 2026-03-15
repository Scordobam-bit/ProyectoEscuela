## Sector3PulsarTuner.gd
## ======================
## Sector 3: Sintonizador de Púlsares — Tipos de Funciones, Transformaciones (Desplazamientos, Escala, Reflexiones)
##
## Pedagogía
## ---------
## Las transformaciones de funciones son operaciones algebraicas que trasladan,
## escalan o reflejan sistemáticamente una función base:
##   Desplazamiento vertical  :  g(x) = f(x) + k
##   Desplazamiento horizontal:  g(x) = f(x − h)
##   Escala vertical          :  g(x) = a·f(x)
##   Escala horizontal        :  g(x) = f(b·x)
##   Reflexión sobre eje X    :  g(x) = −f(x)
##   Reflexión sobre eje Y    :  g(x) = f(−x)
##
## Desafíos
## --------
## 1. Desplazar sin(x) a la derecha por π y hacia arriba por 2.
## 2. Comprimir cos(x) verticalmente por el factor 0.5 y reflejar sobre el eje x.
## 3. JEFE: Igualar una forma de onda misteriosa aplicando la cadena de transformaciones correcta.
class_name Sector3PulsarTuner
extends SectorBase

var _reference_plotter: FunctionPlotter = null
var _mystery_formula: String = ""
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 3
	background_color = Color(0.04, 0.02, 0.08, 1.0)

	_mystery_formula = "2 * sin(2 * x) - 1"

	_challenges = [
		{
			"instruction": "Desafío 1: Desplaza sin(x) a la DERECHA por π y hacia ARRIBA por 2.\n" +
				"Recuerda: f(x−h)+k desplaza a la derecha en h y hacia arriba en k.",
			"hint": "sin(x - PI) + 2",
			"expected_formula": "sin(x - PI) + 2",
			"feedback_correct": "¡Frecuencia del púlsar bloqueada! Cambio de fase perfecto.",
			"feedback_wrong": "Verifica tu desplazamiento. Los desplazamientos horizontales usan (x − h) dentro de la función.",
			"solution_hint": "sin(x − π) + 2",
			"score": 200,
		},
		{
			"instruction": "Desafío 2: Toma cos(x), comprímelo verticalmente por 0.5 y luego refléjalo sobre el eje x.\n" +
				"g(x) = −(0.5·cos(x))",
			"hint": "-0.5 * cos(x)",
			"expected_formula": "-0.5 * cos(x)",
			"feedback_correct": "¡Señal invertida y comprimida. ¡Púlsar sintonizado!",
			"feedback_wrong": "Escala vertical: multiplica por 0.5. Reflexión: niega todo el resultado.",
			"solution_hint": "g(x) = −0.5·cos(x)",
			"score": 200,
		},
		{
			"instruction": "JEFE: ¡Iguala la forma de onda del púlsar misterioso mostrada en morado!\n" +
				"Es una función seno transformada. Analiza su amplitud, período y desplazamiento.",
			"hint": "2 * sin(2*x) - 1",
			"expected_formula": "2 * sin(2*x) - 1",
			"feedback_correct": "¡PÚLSAR SINCRONIZADO! ¡Sector 3 completado!",
			"feedback_wrong": "Estudia la forma de onda morada: amplitud, período (2π/b) y desplazamiento vertical.",
			"solution_hint": "Amplitud=2, período=π (b=2), desplazamiento vertical=−1",
			"score": 400,
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -2.0 * PI
		_plotter.domain_max = 2.0 * PI
		_plotter.scale_factor = 50.0

	match challenge_index:
		0:
			_show_reference("sin(x)", Color(0.4, 0.8, 1.0, 0.4))
		1:
			_show_reference("cos(x)", Color(0.4, 0.8, 1.0, 0.4))
		2:
			_show_reference(_mystery_formula, Color(0.8, 0.2, 1.0, 0.7))


# ---------------------------------------------------------------------------
# Override: Obstáculos del Sector
# ---------------------------------------------------------------------------

## Genera los obstáculos (púlsares) para cada desafío del Sintonizador de Púlsares.
func _setup_obstacles_for_challenge(challenge_index: int) -> void:
	if not _obstacle_manager:
		return
	var T: int = GestorObstaculos.TipoObstaculo.PULSAR
	match challenge_index:
		0:
			# Desafío 1: y = sin(x−π)+2
			_obstacle_manager.add_obstacle(Vector2(0.0,       4.5), 0.7, "Púlsar Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(0.0,      -0.5), 0.7, "Púlsar Beta", T)
			_obstacle_manager.add_obstacle(Vector2(PI,        0.5), 0.7, "Púlsar Gamma", T)
		1:
			# Desafío 2: y = −0.5·cos(x)
			_obstacle_manager.add_obstacle(Vector2(0.0,   1.0), 0.7, "Púlsar Delta", T)
			_obstacle_manager.add_obstacle(Vector2(0.0,  -2.0), 0.7, "Púlsar Épsilon", T)
			_obstacle_manager.add_obstacle(Vector2(PI,    2.0), 0.7, "Púlsar Zeta", T)
		2:
			# Jefe: y = 2·sin(2x)−1
			_obstacle_manager.add_obstacle(Vector2(0.0,   1.5), 0.7, "Púlsar Maestro Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(0.0,  -3.5), 0.7, "Púlsar Maestro Beta", T)
			_obstacle_manager.add_obstacle(Vector2(2.0,   2.5), 0.7, "Púlsar Maestro Gamma", T)


func _on_formula_submitted_sector(formula: String) -> void:
	if hud_node and MathEngine.is_valid_formula(formula):
		# Mostrar comparación evaluada en un punto de prueba
		var sample_x: float = 1.0
		var player_y: float = MathEngine.evaluate(formula, sample_x)
		hud_node.show_feedback(
			"En x=1: tu f(1) = %s" % MathEngine.format_float(player_y), "info"
		)
	_validate_formula_against_current(formula)


func _show_reference(ref_formula: String, color: Color) -> void:
	if _reference_plotter:
		_reference_plotter.queue_free()
	_reference_plotter = FunctionPlotter.new()
	_reference_plotter.formula = ref_formula
	_reference_plotter.domain_min = -2.0 * PI
	_reference_plotter.domain_max = 2.0 * PI
	_reference_plotter.scale_factor = 50.0
	_reference_plotter.line_color = color
	_reference_plotter.line_width = 1.5
	_reference_plotter.show_axes = false
	_reference_plotter.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(_reference_plotter)
	_markers.append(_reference_plotter)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
	_reference_plotter = null
