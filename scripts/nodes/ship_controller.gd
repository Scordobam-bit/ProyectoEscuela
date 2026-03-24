## ShipController.gd
## ==================
## Mueve un sprite de nave a lo largo de una trayectoria de FunctionPlotter
## mediante interpolación PathFollow2D o interpolación directa de puntos.
##
## La posición de la nave en el parámetro t ∈ [0, 1] corresponde al punto
## path_points[floor(t * (N-1))] en la curva de la función graficada.
class_name ShipController
extends Node2D

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando la nave llega al final de la trayectoria.
signal trajectory_completed
signal reached_goal

## Emitida cada fotograma con el progreso actual [0, 1].
signal progress_updated(progress: float)

# ---------------------------------------------------------------------------
# Propiedades Exportadas
# ---------------------------------------------------------------------------

## El FunctionPlotter que sigue esta nave. Asigna en el inspector o por código.
@export var plotter: FunctionPlotter = null

## Velocidad de movimiento a lo largo de la trayectoria (unidades de progreso por segundo, escala 0–1).
@export_range(0.01, 1.0, 0.01) var speed: float = 0.1
const SPEED_MULTIPLIER: float = 4.0
const PROGRESS_SPEED_FACTOR: float = 2.0

## Si es true, la nave comienza a moverse automáticamente cuando se establece la trayectoria.
@export var auto_start: bool = false

## Si es true, la nave regresa al inicio al llegar al final.
@export var loop: bool = false

## Rotar la nave para que mire hacia su dirección de movimiento.
@export var rotate_to_direction: bool = true

## Velocidad de rotación suavizada (radianes por segundo). Establecer en 0 para instantáneo.
@export var rotation_speed: float = 10.0

## El nodo sprite a mover (si es null, mueve los hijos de este nodo).
@export var ship_sprite: Node2D = null

# ---------------------------------------------------------------------------
# Estado Privado
# ---------------------------------------------------------------------------

var _progress: float = 0.0    # 0.0 → inicio, 1.0 → fin
var _moving: bool = false
var _points: PackedVector2Array = PackedVector2Array()
var _target_rotation: float = 0.0
var _last_delta: float = 0.016   # Delta en caché para uso en callbacks fuera de _process
var _path_node: Path2D = null
var _path_follow: PathFollow2D = null
var _collision_body: CharacterBody2D = null
var _owns_path_node: bool = false
var _owns_runtime_path: bool = false
var _path_connection_error_logged: bool = false
var _reached_goal_emitted: bool = false

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _enter_tree() -> void:
	_ensure_path_connection()


func _ready() -> void:
	add_to_group("player_ship")
	if not reached_goal.is_connected(_on_reached_goal):
		reached_goal.connect(_on_reached_goal)
	_ensure_path_follow_ready()
	_ensure_collision_body()
	if plotter:
		_connect_plotter(plotter)
	if auto_start and _points.size() > 1:
		start()


func _process(delta: float) -> void:
	_last_delta = delta
	if not _moving or _points.size() < 2:
		return

	_progress += speed * SPEED_MULTIPLIER * PROGRESS_SPEED_FACTOR * delta
	_progress = clampf(_progress, 0.0, 1.0)
	progress_updated.emit(_progress)

	if is_equal_approx(_progress, 1.0) or _progress >= 1.0:
		_progress = 1.0 if not loop else 0.0
		_update_ship_position()
		if not loop:
			_moving = false
			trajectory_completed.emit()
			if not _reached_goal_emitted:
				push_warning("Trayectoria Fallida")
				reset()
		return

	_update_ship_position()


# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Conecta este controlador a un FunctionPlotter y carga sus puntos.
func attach_to_plotter(new_plotter: FunctionPlotter) -> void:
	if plotter:
		_disconnect_plotter(plotter)
	plotter = new_plotter
	_connect_plotter(plotter)
	_load_points()


## Comienza a mover la nave a lo largo de la trayectoria desde el progreso actual.
func start() -> void:
	if _points.size() < 2:
		push_warning("ShipController: no hay puntos de trayectoria disponibles.")
		return
	_progress = 0.0
	_reached_goal_emitted = false
	_teleport_to_curve_start()
	_update_ship_position()
	_moving = true


## Detiene el movimiento sin reiniciar el progreso.
func stop() -> void:
	_moving = false


## Reinicia el progreso a 0 y opcionalmente vuelve a empezar.
func reset(restart: bool = false) -> void:
	_progress = 0.0
	_moving = false
	_reached_goal_emitted = false
	_update_ship_position()
	if restart:
		start()


## Devuelve el progreso actual [0, 1].
func get_progress() -> float:
	return _progress


## Devuelve la posición en el mundo para un valor de progreso dado.
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
# Auxiliares Privados
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
		_rebuild_path_from_plotter()
		_progress = 0.0
		_update_ship_position()


func _update_ship_position() -> void:
	var world_pos: Vector2 = get_position_at(_progress)
	if _can_use_path_follow():
		_path_follow.progress_ratio = _progress
		world_pos = _path_follow.global_position
	elif plotter:
		world_pos += plotter.global_position
	# Desplazar por la posición global del graficador si es un nodo hermano
	var target_node: Node2D = ship_sprite if ship_sprite else self
	target_node.global_position = world_pos
	if _collision_body and is_instance_valid(_collision_body):
		_collision_body.global_position = world_pos

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


func _is_path_ready_for_progress_ratio() -> bool:
	if not _has_parent_path_hierarchy():
		return false
	if _path_node.curve == null:
		return false
	if _path_node.curve.point_count < 2:
		return false
	return _path_node.curve.get_baked_length() > 0.0


func _on_plot_completed(points: PackedVector2Array) -> void:
	_points = points
	_rebuild_path_from_plotter()
	_progress = 0.0
	_update_ship_position()
	if auto_start:
		start()


func set_path(path: Path2D) -> void:
	if _owns_path_node and _path_node and is_instance_valid(_path_node):
		_path_node.queue_free()
		_owns_path_node = false
		_owns_runtime_path = false
		_path_node = null
		_path_follow = null
	if path == null:
		return
	if not is_inside_tree():
		_report_path_connection_issue("set_path() se llamó fuera del SceneTree; se omitió asignación de trayectoria.")
		return
	if _has_parent_path_hierarchy():
		if _path_node.curve == null:
			_path_node.curve = Curve2D.new()
		var source_curve: Curve2D = path.curve
		_path_node.curve.clear_points()
		if source_curve:
			for point_idx in range(source_curve.point_count):
				_path_node.curve.add_point(source_curve.get_point_position(point_idx))
		if _is_path_ready_for_progress_ratio():
			_path_follow.progress_ratio = _progress
		return
	if _path_node and is_instance_valid(_path_node) and _owns_runtime_path:
		_path_node.queue_free()
		_owns_runtime_path = false
	_path_node = path
	_owns_path_node = false
	_path_follow = null
	_path_node.name = "TrajectoryPath"
	var controller_owned_path: bool = _path_node.get_parent() == null
	var host: Node = plotter.get_parent() if plotter and plotter.get_parent() else get_parent()
	if host:
		host.add_child(_path_node)
	else:
		add_child(_path_node)
	_owns_path_node = controller_owned_path
	_owns_runtime_path = true
	if plotter:
		_path_node.global_position = plotter.global_position
	_path_follow = PathFollow2D.new()
	_path_follow.name = "TrajectoryFollow"
	_path_follow.rotates = false
	_path_follow.loop = false
	_path_node.add_child(_path_follow)
	if _is_path_ready_for_progress_ratio():
		_path_follow.progress_ratio = _progress


func follow_path(path: Path2D, restart: bool = true) -> void:
	set_path(path)
	if restart:
		reset(true)


func _rebuild_path_from_plotter() -> void:
	_ensure_path_connection()
	if not plotter:
		push_warning("ShipController: plotter no asignado; no se pudo reconstruir trayectoria.")
		return
	if _points.size() < 2:
		stop()
		_progress = 0.0
		if _path_node and is_instance_valid(_path_node) and _path_node.curve:
			_path_node.curve.clear_points()
		_update_ship_position()
		return
	var path: Path2D = plotter.build_path2d()
	set_path(path)


func _ensure_path_follow_ready() -> void:
	if _path_follow and is_instance_valid(_path_follow):
		return
	var parent_follow: PathFollow2D = get_parent() as PathFollow2D
	if parent_follow and parent_follow.is_inside_tree():
		_path_follow = parent_follow


func _ensure_collision_body() -> void:
	if _collision_body and is_instance_valid(_collision_body):
		return
	_collision_body = CharacterBody2D.new()
	_collision_body.name = "ShipCollisionBody"
	_collision_body.collision_layer = 1
	_collision_body.collision_mask = 1
	_collision_body.add_to_group("player_ship")
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 12.0
	shape_node.shape = circle
	_collision_body.add_child(shape_node)
	add_child(_collision_body)


func _ensure_path_connection() -> void:
	if _has_parent_path_hierarchy():
		return
	if not is_inside_tree():
		return
	var current: Node = self
	while current:
		var candidate_follow: PathFollow2D = current as PathFollow2D
		if candidate_follow:
			var candidate_path: Path2D = candidate_follow.get_parent() as Path2D
			if candidate_path:
				_path_follow = candidate_follow
				_path_node = candidate_path
				_owns_runtime_path = false
				_path_connection_error_logged = false
				return
		current = current.get_parent()
	_report_path_connection_issue("No se encontró jerarquía Path2D -> PathFollow2D para ShipController.")


func _has_parent_path_hierarchy() -> bool:
	return _path_follow != null \
		and is_instance_valid(_path_follow) \
		and _path_node != null \
		and is_instance_valid(_path_node) \
		and _path_follow.get_parent() == _path_node


func _can_use_path_follow() -> bool:
	_ensure_path_connection()
	if not _has_parent_path_hierarchy():
		return false
	if not _path_follow.is_inside_tree() or not _path_node.is_inside_tree():
		return false
	if _path_node.curve == null:
		return false
	if _path_node.curve.point_count < 2:
		return false
	return _path_node.curve.get_baked_length() > 0.0


func _report_path_connection_issue(message: String) -> void:
	if _path_connection_error_logged:
		return
	_path_connection_error_logged = true
	push_warning("ShipController: " + message)


func _teleport_to_curve_start() -> void:
	if not _path_node or not is_instance_valid(_path_node):
		return
	if _path_node.curve == null or _path_node.curve.point_count == 0:
		return
	var world_start: Vector2 = _path_node.to_global(_path_node.curve.get_point_position(0))
	if _path_follow and is_instance_valid(_path_follow):
		_path_follow.progress_ratio = 0.0
	var target_node: Node2D = ship_sprite if ship_sprite else self
	target_node.global_position = world_start
	if _collision_body and is_instance_valid(_collision_body):
		_collision_body.global_position = world_start


func _on_reached_goal() -> void:
	_reached_goal_emitted = true
