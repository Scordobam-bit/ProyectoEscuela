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
@onready var _sector2_button:       Button             = $VBoxContainer/Sector2Button
@onready var _sector3_button:       Button             = $VBoxContainer/Sector3Button
@onready var _sector4_button:       Button             = $VBoxContainer/Sector4Button
@onready var _sector5_button:       Button             = $VBoxContainer/Sector5Button
@onready var _lab_button:           Button             = $VBoxContainer/LabButton
@onready var _clear_button:         Button             = $VBoxContainer/ClearProgressButton
@onready var _confirm_dialog:       ConfirmationDialog = $ConfirmClearDialog

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_connect_buttons()
	_refresh_sector_states()

	# Actualizar el menú si el progreso cambia durante la sesión
	SaveSystem.progress_loaded.connect(_refresh_sector_states)
	SaveSystem.progress_cleared.connect(_refresh_sector_states)
	SaveSystem.sector_unlocked.connect(_on_sector_unlocked)


# ---------------------------------------------------------------------------
# Conexiones de Botones
# ---------------------------------------------------------------------------

func _connect_buttons() -> void:
	_start_button.pressed.connect(   func() -> void: GameManager.go_to_sector(1))
	_sector2_button.pressed.connect( func() -> void: GameManager.go_to_sector(2))
	_sector3_button.pressed.connect( func() -> void: GameManager.go_to_sector(3))
	_sector4_button.pressed.connect( func() -> void: GameManager.go_to_sector(4))
	_sector5_button.pressed.connect( func() -> void: GameManager.go_to_sector(5))
	_lab_button.pressed.connect(_on_lab_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_confirm_dialog.confirmed.connect(_on_clear_confirmed)


## Abre el Laboratorio Estelar (modo sandbox de exploración libre).
func _on_lab_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/laboratorio_estelar.tscn")


## Muestra el diálogo de confirmación para borrar el progreso.
func _on_clear_pressed() -> void:
	_confirm_dialog.popup_centered()


## Borra todo el progreso y reinicia el menú al estado inicial.
func _on_clear_confirmed() -> void:
	SaveSystem.clear_progress()
	# Sincronizar GameManager con el estado limpio
	GameManager.total_score       = 0
	GameManager.hints_used        = 0
	GameManager.tutorial_completed = false
	GameManager.current_sector    = 1
	for sid: int in GameManager.completed_challenges.keys():
		GameManager.completed_challenges[sid] = []
	_refresh_sector_states()


# ---------------------------------------------------------------------------
# Actualización Visual de Sectores
# ---------------------------------------------------------------------------

## Actualiza el estado visual (color, texto, habilitado/deshabilitado) de cada botón de sector.
func _refresh_sector_states() -> void:
	_apply_sector_state(_start_button,   1, "INICIAR MISIÓN (Sector 1)")
	_apply_sector_state(_sector2_button, 2, "Sector 2: Pozos Gravitatorios")
	_apply_sector_state(_sector3_button, 3, "Sector 3: Sintonizador de Púlsares")
	_apply_sector_state(_sector4_button, 4, "Sector 4: Estación de Acoplamiento")
	_apply_sector_state(_sector5_button, 5, "Sector 5: Horizonte de Sucesos")


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
		button.disabled    = true
		button.add_theme_color_override("font_color",         COLOR_LOCKED)
		button.add_theme_color_override("font_hover_color",   COLOR_LOCKED)
		button.add_theme_color_override("font_pressed_color", COLOR_LOCKED)


## Se llama cuando un sector nuevo es desbloqueado; refresca el menú.
func _on_sector_unlocked(_sector_index: int) -> void:
	_refresh_sector_states()
