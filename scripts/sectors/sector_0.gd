class_name Sector0Academia
extends SectorBase

var _tutorial_manager: TutorialManager = null


func _setup_challenges() -> void:
	sector_index = 0
	background_color = Color(0.01, 0.03, 0.1, 1.0)
	_challenges = [
		{
			"briefing_key": "s0_tutorial",
			"instruction":
				(
					"Para avanzar, escribe una función f(x) que trace tu ruta. Usa Backspace para corregir y el botón 'Graficar' para ejecutar tu vuelo.\n"
					+ "Llega al portal verde. Si el portal está a una altura de 5, prueba escribiendo simplemente '5'."
				),
			"hint": "5",
			"expected_formula": "5",
			"feedback_correct": "¡Academia completada! Sector 1 desbloqueado.",
			"feedback_wrong": "Intenta una función constante que pase por y = 5.",
			"solution_hint": "Escribe solo: 5",
			"score": 50,
			"waypoints": [],
		},
	]


func _on_challenge_begin(_challenge_index: int) -> void:
	if _plotter:
		_plotter.domain_min = -10.0
		_plotter.domain_max = 10.0
		_plotter.scale_factor = 40.0
	if not GameManager.tutorial_completed:
		_setup_tutorial_manager()
		if _tutorial_manager:
			_tutorial_manager.start()


func _setup_obstacles_for_challenge(_challenge_index: int) -> void:
	pass


func _setup_tutorial_manager() -> void:
	if _tutorial_manager:
		return
	_tutorial_manager = TutorialManager.new()
	_tutorial_manager.name = "TutorialManager"
	add_child(_tutorial_manager)
	if hud_node:
		_tutorial_manager.setup(hud_node)
	_tutorial_manager.guide_completed.connect(_on_tutorial_guide_finished)
	_tutorial_manager.guide_skipped.connect(_on_tutorial_guide_finished)


func _on_tutorial_guide_finished() -> void:
	GameManager.tutorial_completed = true
