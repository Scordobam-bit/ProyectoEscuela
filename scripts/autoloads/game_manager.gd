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

# ---------------------------------------------------------------------------
# Definición de Sectores
# ---------------------------------------------------------------------------

## Datos inmutables que describen cada sector del currículo.
const SECTORS: Array[Dictionary] = [
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

# ---------------------------------------------------------------------------
# Estado del Jugador
# ---------------------------------------------------------------------------

var current_sector: int = 1
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
const SAVE_PATH: String = "user://planet_waves_save.cfg"

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_initialise_progress()
	load_progress()   # Cargar progreso guardado al iniciar


func _initialise_progress() -> void:
	for s in SECTORS:
		completed_challenges[s["index"]] = []


# ---------------------------------------------------------------------------
# Navegación
# ---------------------------------------------------------------------------

## Transiciona a la escena del sector especificado.
func go_to_sector(sector_index: int) -> void:
	if sector_index < 1 or sector_index > SECTORS.size():
		push_warning("GameManager: índice de sector inválido %d" % sector_index)
		return
	current_sector = sector_index
	sector_changed.emit(sector_index)
	var scene_path: String = SECTORS[sector_index - 1]["scene"]
	get_tree().change_scene_to_file(scene_path)


## Devuelve el diccionario de datos del sector actual.
func get_current_sector_data() -> Dictionary:
	return SECTORS[current_sector - 1]


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
		var player_y: float = MathEngine.evaluate(player_formula, x)
		var expected_y: float = MathEngine.evaluate(expected_formula, x)
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


# ---------------------------------------------------------------------------
# Utilidades de Sesión
# ---------------------------------------------------------------------------

## Devuelve el tiempo transcurrido de la sesión en segundos.
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - session_start_time


## Devuelve la puntuación total del jugador.
func get_score() -> int:
	return total_score


# ---------------------------------------------------------------------------
# Persistencia de Progreso
# ---------------------------------------------------------------------------

## Guarda el progreso actual del jugador en disco.
func save_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("jugador", "sector_actual", current_sector)
	config.set_value("jugador", "puntuacion_total", total_score)
	config.set_value("jugador", "pistas_usadas", hints_used)
	config.set_value("jugador", "tutorial_completado", tutorial_completed)

	# Serializar desafíos completados (sector_index → arreglo de índices)
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

	# Restaurar desafíos completados
	for sector_data in SECTORS:
		var sid: int = sector_data["index"]
		var key: String = "sector_%d" % sid
		if config.has_section_key("desafios", key):
			completed_challenges[sid] = config.get_value("desafios", key, [])
