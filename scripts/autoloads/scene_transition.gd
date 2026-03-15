## SceneTransition.gd  (Autoload — accesible como SceneTransition desde cualquier script)
## ========================================================================================
## Proporciona transiciones cinemáticas de "Fundido a Negro" entre escenas.
## Al cambiar de sector o abrir el Laboratorio, la pantalla se oscurece suavemente
## (0.5 s), se carga la nueva escena y luego se aclara (0.5 s).
##
## Uso típico (en lugar de change_scene_to_file):
##     SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
extends CanvasLayer

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

## Duración del fundido de entrada/salida en segundos.
const FADE_DURATION: float = 0.5

## Capa de renderizado — encima de todo el resto del juego.
const TRANSITION_LAYER: int = 100

# ---------------------------------------------------------------------------
# Nodos Internos
# ---------------------------------------------------------------------------

var _overlay: ColorRect = null
var _busy: bool = false

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	layer = TRANSITION_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS   # Funciona incluso si el árbol está pausado

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.anchor_right  = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)   # Completamente transparente al inicio
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Cambia a la escena indicada con un fundido a negro de entrada y salida.
## Si ya hay una transición en curso, ignora la llamada.
func fade_to_scene(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP   # Bloquear input durante la transición

	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await _fade_in()

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Realiza solo el fundido de salida (oscurecer) sin cambiar de escena.
## Útil si la escena se cambia manualmente después.
func fade_out_only() -> void:
	if _busy:
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_out()


## Realiza solo el fundido de entrada (aclarar).
## Debe llamarse después de un fade_out_only() y un cambio de escena.
func fade_in_only() -> void:
	await _fade_in()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


# ---------------------------------------------------------------------------
# Auxiliares Privados
# ---------------------------------------------------------------------------

## Oscurece la pantalla de transparente a negro opaco en FADE_DURATION segundos.
func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_DURATION)
	await tween.finished


## Aclara la pantalla de negro opaco a transparente en FADE_DURATION segundos.
func _fade_in() -> void:
	# Asegurar que el overlay esté opaco antes de aclarar
	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), FADE_DURATION)
	await tween.finished
