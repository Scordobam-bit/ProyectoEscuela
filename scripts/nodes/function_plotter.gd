## FunctionPlotter.gd
## ===================
## Nodo de renderizado principal para Planet Waves.
##
## Base Matemática (Nivel Universitario)
## ---------------------------------------
## Una función f: D → ℝ mapea cada elemento x en el dominio D a una única
## salida y = f(x) en el codominio. Este nodo evalúa f en N puntos de
## muestra uniformemente espaciados en el dominio [domain_min, domain_max] y
## renderiza los pares ordenados resultantes (x, f(x)) como una polilínea (Line2D).
##
## Convención de Coordenadas:
##   • Espacio matemático : x crece hacia la derecha, y crece hacia arriba
##   • Espacio de pantalla: x crece hacia la derecha, y crece hacia ABAJO (predeterminado de Godot)
##   • Conversión        : screen_pos = Vector2(x · escala, -y · escala) + origen
##
## Uso (GDScript):
##   var plotter := FunctionPlotter.new()
##   plotter.formula     = "sin(x) * x"
##   plotter.domain_min  = -PI * 2
##   plotter.domain_max  =  PI * 2
##   plotter.scale_factor = 60.0
##   add_child(plotter)
##   plotter.plot()
##   var path := plotter.build_path2d()   # para movimiento de nave con PathFollow2D
@tool
class_name FunctionPlotter
extends Node2D

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida tras un graficado exitoso con todos los puntos calculados en espacio de pantalla.
signal plot_completed(points: PackedVector2Array)

## Emitida cuando el análisis o la evaluación fallan.
signal plot_failed(error_message: String)

# ---------------------------------------------------------------------------
# Propiedades exportadas (editables en el Inspector de Godot)
# ---------------------------------------------------------------------------

## Fórmula matemática usando la variable "x".
## Admite la sintaxis de Expression de Godot: +, -, *, /, ^, sin, cos, tan,
## exp, log, sqrt, abs, ceil, floor, PI, TAU, etc.
## Ejemplos: "2*x + 1",  "x^2 - 4",  "sin(x)",  "log(x)"
@export var formula: String = "x":
	set(value):
		formula = value
		if auto_plot and is_inside_tree():
			plot()

## Extremo izquierdo del dominio de graficado (inclusive).
@export var domain_min: float = -10.0:
	set(value):
		domain_min = value
		_rebuild_axes()
		queue_redraw()
		if auto_plot and is_inside_tree():
			plot()

## Extremo derecho del dominio de graficado (inclusive).
@export var domain_max: float = 10.0:
	set(value):
		domain_max = value
		_rebuild_axes()
		queue_redraw()
		if auto_plot and is_inside_tree():
			plot()

## Número de puntos de muestra (mayor = más suave, menor = más rápido).
## Limitado a [2, 2000].
@export_range(2, 2000, 1) var sample_count: int = 300:
	set(value):
		sample_count = clampi(value, 2, 2000)
		if auto_plot and is_inside_tree():
			plot()

## Píxeles por unidad matemática (nivel de zoom).
@export var scale_factor: float = 50.0:
	set(value):
		scale_factor = maxf(value, 0.001)
		_rebuild_axes()
		queue_redraw()
		if auto_plot and is_inside_tree():
			plot()

## Límite vertical: los valores y fuera de [-y_clamp, y_clamp] se omiten.
## Establece en 0 para deshabilitar el límite.
@export var y_clamp: float = 20.0

## Vuelve a graficar automáticamente cuando cambia alguna propiedad.
@export var auto_plot: bool = true

## Color de la curva de la función graficada.
@export var line_color: Color = Color(0.0, 1.0, 0.8, 1.0)

## Grosor de la línea de la función graficada (en píxeles).
@export_range(0.5, 10.0, 0.5) var line_width: float = 2.5:
	set(value):
		line_width = value
		if _function_line:
			_function_line.width = value

## Mostrar ejes de coordenadas.
@export var show_axes: bool = true:
	set(value):
		show_axes = value
		_rebuild_axes()

## Color de los ejes de coordenadas.
@export var axis_color: Color = Color(0.4, 0.4, 0.6, 0.7)
@export var grid_color: Color = Color(0.32, 0.38, 0.55, 0.28)
@export_range(10, 24, 1) var axis_label_font_size: int = 13
@export var axis_tick_half_length: float = 4.0
@export var axis_label_color: Color = Color(0.86, 0.9, 1.0, 0.95)
@export var axis_label_offset: float = 8.0
@export var axis_label_y_side_offset: float = 3.0
const _DEFAULT_Y_EXTENT_UNITS: float = 15.0

# ---------------------------------------------------------------------------
# Miembros privados
# ---------------------------------------------------------------------------

var _function_line: Line2D = null
var _x_axis_line: Line2D = null
var _y_axis_line: Line2D = null
var _grid_lines: Node2D = null
var _expression: Expression = Expression.new()
var _last_points: PackedVector2Array = PackedVector2Array()
var _plot_valid: bool = false

## Línea de referencia / "Línea Fantasma" — muestra la solución correcta en verde.
var _reference_line: Line2D = null
## Color original de la línea de función (para restaurar después de marcar error).
var _original_line_color: Color = Color(0.0, 1.0, 0.8, 1.0)

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_visuals()
	if auto_plot:
		plot()


func _draw() -> void:
	if not show_axes:
		return
	var y_units: int = _get_y_extent_units()
	var y_extent_px: float = float(y_units) * scale_factor
	var min_x_tick: int = int(ceil(domain_min))
	var max_x_tick: int = int(floor(domain_max))
	var tick_half_len: float = axis_tick_half_length
	for x_tick in range(min_x_tick, max_x_tick + 1):
		var x_pos: float = float(x_tick) * scale_factor
		if x_tick != 0:
			draw_line(
				Vector2(x_pos, -y_extent_px),
				Vector2(x_pos, y_extent_px),
				grid_color,
				1.0
			)
		draw_line(
			Vector2(x_pos, -tick_half_len),
			Vector2(x_pos, tick_half_len),
			axis_color,
			1.2
		)
		_draw_axis_label(Vector2(x_pos, axis_label_offset), str(x_tick), true)
	for y_tick in range(-y_units, y_units + 1):
		var y_pos: float = -float(y_tick) * scale_factor
		if y_tick != 0:
			draw_line(
				Vector2(float(min_x_tick) * scale_factor, y_pos),
				Vector2(float(max_x_tick) * scale_factor, y_pos),
				grid_color,
				1.0
			)
		draw_line(
			Vector2(-tick_half_len, y_pos),
			Vector2(tick_half_len, y_pos),
			axis_color,
			1.2
		)
		_draw_axis_label(Vector2(axis_label_offset, y_pos), str(y_tick), false)


# ---------------------------------------------------------------------------
# Construcción Visual
# ---------------------------------------------------------------------------

func _build_visuals() -> void:
	_build_axes()
	_build_function_line()


func _build_function_line() -> void:
	if _function_line:
		_function_line.queue_free()
	_function_line = Line2D.new()
	_function_line.name = "FunctionLine"
	_function_line.width = line_width
	_function_line.default_color = line_color
	_function_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_function_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_function_line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_function_line)


func _build_axes() -> void:
	_rebuild_axes()


func _rebuild_axes() -> void:
	if _x_axis_line:
		_x_axis_line.queue_free()
		_x_axis_line = null
	if _y_axis_line:
		_y_axis_line.queue_free()
		_y_axis_line = null

	if not show_axes:
		return

	var x0: float = domain_min * scale_factor
	var x1: float = domain_max * scale_factor
	var y_extent: float = (y_clamp if y_clamp > 0.0 else _DEFAULT_Y_EXTENT_UNITS) * scale_factor

	# Eje horizontal (X)
	_x_axis_line = Line2D.new()
	_x_axis_line.name = "XAxis"
	_x_axis_line.width = 1.0
	_x_axis_line.default_color = axis_color
	_x_axis_line.add_point(Vector2(x0, 0.0))
	_x_axis_line.add_point(Vector2(x1, 0.0))
	add_child(_x_axis_line)

	# Eje vertical (Y)
	_y_axis_line = Line2D.new()
	_y_axis_line.name = "YAxis"
	_y_axis_line.width = 1.0
	_y_axis_line.default_color = axis_color
	_y_axis_line.add_point(Vector2(0.0, -y_extent))
	_y_axis_line.add_point(Vector2(0.0,  y_extent))
	add_child(_y_axis_line)
	queue_redraw()


# ---------------------------------------------------------------------------
# API Principal
# ---------------------------------------------------------------------------

## Analiza y evalúa la fórmula, luego actualiza el Line2D.
## Llama esto explícitamente, o confía en auto_plot al establecer propiedades.
func plot() -> void:
	if not is_inside_tree():
		return
	if not MathEngine:
		plot_failed.emit("MathEngine no está inicializado todavía.")
		return
	if not _function_line:
		_build_visuals()

	_function_line.clear_points()
	_last_points = PackedVector2Array()
	_plot_valid = false

	if formula.is_empty():
		plot_failed.emit("La fórmula está vacía.")
		return

	if domain_min >= domain_max:
		plot_failed.emit("domain_min debe ser menor que domain_max.")
		return

	# Analizar la fórmula una vez; "x" es la única variable
	# usando las mismas normalizaciones que MathEngine (e.g. ^, log(base,x), E/e).
	var normalized_formula: String = MathEngine.normalize_formula(formula)
	var parse_err: Error = _expression.parse(normalized_formula, ["x"])
	if parse_err != OK:
		plot_failed.emit("Error de análisis en la fórmula \"%s\"." % formula)
		return

	var step: float = (domain_max - domain_min) / float(sample_count - 1)
	var segments: Array[PackedVector2Array] = []
	var current_segment: PackedVector2Array = PackedVector2Array()

	for i in range(sample_count):
		var x: float = domain_min + step * float(i)
		var y: float = _safe_evaluate(x)

		# Omitir discontinuidades / valores indefinidos
		if is_nan(y) or is_inf(y):
			if current_segment.size() >= 2:
				segments.append(current_segment)
			current_segment = PackedVector2Array()
			continue

		# Límite vertical
		if y_clamp > 0.0 and absf(y) > y_clamp:
			if current_segment.size() >= 2:
				segments.append(current_segment)
			current_segment = PackedVector2Array()
			continue

		var screen_pt: Vector2 = math_to_screen(Vector2(x, y))
		current_segment.append(screen_pt)
		_last_points.append(screen_pt)

	if current_segment.size() >= 2:
		segments.append(current_segment)

	if _last_points.is_empty():
		plot_failed.emit("No se calcularon puntos válidos para la fórmula \"%s\"." % formula)
		return

	# Renderizar todos los segmentos conectados.
	# Para una función de un solo segmento simple, el primer segmento lo cubre todo.
	# Para multi-segmento (p. ej., función racional con asíntotas), usamos el primer segmento
	# en el Line2D principal y creamos nodos Line2D auxiliares para segmentos adicionales.
	_render_segments(segments)

	_plot_valid = true
	queue_redraw()
	plot_completed.emit(_last_points)


## Vuelve a graficar con una nueva fórmula (envoltura de conveniencia).
func set_formula_and_plot(new_formula: String) -> void:
	formula = new_formula
	if not auto_plot:
		plot()


## Establece el dominio y vuelve a graficar (envoltura de conveniencia).
func set_domain(min_x: float, max_x: float) -> void:
	domain_min = min_x
	domain_max = max_x
	if not auto_plot:
		plot()


## Limpia la curva renderizada y marca el estado como no válido sin emitir errores.
func clear_plot() -> void:
	if _function_line:
		_function_line.clear_points()
	# Eliminar líneas de segmentos auxiliares creadas previamente
	for child in get_children():
		if _is_aux_segment_line(child):
			child.queue_free()
	_last_points = PackedVector2Array()
	_plot_valid = false
	hide_reference_line()
	queue_redraw()


## Evalúa la fórmula actual en un único valor x.
## Devuelve NAN si la evaluación falla.
func evaluate_at(x_val: float) -> float:
	return _safe_evaluate(x_val)


## Devuelve todos los puntos calculados en espacio de pantalla del último graficado exitoso.
func get_screen_points() -> PackedVector2Array:
	return _last_points


## Devuelve true si la última llamada a plot() produjo una salida válida.
func is_plot_valid() -> bool:
	return _plot_valid


## Construye y devuelve un nodo Path2D cuya Curve2D sigue la trayectoria graficada.
## Adjunta un PathFollow2D y un sprite de nave como hijos de este Path2D para animar
## la nave a lo largo de la curva de la función.
##
## Ejemplo:
##   var path := plotter.build_path2d()
##   scene.add_child(path)
##   var follower := PathFollow2D.new()
##   path.add_child(follower)
##   follower.add_child(ship_sprite)
##   # Animar progress de 0.0 → 1.0 con el tiempo
func build_path2d() -> Path2D:
	var path: Path2D = Path2D.new()
	var curve: Curve2D = Curve2D.new()
	for pt in _last_points:
		curve.add_point(pt)
	path.curve = curve
	return path


## Muestra una "Línea Fantasma" de referencia con la fórmula y color indicados.
## Llamar con la fórmula correcta (verde) cuando el jugador cometió un error.
func show_reference_line(ref_formula: String, ref_color: Color = Color(0.0, 1.0, 0.3, 0.7)) -> void:
	if not is_inside_tree():
		return
	if not MathEngine:
		return

	# Eliminar referencia previa si existe
	hide_reference_line()

	var expr: Expression = Expression.new()
	var normalized_ref_formula: String = MathEngine.normalize_formula(ref_formula)
	if expr.parse(normalized_ref_formula, ["x"]) != OK:
		return

	var step: float = (domain_max - domain_min) / float(sample_count - 1)
	var ref_pts: PackedVector2Array = PackedVector2Array()

	for i in range(sample_count):
		var x: float = domain_min + step * float(i)
		var result: Variant = expr.execute([x])
		if expr.has_execute_failed() or result == null:
			continue
		var y: float = float(result)
		if is_nan(y) or is_inf(y):
			continue
		if y_clamp > 0.0 and absf(y) > y_clamp:
			continue
		ref_pts.append(math_to_screen(Vector2(x, y)))

	if ref_pts.size() < 2:
		return

	_reference_line = Line2D.new()
	_reference_line.name = "_ReferenceLine"
	_reference_line.width = line_width + 0.5
	_reference_line.default_color = ref_color
	_reference_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_reference_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_reference_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_reference_line.points = ref_pts
	add_child(_reference_line)


## Oculta y elimina la Línea Fantasma de referencia.
func hide_reference_line() -> void:
	if _reference_line and is_instance_valid(_reference_line):
		_reference_line.queue_free()
	_reference_line = null


## Marca la línea de función actual como errónea (color rojo semitransparente).
## Llama a reset_line_style() para restaurar el estilo original.
func mark_as_error() -> void:
	_original_line_color = line_color
	if _function_line:
		_function_line.default_color = Color(1.0, 0.2, 0.2, 0.55)
	for child in get_children():
		if child.name.begins_with("_SegLine"):
			(child as Line2D).default_color = Color(1.0, 0.2, 0.2, 0.55)


## Restaura el color y estilo originales de la línea de función.
func reset_line_style() -> void:
	if _function_line:
		_function_line.default_color = _original_line_color
	for child in get_children():
		if child.name.begins_with("_SegLine"):
			(child as Line2D).default_color = _original_line_color
	hide_reference_line()


## Devuelve el Vector2 en espacio de pantalla para un par (x, y) en espacio matemático.
func math_to_screen(math_pos: Vector2) -> Vector2:
	return Vector2(math_pos.x * scale_factor, -math_pos.y * scale_factor)


## Devuelve el Vector2 en espacio matemático para una posición en espacio de pantalla.
func screen_to_math(screen_pos: Vector2) -> Vector2:
	return Vector2(screen_pos.x / scale_factor, -screen_pos.y / scale_factor)


## Devuelve la coordenada x en pantalla para el valor matemático x dado.
func math_x_to_screen(x_val: float) -> float:
	return x_val * scale_factor


## Devuelve la coordenada y en pantalla para el valor matemático y dado (eje Y invertido).
func math_y_to_screen(y_val: float) -> float:
	return -y_val * scale_factor


# ---------------------------------------------------------------------------
# Auxiliares privados
# ---------------------------------------------------------------------------

func _safe_evaluate(x_val: float) -> float:
	var result: Variant = _expression.execute([x_val])
	if _expression.has_execute_failed():
		return NAN
	if result == null:
		return NAN
	return float(result)


func _render_segments(segments: Array[PackedVector2Array]) -> void:
	# Eliminar líneas de segmentos auxiliares creadas previamente
	for child in get_children():
		if _is_aux_segment_line(child):
			child.queue_free()

	if segments.is_empty():
		return

	# Primer segmento → _function_line principal
	_function_line.clear_points()
	for pt in segments[0]:
		_function_line.add_point(pt)

	# Segmentos adicionales → nodos Line2D auxiliares (p. ej., ramas de función racional)
	for i in range(1, segments.size()):
		var seg_line: Line2D = Line2D.new()
		seg_line.name = "_SegLine%d" % i
		seg_line.width = line_width
		seg_line.default_color = line_color
		seg_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		seg_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		seg_line.joint_mode = Line2D.LINE_JOINT_ROUND
		seg_line.set_meta("is_aux_segment_line", true)
		for pt in segments[i]:
			seg_line.add_point(pt)
		add_child(seg_line)


func _get_y_extent_units() -> int:
	var y_extent_units: int = int(ceil(y_clamp if y_clamp > 0.0 else _DEFAULT_Y_EXTENT_UNITS))
	return maxi(y_extent_units, 1)


func _draw_axis_label(anchor: Vector2, text: String, is_x_axis: bool) -> void:
	var fallback_font: Font = ThemeDB.fallback_font
	if fallback_font == null:
		return
	var text_size: Vector2 = fallback_font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		axis_label_font_size
	)
	var draw_pos: Vector2 = anchor
	if is_x_axis:
		draw_pos.x -= text_size.x * 0.5
		draw_pos.y += text_size.y
	else:
		draw_pos.x += axis_label_y_side_offset
		draw_pos.y += text_size.y * 0.5
	draw_string(
		fallback_font,
		draw_pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		axis_label_font_size,
		axis_label_color
	)


func _is_aux_segment_line(node: Node) -> bool:
	return node is Line2D and (
		node.has_meta("is_aux_segment_line")
		or node.name.begins_with("_SegLine")
	)
