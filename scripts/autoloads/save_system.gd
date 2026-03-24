## SaveSystem.gd  (Autoload — accesible como SaveSystem desde cualquier script)
## =========================================================================
## Sistema de persistencia dedicado para Planet Waves.
##
## Responsabilidades
## -----------------
##   • Guardar y cargar el progreso del jugador desde disco.
##   • Rastrear qué sectores están desbloqueados y cuáles están completados.
##   • Mantener el listado de conceptos matemáticos dominados (Logros).
##   • Proporcionar una función de "Borrar Progreso" para reiniciar desde cero.
##
## Archivo de guardado: user://save_game.cfg  (formato ConfigFile de Godot)
extends Node

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando se guarda el progreso con éxito.
signal progress_saved

## Emitida cuando se carga el progreso con éxito.
signal progress_loaded

## Emitida cuando el progreso es borrado (reinicio completo).
signal progress_cleared

## Emitida cuando se desbloquea un sector nuevo.
signal sector_unlocked(sector_index: int)

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

## Ruta del archivo de guardado en la carpeta de datos del usuario.
const SAVE_FILE: String = "user://save_game.cfg"

## Índice del primer sector (siempre desbloqueado).
const FIRST_SECTOR: int = 0

## Índice máximo válido de sector (inclusive): Sector 0..5.
const MAX_SECTOR_INDEX: int = 5

# ---------------------------------------------------------------------------
# Estado del Jugador
# ---------------------------------------------------------------------------

## Conjunto de sectores desbloqueados (accesibles desde el menú principal).
## El Sector 0 está desbloqueado por defecto.
var unlocked_sectors: Array[int] = [FIRST_SECTOR]

## Conjunto de sectores completados exitosamente.
var completed_sectors: Array[int] = []

## Puntuación total acumulada a través de todos los sectores.
var total_score: int = 0

## Lista de conceptos matemáticos dominados (logros de concepto).
var mastered_concepts: Array[String] = []

## True si el jugador completó la guía de inicio rápido del Sector 1.
var tutorial_completed: bool = false

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	load_game_data()


# ---------------------------------------------------------------------------
# API Pública — Sectores
# ---------------------------------------------------------------------------

## Desbloquea un sector para que sea accesible desde el menú principal.
## Si el sector ya está desbloqueado, no hace nada.
func unlock_sector(sector_index: int) -> void:
	if sector_index not in unlocked_sectors:
		unlocked_sectors.append(sector_index)
		unlocked_sectors.sort()
		sector_unlocked.emit(sector_index)
		save_game_data()


## Devuelve true si el sector dado está desbloqueado.
func is_sector_unlocked(sector_index: int) -> bool:
	return sector_index in unlocked_sectors


## Marca un sector como completado y desbloquea el siguiente.
## Llama a save_game_data() directamente al final, y también de forma
## indirecta a través de unlock_sector() cuando hay un sector siguiente.
func mark_sector_complete(sector_index: int, persist_to_disk: bool = true) -> void:
	if sector_index not in completed_sectors:
		completed_sectors.append(sector_index)
		completed_sectors.sort()
	# Desbloquear el sector siguiente automáticamente
	var next: int = sector_index + 1
	if next <= MAX_SECTOR_INDEX:
		if next not in unlocked_sectors:
			unlocked_sectors.append(next)
			unlocked_sectors.sort()
			sector_unlocked.emit(next)
			if persist_to_disk:
				save_game_data()
	if persist_to_disk:
		save_game_data()


## Devuelve true si el sector dado ha sido completado.
func is_sector_complete(sector_index: int) -> bool:
	return sector_index in completed_sectors


# ---------------------------------------------------------------------------
# API Pública — Conceptos Dominados (Logros)
# ---------------------------------------------------------------------------

## Agrega un concepto al listado de logros si no existe ya.
func add_mastered_concept(concept: String) -> void:
	if concept not in mastered_concepts:
		mastered_concepts.append(concept)


## Agrega una lista de conceptos al listado de logros.
func add_mastered_concepts(concepts: Array) -> void:
	for c: String in concepts:
		add_mastered_concept(c)


## Devuelve todos los conceptos dominados.
func get_mastered_concepts() -> Array[String]:
	return mastered_concepts


## Devuelve cuántos conceptos únicos ha dominado el jugador.
func get_mastered_count() -> int:
	return mastered_concepts.size()


# ---------------------------------------------------------------------------
# API Pública — Puntuación
# ---------------------------------------------------------------------------

## Actualiza la puntuación total (normalmente sincronizada desde GameManager).
func set_total_score(score: int) -> void:
	total_score = score


# ---------------------------------------------------------------------------
# API Pública — Persistencia
# ---------------------------------------------------------------------------

## Guarda todo el progreso en disco.
## path: ruta destino del archivo de guardado (por defecto: SAVE_FILE).
func save_game_data(path: String = SAVE_FILE) -> void:
	var config: ConfigFile = ConfigFile.new()

	# ── Sección jugador ──────────────────────────────────────────────────
	config.set_value("jugador", "puntuacion_total",    total_score)
	config.set_value("jugador", "tutorial_completado", tutorial_completed)

	# ── Sectores desbloqueados y completados ─────────────────────────────
	config.set_value("sectores", "desbloqueados", unlocked_sectors)
	config.set_value("sectores", "completados",   completed_sectors)

	# ── Logros de Concepto ────────────────────────────────────────────────
	config.set_value("logros", "conceptos_dominados", mastered_concepts)

	var err: Error = config.save(path)
	if err == OK:
		progress_saved.emit()
	else:
		push_warning("SaveSystem: no se pudo guardar en '%s' (error %d)" % [path, err])


## Carga el progreso desde disco.
## path: ruta fuente del archivo de guardado (por defecto: SAVE_FILE).
## Si el archivo no existe o está corrupto, inicializa el estado por defecto
## para evitar que el resto del juego reciba valores nulos.
func load_game_data(path: String = SAVE_FILE) -> void:
	# Validación preventiva: no intentar leer si el archivo no existe
	if not FileAccess.file_exists(path):
		_apply_default_state()
		return

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(path)
	if err != OK:
		push_warning("SaveSystem: no se pudo cargar '%s' (error %d). Se usarán valores por defecto." % [path, err])
		_apply_default_state()
		return

	var loaded_score: Variant = config.get_value("jugador", "puntuacion_total", 0)
	var loaded_tutorial: Variant = config.get_value("jugador", "tutorial_completado", false)
	# El puntaje del juego es entero; si un guardado legado trae float, se normaliza a int.
	total_score = int(loaded_score) if loaded_score is int or loaded_score is float else 0
	tutorial_completed = bool(loaded_tutorial) if loaded_tutorial is bool else false

	var loaded_unlocked_variant: Variant = config.get_value("sectores", "desbloqueados", [FIRST_SECTOR])
	var loaded_unlocked: Array = loaded_unlocked_variant if loaded_unlocked_variant is Array else [FIRST_SECTOR]
	unlocked_sectors.clear()
	for idx_variant in loaded_unlocked:
		if not (idx_variant is int or idx_variant is float):
			continue
		var idx: int = int(idx_variant)
		if idx >= FIRST_SECTOR and idx <= MAX_SECTOR_INDEX and idx not in unlocked_sectors:
			unlocked_sectors.append(idx)
	if FIRST_SECTOR not in unlocked_sectors:
		unlocked_sectors.append(FIRST_SECTOR)   # Sector 0 siempre desbloqueado
	unlocked_sectors.sort()

	var loaded_completed_variant: Variant = config.get_value("sectores", "completados", [])
	var loaded_completed: Array = loaded_completed_variant if loaded_completed_variant is Array else []
	completed_sectors.clear()
	for idx_variant in loaded_completed:
		if not (idx_variant is int or idx_variant is float):
			continue
		var idx: int = int(idx_variant)
		if idx >= FIRST_SECTOR and idx <= MAX_SECTOR_INDEX and idx not in completed_sectors:
			completed_sectors.append(idx)
	completed_sectors.sort()

	# Regla de bloqueo estricta: Sector 1 solo se habilita si Sector 0 está completado.
	# Si el guardado llega inconsistente (sectores abiertos sin completar Academia),
	# se fuerza estado inicial para evitar acceso prematuro.
	if FIRST_SECTOR not in completed_sectors:
		unlocked_sectors = [FIRST_SECTOR]
	elif 1 not in unlocked_sectors:
		unlocked_sectors.append(1)
		unlocked_sectors.sort()

	var loaded_concepts_variant: Variant = config.get_value("logros", "conceptos_dominados", [])
	var loaded_concepts: Array = loaded_concepts_variant if loaded_concepts_variant is Array else []
	mastered_concepts.clear()
	for c_variant in loaded_concepts:
		var c: String = str(c_variant).strip_edges()
		if not c.is_empty():
			mastered_concepts.append(c)

	progress_loaded.emit()


## Inicializa el estado del jugador a los valores por defecto.
## Se llama cuando no existe archivo de guardado o la lectura falla.
## Refleja intencionalmente los valores iniciales declarados en los campos
## de la clase, para poder restablecer el estado en tiempo de ejecución.
func _apply_default_state() -> void:
	total_score        = 0
	tutorial_completed = false
	unlocked_sectors   = [FIRST_SECTOR]
	completed_sectors  = []
	mastered_concepts  = []


## Borra todo el progreso y reinicia el archivo de guardado.
## Útil para que un nuevo estudiante empiece desde cero.
func clear_progress() -> void:
	unlocked_sectors   = [FIRST_SECTOR]
	completed_sectors  = []
	total_score        = 0
	mastered_concepts  = []
	tutorial_completed = false

	# Eliminar el archivo de guardado principal si existe
	if FileAccess.file_exists(SAVE_FILE):
		var err: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
		if err != OK:
			push_warning("SaveSystem: no se pudo eliminar '%s' (error %d)." % [SAVE_FILE, err])

	# También limpiar archivos legados si existen
	for legacy_path in ["user://save.cfg", "user://planet_waves_save.cfg"]:
		if FileAccess.file_exists(legacy_path):
			var err2: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
			if err2 != OK:
				push_warning("SaveSystem: no se pudo eliminar legado '%s' (error %d)." % [legacy_path, err2])

	progress_cleared.emit()
