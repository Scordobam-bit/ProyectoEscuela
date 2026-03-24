## GameManager.gd  (Autoload — accesible como GameManager desde cualquier script)
## =========================================================================
## Estado global, progresión y centro de eventos de Planet Waves.
extends Node

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando el jugador cambia a un sector diferente.
signal sector_changed(sector_index: int)

## Emitida cuando se completa un desafío en el sector actual.
signal challenge_completed(sector_index: int, challenge_index: int)

## Emitida cuando se valida la respuesta (fórmula) del jugador.
signal answer_validated(correct: bool, feedback: String)

## Emitida para solicitar la actualización del panel de teoría.
# TODO: Rehabilitar cuando exista un emisor/consumidor activo centralizado para teoría.
# signal theory_requested(sector_index: int, topic_key: String)

## Emitida cuando el jugador modifica valores de inspección del HUD (p. ej. dominio).
signal inspector_values_changed(sector_index: int, domain_min: float, domain_max: float)
signal scene_transition_failed(message: String, target_scene: String)

# ---------------------------------------------------------------------------
# Definición de Sectores
# ---------------------------------------------------------------------------

## Datos inmutables que describen cada sector del currículo.
const SECTORS: Array[Dictionary] = [
	{
		"index": 0,
		"name": "Academia de Vuelo",
		"subtitle": "Introducción y Controles",
		"scene": "res://scenes/sectors/sector_0.tscn",
		"color": Color(0.5, 0.9, 1.0),
		"topics": ["intro_functions"]
	},
	{
		"index": 1,
		"name": "Cinturón de Asteroides",
		"subtitle": "Líneas y Fundamentos",
		"scene": "res://scenes/sectors/sector_1_asteroid_belt.tscn",
		"color": Color(0.2, 0.8, 1.0),
		"topics": ["intro_functions", "linear_functions", "domain_range"]
	},
	{
		"index": 2,
		"name": "Pozos Gravitatorios",
		"subtitle": "Funciones Cuadráticas",
		"scene": "res://scenes/sectors/sector_2_gravity_wells.tscn",
		"color": Color(1.0, 0.6, 0.0),
		"topics": ["quadratics", "vertex_form", "roots_discriminant"]
	},
	{
		"index": 3,
		"name": "Sintonizador de Púlsares",
		"subtitle": "Tipos y Transformaciones",
		"scene": "res://scenes/sectors/sector_3_pulsar_tuner.tscn",
		"color": Color(0.8, 0.2, 1.0),
		"topics": ["function_types", "shifts", "scaling", "reflections"]
	},
	{
		"index": 4,
		"name": "Estación de Acoplamiento",
		"subtitle": "Operaciones y Composición",
		"scene": "res://scenes/sectors/sector_4_docking_station.tscn",
		"color": Color(0.2, 1.0, 0.4),
		"topics": ["sum_difference", "product_quotient", "composition"]
	},
	{
		"index": 5,
		"name": "Horizonte de Sucesos",
		"subtitle": "Inversas, Logs y Trigonometría",
		"scene": "res://scenes/sectors/sector_5_event_horizon.tscn",
		"color": Color(1.0, 0.2, 0.4),
		"topics": ["injectivity", "inverses", "exponentials", "logarithms", "inverse_trig"]
	},
]
const SECTOR_SCENE_PATHS: PackedStringArray = [
	"res://scenes/sectors/sector_0.tscn",
	"res://scenes/sectors/sector_1_asteroid_belt.tscn",
	"res://scenes/sectors/sector_2_gravity_wells.tscn",
	"res://scenes/sectors/sector_3_pulsar_tuner.tscn",
	"res://scenes/sectors/sector_4_docking_station.tscn",
	"res://scenes/sectors/sector_5_event_horizon.tscn",
]
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

# ---------------------------------------------------------------------------
# Estado del Jugador
# ---------------------------------------------------------------------------

var current_sector: int = 0
var completed_challenges: Dictionary = {}   # sector_index → Array[int]
var total_score: int = 0
var hints_used: int = 0
var session_start_time: float = 0.0

## True después de que el jugador completa (o salta) la guía de inicio rápido del Sector 1.
## Evita que la guía se repita en sesiones posteriores de la misma ejecución.
var tutorial_completed: bool = false

# ---------------------------------------------------------------------------
# Persistencia
# ---------------------------------------------------------------------------

## Ruta del archivo de guardado de progreso.
const SAVE_PATH: String = "user://save_game.cfg"

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_initialise_progress()
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_new_game_defaults()
		save_to_disk()
	load_progress()   # Cargar progreso guardado al iniciar

	# Sincronizar estado con SaveSystem
	_sync_from_save_system()


func _initialise_progress() -> void:
	for s in SECTORS:
		completed_challenges[s["index"]] = []


# ---------------------------------------------------------------------------
# Navegación
# ---------------------------------------------------------------------------

## Transiciona a la escena del sector especificado con fundido a negro.
func go_to_sector(sector_index: int) -> void:
	var data: Dictionary = get_sector_data(sector_index)
	if data.is_empty():
		push_warning("GameManager: índice de sector inválido %d" % sector_index)
		return
	var scene_path: String = data.get("scene", "")
	if not _is_scene_path_loadable(scene_path):
		_handle_scene_load_failure(
			"No se pudo cargar el sector solicitado. Regresando al menú principal.",
			scene_path
		)
		return
	current_sector = sector_index
	save_to_disk()
	sector_changed.emit(sector_index)
	SceneTransition.fade_to_scene(scene_path)


func unlock_next_level() -> void:
	var next_sector: int = current_sector + 1
	if next_sector >= 0 and next_sector < SECTOR_SCENE_PATHS.size():
		var next_scene_path: String = SECTOR_SCENE_PATHS[next_sector]
		if not _is_scene_path_loadable(next_scene_path):
			_handle_scene_load_failure(
				"No se pudo cargar la siguiente escena.",
				next_scene_path
			)
			return
		current_sector = next_sector
		save_to_disk()
		sector_changed.emit(current_sector)
		SceneTransition.fade_to_scene(next_scene_path)
		return
	if not _is_scene_path_loadable(MAIN_MENU_SCENE_PATH):
		_handle_scene_load_failure(
			"No se pudo volver al menú principal.",
			MAIN_MENU_SCENE_PATH
		)
		return
	save_to_disk()
	SceneTransition.fade_to_scene(MAIN_MENU_SCENE_PATH)


## Devuelve el diccionario de datos del sector actual.
func get_current_sector_data() -> Dictionary:
	return get_sector_data(current_sector)


## Devuelve el diccionario de datos del sector solicitado.
func get_sector_data(sector_index: int) -> Dictionary:
	for sector_data: Dictionary in SECTORS:
		if sector_data.get("index", -1) == sector_index:
			return sector_data
	return {}


## Devuelve el mayor índice de sector definido en SECTORS.
func get_last_sector_index() -> int:
	var last_index: int = -1
	for sector_data: Dictionary in SECTORS:
		last_index = maxi(last_index, int(sector_data.get("index", -1)))
	return last_index


## Devuelve true si todos los desafíos de un sector están completados.
func is_sector_complete(sector_index: int) -> bool:
	if not completed_challenges.has(sector_index):
		return false
	return completed_challenges[sector_index].size() >= 3  # 3 desafíos por sector


# ---------------------------------------------------------------------------
# Gestión de Desafíos
# ---------------------------------------------------------------------------

## Registra un desafío completado y emite la señal correspondiente.
func complete_challenge(sector_index: int, challenge_index: int, score: int = 100) -> void:
	if not completed_challenges.has(sector_index):
		completed_challenges[sector_index] = []
	var list: Array = completed_challenges[sector_index]
	if challenge_index not in list:
		list.append(challenge_index)
		total_score += score
	challenge_completed.emit(sector_index, challenge_index)


## Valida la fórmula del jugador contra la fórmula esperada en un rango de prueba.
## La tolerancia es la diferencia absoluta máxima permitida en cada punto de prueba.
func validate_formula(player_formula: String, expected_formula: String,
		x_min: float = -5.0, x_max: float = 5.0,
		test_points: int = 20, tolerance: float = 0.01) -> bool:
	var step: float = (x_max - x_min) / float(test_points - 1)
	for i in range(test_points):
		var x: float = x_min + step * float(i)
		var player_y: float = MathEngine.evaluate_value(player_formula, x)
		var expected_y: float = MathEngine.evaluate_value(expected_formula, x)
		if is_nan(player_y) or is_nan(expected_y):
			continue
		if absf(player_y - expected_y) > tolerance:
			return false
	return true


## Valida y emite la señal de retroalimentación.
func submit_answer(player_formula: String, expected_formula: String,
		feedback_correct: String = "¡Correcto! ¡Bien hecho!",
		feedback_wrong: String = "No es correcto. Inténtalo de nuevo.") -> bool:
	var correct: bool = validate_formula(player_formula, expected_formula)
	answer_validated.emit(correct,
		feedback_correct if correct else feedback_wrong)
	return correct


## Notifica cambios en valores de inspector del HUD para reactividad en tiempo real.
func notify_inspector_values_changed(sector_index: int, domain_min: float, domain_max: float) -> void:
	inspector_values_changed.emit(sector_index, domain_min, domain_max)


# ---------------------------------------------------------------------------
# Utilidades de Sesión
# ---------------------------------------------------------------------------

## Devuelve el tiempo transcurrido de la sesión en segundos.
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - session_start_time


## Devuelve la puntuación total del jugador.
func get_score() -> int:
	return total_score


## Reinicia todos los campos del GameManager a sus valores por defecto.
## Debe llamarse junto con SaveSystem.clear_progress() para un borrado completo.
func reset_to_defaults() -> void:
	total_score        = 0
	hints_used         = 0
	tutorial_completed = false
	current_sector     = 0
	for sid: int in completed_challenges.keys():
		completed_challenges[sid] = []


# ---------------------------------------------------------------------------
# Persistencia de Progreso
# ---------------------------------------------------------------------------

## Guarda el progreso actual del jugador en disco (GameManager + SaveSystem).
func save_progress() -> void:
	# Sincronizar puntuación con SaveSystem antes de guardar
	SaveSystem.set_total_score(total_score)
	SaveSystem.tutorial_completed = tutorial_completed
	SaveSystem.save_game_data()

	# Guardar datos complementarios de GameManager (desafíos individuales)
	var config: ConfigFile = ConfigFile.new()
	var load_err: Error = config.load(SAVE_PATH)
	if load_err != OK and load_err != ERR_FILE_NOT_FOUND:
		push_warning("GameManager: no se pudo leer '%s' antes de guardar (error %d). Se reescribirá." % [SAVE_PATH, load_err])
	config.set_value("jugador", "sector_actual", current_sector)
	config.set_value("jugador", "puntos_totales", total_score)
	config.set_value("jugador", "niveles_desbloqueados", _get_unlocked_level_names())
	config.set_value("jugador", "pistas_usadas", hints_used)
	config.set_value("jugador", "tutorial_completado", tutorial_completed)

	for sector_idx: int in completed_challenges.keys():
		config.set_value("desafios", "sector_%d" % sector_idx,
			completed_challenges[sector_idx])

	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_warning("GameManager: no se pudo guardar el progreso en '%s' (error %d)" % [SAVE_PATH, err])


## Guarda el progreso actual en disco delegando en save_progress().
## Alias semántico para persistencia previa a transiciones de escena.
## Mantiene explícita la intención de "guardar en disco antes de cambiar de sector".
func save_to_disk() -> void:
	save_progress()


## Registra una victoria de sector y persiste progreso/desbloqueo de forma centralizada.
func register_sector_victory(sector_index: int) -> void:
	SaveSystem.mark_sector_complete(sector_index)
	save_progress()


## Transacción atómica de victoria:
## 1) actualiza puntos y progreso en memoria, 2) persiste inmediatamente, 3) habilita transición segura.
func process_sector_victory_atomic(sector_index: int, challenge_index: int, score: int) -> void:
	complete_challenge(sector_index, challenge_index, score)
	SaveSystem.mark_sector_complete(sector_index)
	save_progress()


## Carga el progreso guardado desde disco. Si no existe el archivo, no hace nada.
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_new_game_defaults()
		save_progress()
		return

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err != OK:
		_apply_new_game_defaults()
		save_progress()
		return

	var save_is_corrupted: bool = false
	var loaded_current_sector: Variant = config.get_value("jugador", "sector_actual", current_sector)
	if not (loaded_current_sector is int or loaded_current_sector is float):
		save_is_corrupted = true
	var legacy_score: int = int(config.get_value("jugador", "puntuacion_total", 0))
	var loaded_total_score: Variant = config.get_value("jugador", "puntos_totales", legacy_score)
	if not (loaded_total_score is int or loaded_total_score is float):
		save_is_corrupted = true
	var unlocked_levels_data: Variant = config.get_value("jugador", "niveles_desbloqueados", ["Sector 0"])
	if not (unlocked_levels_data is Array):
		save_is_corrupted = true
	var loaded_hints_used: Variant = config.get_value("jugador", "pistas_usadas", 0)
	if not (loaded_hints_used is int or loaded_hints_used is float):
		save_is_corrupted = true
	var loaded_tutorial_completed: Variant = config.get_value("jugador", "tutorial_completado", false)
	if not (loaded_tutorial_completed is bool):
		save_is_corrupted = true

	current_sector = clampi(int(loaded_current_sector), 0, get_last_sector_index())
	total_score = maxi(int(loaded_total_score), 0)
	hints_used = maxi(int(loaded_hints_used), 0)
	tutorial_completed = bool(loaded_tutorial_completed)

	for sector_data in SECTORS:
		var sid: int = sector_data["index"]
		var key: String = "sector_%d" % sid
		if config.has_section_key("desafios", key):
			var loaded_challenges: Variant = config.get_value("desafios", key, [])
			if loaded_challenges is Array:
				completed_challenges[sid] = loaded_challenges
			else:
				save_is_corrupted = true

	var requested_unlocks: Array[int] = []
	if unlocked_levels_data is Array:
		for level_variant in unlocked_levels_data:
			var idx: int = _level_variant_to_index(level_variant)
			if idx >= 0 and idx not in requested_unlocks:
				requested_unlocks.append(idx)
			elif idx < 0:
				save_is_corrupted = true
				push_warning("GameManager: nivel desbloqueado inválido en guardado: %s" % [str(level_variant)])

	# Validar consistencia de progresión ANTES de aplicar desbloqueos al SaveSystem:
	# si Sector 0 no está completado, ningún sector mayor debe venir desbloqueado.
	if 0 not in SaveSystem.completed_sectors:
		for unlock_idx: int in requested_unlocks:
			if unlock_idx > 0:
				save_is_corrupted = true
				break

	if save_is_corrupted:
		_apply_new_game_defaults()
		save_progress()
		return

	for unlock_idx: int in requested_unlocks:
		if unlock_idx == 0 or 0 in SaveSystem.completed_sectors:
			SaveSystem.unlock_sector(unlock_idx)

	if 0 not in SaveSystem.completed_sectors:
		SaveSystem.unlocked_sectors = [0]


## Sincroniza el estado interno de GameManager con lo que SaveSystem ya cargó.
## Se llama en _ready() después de load_progress().
func _sync_from_save_system() -> void:
	# Puntuación desde SaveSystem (tiene prioridad si es mayor)
	if SaveSystem.total_score > total_score:
		total_score = SaveSystem.total_score
	tutorial_completed = tutorial_completed or SaveSystem.tutorial_completed

	# Reconstruir completed_challenges a partir de los sectores completados en SaveSystem.
	# Se usa is_sector_complete() para marcar el sector; los índices individuales de desafíos
	# no se conocen aquí, así que sólo actualizamos sectores vacíos para evitar duplicados.
	for sid: int in SaveSystem.completed_sectors:
		if completed_challenges.has(sid) and completed_challenges[sid].is_empty():
			# Buscar el número de desafíos real del sector desde SECTORS
			var sector_challenge_count: int = 5   # Valor por defecto
			for s: Dictionary in SECTORS:
				if s["index"] == sid:
					sector_challenge_count = s.get("challenge_count", 5)
					break
			completed_challenges[sid] = Array(range(sector_challenge_count))


func _is_scene_path_loadable(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	return ResourceLoader.exists(scene_path, "PackedScene")


func _handle_scene_load_failure(message: String, target_scene: String) -> void:
	push_warning("GameManager: %s Ruta: %s" % [message, target_scene])
	scene_transition_failed.emit(message, target_scene)
	if target_scene == MAIN_MENU_SCENE_PATH:
		return
	if _is_scene_path_loadable(MAIN_MENU_SCENE_PATH):
		SceneTransition.fade_to_scene(MAIN_MENU_SCENE_PATH)


func _get_unlocked_level_names() -> Array[String]:
	var level_names: Array[String] = []
	for sector_idx in SaveSystem.unlocked_sectors:
		level_names.append("Sector %d" % sector_idx)
	if level_names.is_empty():
		level_names.append("Sector 0")
	return level_names


func _level_variant_to_index(level_variant: Variant) -> int:
	if level_variant is int or level_variant is float:
		return clampi(int(level_variant), 0, get_last_sector_index())
	var level_text: String = str(level_variant).strip_edges()
	if level_text.is_empty():
		return -1
	if level_text.is_valid_int():
		return clampi(level_text.to_int(), 0, get_last_sector_index())
	if level_text.begins_with("Sector "):
		var suffix: String = level_text.substr("Sector ".length())
		if suffix.is_valid_int():
			return clampi(suffix.to_int(), 0, get_last_sector_index())
	return -1


func _apply_new_game_defaults() -> void:
	total_score = 0
	current_sector = 0
	hints_used = 0
	tutorial_completed = false
	for sector_data in SECTORS:
		var sid: int = sector_data["index"]
		completed_challenges[sid] = []
	SaveSystem.total_score = 0
	SaveSystem.unlocked_sectors = [0]
	SaveSystem.completed_sectors = []
	SaveSystem.tutorial_completed = false
