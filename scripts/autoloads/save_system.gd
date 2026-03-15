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
## Archivo de guardado: user://save_data.cfg  (formato ConfigFile de Godot)
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
const SAVE_FILE: String = "user://save_data.cfg"

## Índice del primer sector (siempre desbloqueado).
const FIRST_SECTOR: int = 1

## Número total de sectores de Planet Waves. Actualizar si se agregan sectores futuros.
const TOTAL_SECTORS: int = 5

# ---------------------------------------------------------------------------
# Estado del Jugador
# ---------------------------------------------------------------------------

## Conjunto de sectores desbloqueados (accesibles desde el menú principal).
## El Sector 1 está desbloqueado por defecto.
var unlocked_sectors: Array[int] = [1]

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
	load()


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
		save()


## Devuelve true si el sector dado está desbloqueado.
func is_sector_unlocked(sector_index: int) -> bool:
	return sector_index in unlocked_sectors


## Marca un sector como completado y desbloquea el siguiente.
## Llama a save() automáticamente.
func mark_sector_complete(sector_index: int) -> void:
	if sector_index not in completed_sectors:
		completed_sectors.append(sector_index)
		completed_sectors.sort()
	# Desbloquear el sector siguiente automáticamente
	var next: int = sector_index + 1
	if next <= TOTAL_SECTORS:
		unlock_sector(next)
	save()


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
func save() -> void:
	var config: ConfigFile = ConfigFile.new()

	# ── Sección jugador ──────────────────────────────────────────────────
	config.set_value("jugador", "puntuacion_total",    total_score)
	config.set_value("jugador", "tutorial_completado", tutorial_completed)

	# ── Sectores desbloqueados y completados ─────────────────────────────
	config.set_value("sectores", "desbloqueados", unlocked_sectors)
	config.set_value("sectores", "completados",   completed_sectors)

	# ── Logros de Concepto ────────────────────────────────────────────────
	config.set_value("logros", "conceptos_dominados", mastered_concepts)

	var err: Error = config.save(SAVE_FILE)
	if err == OK:
		progress_saved.emit()
	else:
		push_warning("SaveSystem: no se pudo guardar en '%s' (error %d)" % [SAVE_FILE, err])


## Carga el progreso desde disco.
## Si el archivo no existe o está corrupto, mantiene los valores por defecto.
func load() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_FILE)
	if err != OK:
		return   # Primera sesión — no hay archivo guardado

	total_score         = config.get_value("jugador",  "puntuacion_total",    0)
	tutorial_completed  = config.get_value("jugador",  "tutorial_completado", false)

	var loaded_unlocked: Array = config.get_value("sectores", "desbloqueados", [1])
	unlocked_sectors.clear()
	for idx: int in loaded_unlocked:
		if idx not in unlocked_sectors:
			unlocked_sectors.append(idx)
	if FIRST_SECTOR not in unlocked_sectors:
		unlocked_sectors.append(FIRST_SECTOR)   # Sector 1 siempre desbloqueado
	unlocked_sectors.sort()

	var loaded_completed: Array = config.get_value("sectores", "completados", [])
	completed_sectors.clear()
	for idx: int in loaded_completed:
		if idx not in completed_sectors:
			completed_sectors.append(idx)
	completed_sectors.sort()

	var loaded_concepts: Array = config.get_value("logros", "conceptos_dominados", [])
	mastered_concepts.clear()
	for c: String in loaded_concepts:
		mastered_concepts.append(c)

	progress_loaded.emit()


## Borra todo el progreso y reinicia el archivo de guardado.
## Útil para que un nuevo estudiante empiece desde cero.
func clear_progress() -> void:
	unlocked_sectors   = [FIRST_SECTOR]
	completed_sectors  = []
	total_score        = 0
	mastered_concepts  = []
	tutorial_completed = false

	# Eliminar el archivo de guardado anterior si existe
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))

	# También limpiar el archivo legado de GameManager si existe
	var legacy_path: String = "user://planet_waves_save.cfg"
	if FileAccess.file_exists(legacy_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))

	progress_cleared.emit()
