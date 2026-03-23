## Sector4DockingStation.gd
## =========================
## Sector 4: Estación de Acoplamiento — Logaritmos y Exponenciales
##
## Pedagogía
## ---------
## La función exponencial y = e^x y el logaritmo natural y = ln(x) son funciones
## inversas y modelan crecimiento/aceleración y escalas multiplicativas.
##
## Desafíos
## --------
## 1. Exponencial básica exp(x).
## 2. Logaritmo natural log(x).
## 3. JEFE: combinación log(exp(x) + 1).
class_name Sector4DockingStation
extends SectorBase

var _f_formula: String = "exp(x)"
var _g_formula: String = "log(x)"
var _markers: Array[Node2D] = []

func _setup_challenges() -> void:
	sector_index = 4
	background_color = Color(0.02, 0.06, 0.04, 1.0)

	_challenges = [
		{
			"briefing_key": "s4_tutorial",
			"instruction": "Desafío 1: Activa los propulsores exponenciales graficando f(x) = exp(x).",
			"hint": "exp(x)",
			"expected_formula": "exp(x)",
			"feedback_correct": "¡Exponencial establecida! Telemetría de crecimiento calibrada.",
			"feedback_wrong": "Usa la función exponencial natural: exp(x).",
			"solution_hint": "f(x) = exp(x)",
			"score": 200,
		},
		{
			"instruction": "Desafío 2: Estabiliza el escáner logarítmico graficando g(x) = log(x).\n" +
				"Recuerda: dominio x > 0.",
			"hint": "log(x)",
			"expected_formula": "log(x)",
			"feedback_correct": "¡Logaritmo confirmado! Dominio positivo registrado.",
			"feedback_wrong": "Usa log(x) y recuerda que x debe ser mayor que 0.",
			"solution_hint": "g(x) = log(x), con dominio x > 0",
			"score": 250,
		},
		{
			"instruction": "DESAFÍO JEFE: Combina ambos sistemas con h(x) = log(exp(x) + 1).",
			"hint": "log(exp(x) + 1)",
			"expected_formula": "log(exp(x) + 1)",
			"feedback_correct": "¡ESCLUSA DE AIRE DESBLOQUEADA! Logaritmos y exponenciales dominados.",
			"feedback_wrong": "Ingresa exactamente la combinación: log(exp(x) + 1).",
			"solution_hint": "h(x) = log(exp(x) + 1)",
			"score": 400,
		},
	]


func _ready() -> void:
	await super._ready()
	_position_meta_area()


func _on_challenge_begin(challenge_index: int) -> void:
	_clear_markers()
	if _plotter:
		_plotter.domain_min = -6.0
		_plotter.domain_max = 6.0
		_plotter.scale_factor = 45.0
		_plotter.y_clamp = 15.0

	match challenge_index:
		0:
			_show_ref_curve(_f_formula, Color(0.2, 0.6, 1.0, 0.4))
		1:
			_show_ref_curve(_g_formula, Color(1.0, 0.6, 0.2, 0.4))
		2:
			_show_ref_curve("log(exp(x) + 1)", Color(0.8, 0.4, 1.0, 0.4))


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
			# Desafío 1: y = exp(x)
			_obstacle_manager.add_obstacle(Vector2( 0.0,  2.0), 0.9, "Escombro Orbital Alfa", T)
			_obstacle_manager.add_obstacle(Vector2( 0.0, -4.0), 0.9, "Escombro Orbital Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 2.0,  3.0), 0.9, "Escombro Orbital Gamma", T)
			_obstacle_manager.add_obstacle(Vector2(-3.0,  4.0), 0.9, "Escombro Orbital Delta", T)
		1:
			# Desafío 2: y = log(x)
			_obstacle_manager.add_obstacle(Vector2( 3.5, -2.0), 0.9, "Residuo de Acoplamiento Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(-2.0,  5.0), 0.9, "Residuo de Acoplamiento Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 4.0,  0.0), 0.9, "Residuo de Acoplamiento Gamma", T)
		2:
			# Jefe: y = log(exp(x)+1)
			_obstacle_manager.add_obstacle(Vector2( 3.5,  5.0), 0.9, "Escudo de Acoplamiento Alfa", T)
			_obstacle_manager.add_obstacle(Vector2(-3.5,  5.0), 0.9, "Escudo de Acoplamiento Beta", T)
			_obstacle_manager.add_obstacle(Vector2( 5.0,  0.5), 0.9, "Escudo de Acoplamiento Gamma", T)


func _on_formula_submitted_sector(formula: String) -> void:
	if hud_node and MathEngine.is_valid_formula(formula):
		match _current_challenge:
			0:
				hud_node.show_feedback("Referencia: exp(x) modela crecimiento acelerado.", "info")
			1:
				hud_node.show_feedback(
					"Recuerda: log(x) solo está definido para x > 0.", "warning"
				)
			2:
				var composed: String = MathEngine.compose("log(x)", "exp(x) + 1")
				hud_node.show_feedback(
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


func _position_meta_area() -> void:
	var meta_area: Area2D = get_node_or_null("MetaArea")
	if meta_area:
		meta_area.position = Vector2(1060, 210)
