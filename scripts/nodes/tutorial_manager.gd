## TutorialManager.gd
## ====================
## Guía de Inicio Rápido del Sector 1.
## Muestra una secuencia de burbujas flotantes que señalan los elementos clave del HUD.
## Solo aparece la primera vez (controlado por GameManager.tutorial_completed).
##
## Uso:
##   var tm := TutorialManager.new()
##   add_child(tm)
##   tm.setup(hud_node)       # configurar antes de iniciar
##   tm.start()               # mostrar la secuencia (desde _on_theory_closed)
##   tm.force_hide()          # ocultar inmediatamente si es necesario
class_name TutorialManager
extends CanvasLayer

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando el jugador completa todos los pasos de la guía.
signal guide_completed

## Emitida si el jugador presionó "Saltar Guía".
signal guide_skipped

# ---------------------------------------------------------------------------
# Pasos de la Guía (orden fijo)
# ---------------------------------------------------------------------------

const _STEP_TARGET_INPUT: String = "input"
const _STEP_TARGET_PLOT: String = "plot_button"
const _STEP_TARGET_DOMAIN: String = "domain"

## Capa del CanvasLayer — debe ser mayor que la del HUD (HUD usa layer=20).
const TUTORIAL_LAYER: int = 30

# Definición de los tres pasos en orden de aparición.
var _steps: Array = [
	{
		"message":
			(
				"[b]Capitán, ingrese aquí la ecuación de su trayectoria.[/b]\n"
				+ "[color=#aaddff]Ejemplo:  [color=#ffcc00]2*x + 1[/color][/color]"
			),
		"target": _STEP_TARGET_INPUT,
	},
	{
		"message":
			(
				"[b]Presione este botón [color=#ffcc00]GRAFICAR[/color] o la tecla [color=#ffcc00]Enter[/color]"
				+ " para calcular la ruta.[/b]\n"
				+ "[color=#aaddff]La trayectoria se trazará en el mapa estelar.[/color]"
			),
		"target": _STEP_TARGET_PLOT,
	},
	{
		"message":
			(
				"[b]Use estos controles para ajustar qué tan larga es su trayectoria en el eje X.[/b]\n"
				+ "[color=#aaddff]El dominio define el rango de valores en que se traza la función.[/color]"
			),
		"target": _STEP_TARGET_DOMAIN,
	},
]

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var _hud: HUD = null
var _current_step: int = 0

# Nodos de la interfaz creados programáticamente
var _overlay: ColorRect = null
var _highlight: Panel = null
var _bubble: PanelContainer = null
var _bubble_text: RichTextLabel = null
var _step_label: Label = null
var _next_btn: Button = null
var _skip_btn: Button = null

# ---------------------------------------------------------------------------
# Inicialización
# ---------------------------------------------------------------------------

func _ready() -> void:
	layer = TUTORIAL_LAYER   # Por encima del HUD


## Configura el gestor y construye la interfaz gráfica.
## Debe llamarse antes de start().
func setup(hud: HUD) -> void:
	_hud = hud
	_build_ui()
	visible = false


func _build_ui() -> void:
	# ── Fondo semitransparente ──────────────────────────────────────────────
	_overlay = ColorRect.new()
	_overlay.name = "TutorialOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.02, 0.5)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# ── Marco de resaltado neón alrededor del elemento señalado ────────────
	_highlight = Panel.new()
	_highlight.name = "TutorialHighlight"
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hl_style: StyleBoxFlat = StyleBoxFlat.new()
	hl_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	hl_style.border_color = Color(0.0, 1.0, 0.8, 0.9)
	hl_style.set_border_width_all(3)
	hl_style.set_corner_radius_all(4)
	_highlight.add_theme_stylebox_override("panel", hl_style)
	add_child(_highlight)

	# ── Burbuja flotante de texto ───────────────────────────────────────────
	_bubble = PanelContainer.new()
	_bubble.name = "TutorialBubble"
	_bubble.custom_minimum_size = Vector2(440.0, 110.0)

	var bubble_style: StyleBoxFlat = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.03, 0.05, 0.18, 0.96)
	bubble_style.border_color = Color(0.0, 1.0, 0.8, 0.85)
	bubble_style.set_border_width_all(2)
	bubble_style.set_corner_radius_all(8)
	_bubble.add_theme_stylebox_override("panel", bubble_style)
	add_child(_bubble)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_bubble.add_child(vbox)

	# Texto del paso actual
	_bubble_text = RichTextLabel.new()
	_bubble_text.bbcode_enabled = true
	_bubble_text.fit_content = true
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_bubble_text.custom_minimum_size = Vector2(420.0, 55.0)
	_bubble_text.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0, 1.0))
	vbox.add_child(_bubble_text)

	# Fila de botones
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	_skip_btn = Button.new()
	_skip_btn.text = "Saltar Guía"
	_skip_btn.pressed.connect(_on_skip_pressed)
	btn_row.add_child(_skip_btn)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	_step_label = Label.new()
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8, 1.0))
	btn_row.add_child(_step_label)

	var spacer2: Control = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer2)

	_next_btn = Button.new()
	_next_btn.text = "Siguiente ▶"
	_next_btn.pressed.connect(_on_next_pressed)
	btn_row.add_child(_next_btn)


# ---------------------------------------------------------------------------
# Control de la Secuencia
# ---------------------------------------------------------------------------

## Inicia la secuencia de la guía desde el paso 0.
func start() -> void:
	if not _hud:
		guide_completed.emit()
		return
	_current_step = 0
	_hud.set_controls_enabled(false)
	visible = true
	_show_step(_current_step)


## Oculta la guía sin emitir señal (p. ej., si el sector avanza sin tutorial).
func force_hide() -> void:
	visible = false
	if _hud:
		_hud.set_controls_enabled(true)


func _show_step(index: int) -> void:
	if index < 0 or index >= _steps.size():
		_finish()
		return

	var step: Dictionary = _steps[index]
	_bubble_text.text = step["message"]
	_step_label.text = "%d / %d" % [index + 1, _steps.size()]

	if index == _steps.size() - 1:
		_next_btn.text = "¡Entendido! ✔"
	else:
		_next_btn.text = "Siguiente ▶"

	# Obtener el rect del elemento objetivo en el HUD
	var target_rect: Rect2 = _get_target_rect(step.get("target", ""))

	# Posicionar el marco de resaltado
	_highlight.position = target_rect.position - Vector2(4.0, 4.0)
	_highlight.size = target_rect.size + Vector2(8.0, 8.0)

	# Posicionar la burbuja debajo del elemento; si no cabe, colocarla encima
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var bub_w: float = _bubble.custom_minimum_size.x
	var bub_h: float = _bubble.custom_minimum_size.y

	var bub_x: float = clampf(target_rect.position.x, 10.0, viewport_size.x - bub_w - 10.0)
	var bub_y: float = target_rect.end.y + 14.0

	if bub_y + bub_h > viewport_size.y - 10.0:
		bub_y = target_rect.position.y - bub_h - 14.0

	_bubble.position = Vector2(bub_x, bub_y)


func _get_target_rect(target_id: String) -> Rect2:
	if not _hud:
		return Rect2(60.0, 40.0, 220.0, 40.0)
	match target_id:
		_STEP_TARGET_INPUT:
			return _hud.get_input_global_rect()
		_STEP_TARGET_PLOT:
			return _hud.get_plot_button_global_rect()
		_STEP_TARGET_DOMAIN:
			return _hud.get_domain_row_global_rect()
		_:
			return Rect2(60.0, 40.0, 220.0, 40.0)


func _on_next_pressed() -> void:
	_current_step += 1
	if _current_step >= _steps.size():
		_finish()
	else:
		_show_step(_current_step)


func _on_skip_pressed() -> void:
	guide_skipped.emit()
	_finish()


func _finish() -> void:
	visible = false
	if _hud:
		_hud.set_controls_enabled(true)
	guide_completed.emit()
