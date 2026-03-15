## Sector4DockingStation.gd
## =========================
## Sector 4: Estación de Acoplamiento — Operaciones de Funciones (Suma, Resta, División) y Composición
##
## Pedagogía
## ---------
## Dos funciones f y g pueden combinarse:
##   (f+g)(x) = f(x)+g(x)    dominio: D_f ∩ D_g
##   (f−g)(x) = f(x)−g(x)    dominio: D_f ∩ D_g
##   (f/g)(x) = f(x)/g(x)    dominio: D_f ∩ D_g \ {g(x)=0}
##   (f∘g)(x) = f(g(x))      dominio: {x∈D_g : g(x)∈D_f}
##
## Desafíos
## --------
## 1. Calcular y graficar (f+g)(x) donde f(x)=x² y g(x)=3x−1.
## 2. Calcular (f/g)(x) e identificar la asíntota.
## 3. JEFE: Hallar la composición (f∘g)(x) e ingresarla para desbloquear la esclusa de aire.
class_name Sector4DockingStation
extends SectorBase

var _f_formula: String = "x^2"
var _g_formula: String = "3*x - 1"
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 4
	background_color = Color(0.02, 0.06, 0.04, 1.0)

	_challenges = [
		{
			"instruction": "Desafío 1: f(x) = x²  y  g(x) = 3x − 1.\n" +
				"Calcula y grafica (f + g)(x).",
			"hint": "x^2 + 3*x - 1",
			"expected_formula": "x^2 + 3*x - 1",
			"feedback_correct": "¡Suma calculada correctamente! Vector de aproximación de acoplamiento alineado.",
			"feedback_wrong": "Suma: (f+g)(x) = f(x) + g(x) = x² + 3x − 1",
			"solution_hint": "(f+g)(x) = x² + (3x − 1) = x² + 3x − 1",
			"score": 200,
		},
		{
			"instruction": "Desafío 2: f(x) = x + 1  y  g(x) = x − 1.\n" +
				"Ingresa (f/g)(x). ¡Nota: hay una asíntota vertical!",
			"hint": "(x + 1) / (x - 1)",
			"expected_formula": "(x + 1) / (x - 1)",
			"feedback_correct": "¡Cociente correcto! Asíntota en x=1 registrada en el diario de navegación.",
			"feedback_wrong": "(f/g)(x) = (x+1)/(x−1). Cuidado con la división por cero en x=1.",
			"solution_hint": "(f/g)(x) = (x+1)/(x−1)",
			"score": 250,
		},
		{
			"instruction": "DESAFÍO JEFE: f(x) = √x  y  g(x) = x² − 4.\n" +
				"Calcula (f∘g)(x) = f(g(x)) e ingresa la fórmula compuesta.\n" +
				"Recuerda la restricción de dominio: g(x) ≥ 0.",
			"hint": "sqrt(x^2 - 4)",
			"expected_formula": "sqrt(x^2 - 4)",
			"feedback_correct": "¡ESCLUSA DE AIRE DESBLOQUEADA! ¡Composición dominada! ¡Sector 4 completado!",
			"feedback_wrong": "(f∘g)(x) = f(g(x)) = √(x²−4). Reemplaza x en f(x)=√x con g(x).",
			"solution_hint": "f(g(x)) = √(g(x)) = √(x² − 4)",
			"score": 400,
		},
	]


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -6.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 45.0
		_plotter.y_clamp = 15.0

	match challenge_index:
		0:
			# Mostrar curvas de referencia f y g
			_show_ref_curve(_f_formula, Color(0.2, 0.6, 1.0, 0.4))
			_show_ref_curve(_g_formula, Color(1.0, 0.6, 0.2, 0.4))
		1:
			_show_ref_curve("x + 1", Color(0.2, 0.6, 1.0, 0.4))
			_show_ref_curve("x - 1", Color(1.0, 0.6, 0.2, 0.4))
		2:
			_show_ref_curve("x^2 - 4", Color(0.8, 0.4, 1.0, 0.4))


# ---------------------------------------------------------------------------
# Override: Obstáculos del Sector
# ---------------------------------------------------------------------------

## Genera los obstáculos para cada desafío de la Estación de Acoplamiento.
func _setup_obstacles_for_challenge(challenge_index: int) -> void:
	if not _obstacle_manager:
		return
	var T: int = GestorObstaculos.TipoObstaculo.ASTEROIDE
	match challenge_index:
		0:
			# Desafío 1: y = x² + 3x − 1
			_obstacle_manager.add_obstacle(Vector2( 0.0,  2.0), 0.9, "Escombro Orbital Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -4.0), 0.9, "Escombro Orbital Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 2.0,  3.0), 0.9, "Escombro Orbital Gamma", T)
			_obstacle_manager.add_obstacle(Vector2(-3.0,  4.0), 0.9, "Escombro Orbital Delta", T)
		1:
			# Desafío 2: y = (x+1)/(x−1)
			_obstacle_manager.add_obstacle(Vector2( 3.5, -2.0), 0.9, "Residuo de Acoplamiento Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(-2.0,  5.0), 0.9, "Residuo de Acoplamiento Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 4.0,  0.0), 0.9, "Residuo de Acoplamiento Gamma", T)
		2:
			# Jefe: y = sqrt(x²−4)
			_obstacle_manager.add_obstacle(Vector2( 3.5,  5.0), 0.9, "Escudo de Acoplamiento Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(-3.5,  5.0), 0.9, "Escudo de Acoplamiento Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 5.0,  0.5), 0.9, "Escudo de Acoplamiento Gamma", T)


func _on_formula_submitted_sector(formula: String) -> void:
	if _hud and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			0:
				var expected: String = MathEngine.operation_sum(_f_formula, _g_formula)
				_hud.show_feedback(
					"Suma (MathEngine): %s" % expected, "info"
				)
			1:
				_hud.show_feedback(
					"El dominio del cociente excluye x = 1 (división por cero)", "warning"
				)
			2:
				var composed: String = MathEngine.compose("sqrt(x)", "x^2 - 4")
				_hud.show_feedback(
					"Composición f∘g: %s" % composed, "info"
				)
	_validate_formula_against_current(formula)


func _show_ref_curve(ref_formula: String, color: Color) -> void:
	var ref: FunctionPlotter = FunctionPlotter.new()
	ref.formula = ref_formula
	ref.domain_min = -6.0
	ref.domain_max = 6.0
	ref.scale_factor = 45.0
	ref.y_clamp = 15.0
	ref.line_color = color
	ref.line_width = 1.5
	ref.show_axes = false
	ref.position = _plotter.position if _plotter else Vector2.ZERO
	add_child(ref)
	_markers.append(ref)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()
