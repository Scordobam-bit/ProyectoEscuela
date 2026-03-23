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
signal theory_requested(sector_index: int, topic_key: String)

## Emitida cuando el jugador modifica valores de inspección del HUD (p. ej. dominio).
signal inspector_values_changed(sector_index: int, domain_min: float, domain_max: float)

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
const SAVE_PATH: String = "user://save.cfg"

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_initialise_progress()
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
	current_sector = sector_index
	sector_changed.emit(sector_index)
	var scene_path: String = data["scene"]
	SceneTransition.fade_to_scene(scene_path)


func unlock_next_level() -> void:
	var next_sector: int = current_sector + 1
	if next_sector >= 0 and next_sector < SECTOR_SCENE_PATHS.size():
		current_sector = next_sector
		sector_changed.emit(current_sector)
		get_tree().change_scene_to_file(SECTOR_SCENE_PATHS[current_sector])
		return
	current_sector = 0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


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
	config.set_value("jugador", "puntuacion_total", total_score)
	config.set_value("jugador", "pistas_usadas", hints_used)
	config.set_value("jugador", "tutorial_completado", tutorial_completed)

	for sector_idx: int in completed_challenges.keys():
		config.set_value("desafios", "sector_%d" % sector_idx,
			completed_challenges[sector_idx])

	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_warning("GameManager: no se pudo guardar el progreso en '%s' (error %d)" % [SAVE_PATH, err])


## Carga el progreso guardado desde disco. Si no existe el archivo, no hace nada.
func load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err != OK:
		return   # Sin archivo de guardado previo — primera sesión

	current_sector      = config.get_value("jugador", "sector_actual",     current_sector)
	total_score         = config.get_value("jugador", "puntuacion_total",   0)
	hints_used          = config.get_value("jugador", "pistas_usadas",      0)
	tutorial_completed  = config.get_value("jugador", "tutorial_completado", false)

	for sector_data in SECTORS:
		var sid: int = sector_data["index"]
		var key: String = "sector_%d" % sid
		if config.has_section_key("desafios", key):
			completed_challenges[sid] = config.get_value("desafios", key, [])


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
