extends Node

const _SECTOR_HELP: Dictionary = {
	0: {
		"theory": "Una función f(x) es una relación donde a cada x le corresponde un único y.",
		"hint": "El objetivo está a altura fija. Usa f(x) = 5.",
		"domain": "Define un dominio [min, max] para ver la curva en la zona relevante.",
	},
	1: {
		"theory": "Las funciones lineales tienen la forma f(x) = mx + b.",
		"hint": "Ajusta la pendiente 'm' para inclinar la trayectoria hacia el portal.",
		"domain": "En funciones lineales puedes ampliar el dominio para inspeccionar pendiente e intersecciones.",
	},
	2: {
		"theory": "Las cuadráticas f(x)=ax²+bx+c generan parábolas con vértice y posibles raíces reales.",
		"hint": "Observa cómo cambian vértice y raíces al ajustar coeficientes.",
		"domain": "Recorta el dominio para enfocarte en el tramo útil de la parábola.",
	},
	3: {
		"theory": "Las transformaciones desplazan, escalan y reflejan funciones trigonométricas.",
		"hint": "Modifica amplitud, período y desplazamientos para sincronizar la señal.",
		"domain": "Usa varios períodos en el dominio para verificar la periodicidad.",
	},
	4: {
		"theory": "Puedes sumar, restar, multiplicar, dividir y componer funciones.",
		"hint": "Aplica la operación indicada antes de simplificar la expresión final.",
		"domain": "Evita valores que anulan denominadores en cocientes.",
	},
	5: {
		"theory": "Inversas, logaritmos y trigonometría inversa requieren respetar dominios válidos.",
		"hint": "Revisa inyectividad y restricciones antes de calcular inversas.",
		"domain": "Para asin/acos usa x∈[-1,1]. Para log(x), exige x>0.",
	},
}


func get_help_data(sector_id: int) -> Dictionary:
	return _SECTOR_HELP.get(sector_id, {})


func get_theory_text(sector_id: int) -> String:
	return String(get_help_data(sector_id).get("theory", ""))


func get_hint_text(sector_id: int) -> String:
	return String(get_help_data(sector_id).get("hint", ""))


func get_domain_text(sector_id: int) -> String:
	return String(get_help_data(sector_id).get("domain", ""))
