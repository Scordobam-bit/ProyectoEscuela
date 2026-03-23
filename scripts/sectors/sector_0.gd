class_name Sector0Academia
extends SectorBase


func _setup_challenges() -> void:
	sector_index = 0
	background_color = Color(0.01, 0.03, 0.1, 1.0)
	_challenges = [
		{
			"briefing_key": "s0_tutorial",
			"instruction":
				(
					"Academia de Vuelo: Traza una función constante que lleve la nave al portal verde.\n"
					+ "Objetivo inicial: altura y = 5."
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


func _setup_obstacles_for_challenge(_challenge_index: int) -> void:
	pass
