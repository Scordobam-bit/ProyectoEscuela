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

# Fila de fórmulas para añadir el botón "?" de ayuda de sintaxis.
@onready var _formula_row: HBoxContainer = $HUDPanel/VBox/FormulaRow
# Fila del dominio para calcular su rect de pantalla.
@onready var _domain_row: HBoxContainer = $HUDPanel/VBox/DomainRow

# ---------------------------------------------------------------------------
# Propiedades Exportadas
# ---------------------------------------------------------------------------

@export var neon_color: Color = Color(0.0, 1.0, 0.8, 1.0)
@export var warning_color: Color = Color(1.0, 0.4, 0.0, 1.0)
@export var error_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var mission_failed_color: Color = Color(1.0, 0.05, 0.05, 1.0)

## Duración en segundos del mensaje de retroalimentación visible en pantalla.
const FEEDBACK_DURATION: float = 5.0

# Etiqueta secundaria para la explicación detallada del error.
var _detail_label: Label = null

# Botón "?" de referencia de sintaxis y su panel emergente.
var _syntax_help_button: Button = null
var _syntax_panel: PanelContainer = null

# Teclado matemático virtual y su botón de alternancia.
var _keyboard_panel: PanelContainer = null
var _keyboard_button: Button = null

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_plot_button.pressed.connect(_on_plot_pressed)
	_theory_button.pressed.connect(_on_theory_pressed)
	_hint_button.pressed.connect(_on_hint_pressed)
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
	_build_syntax_ui()
	_build_virtual_keyboard()


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


## Crea el botón "?" de ayuda de sintaxis y el panel de referencia emergente.
func _build_syntax_ui() -> void:
	# ── Botón "?" ──────────────────────────────────────────────────────────
	_syntax_help_button = Button.new()
	_syntax_help_button.name = "SyntaxHelpButton"
	_syntax_help_button.text = "?"
	_syntax_help_button.tooltip_text = "Referencia de sintaxis matemática"
	_syntax_help_button.custom_minimum_size = Vector2(32.0, 0.0)
	_syntax_help_button.pressed.connect(_toggle_syntax_panel)
	_formula_row.add_child(_syntax_help_button)

	# ── Panel de Referencia de Sintaxis ────────────────────────────────────
	_syntax_panel = PanelContainer.new()
	_syntax_panel.name = "SyntaxPanel"
	# Posicionar debajo del HUDPanel (offset_top ~125 px)
	_syntax_panel.anchor_left   = 0.0
	_syntax_panel.anchor_top    = 0.0
	_syntax_panel.anchor_right  = 0.0
	_syntax_panel.anchor_bottom = 0.0
	_syntax_panel.offset_left   = 5.0
	_syntax_panel.offset_top    = 128.0
	_syntax_panel.offset_right  = 460.0
	_syntax_panel.offset_bottom = 410.0
	_syntax_panel.visible = false

	# Estilo neón/espacial
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.15, 0.97)
	style.border_color = Color(0.0, 1.0, 0.8, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_syntax_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_syntax_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "📐  Referencia de Sintaxis Matemática"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	vbox.add_child(title)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	var content: RichTextLabel = RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = true
	content.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.custom_minimum_size = Vector2(430.0, 220.0)
	content.add_theme_color_override("default_color", Color(0.85, 0.92, 1.0, 1.0))
	content.text = (
		"[b]Potencias:[/b]       [color=#ffcc00]x^2[/color]  o  [color=#ffcc00]pow(x, 2)[/color]\n"
		+ "[b]Raíces:[/b]         [color=#ffcc00]sqrt(x)[/color]\n"
		+ "[b]Trigonometría:[/b]  [color=#ffcc00]sin(x)[/color],  [color=#ffcc00]cos(x)[/color],  [color=#ffcc00]tan(x)[/color]\n"
		+ "[b]Logaritmo:[/b]      [color=#ffcc00]log(x)[/color]  ←  ln(x)\n"
		+ "[b]Exponencial:[/b]    [color=#ffcc00]exp(x)[/color]  ←  eˣ\n"
		+ "[b]Constantes:[/b]     [color=#ffcc00]PI[/color],  [color=#ffcc00]E[/color]\n"
		+ "[b]Multiplicar:[/b]    [color=#ffcc00]2*x[/color]  — [color=#ff6644]¡nunca escribas 2x sin el *![/color]\n"
		+ "[b]División:[/b]       [color=#ffcc00]x/2[/color]\n"
		+ "[b]Valor absoluto:[/b] [color=#ffcc00]abs(x)[/color]\n"
		+ "\n"
		+ "[color=#aaaacc]Ejemplo completo:  [/color][color=#ffcc00]2*x^2 - 3*x + 1[/color]"
	)
	vbox.add_child(content)

	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	var close_btn: Button = Button.new()
	close_btn.text = "✕  Cerrar"
	close_btn.pressed.connect(hide_syntax_help)
	vbox.add_child(close_btn)

	add_child(_syntax_panel)


# ---------------------------------------------------------------------------
# Teclado Matemático Virtual
# ---------------------------------------------------------------------------

## Construye el teclado matemático virtual desplegable.
## El botón ⌨ se añade a la fila de fórmulas; el panel aparece debajo del HUD.
func _build_virtual_keyboard() -> void:
	# ── Botón de alternancia ⌨ ────────────────────────────────────────────
	_keyboard_button = Button.new()
	_keyboard_button.name = "KeyboardButton"
	_keyboard_button.text = "⌨"
	_keyboard_button.tooltip_text = "Teclado matemático virtual"
	_keyboard_button.custom_minimum_size = Vector2(36.0, 0.0)
	_keyboard_button.pressed.connect(_toggle_keyboard_panel)
	_formula_row.add_child(_keyboard_button)

	# ── Panel del teclado ────────────────────────────────────────────────
	_keyboard_panel = PanelContainer.new()
	_keyboard_panel.name = "KeyboardPanel"
	_keyboard_panel.anchor_left   = 0.0
	_keyboard_panel.anchor_top    = 0.0
	_keyboard_panel.anchor_right  = 0.0
	_keyboard_panel.anchor_bottom = 0.0
	_keyboard_panel.offset_left   = 5.0
	_keyboard_panel.offset_top    = 128.0
	_keyboard_panel.offset_right  = 690.0
	_keyboard_panel.offset_bottom = 410.0
	_keyboard_panel.visible = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.14, 0.97)
	style.border_color = Color(0.0, 0.9, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_keyboard_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_keyboard_panel.add_child(vbox)

	# Cabecera
	var header_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header_row)

	var title_lbl: Label = Label.new()
	title_lbl.text = "⌨  Teclado Matemático Virtual"
	title_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_lbl)

	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28.0, 0.0)
	close_btn.pressed.connect(func() -> void: _keyboard_panel.visible = false)
	header_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Filas temáticas de botones
	_add_keyboard_section(vbox, "Variables / Constantes", [
		["x", "x"], ["PI", "PI"], ["E", "E"],
	])
	_add_keyboard_section(vbox, "Agrupación y Operadores", [
		["(", "("], [")", ")"],
		["+", "+"], ["−", "-"], ["×", "*"], ["÷", "/"], ["^", "^"],
	])
	_add_keyboard_section(vbox, "Funciones Básicas", [
		["sqrt()", "sqrt("], ["abs()", "abs("],
	])
	_add_keyboard_section(vbox, "Transcendentes", [
		["exp()", "exp("], ["log() [ln]", "log("], ["log10()", "log10("],
	])
	_add_keyboard_section(vbox, "Trigonométricas", [
		["sin()", "sin("], ["cos()", "cos("], ["tan()", "tan("],
	])
	_add_keyboard_section(vbox, "Inversas Trigonométricas", [
		["asin()", "asin("], ["acos()", "acos("], ["atan()", "atan("],
	])

	add_child(_keyboard_panel)


## Agrega una fila de categoría al teclado virtual.
## category_label : nombre visible de la categoría.
## buttons        : arreglo de [texto_del_botón, texto_a_insertar].
func _add_keyboard_section(parent: VBoxContainer, category_label: String, buttons: Array) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)

	var cat_lbl: Label = Label.new()
	cat_lbl.text = category_label + ":"
	cat_lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 1.0, 0.9))
	cat_lbl.add_theme_font_size_override("font_size", 11)
	cat_lbl.custom_minimum_size = Vector2(185.0, 0.0)
	row.add_child(cat_lbl)

	for btn_data: Array in buttons:
		var btn: Button = Button.new()
		btn.text      = btn_data[0]
		var insert_text: String = btn_data[1]
		btn.tooltip_text = "Insertar: %s" % insert_text
		btn.custom_minimum_size = Vector2(66.0, 28.0)
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8, 1.0))
		btn.pressed.connect(_insert_at_cursor.bind(insert_text))
		row.add_child(btn)


## Inserta el texto dado en la posición actual del cursor del campo de fórmulas.
## Deja el cursor justo después del texto insertado para que el estudiante
## pueda seguir escribiendo sin mover el teclado.
func _insert_at_cursor(text: String) -> void:
	var pos: int        = _formula_input.caret_column
	var current: String = _formula_input.text
	_formula_input.text         = current.left(pos) + text + current.substr(pos)
	_formula_input.caret_column = pos + text.length()
	_formula_input.grab_focus()


## Alterna la visibilidad del teclado matemático virtual.
## Cierra el panel de sintaxis si está abierto.
func _toggle_keyboard_panel() -> void:
	if _keyboard_panel:
		var new_visible: bool = not _keyboard_panel.visible
		_keyboard_panel.visible = new_visible
		if new_visible and _syntax_panel:
			_syntax_panel.visible = false


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
	_feedback_timer.start(FEEDBACK_DURATION)


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
	# Ocultar junto con el feedback principal al cabo de FEEDBACK_DURATION segundos
	_feedback_timer.start(FEEDBACK_DURATION)


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


## Muestra el panel de referencia de sintaxis.
func show_syntax_help() -> void:
	if _syntax_panel:
		_syntax_panel.visible = true


## Oculta el panel de referencia de sintaxis.
func hide_syntax_help() -> void:
	if _syntax_panel:
		_syntax_panel.visible = false


## Alterna la visibilidad del panel de referencia de sintaxis.
func _toggle_syntax_panel() -> void:
	if _syntax_panel:
		var new_visible: bool = not _syntax_panel.visible
		_syntax_panel.visible = new_visible
		# Cerrar el teclado virtual si se abre el panel de sintaxis
		if new_visible and _keyboard_panel:
			_keyboard_panel.visible = false


# ---------------------------------------------------------------------------
# Métodos de Geometría de Controles (para posicionamiento del TutorialManager)
# ---------------------------------------------------------------------------

## Devuelve el Rect2 en coordenadas de pantalla del campo de entrada de fórmulas.
func get_input_global_rect() -> Rect2:
	return _formula_input.get_global_rect()


## Devuelve el Rect2 en coordenadas de pantalla del botón Graficar.
func get_plot_button_global_rect() -> Rect2:
	return _plot_button.get_global_rect()


## Devuelve el Rect2 en coordenadas de pantalla que engloba los controles de dominio.
func get_domain_row_global_rect() -> Rect2:
	return _domain_row.get_global_rect()


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


func _on_theory_pressed() -> void:
	theory_requested.emit()


func _on_hint_pressed() -> void:
	hint_requested.emit()


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
