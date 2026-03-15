## HUD.gd
## =======
## Heads-Up Display de temática espacial para Planet Waves.
## Estética neón con entrada de fórmulas en tiempo real e información del sector.
class_name HUD
extends CanvasLayer

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando el jugador envía una fórmula desde la entrada del HUD.
signal formula_submitted(formula: String)

## Emitida cuando el jugador cambia los límites del dominio.
signal domain_changed(min_x: float, max_x: float)

## Emitida cuando se presiona el botón de Teoría.
signal theory_requested

## Emitida cuando se presiona el botón de Pista.
signal hint_requested

# ---------------------------------------------------------------------------
# Referencias de Nodos (enlazadas en _ready mediante la sintaxis $Ruta)
# ---------------------------------------------------------------------------

@onready var _formula_input: LineEdit = $HUDPanel/VBox/FormulaRow/FormulaInput
@onready var _plot_button: Button = $HUDPanel/VBox/FormulaRow/PlotButton
@onready var _domain_min_spin: SpinBox = $HUDPanel/VBox/DomainRow/DomainMinSpin
@onready var _domain_max_spin: SpinBox = $HUDPanel/VBox/DomainRow/DomainMaxSpin
@onready var _sector_label: Label = $TopBar/SectorLabel
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _feedback_label: Label = $FeedbackLabel
@onready var _theory_button: Button = $HUDPanel/VBox/ButtonRow/TheoryButton
@onready var _hint_button: Button = $HUDPanel/VBox/ButtonRow/HintButton
@onready var _feedback_timer: Timer = $FeedbackTimer

# ---------------------------------------------------------------------------
# Propiedades Exportadas
# ---------------------------------------------------------------------------

@export var neon_color: Color = Color(0.0, 1.0, 0.8, 1.0)
@export var warning_color: Color = Color(1.0, 0.4, 0.0, 1.0)
@export var error_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var mission_failed_color: Color = Color(1.0, 0.05, 0.05, 1.0)

# Etiqueta secundaria para la explicación detallada del error.
var _detail_label: Label = null

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_plot_button.pressed.connect(_on_plot_pressed)
	_theory_button.pressed.connect(theory_requested.emit)
	_hint_button.pressed.connect(hint_requested.emit)
	_domain_min_spin.value_changed.connect(_on_domain_changed)
	_domain_max_spin.value_changed.connect(_on_domain_changed)
	_formula_input.text_submitted.connect(_on_formula_submitted)
	_feedback_timer.timeout.connect(_clear_feedback)

	GameManager.answer_validated.connect(_on_answer_validated)
	GameManager.sector_changed.connect(_on_sector_changed)
	GameManager.challenge_completed.connect(_on_challenge_completed)

	_update_sector_display(GameManager.current_sector)
	_update_score_display()
	_build_detail_label()


func _build_detail_label() -> void:
	_detail_label = Label.new()
	_detail_label.name = "DetailLabel"
	_detail_label.anchor_left   = 0.5
	_detail_label.anchor_top    = 0.9
	_detail_label.anchor_right  = 0.5
	_detail_label.anchor_bottom = 0.9
	_detail_label.offset_left   = -380.0
	_detail_label.offset_right  = 380.0
	_detail_label.offset_bottom = 32.0
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_label.visible = false
	add_child(_detail_label)


# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Establece el texto de fórmula en el cuadro de entrada (p. ej., para mostrar una pista).
func set_formula_hint(text: String) -> void:
	_formula_input.placeholder_text = text


## Muestra un mensaje de retroalimentación temporal.
func show_feedback(message: String, feedback_type: String = "info") -> void:
	_feedback_label.text = message
	match feedback_type:
		"success":
			_feedback_label.add_theme_color_override("font_color", neon_color)
		"error":
			_feedback_label.add_theme_color_override("font_color", error_color)
		"warning":
			_feedback_label.add_theme_color_override("font_color", warning_color)
		"mission_failed":
			_feedback_label.add_theme_color_override("font_color", mission_failed_color)
		_:
			_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.visible = true
	_feedback_timer.start(4.0)


## Activa el estado de "Misión Fallida": muestra un banner rojo de advertencia
## con el nombre del obstáculo impactado.
func show_mission_failed(obstacle_name: String) -> void:
	show_feedback("⚠ MISIÓN FALLIDA — Tu trayectoria impacta: %s\nAjusta la fórmula para esquivarlo." % obstacle_name,
			"mission_failed")


## Muestra una explicación detallada del error matemático debajo del mensaje principal.
## error_detail : descripción del problema (p. ej., "La pendiente es demasiado baja").
func show_error_detail(error_detail: String) -> void:
	if not _detail_label:
		return
	_detail_label.text = "🔍 " + error_detail
	_detail_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_detail_label.visible = true
	# Ocultar junto con el feedback principal al cabo de 5 segundos
	_feedback_timer.start(5.0)


## Genera una explicación automática comparando la fórmula del jugador con la esperada.
func show_auto_error_explanation(player_formula: String, expected_formula: String) -> void:
	var detail: String = _generate_error_explanation(player_formula, expected_formula)
	if not detail.is_empty():
		show_error_detail(detail)


## Devuelve la cadena de fórmula actual del cuadro de entrada.
func get_formula() -> String:
	return _formula_input.text.strip_edges()


## Devuelve el dominio actual como [min, max].
func get_domain() -> Array[float]:
	return [_domain_min_spin.value, _domain_max_spin.value]


## Bloquea o desbloquea los controles de entrada.
func set_controls_enabled(enabled: bool) -> void:
	_formula_input.editable = enabled
	_plot_button.disabled = not enabled
	_domain_min_spin.editable = enabled
	_domain_max_spin.editable = enabled


# ---------------------------------------------------------------------------
# Generador de Explicaciones de Error
# ---------------------------------------------------------------------------

func _generate_error_explanation(player: String, expected: String) -> String:
	if player.is_empty() or expected.is_empty():
		return ""

	# Comparar pendientes (funciones lineales)
	var p_slope: float = MathEngine.get_slope_and_intercept(player)["slope"]
	var e_slope: float = MathEngine.get_slope_and_intercept(expected)["slope"]

	var msg: String = ""

	# Comparar valores en varios puntos de prueba para deducir el tipo de error
	var diffs: PackedFloat64Array = PackedFloat64Array()
	for x in [-3.0, -1.0, 0.0, 1.0, 3.0]:
		var pv: float = MathEngine.evaluate(player, x)
		var ev: float = MathEngine.evaluate(expected, x)
		if not is_nan(pv) and not is_nan(ev):
			diffs.append(pv - ev)

	if diffs.is_empty():
		return "Fórmula no evaluable. Revisa la sintaxis."

	# Calcular si el error es constante (offset), proporcional, u otro
	var min_diff: float = diffs[0]
	var max_diff: float = diffs[0]
	for d in diffs:
		min_diff = minf(min_diff, d)
		max_diff = maxf(max_diff, d)

	var diff_range: float = max_diff - min_diff
	var avg_diff: float = 0.0
	for d in diffs:
		avg_diff += d
	avg_diff /= float(diffs.size())

	if absf(avg_diff) < 0.05:
		msg = "Las curvas coinciden aproximadamente — quizás un error de redondeo."
	elif diff_range < 0.1 and absf(avg_diff) > 0.1:
		# Error constante en todos los puntos → error en el término independiente
		if avg_diff > 0.0:
			msg = "Tu función es %.2f unidades demasiado alta — reduce el término independiente (b)." % avg_diff
		else:
			msg = "Tu función es %.2f unidades demasiado baja — aumenta el término independiente (b)." % absf(avg_diff)
	else:
		# Error no constante → probablemente error en la pendiente o en los coeficientes
		var slope_diff: float = p_slope - e_slope
		if absf(slope_diff) > 0.05:
			if slope_diff > 0.0:
				msg = "La pendiente es demasiado alta (%.2f en lugar de %.2f). Reduce el coeficiente de x." % [p_slope, e_slope]
			else:
				msg = "La pendiente es demasiado baja (%.2f en lugar de %.2f). Aumenta el coeficiente de x." % [p_slope, e_slope]
		else:
			if avg_diff > 0.0:
				msg = "La curva está desplazada hacia arriba. Revisa los coeficientes y el término independiente."
			else:
				msg = "La curva está desplazada hacia abajo. Revisa los coeficientes y el término independiente."

	return msg


# ---------------------------------------------------------------------------
# Manejadores Privados
# ---------------------------------------------------------------------------

func _on_plot_pressed() -> void:
	var formula: String = get_formula()
	if formula.is_empty():
		show_feedback("Por favor ingresa una fórmula primero.", "warning")
		return
	formula_submitted.emit(formula)


func _on_formula_submitted(formula: String) -> void:
	formula_submitted.emit(formula.strip_edges())


func _on_domain_changed(_value: float) -> void:
	var min_x: float = _domain_min_spin.value
	var max_x: float = _domain_max_spin.value
	if min_x < max_x:
		domain_changed.emit(min_x, max_x)


func _on_answer_validated(correct: bool, feedback: String) -> void:
	show_feedback(feedback, "success" if correct else "error")
	_update_score_display()


func _on_sector_changed(sector_index: int) -> void:
	_update_sector_display(sector_index)


func _on_challenge_completed(_sector: int, _challenge: int) -> void:
	_update_score_display()


func _update_sector_display(sector_index: int) -> void:
	if sector_index < 1 or sector_index > GameManager.SECTORS.size():
		return
	var data: Dictionary = GameManager.SECTORS[sector_index - 1]
	_sector_label.text = "Sector %d: %s" % [sector_index, data["name"]]
	_sector_label.add_theme_color_override("font_color", data["color"])


func _update_score_display() -> void:
	_score_label.text = "Puntuación: %d" % GameManager.get_score()


func _clear_feedback() -> void:
	_feedback_label.visible = false
	if _detail_label:
		_detail_label.visible = false
