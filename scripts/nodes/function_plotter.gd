## FunctionPlotter.gd
## ===================
## Core rendering node for Planet Waves.
##
## Mathematical Background (University Level)
## -------------------------------------------
## A function f: D → ℝ maps each element x in the domain D to a unique
## output y = f(x) in the codomain. This node evaluates f at N uniformly
## spaced sample points across the domain [domain_min, domain_max] and
## renders the resulting ordered pairs (x, f(x)) as a polyline (Line2D).
##
## Coordinate Convention:
##   • Math space : x increases right, y increases up
##   • Screen space: x increases right, y increases DOWN (Godot default)
##   • Conversion : screen_pos = Vector2(x · scale, -y · scale) + origin
##
## Usage (GDScript):
##   var plotter := FunctionPlotter.new()
##   plotter.formula     = "sin(x) * x"
##   plotter.domain_min  = -PI * 2
##   plotter.domain_max  =  PI * 2
##   plotter.scale_factor = 60.0
##   add_child(plotter)
##   plotter.plot()
##   var path := plotter.build_path2d()   # for PathFollow2D ship movement
@tool
class_name FunctionPlotter
extends Node2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted after a successful plot with all computed screen-space points.
signal plot_completed(points: PackedVector2Array)

## Emitted when parsing or evaluation fails.
signal plot_failed(error_message: String)

# ---------------------------------------------------------------------------
# Exported properties (editable in the Godot Inspector)
# ---------------------------------------------------------------------------

## Mathematical formula using variable "x".
## Supports Godot Expression syntax: +, -, *, /, ^, sin, cos, tan,
## exp, log, sqrt, abs, ceil, floor, PI, TAU, etc.
## Examples: "2*x + 1",  "x^2 - 4",  "sin(x)",  "log(x)"
@export var formula: String = "x":
	set(value):
		formula = value
		if auto_plot and is_inside_tree():
			plot()

## Left endpoint of the plotting domain (inclusive).
@export var domain_min: float = -10.0:
	set(value):
		domain_min = value
		if auto_plot and is_inside_tree():
			plot()

## Right endpoint of the plotting domain (inclusive).
@export var domain_max: float = 10.0:
	set(value):
		domain_max = value
		if auto_plot and is_inside_tree():
			plot()

## Number of sample points (higher = smoother, lower = faster).
## Clamped to [2, 2000].
@export_range(2, 2000, 1) var sample_count: int = 300:
	set(value):
		sample_count = clampi(value, 2, 2000)
		if auto_plot and is_inside_tree():
			plot()

## Pixels per math unit (zoom level).
@export var scale_factor: float = 50.0:
	set(value):
		scale_factor = maxf(value, 0.001)
		if auto_plot and is_inside_tree():
			plot()

## Vertical clamp: y values outside [-y_clamp, y_clamp] are skipped.
## Set to 0 to disable clamping.
@export var y_clamp: float = 20.0

## Automatically re-plot whenever any property changes.
@export var auto_plot: bool = true

## Color of the plotted function curve.
@export var line_color: Color = Color(0.0, 1.0, 0.8, 1.0)

## Width of the plotted function line (pixels).
@export_range(0.5, 10.0, 0.5) var line_width: float = 2.5:
	set(value):
		line_width = value
		if _function_line:
			_function_line.width = value

## Display coordinate axes.
@export var show_axes: bool = true:
	set(value):
		show_axes = value
		_rebuild_axes()

## Color of the coordinate axes.
@export var axis_color: Color = Color(0.4, 0.4, 0.6, 0.7)

# ---------------------------------------------------------------------------
# Private members
# ---------------------------------------------------------------------------

var _function_line: Line2D = null
var _x_axis_line: Line2D = null
var _y_axis_line: Line2D = null
var _grid_lines: Node2D = null
var _expression: Expression = Expression.new()
var _last_points: PackedVector2Array = PackedVector2Array()
var _plot_valid: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_visuals()
	if auto_plot:
		plot()


# ---------------------------------------------------------------------------
# Visual Construction
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
	var y_extent: float = (y_clamp if y_clamp > 0.0 else 15.0) * scale_factor

	# Horizontal (X) axis
	_x_axis_line = Line2D.new()
	_x_axis_line.name = "XAxis"
	_x_axis_line.width = 1.0
	_x_axis_line.default_color = axis_color
	_x_axis_line.add_point(Vector2(x0, 0.0))
	_x_axis_line.add_point(Vector2(x1, 0.0))
	add_child(_x_axis_line)

	# Vertical (Y) axis
	_y_axis_line = Line2D.new()
	_y_axis_line.name = "YAxis"
	_y_axis_line.width = 1.0
	_y_axis_line.default_color = axis_color
	_y_axis_line.add_point(Vector2(0.0, -y_extent))
	_y_axis_line.add_point(Vector2(0.0,  y_extent))
	add_child(_y_axis_line)


# ---------------------------------------------------------------------------
# Core API
# ---------------------------------------------------------------------------

## Parses and evaluates the formula, then updates the Line2D.
## Call this explicitly, or rely on auto_plot when setting properties.
func plot() -> void:
	if not is_inside_tree():
		return
	if not _function_line:
		_build_visuals()

	_function_line.clear_points()
	_last_points = PackedVector2Array()
	_plot_valid = false

	if formula.is_empty():
		plot_failed.emit("Formula is empty.")
		return

	if domain_min >= domain_max:
		plot_failed.emit("domain_min must be less than domain_max.")
		return

	# Parse the formula once; "x" is the only variable
	var parse_err: Error = _expression.parse(formula, ["x"])
	if parse_err != OK:
		plot_failed.emit("Parse error in formula \"%s\"." % formula)
		return

	var step: float = (domain_max - domain_min) / float(sample_count - 1)
	var segments: Array[PackedVector2Array] = []
	var current_segment: PackedVector2Array = PackedVector2Array()

	for i in range(sample_count):
		var x: float = domain_min + step * float(i)
		var y: float = _safe_evaluate(x)

		# Skip discontinuities / undefined values
		if is_nan(y) or is_inf(y):
			if current_segment.size() >= 2:
				segments.append(current_segment)
			current_segment = PackedVector2Array()
			continue

		# Vertical clamp
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
		plot_failed.emit("No valid points computed for formula \"%s\"." % formula)
		return

	# Render all connected segments
	# For a simple single-segment function, the first segment covers everything.
	# For multi-segment (e.g. rational with asymptotes), we use the first segment
	# on the main Line2D and create auxiliary Line2D nodes for extra segments.
	_render_segments(segments)

	_plot_valid = true
	plot_completed.emit(_last_points)


## Re-plots with a new formula (convenience wrapper).
func set_formula_and_plot(new_formula: String) -> void:
	formula = new_formula
	if not auto_plot:
		plot()


## Sets the domain and re-plots (convenience wrapper).
func set_domain(min_x: float, max_x: float) -> void:
	domain_min = min_x
	domain_max = max_x
	if not auto_plot:
		plot()


## Evaluates the current formula at a single x value.
## Returns NAN if evaluation fails.
func evaluate_at(x_val: float) -> float:
	return _safe_evaluate(x_val)


## Returns all computed screen-space points from the last successful plot.
func get_screen_points() -> PackedVector2Array:
	return _last_points


## Returns true if the last call to plot() produced valid output.
func is_plot_valid() -> bool:
	return _plot_valid


## Builds and returns a Path2D node whose Curve2D follows the plotted trajectory.
## Attach a PathFollow2D and a ship sprite as children of this Path2D to animate
## the ship along the function curve.
##
## Example:
##   var path := plotter.build_path2d()
##   scene.add_child(path)
##   var follower := PathFollow2D.new()
##   path.add_child(follower)
##   follower.add_child(ship_sprite)
##   # Animate progress from 0.0 → 1.0 over time
func build_path2d() -> Path2D:
	var path: Path2D = Path2D.new()
	var curve: Curve2D = Curve2D.new()
	for pt in _last_points:
		curve.add_point(pt)
	path.curve = curve
	return path


## Returns the screen-space Vector2 for a math-space (x, y) pair.
func math_to_screen(math_pos: Vector2) -> Vector2:
	return Vector2(math_pos.x * scale_factor, -math_pos.y * scale_factor)


## Returns the math-space Vector2 for a screen-space position.
func screen_to_math(screen_pos: Vector2) -> Vector2:
	return Vector2(screen_pos.x / scale_factor, -screen_pos.y / scale_factor)


## Returns the screen x-coordinate for the given math x value.
func math_x_to_screen(x_val: float) -> float:
	return x_val * scale_factor


## Returns the screen y-coordinate for the given math y value (Y-axis is flipped).
func math_y_to_screen(y_val: float) -> float:
	return -y_val * scale_factor


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _safe_evaluate(x_val: float) -> float:
	var result: Variant = _expression.execute([x_val])
	if _expression.has_execute_failed():
		return NAN
	if result == null:
		return NAN
	return float(result)


func _render_segments(segments: Array[PackedVector2Array]) -> void:
	# Remove previously created auxiliary segment lines
	for child in get_children():
		if child.name.begins_with("_SegLine"):
			child.queue_free()

	if segments.is_empty():
		return

	# First segment → main _function_line
	_function_line.clear_points()
	for pt in segments[0]:
		_function_line.add_point(pt)

	# Additional segments → auxiliary Line2D nodes (e.g., rational function branches)
	for i in range(1, segments.size()):
		var seg_line: Line2D = Line2D.new()
		seg_line.name = "_SegLine%d" % i
		seg_line.width = line_width
		seg_line.default_color = line_color
		seg_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		seg_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		seg_line.joint_mode = Line2D.LINE_JOINT_ROUND
		for pt in segments[i]:
			seg_line.add_point(pt)
		add_child(seg_line)
