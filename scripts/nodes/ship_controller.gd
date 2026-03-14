## ShipController.gd
## ==================
## Moves a ship sprite along a FunctionPlotter trajectory using PathFollow2D
## interpolation or direct point interpolation.
##
## The ship's position at parameter t ∈ [0, 1] corresponds to the point
## path_points[floor(t * (N-1))] on the plotted function curve.
class_name ShipController
extends Node2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the ship reaches the end of the trajectory.
signal trajectory_completed

## Emitted each frame with the current progress [0, 1].
signal progress_updated(progress: float)

# ---------------------------------------------------------------------------
# Exported Properties
# ---------------------------------------------------------------------------

## The FunctionPlotter this ship follows. Assign in the inspector or via code.
@export var plotter: FunctionPlotter = null

## Movement speed along the trajectory (progress units per second, 0–1 scale).
@export_range(0.01, 1.0, 0.01) var speed: float = 0.1

## If true, the ship automatically starts moving when the trajectory is set.
@export var auto_start: bool = false

## If true, the ship loops back to the start after reaching the end.
@export var loop: bool = false

## Rotate the ship to face its direction of travel.
@export var rotate_to_direction: bool = true

## Smooth rotation speed (radians per second). Set to 0 for instant.
@export var rotation_speed: float = 10.0

## The sprite node to move (if null, moves this node's children).
@export var ship_sprite: Node2D = null

# ---------------------------------------------------------------------------
# Private State
# ---------------------------------------------------------------------------

var _progress: float = 0.0    # 0.0 → start, 1.0 → end
var _moving: bool = false
var _points: PackedVector2Array = PackedVector2Array()
var _target_rotation: float = 0.0
var _last_delta: float = 0.016   # Cached delta for use in non-_process callbacks

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	if plotter:
		_connect_plotter(plotter)
	if auto_start and _points.size() > 1:
		start()


func _process(delta: float) -> void:
	_last_delta = delta
	if not _moving or _points.size() < 2:
		return

	_progress += speed * delta
	progress_updated.emit(_progress)

	if _progress >= 1.0:
		_progress = 1.0 if not loop else 0.0
		_update_ship_position()
		if not loop:
			_moving = false
			trajectory_completed.emit()
		return

	_update_ship_position()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Attaches this controller to a FunctionPlotter and loads its points.
func attach_to_plotter(new_plotter: FunctionPlotter) -> void:
	if plotter:
		_disconnect_plotter(plotter)
	plotter = new_plotter
	_connect_plotter(plotter)
	_load_points()


## Begins moving the ship along the trajectory from the current progress.
func start() -> void:
	if _points.size() < 2:
		push_warning("ShipController: no trajectory points available.")
		return
	_moving = true


## Stops movement without resetting progress.
func stop() -> void:
	_moving = false


## Resets progress to 0 and optionally starts again.
func reset(restart: bool = false) -> void:
	_progress = 0.0
	_moving = false
	_update_ship_position()
	if restart:
		start()


## Returns current progress [0, 1].
func get_progress() -> float:
	return _progress


## Returns the world position at a given progress value.
func get_position_at(t: float) -> Vector2:
	if _points.is_empty():
		return Vector2.ZERO
	var clamped_t: float = clampf(t, 0.0, 1.0)
	var float_index: float = clamped_t * float(_points.size() - 1)
	var index_a: int = floori(float_index)
	var index_b: int = mini(index_a + 1, _points.size() - 1)
	var frac: float = float_index - float(index_a)
	return _points[index_a].lerp(_points[index_b], frac)


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

func _connect_plotter(p: FunctionPlotter) -> void:
	if not p.plot_completed.is_connected(_on_plot_completed):
		p.plot_completed.connect(_on_plot_completed)


func _disconnect_plotter(p: FunctionPlotter) -> void:
	if p.plot_completed.is_connected(_on_plot_completed):
		p.plot_completed.disconnect(_on_plot_completed)


func _load_points() -> void:
	if plotter and plotter.is_plot_valid():
		_points = plotter.get_screen_points()
		_progress = 0.0
		_update_ship_position()


func _update_ship_position() -> void:
	var world_pos: Vector2 = get_position_at(_progress)
	# Offset by plotter's global position if plotter is a sibling
	var target_node: Node2D = ship_sprite if ship_sprite else self
	target_node.position = world_pos

	if rotate_to_direction and _points.size() >= 2:
		var ahead_t: float = clampf(_progress + 0.01, 0.0, 1.0)
		var ahead_pos: Vector2 = get_position_at(ahead_t)
		var dir: Vector2 = (ahead_pos - world_pos)
		if dir.length_squared() > 0.001:
			_target_rotation = dir.angle()

	if rotation_speed > 0.0:
		target_node.rotation = lerp_angle(
			target_node.rotation, _target_rotation,
			rotation_speed * _last_delta
		)
	else:
		target_node.rotation = _target_rotation


func _on_plot_completed(points: PackedVector2Array) -> void:
	_points = points
	_progress = 0.0
	_update_ship_position()
	if auto_start:
		start()
