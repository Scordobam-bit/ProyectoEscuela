## GestorObstaculos.gd
## ====================
## Nodo que genera y gestiona los obstáculos espaciales de Planet Waves.
## Genera representaciones visuales (Line2D) y detecta colisiones contra la
## trayectoria del jugador (puntos en espacio local del FunctionPlotter).
##
## Tipos de obstáculo por sector:
##   • TipoObstaculo.ASTEROIDE        — Sector 1: polígonos irregulares
##   • TipoObstaculo.POZO_GRAVITATORIO — Sector 2: anillos concéntricos
##   • TipoObstaculo.PULSAR           — Sector 3: figuras de estrella
class_name GestorObstaculos
extends Node2D

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando la trayectoria impacta un obstáculo.
signal obstacle_hit(obstacle_name: String, hit_position: Vector2)

# ---------------------------------------------------------------------------
# Tipos de Obstáculo
# ---------------------------------------------------------------------------

enum TipoObstaculo {
	ASTEROIDE,
	POZO_GRAVITATORIO,
	PULSAR,
}

# ---------------------------------------------------------------------------
# Estado Privado
# ---------------------------------------------------------------------------

## Lista de obstáculos registrados: {local_pos, radius, name, tipo}
var _obstacles: Array[Dictionary] = []

## Nombre del último obstáculo golpeado.
var _last_hit_name: String = ""

## Referencia al FunctionPlotter para conversión de coordenadas.
var _plotter: FunctionPlotter = null

# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Vincula este gestor al FunctionPlotter del sector (necesario antes de add_obstacle).
func setup(plotter: FunctionPlotter) -> void:
	_plotter = plotter


## Registra un obstáculo en coordenadas matemáticas y genera su representación visual.
##
## math_pos    : posición en espacio matemático cartesiano (unidades).
## radius_math : radio del obstáculo en unidades matemáticas.
## obstacle_name : etiqueta mostrada al jugador en caso de impacto.
## tipo        : valor de TipoObstaculo (determina el dibujo visual).
func add_obstacle(
		math_pos: Vector2,
		radius_math: float,
		obstacle_name: String,
		tipo: TipoObstaculo = TipoObstaculo.ASTEROIDE) -> void:
	if not _plotter:
		push_warning("GestorObstaculos: llama a setup(plotter) antes de add_obstacle().")
		return

	var local_pos: Vector2 = _plotter.math_to_screen(math_pos)
	var radius_px: float = radius_math * _plotter.scale_factor

	_obstacles.append({
		"local_pos": local_pos,
		"radius": radius_px,
		"name": obstacle_name,
		"tipo": tipo,
	})

	# Los visuales se posicionan en coordenadas globales de la escena.
	var global_vis_pos: Vector2 = local_pos + _plotter.position
	_spawn_visual(global_vis_pos, radius_px, tipo)


## Elimina todos los obstáculos registrados y sus representaciones visuales.
func clear_obstacles() -> void:
	for child in get_children():
		child.queue_free()
	_obstacles.clear()
	_last_hit_name = ""


## Comprueba si algún punto de la trayectoria colisiona con un obstáculo registrado.
##
## trajectory_points deben estar en el espacio local del FunctionPlotter
## (tal como los devuelve FunctionPlotter.get_screen_points()).
##
## Devuelve true si hay al menos una colisión; emite la señal obstacle_hit.
func check_trajectory_collision(trajectory_points: PackedVector2Array) -> bool:
	for obs in _obstacles:
		var obs_pos: Vector2 = obs["local_pos"]
		var obs_radius: float = obs["radius"]
		for pt in trajectory_points:
			if pt.distance_to(obs_pos) < obs_radius:
				_last_hit_name = obs["name"]
				var global_hit: Vector2 = obs_pos
				if _plotter:
					global_hit += _plotter.position
				obstacle_hit.emit(_last_hit_name, global_hit)
				return true
	return false


## Devuelve el nombre del último obstáculo golpeado (vacío si no ha habido colisión).
func get_last_hit_name() -> String:
	return _last_hit_name


# ---------------------------------------------------------------------------
# Auxiliares de Dibujo
# ---------------------------------------------------------------------------

func _spawn_visual(global_pos: Vector2, radius_px: float, tipo: TipoObstaculo) -> void:
	var container: Node2D = Node2D.new()
	container.position = global_pos
	add_child(container)

	match tipo:
		TipoObstaculo.ASTEROIDE:
			_draw_asteroid(container, radius_px)
		TipoObstaculo.POZO_GRAVITATORIO:
			_draw_gravity_well(container, radius_px)
		TipoObstaculo.PULSAR:
			_draw_pulsar(container, radius_px)


func _draw_asteroid(parent: Node2D, radius: float) -> void:
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.8, 0.6, 0.3, 0.85)
	var pts: PackedVector2Array = PackedVector2Array()

	# Polígono irregular determinista basado en la posición global del contenedor.
	var seed_val: int = int(abs(parent.position.x * 17.0 + parent.position.y * 31.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	const SIDES: int = 8
	for i in range(SIDES):
		var angle: float = TAU * float(i) / float(SIDES)
		var r: float = radius * rng.randf_range(0.7, 1.3)
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	pts.append(pts[0])  # cerrar el polígono
	line.points = pts
	parent.add_child(line)

	# Brillo interior tenue
	var glow: Line2D = Line2D.new()
	glow.width = 1.0
	glow.default_color = Color(1.0, 0.8, 0.4, 0.3)
	var glow_pts: PackedVector2Array = PackedVector2Array()
	for i in range(SIDES):
		var angle: float = TAU * float(i) / float(SIDES)
		glow_pts.append(Vector2(cos(angle) * radius * 0.5, sin(angle) * radius * 0.5))
	glow_pts.append(glow_pts[0])
	glow.points = glow_pts
	parent.add_child(glow)


func _draw_gravity_well(parent: Node2D, radius: float) -> void:
	for i in range(3):
		var ring_scale: float = 1.0 - float(i) * 0.3
		var ring: Line2D = Line2D.new()
		ring.width = 1.5
		ring.default_color = Color(0.5, 0.2, 1.0, 0.35 + float(i) * 0.1)
		var pts: PackedVector2Array = PackedVector2Array()
		for j in range(33):
			var angle: float = TAU * float(j) / 32.0
			pts.append(Vector2(cos(angle) * radius * ring_scale,
					sin(angle) * radius * ring_scale))
		ring.points = pts
		parent.add_child(ring)


func _draw_pulsar(parent: Node2D, radius: float) -> void:
	var star: Line2D = Line2D.new()
	star.width = 2.0
	star.default_color = Color(1.0, 0.4, 0.8, 0.85)
	var pts: PackedVector2Array = PackedVector2Array()
	const POINTS: int = 12
	for i in range(POINTS + 1):
		var angle: float = TAU * float(i) / float(POINTS)
		var r: float = radius if i % 2 == 0 else radius * 0.4
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	star.points = pts
	parent.add_child(star)

	# Halo parpadeante (implementado como anillo exterior tenue)
	var halo: Line2D = Line2D.new()
	halo.width = 1.0
	halo.default_color = Color(1.0, 0.2, 0.8, 0.2)
	var halo_pts: PackedVector2Array = PackedVector2Array()
	for i in range(33):
		var angle: float = TAU * float(i) / 32.0
		halo_pts.append(Vector2(cos(angle) * radius * 1.5, sin(angle) * radius * 1.5))
	halo.points = halo_pts
	parent.add_child(halo)
