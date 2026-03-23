## MissionCompletePanel.gd
## =======================
## Panel de "¡Misión Cumplida!" que se muestra al completar cada sector.
## Genera un resumen pedagógico dinámico basado en los desafíos superados.
## Construido programáticamente como CanvasLayer para superponerse a todo.
class_name MissionCompletePanel
extends CanvasLayer

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando el jugador presiona "Siguiente Sector" o "Menú Principal".
signal continue_pressed

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

## Capa de renderizado (por encima del HUD y del TutorialManager).
const PANEL_LAYER: int = 20

## Conceptos pedagógicos asociados a cada sector (índice → Array de conceptos posibles).
## Se selecciona un subconjunto según los desafíos completados.
const SECTOR_CONCEPTS: Dictionary = {
	1: [
		"Identificación de la pendiente y la ordenada al origen de una función lineal",
		"Uso de la forma pendiente-intercepto  f(x) = mx + b",
		"Cálculo preciso de trayectorias lineales en el cinturón de asteroides",
		"Dominio del concepto de función constante (m = 0)",
		"Interpretación geométrica de la pendiente como razón de cambio",
	],
	2: [
		"Identificación de la forma estándar de una función cuadrática ax² + bx + c",
		"Cálculo del vértice de una parábola:  h = −b / (2a),  k = f(h)",
		"Uso del discriminante Δ = b² − 4ac para determinar el número de raíces reales",
		"Dominio de la forma vértice:  f(x) = a(x − h)² + k",
		"Comprensión de los pozos gravitatorios como parábolas con mínimo/máximo",
	],
	3: [
		"Reconocimiento de las principales familias de funciones (seno, coseno, raíz, valor absoluto)",
		"Aplicación de desplazamientos verticales  f(x) + k  y horizontales  f(x − h)",
		"Escala vertical  a·f(x)  y horizontal  f(b·x)  de funciones",
		"Reflexión sobre el eje X  −f(x)  y sobre el eje Y  f(−x)",
		"Transformaciones combinadas aplicadas a señales de púlsares",
	],
	4: [
		"Suma y diferencia de funciones:  (f ± g)(x) = f(x) ± g(x)",
		"Producto y cociente de funciones:  (f·g)(x),  (f/g)(x)",
		"Composición de funciones:  (f∘g)(x) = f(g(x))",
		"Identificación del dominio de una función compuesta",
		"Acoplamiento de módulos mediante composición funcional",
	],
	5: [
		"Prueba de la línea horizontal para verificar inyectividad (uno a uno)",
		"Cálculo analítico de funciones inversas intercambiando x e y",
		"Propiedades fundamentales: e^(ln(x)) = x  y  ln(eˣ) = x",
		"Composición de funciones inversas:  f⁻¹(f(x)) = x = f(f⁻¹(x))",
		"Evaluación de  f(g(x))  con funciones transcendentales compuestas",
	],
}

## Títulos de misión por sector para la pantalla de resultados.
const SECTOR_MISSION_NAMES: Dictionary = {
	0: "Academia de Vuelo",
	1: "Cinturón de Asteroides",
	2: "Pozos Gravitatorios",
	3: "Sintonizador de Púlsares",
	4: "Estación de Acoplamiento",
	5: "Horizonte de Sucesos — COMPLETADO",
}

# ---------------------------------------------------------------------------
# Estado Privado
# ---------------------------------------------------------------------------

var _root: Control = null
var _sector_index: int = 1
var _score_earned: int = 0
var _challenges_completed: Array = []

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	layer = PANEL_LAYER
	_build_ui()


# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Muestra el panel con los resultados del sector completado.
## sector_index        : número de sector (1–5).
## score_earned        : puntos ganados en esta sesión de sector.
## challenges_done     : arreglo con los índices de desafíos completados.
func show_results(sector_index: int, score_earned: int, challenges_done: Array) -> void:
	_sector_index = sector_index
	_score_earned = score_earned
	_challenges_completed = challenges_done
	_populate_ui()
	visible = true


# ---------------------------------------------------------------------------
# Construcción de la Interfaz (programática)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Fondo semi-transparente oscuro
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "Overlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.05, 0.88)
	add_child(overlay)

	# Panel central neón
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ResultsPanel"
	panel.anchor_left   = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -400.0
	panel.offset_top    = -280.0
	panel.offset_right  = 400.0
	panel.offset_bottom = 280.0

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.15, 0.98)
	style.border_color = Color(0.0, 1.0, 0.8, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# ── Encabezado ──────────────────────────────────────────────────────
	var header: Label = Label.new()
	header.name = "HeaderLabel"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	header.text = "⭐  ¡MISIÓN CUMPLIDA!  ⭐"
	vbox.add_child(header)

	var sector_label: Label = Label.new()
	sector_label.name = "SectorNameLabel"
	sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sector_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(sector_label)

	# ── Puntuación ──────────────────────────────────────────────────────
	var sep1: HSeparator = HSeparator.new()
	vbox.add_child(sep1)

	var score_label: Label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
	vbox.add_child(score_label)

	# ── Conceptos Aprendidos ─────────────────────────────────────────────
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	var concepts_title: Label = Label.new()
	concepts_title.text = "🧠  Conceptos Matemáticos Dominados:"
	concepts_title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	concepts_title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(concepts_title)

	var concepts_text: RichTextLabel = RichTextLabel.new()
	concepts_text.name = "ConceptsLabel"
	concepts_text.bbcode_enabled = true
	concepts_text.fit_content = true
	concepts_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	concepts_text.custom_minimum_size = Vector2(750.0, 120.0)
	concepts_text.add_theme_color_override("default_color", Color(0.85, 0.92, 1.0, 1.0))
	vbox.add_child(concepts_text)

	# ── Reflexión Final ──────────────────────────────────────────────────
	var sep3: HSeparator = HSeparator.new()
	vbox.add_child(sep3)

	var reflection: RichTextLabel = RichTextLabel.new()
	reflection.name = "ReflectionLabel"
	reflection.bbcode_enabled = true
	reflection.fit_content = true
	reflection.autowrap_mode = TextServer.AUTOWRAP_WORD
	reflection.custom_minimum_size = Vector2(750.0, 40.0)
	reflection.add_theme_color_override("default_color", Color(0.7, 0.8, 0.7, 1.0))
	vbox.add_child(reflection)

	# ── Botón de Continuación ────────────────────────────────────────────
	var sep4: HSeparator = HSeparator.new()
	vbox.add_child(sep4)

	var continue_btn: Button = Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "SIGUIENTE NIVEL  ▶"
	continue_btn.custom_minimum_size = Vector2(320.0, 64.0)
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)

	_root = panel
	visible = false


## Rellena la UI con los datos del sector completado.
func _populate_ui() -> void:
	if not _root:
		return

	var vbox: VBoxContainer = _root.get_child(0)

	# Nombre del sector
	var sector_name_lbl: Label = vbox.get_node("SectorNameLabel")
	var mission_name: String = SECTOR_MISSION_NAMES.get(_sector_index,
		"Sector %d" % _sector_index)
	sector_name_lbl.text = "Sector %d: %s" % [_sector_index, mission_name]

	# Puntuación
	var score_lbl: Label = vbox.get_node("ScoreLabel")
	score_lbl.text = "Puntuación del sector: %d  |  Total acumulado: %d" % [
		_score_earned, GameManager.get_score()
	]

	# Conceptos aprendidos (dinámicos)
	var concepts_lbl: RichTextLabel = vbox.get_node("ConceptsLabel")
	var concept_list: Array = _build_concept_list()
	var concepts_text: String = ""
	for c in concept_list:
		concepts_text += "• [color=#ffcc00]%s[/color]\n" % c
	concepts_lbl.text = concepts_text.strip_edges()

	# Reflexión final
	var reflection_lbl: RichTextLabel = vbox.get_node("ReflectionLabel")
	reflection_lbl.text = _build_reflection_text()

	# Actualizar botón según si hay sector siguiente o se va al menú
	var continue_btn: Button = vbox.get_node("ContinueButton")
	if _sector_index >= GameManager.get_last_sector_index():
		continue_btn.text = "🏠  Volver al Menú Principal"
	else:
		continue_btn.text = "SIGUIENTE NIVEL — SECTOR %d  ▶" % (_sector_index + 1)


## Genera la lista de conceptos pedagógicos para el sector completado.
## Devuelve como mínimo 2 conceptos y como máximo la cantidad de desafíos + 1.
func _build_concept_list() -> Array:
	var all_concepts: Array = SECTOR_CONCEPTS.get(_sector_index, [])
	if all_concepts.is_empty():
		return ["Completaste todos los desafíos del sector."]

	# Seleccionar conceptos según la cantidad de desafíos completados
	var count: int = clampi(_challenges_completed.size(), 2, all_concepts.size())
	var selected: Array = []
	for i in range(count):
		selected.append(all_concepts[i])
	return selected


## Genera el texto de reflexión final para el sector.
func _build_reflection_text() -> String:
	match _sector_index:
		1:
			return ("[i]Reflexión:[/i] Las funciones lineales son la base del análisis matemático. "
				+ "Cada trayectoria recta que trazaste en el espacio es una función  [color=#ffcc00]f(x) = mx + b[/color].")
		2:
			return ("[i]Reflexión:[/i] Las parábolas modelan trayectorias balísticas, "
				+ "diseño de antenas satelitales y la aceleración gravitacional. El álgebra cuadrática "
				+ "está en todas partes del universo.")
		3:
			return ("[i]Reflexión:[/i] Transformar funciones es el lenguaje de las señales. "
				+ "Cada ajuste de frecuencia, amplitud o fase en un púlsar sigue estas mismas leyes matemáticas.")
		4:
			return ("[i]Reflexión:[/i] La composición de funciones modela los sistemas en cadena: "
				+ "sensores, procesadores, actuadores. Cada módulo de la nave aplica una función al resultado de la anterior.")
		5:
			return ("[i]Reflexión:[/i] Las inversas, los logaritmos y las exponenciales son el núcleo "
				+ "de la criptografía, la escala de decibeles y los modelos de crecimiento. "
				+ "¡Has dominado el Horizonte de Sucesos!")
		_:
			return "[i]Excelente trabajo. Continúa explorando las matemáticas del universo.[/i]"


# ---------------------------------------------------------------------------
# Manejadores de Señales
# ---------------------------------------------------------------------------

func _on_continue_pressed() -> void:
	visible = false
	continue_pressed.emit()
