## MainMenuController.gd
## ======================
## Gestiona las interacciones de los botones del menú principal.
## Lee el SaveSystem para habilitar/deshabilitar sectores y mostrar íconos de progreso.
extends Control

# ---------------------------------------------------------------------------
# Colores de Estado
# ---------------------------------------------------------------------------

## Color del botón para sectores completados exitosamente.
const COLOR_COMPLETED: Color = Color(0.2, 0.9, 0.3)
## Color del botón para sectores desbloqueados (disponibles pero no completados).
const COLOR_UNLOCKED:  Color = Color(0.85, 0.85, 0.85)
## Color del botón para sectores bloqueados (requieren completar el anterior).
const COLOR_LOCKED:    Color = Color(0.4, 0.4, 0.4)

# ---------------------------------------------------------------------------
# Referencias de Nodos
# ---------------------------------------------------------------------------

@onready var _start_button:         Button             = $VBoxContainer/StartButton
@onready var _sector0_button:       Button             = $VBoxContainer/Sector0Button
@onready var _sector2_button:       Button             = $VBoxContainer/Sector2Button
@onready var _sector3_button:       Button             = $VBoxContainer/Sector3Button
@onready var _sector4_button:       Button             = $VBoxContainer/Sector4Button
@onready var _sector5_button:       Button             = $VBoxContainer/Sector5Button
@onready var _tutorial_button:      Button             = $VBoxContainer/TutorialButton
@onready var _lab_button:           Button             = $VBoxContainer/LabButton
@onready var _clear_button:         Button             = $VBoxContainer/ClearProgressButton
@onready var _confirm_dialog:       ConfirmationDialog = $ConfirmClearDialog
@onready var _tutorial_dialog:      AcceptDialog       = $TutorialDialog
@onready var _tutorial_scroll:      ScrollContainer    = $TutorialDialog/ScrollContainer
@onready var _score_label:          Label              = $VBoxContainer/ScoreLabel
var _notification_dialog: AcceptDialog = null
const SAVE_FILE_PATH: String = "user://save_game.cfg"

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	load_game()
	GameManager.scene_transition_failed.connect(_on_scene_transition_failed)
	_connect_buttons()
	_refresh_sector_states()

	# Actualizar el menú si el progreso cambia durante la sesión
	SaveSystem.progress_loaded.connect(_refresh_sector_states)
	SaveSystem.progress_cleared.connect(_refresh_sector_states)
	SaveSystem.sector_unlocked.connect(_on_sector_unlocked)


func load_game() -> void:
	SaveSystem.load_game_data(SAVE_FILE_PATH)
	GameManager.total_score = SaveSystem.total_score


# ---------------------------------------------------------------------------
# Conexiones de Botones
# ---------------------------------------------------------------------------

func _connect_buttons() -> void:
	_sector0_button.pressed.connect( func() -> void: _on_sector_pressed(0))
	_start_button.pressed.connect(   func() -> void: _on_sector_pressed(1))
	_sector2_button.pressed.connect( func() -> void: _on_sector_pressed(2))
	_sector3_button.pressed.connect( func() -> void: _on_sector_pressed(3))
	_sector4_button.pressed.connect( func() -> void: _on_sector_pressed(4))
	_sector5_button.pressed.connect( func() -> void: _on_sector_pressed(5))
	_tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	_lab_button.pressed.connect(_on_lab_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_confirm_dialog.confirmed.connect(_on_clear_confirmed)


func _on_sector_pressed(sector_index: int) -> void:
	if SaveSystem.is_sector_unlocked(sector_index):
		GameManager.go_to_sector(sector_index)
		return
	_show_notification("Sector bloqueado", "Debes completar el sector anterior para ver esta pista")


## Abre el Laboratorio Estelar (modo sandbox de exploración libre).
func _on_lab_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/laboratorio_estelar.tscn")


func _on_tutorial_button_pressed() -> void:
	_tutorial_dialog.popup_centered()
	# Forzar la actualización del scroll al abrir
	_tutorial_scroll.get_v_scroll_bar().value = 0


## Muestra el diálogo de confirmación para borrar el progreso.
func _on_clear_pressed() -> void:
	_confirm_dialog.popup_centered()


## Borra todo el progreso y reinicia el menú al estado inicial.
func _on_clear_confirmed() -> void:
	SaveSystem.clear_progress()
	GameManager.reset_to_defaults()
	_refresh_sector_states()


# ---------------------------------------------------------------------------
# Actualización Visual de Sectores
# ---------------------------------------------------------------------------

## Actualiza el estado visual (color, texto, habilitado/deshabilitado) de cada botón de sector.
func _refresh_sector_states() -> void:
	_apply_sector_state(_sector0_button, 0, "ACADEMIA: APRENDE A VOLAR")
	_apply_sector_state(_start_button,   1, "INICIAR MISIÓN (Sector 1)")
	_apply_sector_state(_sector2_button, 2, "Sector 2: Pozos Gravitatorios")
	_apply_sector_state(_sector3_button, 3, "Sector 3: Sintonizador de Púlsares")
	_apply_sector_state(_sector4_button, 4, "Sector 4: Estación de Acoplamiento")
	_apply_sector_state(_sector5_button, 5, "Sector 5: Horizonte de Sucesos")
	_score_label.text = "Puntuación: %d" % SaveSystem.total_score


## Aplica el estado visual correcto a un botón de sector.
## Los estados posibles son: completado, desbloqueado o bloqueado.
func _apply_sector_state(button: Button, sector_index: int, base_text: String) -> void:
	if SaveSystem.is_sector_complete(sector_index):
		# Sector completado: color verde + ícono de verificación
		button.text        = "✔  " + base_text
		button.disabled    = false
		button.add_theme_color_override("font_color",          COLOR_COMPLETED)
		button.add_theme_color_override("font_hover_color",    COLOR_COMPLETED.lightened(0.2))
		button.add_theme_color_override("font_pressed_color",  COLOR_COMPLETED.darkened(0.2))
	elif SaveSystem.is_sector_unlocked(sector_index):
		# Sector desbloqueado: color blanco normal
		button.text        = base_text
		button.disabled    = false
		button.add_theme_color_override("font_color",         COLOR_UNLOCKED)
		button.add_theme_color_override("font_hover_color",   COLOR_UNLOCKED.lightened(0.2))
		button.add_theme_color_override("font_pressed_color", COLOR_UNLOCKED.darkened(0.2))
	else:
		# Sector bloqueado: color gris + ícono de candado
		button.text        = "🔒  " + base_text
		button.disabled    = false
		button.tooltip_text = "Debes completar el sector anterior para ver esta pista"
		button.add_theme_color_override("font_color",         COLOR_LOCKED)
		button.add_theme_color_override("font_hover_color",   COLOR_LOCKED)
		button.add_theme_color_override("font_pressed_color", COLOR_LOCKED)


## Se llama cuando un sector nuevo es desbloqueado; refresca el menú.
func _on_sector_unlocked(_sector_index: int) -> void:
	_refresh_sector_states()


func _on_scene_transition_failed(message: String, _target_scene: String) -> void:
	_show_notification("Error de carga", message)


func _show_notification(title: String, message: String) -> void:
	if not is_instance_valid(_notification_dialog):
		_notification_dialog = AcceptDialog.new()
		add_child(_notification_dialog)
	_notification_dialog.title = title
	_notification_dialog.dialog_text = message
	_notification_dialog.popup_centered()
