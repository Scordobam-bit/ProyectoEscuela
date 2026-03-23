## LaboratorioEstelar.gd
## =====================
## Modo sandbox de exploración libre — "Laboratorio Estelar".
## Permite comparar hasta tres funciones matemáticas simultáneamente
## sin obstáculos ni metas. Fomenta la curiosidad y el descubrimiento autónomo.
class_name LaboratorioEstelar
extends Node2D

# ---------------------------------------------------------------------------
# Constantes de Estética
# ---------------------------------------------------------------------------

## Colores neón para las tres curvas (cian, naranja, magenta).
const PLOT_COLORS: Array[Color] = [
	Color(0.0,  1.0,  0.8,  1.0),   # Cian neón
	Color(1.0,  0.55, 0.0,  1.0),   # Naranja neón
	Color(0.85, 0.0,  1.0,  1.0),   # Magenta neón
]

const LABEL_COLORS: Array[Color] = [
	Color(0.0,  1.0,  0.8,  1.0),
	Color(1.0,  0.65, 0.1,  1.0),
	Color(0.9,  0.2,  1.0,  1.0),
]

## Colores tenues para las estelas (versiones oscurecidas de los colores neón).
const TRAIL_COLORS: Array[Color] = [
	Color(0.0,  0.55, 0.44, 0.45),   # Cian tenue
	Color(0.55, 0.28, 0.0,  0.45),   # Naranja tenue
	Color(0.45, 0.0,  0.55, 0.45),   # Magenta tenue
	Color(0.15, 0.40, 0.75, 0.45),   # Azul tenue
	Color(0.65, 0.55, 0.0,  0.45),   # Amarillo tenue
	Color(0.0,  0.55, 0.25, 0.45),   # Verde tenue
]

const MAX_FUNCTIONS: int = 3

## Máximo de estelas (trazos congelados) simultáneas.
const MAX_TRAILS: int = 6

## Dominio por defecto del graficador.
const DEFAULT_DOMAIN_MIN: float = -10.0
const DEFAULT_DOMAIN_MAX: float = 10.0
const DEFAULT_SCALE: float = 40.0

## Multiplicador de escala para dispersar las semillas del generador de estrellas
## por capa de paralaje, evitando distribuciones idénticas entre capas.
const SEED_SCALE_FACTOR: int = 2000
## Desplazamiento adicional de semilla para evitar colisiones entre capas
## que compartan la misma cantidad de estrellas.
const SEED_OFFSET: int = 99

# ---------------------------------------------------------------------------
# Nodos Dinámicos
# ---------------------------------------------------------------------------

var _plotters: Array[FunctionPlotter] = []
var _hud_layer: CanvasLayer = null
var _formula_inputs: Array[LineEdit] = []
var _active_formula_input: LineEdit = null
var _plot_buttons: Array[Button] = []
var _active_checks: Array[CheckBox] = []
var _domain_min_spin: SpinBox = null
var _domain_max_spin: SpinBox = null
var _status_label: Label = null
var _keyboard_toggle_button: Button = null
var _reference_dialog: AcceptDialog = null

## Lista de graficadores de estela (trazos congelados).
var _trail_plotters: Array[FunctionPlotter] = []
## Índice que apunta al próximo color de estela disponible.
var _trail_index: int = 0
## Etiqueta que indica cuántas estelas hay activas.
var _trails_count_label: Label = null

const _KEYBOARD_BOTTOM_OFFSET: float = -224.0
const _ALLOWED_SYMBOLS: String = "+-*/^().,"
const _ALLOWED_LETTERS: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
const _ALLOWED_WORDS_LOWER: Array[String] = [
	"x", "sin", "cos", "tan", "asin", "acos", "atan",
	"log", "ln", "sqrt", "exp", "abs", "pow", "e", "pi",
]
const _CHAR_CODE_0: int = 48
const _CHAR_CODE_9: int = 57
const _CHAR_CODE_SPACE: int = 32
const _CHAR_CODE_DEL: int = 127

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.02, 0.01, 0.08, 1.0))
	_setup_world_environment()
	_setup_parallax_stars()
	_setup_plotters()
	_build_hud()


# ---------------------------------------------------------------------------
# Entorno Visual
# ---------------------------------------------------------------------------

func _setup_world_environment() -> void:
	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env_res: Environment = load("res://resources/entorno.tres")
	if env_res:
		env_node.environment = env_res
	add_child(env_node)
	move_child(env_node, 0)


func _setup_parallax_stars() -> void:
	var parallax_bg: ParallaxBackground = ParallaxBackground.new()
	parallax_bg.name = "ParallaxBackground"
	add_child(parallax_bg)
	move_child(parallax_bg, 1)

	_create_star_layer(parallax_bg, Vector2(0.04, 0.0), 90, 1.0, 1.5)
	_create_star_layer(parallax_bg, Vector2(0.10, 0.0), 45, 1.5, 2.5)
	_create_star_layer(parallax_bg, Vector2(0.20, 0.0), 22, 2.0, 3.5)

	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(parallax_bg, "scroll_offset", Vector2(3000.0, 0.0), 150.0)


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
	rng.seed = int(motion_scale.x * SEED_SCALE_FACTOR) + star_count + SEED_OFFSET

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
# Graficadores
# ---------------------------------------------------------------------------

func _setup_plotters() -> void:
	for i in range(MAX_FUNCTIONS):
		var plotter: FunctionPlotter = FunctionPlotter.new()
		plotter.name = "Plotter%d" % (i + 1)
		plotter.position = Vector2(640.0, 360.0)
		plotter.formula = ""
		plotter.domain_min = DEFAULT_DOMAIN_MIN
		plotter.domain_max = DEFAULT_DOMAIN_MAX
		plotter.scale_factor = DEFAULT_SCALE
		plotter.line_color = PLOT_COLORS[i]
		plotter.line_width = 2.5
		plotter.show_axes = (i == 0)   # Solo el primero muestra los ejes
		plotter.auto_plot = false
		add_child(plotter)
		_plotters.append(plotter)


# ---------------------------------------------------------------------------
# HUD del Laboratorio (construido programáticamente)
# ---------------------------------------------------------------------------

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUDLab"
	_hud_layer.layer = 2
	add_child(_hud_layer)

	# ── Panel superior (título + volver) ────────────────────────────────
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_right = 1.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_bottom = 36.0
	_hud_layer.add_child(top_bar)

	var title_lbl: Label = Label.new()
	title_lbl.text = "🔬  LABORATORIO ESTELAR — Exploración Libre"
	title_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 16)
	_apply_label_outline(title_lbl)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_lbl)

	var back_btn: Button = Button.new()
	back_btn.text = "🏠 Volver al Menú"
	back_btn.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_btn)

	# ── Panel de control inferior ────────────────────────────────────────
	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.anchor_left   = 0.0
	bottom_panel.anchor_top    = 1.0
	bottom_panel.anchor_right  = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_top    = -220.0

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.02, 0.03, 0.12, 0.95)
	bg_style.border_color = Color(0.0, 1.0, 0.8, 0.6)
	bg_style.border_width_top = 2
	bottom_panel.add_theme_stylebox_override("panel", bg_style)
	_hud_layer.add_child(bottom_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(main_vbox)

	# ── Subtítulo de instrucción ─────────────────────────────────────────
	var instr_lbl: Label = Label.new()
	instr_lbl.text = "Ingrese hasta 3 funciones para compararlas simultáneamente. No hay obstáculos — ¡explore libremente!"
	instr_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 1.0))
	instr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_outline(instr_lbl)
	main_vbox.add_child(instr_lbl)

	# ── Filas de fórmula para cada función ──────────────────────────────
	for i in range(MAX_FUNCTIONS):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		main_vbox.add_child(row)

		var check: CheckBox = CheckBox.new()
		check.text = ""
		check.button_pressed = true
		check.toggled.connect(_on_function_toggled.bind(i))
		row.add_child(check)
		_active_checks.append(check)

		var color_box: ColorRect = ColorRect.new()
		color_box.custom_minimum_size = Vector2(14.0, 14.0)
		color_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		color_box.color = LABEL_COLORS[i]
		row.add_child(color_box)

		var func_lbl: Label = Label.new()
		func_lbl.text = "f%d(x) =" % (i + 1)
		func_lbl.add_theme_color_override("font_color", LABEL_COLORS[i])
		func_lbl.custom_minimum_size = Vector2(62.0, 0.0)
		_apply_label_outline(func_lbl)
		row.add_child(func_lbl)

		var input: LineEdit = LineEdit.new()
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.placeholder_text = _get_placeholder(i)
		input.add_theme_color_override("font_color", LABEL_COLORS[i])
		input.text_submitted.connect(_on_formula_submitted.bind(i))
		input.text_changed.connect(_on_formula_text_changed.bind(input))
		input.focus_entered.connect(_on_formula_input_focus_entered)
		input.gui_input.connect(_on_formula_input_gui_input.bind(input))
		row.add_child(input)
		_formula_inputs.append(input)

		var plot_btn: Button = Button.new()
		plot_btn.text = "GRAFICAR"
		plot_btn.pressed.connect(_on_plot_pressed.bind(i))
		row.add_child(plot_btn)
		_plot_buttons.append(plot_btn)

		var clear_btn: Button = Button.new()
		clear_btn.text = "✕"
		clear_btn.tooltip_text = "Borrar función %d" % (i + 1)
		clear_btn.custom_minimum_size = Vector2(32.0, 0.0)
		clear_btn.pressed.connect(_on_clear_single.bind(i))
		row.add_child(clear_btn)

		# Botón de estela: congela la curva actual como trazo de fondo
		var trace_btn: Button = Button.new()
		trace_btn.text = "📌 Mantener Trazo"
		trace_btn.tooltip_text = "Congela f%d como estela tenue de fondo para comparar" % (i + 1)
		trace_btn.pressed.connect(_on_keep_trace_pressed.bind(i))
		row.add_child(trace_btn)

	# ── Controles de dominio ────────────────────────────────────────────
	var domain_row: HBoxContainer = HBoxContainer.new()
	domain_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(domain_row)

	var dom_lbl: Label = Label.new()
	dom_lbl.text = "Dominio:  ["
	dom_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
	_apply_label_outline(dom_lbl)
	domain_row.add_child(dom_lbl)

	_domain_min_spin = SpinBox.new()
	_domain_min_spin.min_value = -50.0
	_domain_min_spin.max_value = -0.5
	_domain_min_spin.step = 0.5
	_domain_min_spin.value = DEFAULT_DOMAIN_MIN
	_domain_min_spin.value_changed.connect(_on_domain_changed)
	domain_row.add_child(_domain_min_spin)

	var comma_lbl: Label = Label.new()
	comma_lbl.text = " ,  "
	_apply_label_outline(comma_lbl)
	domain_row.add_child(comma_lbl)

	_domain_max_spin = SpinBox.new()
	_domain_max_spin.min_value = 0.5
	_domain_max_spin.max_value = 50.0
	_domain_max_spin.step = 0.5
	_domain_max_spin.value = DEFAULT_DOMAIN_MAX
	_domain_max_spin.value_changed.connect(_on_domain_changed)
	domain_row.add_child(_domain_max_spin)

	var dom_lbl2: Label = Label.new()
	dom_lbl2.text = " ]"
	_apply_label_outline(dom_lbl2)
	domain_row.add_child(dom_lbl2)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	domain_row.add_child(spacer)

	var clear_all_btn: Button = Button.new()
	clear_all_btn.text = "🗑  Limpiar Todo"
	clear_all_btn.pressed.connect(_on_clear_all)
	domain_row.add_child(clear_all_btn)

	var clear_trails_btn: Button = Button.new()
	clear_trails_btn.text = "🌫  Borrar Estelas"
	clear_trails_btn.tooltip_text = "Elimina todos los trazos congelados de fondo"
	clear_trails_btn.pressed.connect(_on_clear_trails)
	domain_row.add_child(clear_trails_btn)

	# ── Toggle de teclado matemático (oculto por defecto) ───────────────
	_keyboard_toggle_button = Button.new()
	_keyboard_toggle_button.text = "⌨ Teclado Matemático"
	_keyboard_toggle_button.toggle_mode = true
	_keyboard_toggle_button.button_pressed = false
	_keyboard_toggle_button.pressed.connect(func() -> void:
		_toggle_keyboard_visibility(_keyboard_toggle_button.button_pressed)
	)
	main_vbox.add_child(_keyboard_toggle_button)

	var reference_btn: Button = Button.new()
	reference_btn.text = "📐 Referencia"
	reference_btn.tooltip_text = "Mostrar cuadro de referencia matemática"
	reference_btn.pressed.connect(_on_reference_pressed)
	main_vbox.add_child(reference_btn)

	# ── Contador de estelas ─────────────────────────────────────────────
	_trails_count_label = Label.new()
	_trails_count_label.name = "TrailsCountLabel"
	_trails_count_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.9, 0.85))
	_trails_count_label.add_theme_font_size_override("font_size", 11)
	_apply_label_outline(_trails_count_label)
	_trails_count_label.text = ""
	domain_row.add_child(_trails_count_label)

	# ── Barra de estado ──────────────────────────────────────────────────
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 1.0))
	_apply_label_outline(_status_label)
	_status_label.text = "Listo. Ingrese una función y presione GRAFICAR o Enter."
	main_vbox.add_child(_status_label)
	_build_virtual_keyboard(bottom_panel)
	_build_reference_dialog()


# ---------------------------------------------------------------------------
# Manejadores de Señales
# ---------------------------------------------------------------------------

func _on_formula_submitted(text: String, index: int) -> void:
	_plot_function(text, index)


func _on_plot_pressed(index: int) -> void:
	_plot_function(_formula_inputs[index].text.strip_edges(), index)


func _on_function_toggled(active: bool, index: int) -> void:
	if index < _plotters.size():
		_plotters[index].visible = active


func _on_clear_single(index: int) -> void:
	if index < _formula_inputs.size():
		_formula_inputs[index].text = ""
	if index < _plotters.size():
		_plotters[index].formula = ""
		_plotters[index].plot()
	_set_status("Función %d borrada." % (index + 1))


func _on_clear_all() -> void:
	for i in range(MAX_FUNCTIONS):
		_formula_inputs[i].text = ""
		_plotters[i].formula = ""
		_plotters[i].plot()
	_set_status("Todas las funciones borradas. ¡Comience de nuevo!")


func _on_domain_changed(_value: float) -> void:
	var d_min: float = _domain_min_spin.value
	var d_max: float = _domain_max_spin.value
	for p in _plotters:
		p.domain_min = d_min
		p.domain_max = d_max
		if not p.formula.is_empty():
			p.plot()
	# Actualizar también las estelas congeladas para mantener consistencia visual
	for t in _trail_plotters:
		if is_instance_valid(t):
			t.domain_min = d_min
			t.domain_max = d_max
			if not t.formula.is_empty():
				t.plot()


func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/main_menu.tscn")


func _on_reference_pressed() -> void:
	if _reference_dialog:
		_reference_dialog.popup_centered()


# ---------------------------------------------------------------------------
# Estelas (Trazos Congelados)
# ---------------------------------------------------------------------------

## Congela la curva activa del índice indicado como estela tenue de fondo.
## Esto permite comparar una transformación (ej. f(x) vs f(x)+c) de forma visual.
func _on_keep_trace_pressed(index: int) -> void:
	var formula: String = _formula_inputs[index].text.strip_edges()
	if formula.is_empty():
		_set_status("f%d está vacía — grafique una función antes de congelar la estela." % (index + 1))
		return

	if not MathEngine.is_valid_formula(formula):
		_set_status("f%d: fórmula inválida — corrija antes de congelar." % (index + 1))
		return

	if _trail_plotters.size() >= MAX_TRAILS:
		_set_status("Máximo de %d estelas alcanzado. Use '🌫 Borrar Estelas' para liberar espacio." % MAX_TRAILS)
		return

	# Crear un nuevo FunctionPlotter para la estela con color tenue
	var trail: FunctionPlotter = FunctionPlotter.new()
	trail.name          = "Estela%d" % (_trail_plotters.size() + 1)
	trail.position      = Vector2(640.0, 360.0)
	trail.formula       = formula
	trail.domain_min    = _domain_min_spin.value
	trail.domain_max    = _domain_max_spin.value
	trail.scale_factor  = DEFAULT_SCALE
	trail.line_color    = TRAIL_COLORS[_trail_index % TRAIL_COLORS.size()]
	trail.line_width    = 1.5
	trail.show_axes     = false
	trail.auto_plot     = true

	# Insertar la estela ANTES de los plotters activos para que se dibuje detrás
	add_child(trail)
	move_child(trail, _plotters[0].get_index())

	_trail_plotters.append(trail)
	_trail_index += 1

	_set_status(
		"✓ Estela de f%d(x) = %s guardada (trazo tenue). Grafique una nueva función encima para comparar." \
		% [index + 1, formula]
	)
	_update_trails_count_label()


## Elimina todas las estelas congeladas de la escena.
func _on_clear_trails() -> void:
	for t in _trail_plotters:
		if is_instance_valid(t):
			t.queue_free()
	_trail_plotters.clear()
	_trail_index = 0
	_set_status("Estelas borradas. La pizarra está limpia — ¡empiece una nueva comparación!")
	_update_trails_count_label()


## Actualiza la etiqueta de conteo de estelas activas.
func _update_trails_count_label() -> void:
	if not _trails_count_label:
		return
	if _trail_plotters.is_empty():
		_trails_count_label.text = ""
	else:
		_trails_count_label.text = "  Estelas: %d/%d" % [_trail_plotters.size(), MAX_TRAILS]


# ---------------------------------------------------------------------------
# Lógica de Graficado
# ---------------------------------------------------------------------------

func _plot_function(formula: String, index: int) -> void:
	if formula.is_empty():
		_set_status("Fórmula vacía para f%d. Ingrese una expresión." % (index + 1))
		return

	# Validación sintáctica con mensaje educativo
	if not MathEngine.is_valid_formula(formula):
		var msg: String = MathEngine.get_friendly_error_message(formula)
		_set_status("f%d: %s" % [index + 1, msg])
		return

	var plotter: FunctionPlotter = _plotters[index]
	plotter.formula = formula
	plotter.domain_min = _domain_min_spin.value
	plotter.domain_max = _domain_max_spin.value
	plotter.plot()
	_set_status("f%d(x) = %s  trazada correctamente." % [index + 1, formula])


# ---------------------------------------------------------------------------
# Auxiliares
# ---------------------------------------------------------------------------

func _set_status(msg: String) -> void:
	if _status_label:
		_status_label.text = msg


func _get_placeholder(index: int) -> String:
	match index:
		0: return "ej.  x^2"
		1: return "ej.  sin(x)"
		2: return "ej.  log(x + 1)"
		_: return "fórmula…"


func _on_formula_input_focus_entered() -> void:
	_active_formula_input = get_viewport().gui_get_focus_owner() as LineEdit
	if _active_formula_input == null and not _formula_inputs.is_empty():
		_active_formula_input = _formula_inputs[0]


func _on_formula_text_changed(new_text: String, input: LineEdit) -> void:
	var sanitized: String = _sanitize_formula_text(new_text)
	if sanitized == new_text:
		return
	var prev_caret: int = input.caret_column
	var left_raw: String = new_text.left(prev_caret)
	var left_sanitized: String = _sanitize_formula_text(left_raw)
	input.text = sanitized
	input.caret_column = clampi(left_sanitized.length(), 0, sanitized.length())


func _on_formula_input_gui_input(event: InputEvent, input: LineEdit) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		var index: int = _formula_inputs.find(input)
		if index >= 0:
			_on_plot_pressed(index)
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		# No marcar como handled para que la flecha llegue al LineEdit
		# y mantenga la navegación normal del cursor sin interferencia.
		return
	if key_event.keycode in [KEY_ALT, KEY_CTRL, KEY_SHIFT, KEY_META, KEY_DELETE]:
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode < KEY_SPACE and key_event.keycode != KEY_BACKSPACE:
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_BACKSPACE:
		var sel_from: int = input.get_selection_from_column()
		var sel_to: int = input.get_selection_to_column()
		if sel_from != sel_to:
			var current_text: String = input.text
			var from_col: int = mini(sel_from, sel_to)
			var to_col: int = maxi(sel_from, sel_to)
			input.text = current_text.left(from_col) + current_text.substr(to_col)
			input.caret_column = from_col
			input.deselect()
			get_viewport().set_input_as_handled()
			return
		var caret: int = input.caret_column
		if caret <= 0:
			get_viewport().set_input_as_handled()
			return
		var text: String = input.text
		input.text = text.left(caret - 1) + text.substr(caret)
		input.caret_column = caret - 1
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_SLASH or key_event.unicode == int('/'):
		_insert_fraction_at_cursor(input)
		get_viewport().set_input_as_handled()
		return
	if key_event.unicode <= 0:
		get_viewport().set_input_as_handled()
		return
	if not _is_allowed_math_code(key_event.unicode):
		get_viewport().set_input_as_handled()
		return


func _toggle_keyboard_visibility(visible: bool) -> void:
	var keyboard_panel: Control = _hud_layer.get_node_or_null("BottomPanel/KeyboardPanel")
	if keyboard_panel:
		keyboard_panel.visible = visible
	if _keyboard_toggle_button:
		_keyboard_toggle_button.button_pressed = visible


func _insert_at_cursor(input: LineEdit, text: String) -> void:
	if text == "/":
		_insert_fraction_at_cursor(input)
		return
	var pos: int = input.caret_column
	var current: String = input.text
	input.text = current.left(pos) + text + current.substr(pos)
	input.caret_column = pos + text.length()
	input.grab_focus()


func _insert_fraction_at_cursor(input: LineEdit) -> void:
	var pos: int = input.caret_column
	var text: String = input.text
	var numerator_start: int = pos
	while numerator_start > 0:
		var ch: String = text.substr(numerator_start - 1, 1)
		if ch in MathKeyboard.MATH_DELIMITERS:
			break
		numerator_start -= 1

	var numerator: String = text.substr(numerator_start, pos - numerator_start)
	var before: String = text.left(numerator_start)
	var after: String = text.substr(pos)
	if numerator.is_empty():
		input.text = before + "()/()" + after
		input.caret_column = before.length() + 4
	else:
		input.text = before + "(%s)/()" % numerator + after
		input.caret_column = before.length() + numerator.length() + 5
	input.grab_focus()


func _build_virtual_keyboard(parent: Control) -> void:
	var keyboard_panel: MathKeyboard = preload("res://scenes/ui/math_keyboard.tscn").instantiate() as MathKeyboard
	keyboard_panel.name = "KeyboardPanel"
	keyboard_panel.anchor_left = 0.0
	keyboard_panel.anchor_top = 1.0
	keyboard_panel.anchor_right = 1.0
	keyboard_panel.anchor_bottom = 1.0
	keyboard_panel.offset_top = -320.0
	keyboard_panel.offset_bottom = _KEYBOARD_BOTTOM_OFFSET
	keyboard_panel.visible = false
	parent.add_child(keyboard_panel)
	keyboard_panel.key_pressed.connect(func(payload: String) -> void:
		if _active_formula_input == null and not _formula_inputs.is_empty():
			_active_formula_input = _formula_inputs[0]
		if _active_formula_input:
			_insert_at_cursor(_active_formula_input, payload)
	)
	keyboard_panel.close_requested.connect(func() -> void:
		_toggle_keyboard_visibility(false)
	)


func _apply_label_outline(label: Label) -> void:
	if not label:
		return
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)


func _sanitize_formula_text(raw_text: String) -> String:
	var out: PackedStringArray = []
	for i in range(raw_text.length()):
		var code: int = raw_text.unicode_at(i)
		if _is_allowed_math_code(code):
			out.append(char(code))
	return _sanitize_math_words("".join(out))


func _sanitize_math_words(text: String) -> String:
	var output: PackedStringArray = []
	var current_word: PackedStringArray = []
	for i in range(text.length()):
		var ch: String = text.substr(i, 1)
		if _ALLOWED_LETTERS.contains(ch):
			current_word.append(ch)
			continue
		_append_sanitized_word(output, "".join(current_word), true)
		current_word.clear()
		output.append(ch)
	_append_sanitized_word(output, "".join(current_word), true)
	return "".join(output)


func _append_sanitized_word(output: PackedStringArray, word: String, allow_prefix: bool) -> void:
	if word.is_empty():
		return
	var lower_word: String = word.to_lower()
	if lower_word in _ALLOWED_WORDS_LOWER:
		output.append(word)
		return
	if allow_prefix:
		for allowed_word in _ALLOWED_WORDS_LOWER:
			if allowed_word.begins_with(lower_word):
				output.append(word)
				return


func _is_allowed_math_code(code: int) -> bool:
	if code < _CHAR_CODE_SPACE or code == _CHAR_CODE_DEL:
		return false
	var ch: String = char(code)
	if _ALLOWED_SYMBOLS.contains(ch):
		return true
	if code >= _CHAR_CODE_0 and code <= _CHAR_CODE_9:
		return true
	if _ALLOWED_LETTERS.contains(ch):
		return true
	return false


func _build_reference_dialog() -> void:
	_reference_dialog = AcceptDialog.new()
	_reference_dialog.title = "Referencia Matemática"
	_reference_dialog.dialog_text = (
		"Potencias: x^2 o pow(x, 2)\n"
		+ "Raíces: sqrt(x)\n"
		+ "Trigonometría: sin(x), cos(x), tan(x)\n"
		+ "Trig. inversa: asin(x), acos(x), atan(x)\n"
		+ "Logaritmos: log(x), ln(x), log(base, x)\n"
		+ "Valor absoluto: abs(x)\n"
		+ "Constantes: PI, E\n"
		+ "Dominio: ajusta [min, max] para enfocar la zona válida."
	)
	add_child(_reference_dialog)
