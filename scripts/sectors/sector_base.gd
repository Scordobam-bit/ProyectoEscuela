## SectorBase.gd
## ==============
## Clase base abstracta para todos los sectores de Planet Waves.
## El nodo raíz de cada escena de sector debe extender esta clase.
class_name SectorBase
extends Node2D

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cuando todos los desafíos de este sector se completan.
signal sector_complete(sector_index: int)

## Emitida cuando un único desafío se completa.
signal challenge_done(challenge_index: int)

## Emitida cuando comienza un nuevo desafío.
signal challenge_started(challenge_index: int)

# ---------------------------------------------------------------------------
# Propiedades Exportadas
# ---------------------------------------------------------------------------

@export var sector_index: int = 1

## Color de fondo para el entorno espacial del sector.
@export var background_color: Color = Color(0.02, 0.02, 0.1, 1.0)

# ---------------------------------------------------------------------------
# Referencias de Nodos (las subclases deben tenerlas en sus escenas)
# ---------------------------------------------------------------------------

@onready var _plotter: FunctionPlotter = $FunctionPlotter
@onready var _ship: ShipController = $Ship
@onready var _hud: HUD = $HUD
@onready var _theory_panel: TheoryPanel = $HUD/TheoryPanel

# ---------------------------------------------------------------------------
# Estado de Desafíos
# ---------------------------------------------------------------------------

var _current_challenge: int = 0
var _challenges: Array = []   # Arreglo de Diccionarios, rellenado por las subclases

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	RenderingServer.set_default_clear_color(background_color)
	_setup_challenges()
	_connect_hud()
	_connect_plotter()
	_start_challenge(0)


# ---------------------------------------------------------------------------
# Métodos Abstractos (sobrescribir en subclases)
# ---------------------------------------------------------------------------

## Rellena el arreglo _challenges con los datos de los desafíos.
func _setup_challenges() -> void:
	push_warning("SectorBase: _setup_challenges() no fue sobrescrito en %s" % name)


## Llamado cuando comienza un nuevo desafío. Sobrescribir para configurar visuales.
func _on_challenge_begin(challenge_index: int) -> void:
	pass


## Llamado cuando el jugador envía una fórmula.
## Sobrescribir para añadir lógica de validación específica del sector.
func _on_formula_submitted_sector(formula: String) -> void:
	_validate_formula_against_current(formula)


# ---------------------------------------------------------------------------
# Gestión de Desafíos
# ---------------------------------------------------------------------------

func _start_challenge(index: int) -> void:
	if index < 0 or index >= _challenges.size():
		return
	_current_challenge = index
	challenge_started.emit(index)

	if _hud:
		var ch: Dictionary = _challenges[index]
		_hud.set_formula_hint(ch.get("hint", "Ingresa la fórmula…"))
		_hud.show_feedback(ch.get("instruction", ""), "info")

	_on_challenge_begin(index)


func _advance_challenge() -> void:
	var next: int = _current_challenge + 1
	if next >= _challenges.size():
		_on_sector_complete()
	else:
		_start_challenge(next)


func _on_sector_complete() -> void:
	sector_complete.emit(sector_index)
	GameManager.complete_challenge(sector_index, _current_challenge)
	if _hud:
		_hud.show_feedback(
			"¡Sector %d Completado! Saltando al siguiente sector…" % sector_index, "success"
		)
	await get_tree().create_timer(2.0).timeout
	var next_sector: int = sector_index + 1
	if next_sector <= GameManager.SECTORS.size():
		GameManager.go_to_sector(next_sector)
	else:
		# Sector final completado → volver al menú principal
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# Conexiones HUD y Graficador
# ---------------------------------------------------------------------------

func _connect_hud() -> void:
	if not _hud:
		return
	_hud.formula_submitted.connect(_on_formula_submitted_hud)
	_hud.domain_changed.connect(_on_domain_changed)
	_hud.theory_requested.connect(_on_theory_requested)
	_hud.hint_requested.connect(_on_hint_requested)


func _connect_plotter() -> void:
	if not _plotter:
		return
	_plotter.plot_failed.connect(_on_plot_failed)
	if _ship:
		_ship.attach_to_plotter(_plotter)


func _on_formula_submitted_hud(formula: String) -> void:
	if _plotter:
		_plotter.formula = formula
	_on_formula_submitted_sector(formula)


func _on_domain_changed(min_x: float, max_x: float) -> void:
	if _plotter:
		_plotter.domain_min = min_x
		_plotter.domain_max = max_x


func _on_plot_failed(error_message: String) -> void:
	if _hud:
		_hud.show_feedback("Error al graficar: " + error_message, "error")


func _on_theory_requested() -> void:
	if _theory_panel:
		_theory_panel.show_sector_theory(sector_index)


func _on_hint_requested() -> void:
	if _current_challenge < _challenges.size():
		var hint: String = _challenges[_current_challenge].get("solution_hint", "Sin pista disponible.")
		if _hud:
			_hud.show_feedback("Pista: " + hint, "warning")
		GameManager.hints_used += 1


# ---------------------------------------------------------------------------
# Validación de Fórmulas
# ---------------------------------------------------------------------------

func _validate_formula_against_current(player_formula: String) -> void:
	if _current_challenge >= _challenges.size():
		return
	var ch: Dictionary = _challenges[_current_challenge]
	var expected: String = ch.get("expected_formula", "")
	if expected.is_empty():
		return

	var correct: bool = GameManager.submit_answer(
		player_formula, expected,
		ch.get("feedback_correct", "¡Correcto! ¡Bien hecho!"),
		ch.get("feedback_wrong", "No es correcto. Revisa tu fórmula e inténtalo de nuevo.")
	)
	if correct:
		GameManager.complete_challenge(sector_index, _current_challenge, ch.get("score", 100))
		challenge_done.emit(_current_challenge)
		await get_tree().create_timer(1.5).timeout
		_advance_challenge()
