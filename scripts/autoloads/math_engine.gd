## MathEngine.gd  (Autoload — accesible como MathEngine desde cualquier script)
## ==========================================================================
## Utilidades matemáticas centralizadas para Planet Waves.
##
## Resumen a Nivel Universitario
## ------------------------------
## Este singleton envuelve la clase Expression de Godot y añade rutinas de
## apoyo para los cinco sectores del currículo:
##
##   Sector 1 – Líneas          : pendiente, ordenada al origen, análisis de dominio/rango
##   Sector 2 – Cuadráticas     : discriminante, forma vértice, raíces (fórmula cuadrática)
##   Sector 3 – Transformaciones: operaciones de desplazamiento, escala y reflexión sobre f(x)
##   Sector 4 – Composición     : (f∘g)(x) = f(g(x)), evaluado simbólicamente
##   Sector 5 – Inversas/Logs   : aproximación numérica de inversa, ln, exp, arcsin/arccos
extends Node

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

## Emitida cada vez que se evalúa una fórmula (para analítica / retroalimentación tutorial).
signal formula_evaluated(formula: String, x: float, result: float)

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

const EULER_E: float = 2.718281828459045
const GOLDEN_RATIO: float = 1.6180339887498948

# ---------------------------------------------------------------------------
# Estado privado
# ---------------------------------------------------------------------------

var _expr: Expression = Expression.new()

# ---------------------------------------------------------------------------
# Evaluación Principal
# ---------------------------------------------------------------------------

## Evalúa una cadena de fórmula en un valor x dado.
## Devuelve NAN si el análisis o la ejecución fallan.
func evaluate(formula: String, x_val: float) -> float:
	var normalized: String = _normalize_formula(formula)
	var err: Error = _expr.parse(normalized, ["x"])
	if err != OK:
		return NAN
	var result: Variant = _expr.execute([x_val])
	if _expr.has_execute_failed():
		return NAN
	var y: float = float(result)
	formula_evaluated.emit(normalized, x_val, y)
	return y


## Devuelve true si la fórmula se analiza sin errores.
func is_valid_formula(formula: String) -> bool:
	return _expr.parse(_normalize_formula(formula), ["x"]) == OK


## Evalúa una fórmula sobre un arreglo de valores x.
## Omite resultados NAN / Inf.
func evaluate_range(formula: String, x_values: PackedFloat64Array) -> PackedFloat64Array:
	var results: PackedFloat64Array = PackedFloat64Array()
	var normalized: String = _normalize_formula(formula)
	var err: Error = _expr.parse(normalized, ["x"])
	if err != OK:
		return results
	for x in x_values:
		var res: Variant = _expr.execute([x])
		if _expr.has_execute_failed():
			results.append(NAN)
		else:
			results.append(float(res))
	return results


## Normaliza entradas de usuario para reducir errores comunes de precedencia y cociente.
## Ejemplo educativo: "x/x+3" -> "(x)/(x+3)" para representar función racional esperada.
func _normalize_formula(formula: String) -> String:
	var f: String = formula.strip_edges()
	var simple_rational: RegEx = RegEx.new()
	simple_rational.compile("^([\\w\\)\\(\\^\\*\\+\\-]+)\\/([\\w\\)\\(\\^\\*\\+\\-]+)\\+([\\w\\)\\(\\^\\*\\+\\-]+)$")
	var match: RegExMatch = simple_rational.search(f)
	if match != null:
		var numerator: String = match.get_string(1).strip_edges()
		var denominator_base: String = match.get_string(2).strip_edges()
		var denominator_tail: String = match.get_string(3).strip_edges()
		if not numerator.is_empty() and not denominator_base.is_empty() and not denominator_tail.is_empty():
			return "(%s)/(%s+%s)" % [numerator, denominator_base, denominator_tail]
	return f


## Genera N valores x uniformemente espaciados en [x_min, x_max].
func linspace(x_min: float, x_max: float, n: int) -> PackedFloat64Array:
	var result: PackedFloat64Array = PackedFloat64Array()
	if n < 2:
		result.append(x_min)
		return result
	var step: float = (x_max - x_min) / float(n - 1)
	for i in range(n):
		result.append(x_min + step * float(i))
	return result


# ---------------------------------------------------------------------------
# Sector 1 – Funciones Lineales
# ---------------------------------------------------------------------------

## Extrae la pendiente m y la ordenada al origen b de una fórmula lineal "m*x + b".
## Usa diferenciación numérica de dos puntos — funciona para cualquier f diferenciable.
func get_slope_and_intercept(formula: String) -> Dictionary:
	var m: float = numerical_derivative(formula, 0.0)
	var b: float = evaluate(formula, 0.0)
	return {"slope": m, "intercept": b}


## Devuelve true si f es lineal en [x_min, x_max] (segunda derivada ≈ 0).
func is_linear(formula: String, x_min: float = -5.0, x_max: float = 5.0) -> bool:
	var d2: float = numerical_second_derivative(formula, (x_min + x_max) / 2.0)
	return absf(d2) < 1e-4


# ---------------------------------------------------------------------------
# Sector 2 – Funciones Cuadráticas
# ---------------------------------------------------------------------------

## Para f(x) = ax²+bx+c, devuelve el vértice (h, k) donde h = -b/(2a).
## Usa métodos numéricos: h es donde f'(x) = 0.
func find_vertex(formula: String, search_min: float = -50.0,
		search_max: float = 50.0, tolerance: float = 1e-6) -> Vector2:
	# Bisección sobre f'(x) = 0 en el rango dado
	var root_x: float = find_root_bisect(
		func(x: float) -> float: return numerical_derivative(formula, x),
		search_min, search_max, tolerance
	)
	var vertex_y: float = evaluate(formula, root_x)
	return Vector2(root_x, vertex_y)


## Devuelve las raíces reales de f(x) = 0 en [x_min, x_max] usando bisección.
## Se encuentran múltiples raíces buscando cambios de signo.
func find_roots(formula: String, x_min: float = -10.0, x_max: float = 10.0,
		steps: int = 1000, tolerance: float = 1e-6) -> PackedFloat64Array:
	var roots: PackedFloat64Array = PackedFloat64Array()
	var step: float = (x_max - x_min) / float(steps)
	var prev_x: float = x_min
	var prev_y: float = evaluate(formula, x_min)

	for i in range(1, steps + 1):
		var curr_x: float = x_min + step * float(i)
		var curr_y: float = evaluate(formula, curr_x)

		if is_nan(prev_y) or is_nan(curr_y):
			prev_x = curr_x
			prev_y = curr_y
			continue

		# Se detectó un cambio de signo → existe una raíz en este intervalo
		if prev_y * curr_y < 0.0:
			var root: float = find_root_bisect(
				func(x: float) -> float: return evaluate(formula, x),
				prev_x, curr_x, tolerance
			)
			if not is_nan(root):
				# Evitar raíces duplicadas
				var is_duplicate: bool = false
				for existing_root in roots:
					if absf(existing_root - root) < tolerance * 10.0:
						is_duplicate = true
						break
				if not is_duplicate:
					roots.append(root)

		prev_x = curr_x
		prev_y = curr_y

	return roots


## Fórmula cuadrática clásica para ax²+bx+c = 0.
## Devuelve un Diccionario: {"discriminant": Δ, "roots": [x1, x2] o [x1] o []}
func quadratic_formula(a: float, b: float, c: float) -> Dictionary:
	var delta: float = b * b - 4.0 * a * c
	if delta < 0.0:
		return {"discriminant": delta, "roots": []}
	elif is_zero_approx(delta):
		return {"discriminant": 0.0, "roots": [-b / (2.0 * a)]}
	else:
		var sqrt_delta: float = sqrt(delta)
		return {
			"discriminant": delta,
			"roots": [(-b - sqrt_delta) / (2.0 * a), (-b + sqrt_delta) / (2.0 * a)]
		}


# ---------------------------------------------------------------------------
# Sector 3 – Transformaciones de Funciones
# ---------------------------------------------------------------------------

## Helper: reemplaza solo el token de variable como palabra independiente.
## Usa RegEx con límites de palabra (`\b`) para evitar reemplazar substrings de
## identificadores (p. ej. "x" en "exp" o "max" permanecen intactos).
func _replace_token_variable(formula: String, var_name: String, replacement: String) -> String:
	var re := RegEx.new()
	re.compile("\\b" + var_name + "\\b")
	return re.sub(formula, replacement, true)


## Devuelve la cadena de fórmula para un desplazamiento vertical: f(x) + k
func transform_shift_vertical(base_formula: String, k: float) -> String:
	if k >= 0.0:
		return "(%s) + %s" % [base_formula, k]
	return "(%s) - %s" % [base_formula, absf(k)]


## Devuelve la cadena de fórmula para un desplazamiento horizontal: f(x - h)
func transform_shift_horizontal(base_formula: String, h: float) -> String:
	if h >= 0.0:
		return _replace_token_variable(base_formula, "x", "(x - %s)" % h)
	return _replace_token_variable(base_formula, "x", "(x + %s)" % absf(h))


## Devuelve la cadena de fórmula para escala vertical: a·f(x)
func transform_scale_vertical(base_formula: String, a: float) -> String:
	return "%s * (%s)" % [a, base_formula]


## Devuelve la cadena de fórmula para escala horizontal: f(b·x)
func transform_scale_horizontal(base_formula: String, b: float) -> String:
	return _replace_token_variable(base_formula, "x", "(%s * x)" % b)


## Devuelve la cadena de fórmula para reflexión sobre el eje X: -f(x)
func transform_reflect_x(base_formula: String) -> String:
	return "-(%s)" % base_formula


## Devuelve la cadena de fórmula para reflexión sobre el eje Y: f(-x)
func transform_reflect_y(base_formula: String) -> String:
	return _replace_token_variable(base_formula, "x", "(-x)")


# ---------------------------------------------------------------------------
# Sector 4 – Operaciones y Composición de Funciones
# ---------------------------------------------------------------------------

## Devuelve la cadena de fórmula compuesta (f∘g)(x) = f(g(x)).
## Reemplaza solo el token variable "x" en f con "(g_formula)" usando
## límites de palabra para preservar identificadores como "exp", "max", etc.
func compose(f_formula: String, g_formula: String) -> String:
	return _replace_token_variable(f_formula, "x", "(%s)" % g_formula)


## Devuelve la fórmula de la suma: (f+g)(x)
func operation_sum(f_formula: String, g_formula: String) -> String:
	return "(%s) + (%s)" % [f_formula, g_formula]


## Devuelve la fórmula de la diferencia: (f-g)(x)
func operation_subtract(f_formula: String, g_formula: String) -> String:
	return "(%s) - (%s)" % [f_formula, g_formula]


## Devuelve la fórmula del producto: (f·g)(x)
func operation_multiply(f_formula: String, g_formula: String) -> String:
	return "(%s) * (%s)" % [f_formula, g_formula]


## Devuelve la fórmula del cociente: (f/g)(x) — el llamador debe manejar la división por cero.
func operation_divide(f_formula: String, g_formula: String) -> String:
	return "(%s) / (%s)" % [f_formula, g_formula]


# ---------------------------------------------------------------------------
# Sector 5 – Inversas, Exponenciales, Logaritmos, Trig Inversa
# ---------------------------------------------------------------------------

## Aproxima numéricamente la inversa de f en un valor objetivo y.
## Usa el método de la secante. Requiere que f sea estrictamente monótona cerca de la solución.
## Devuelve NAN si el método no converge.
func find_inverse(formula: String, target_y: float,
		x_guess: float = 0.0, max_iters: int = 100,
		tolerance: float = 1e-8) -> float:
	# Método de la secante: x_{n+1} = x_n - f(x_n)·(x_n - x_{n-1}) / (f(x_n) - f(x_{n-1}))
	# Definimos g(x) = f(x) - target_y y buscamos su raíz.
	var x0: float = x_guess - 0.1
	var x1: float = x_guess + 0.1
	var g0: float = evaluate(formula, x0) - target_y
	var g1: float = evaluate(formula, x1) - target_y

	for _i in range(max_iters):
		if is_nan(g0) or is_nan(g1):
			return NAN
		if absf(g1 - g0) < 1e-15:
			return NAN
		var x2: float = x1 - g1 * (x1 - x0) / (g1 - g0)
		var g2: float = evaluate(formula, x2) - target_y
		if absf(g2) < tolerance:
			return x2
		x0 = x1
		g0 = g1
		x1 = x2
		g1 = g2

	return NAN


## Comprueba la inyectividad (uno a uno) de una fórmula en [x_min, x_max].
## Una función es inyectiva sii es estrictamente monótona.
## Devuelve un Diccionario: {"injective": bool, "monotone_increasing": bool}
func check_injectivity(formula: String, x_min: float = -5.0,
		x_max: float = 5.0, steps: int = 200) -> Dictionary:
	var step: float = (x_max - x_min) / float(steps)
	var sign_changes: int = 0
	var prev_deriv_sign: int = 0

	for i in range(steps + 1):
		var x: float = x_min + step * float(i)
		var d: float = numerical_derivative(formula, x)
		if is_nan(d):
			continue
		var curr_sign: int = (1 if d > 1e-9 else (-1 if d < -1e-9 else 0))
		if prev_deriv_sign != 0 and curr_sign != 0 and curr_sign != prev_deriv_sign:
			sign_changes += 1
		if curr_sign != 0:
			prev_deriv_sign = curr_sign

	var first_deriv: float = numerical_derivative(formula, x_min)
	return {
		"injective": sign_changes == 0,
		"monotone_increasing": first_deriv > 0.0
	}


# ---------------------------------------------------------------------------
# Auxiliares de Cálculo Numérico
# ---------------------------------------------------------------------------

## Primera derivada numérica usando diferencias centrales: f'(x) ≈ (f(x+h)-f(x-h))/(2h)
func numerical_derivative(formula: String, x_val: float, h: float = 1e-5) -> float:
	var f_plus:  float = evaluate(formula, x_val + h)
	var f_minus: float = evaluate(formula, x_val - h)
	if is_nan(f_plus) or is_nan(f_minus):
		return NAN
	return (f_plus - f_minus) / (2.0 * h)


## Segunda derivada numérica: f''(x) ≈ (f(x+h) - 2f(x) + f(x-h)) / h²
func numerical_second_derivative(formula: String, x_val: float, h: float = 1e-4) -> float:
	var f_plus:  float = evaluate(formula, x_val + h)
	var f_zero:  float = evaluate(formula, x_val)
	var f_minus: float = evaluate(formula, x_val - h)
	if is_nan(f_plus) or is_nan(f_zero) or is_nan(f_minus):
		return NAN
	return (f_plus - 2.0 * f_zero + f_minus) / (h * h)


## Búsqueda de raíces por bisección para un callable g en [a, b].
## g debe ser un Callable: func(x: float) -> float
func find_root_bisect(g: Callable, a: float, b: float,
		tolerance: float = 1e-8, max_iters: int = 200) -> float:
	var ga: float = g.call(a)
	var gb: float = g.call(b)
	if is_nan(ga) or is_nan(gb):
		return NAN
	if ga * gb > 0.0:
		return NAN  # No se garantiza raíz en este intervalo
	for _i in range(max_iters):
		var mid: float = (a + b) * 0.5
		var gm: float = g.call(mid)
		if is_nan(gm) or absf(b - a) < tolerance:
			return mid
		if ga * gm <= 0.0:
			b = mid
			gb = gm
		else:
			a = mid
			ga = gm
	return (a + b) * 0.5


## Integral definida numérica usando la Regla de Simpson.
## n debe ser par.
func integrate_simpson(formula: String, a: float, b: float, n: int = 100) -> float:
	if n % 2 != 0:
		n += 1
	var h: float = (b - a) / float(n)
	var total: float = evaluate(formula, a) + evaluate(formula, b)
	for i in range(1, n):
		var x: float = a + h * float(i)
		var fx: float = evaluate(formula, x)
		if is_nan(fx):
			continue
		total += fx * (4.0 if i % 2 != 0 else 2.0)
	return total * h / 3.0


# ---------------------------------------------------------------------------
# Normalización / Visualización de Fórmulas
# ---------------------------------------------------------------------------

## Devuelve una etiqueta legible para un sector.
func sector_name(sector_index: int) -> String:
	match sector_index:
		1: return "Cinturón de Asteroides"
		2: return "Pozos Gravitatorios"
		3: return "Sintonizador de Púlsares"
		4: return "Estación de Acoplamiento"
		5: return "Horizonte de Sucesos"
		_: return "Sector Desconocido"


## Formatea un float para mostrarlo, limitando los decimales.
func format_float(value: float, decimals: int = 3) -> String:
	return "%.*f" % [decimals, value]


# ---------------------------------------------------------------------------
# Mensajes de Error Educativos
# ---------------------------------------------------------------------------

## Diccionario de errores de fórmula comunes con explicaciones pedagógicas en español.
## Las claves son identificadores internos; los valores son los mensajes para el jugador.
const FRIENDLY_ERRORS: Dictionary = {
	"implicit_multiply":
		"Error de coordenadas: Asegúrese de usar '*' para multiplicar (ej. 2*x en lugar de 2x). Consejo: use el botón × del Teclado Virtual ⌨ para evitar este error.",
	"unknown_function":
		"Función desconocida: Verifique el nombre. Use el Teclado Virtual ⌨ para insertar funciones como sin(), cos(), log(), exp(), asin() sin errores de escritura.",
	"unbalanced_parens":
		"Error de paréntesis: Revise que cada '(' tenga su ')' correspondiente. Use los botones ( y ) del Teclado Virtual ⌨.",
	"empty_formula":
		"Fórmula vacía: Ingrese una expresión matemática usando la variable 'x' (ej. 2*x + 1). Puede usar el Teclado Virtual ⌨.",
	"generic":
		"Error de sintaxis: Use el Teclado Virtual ⌨ para insertar operadores y funciones sin errores. Recuerde usar '*' para multiplicar y '/' para dividir.",
}


## Devuelve un mensaje de error educativo en español para una fórmula inválida.
## Intenta detectar el patrón de error más probable para orientar al estudiante.
func get_friendly_error_message(formula: String) -> String:
	var f: String = formula.strip_edges()
	if f.is_empty():
		return FRIENDLY_ERRORS["empty_formula"]

	# Detectar multiplicación implícita: dígito seguido de letra (ej. 2x, 3sin)
	var impl_mult: RegEx = RegEx.new()
	impl_mult.compile(r"\d[a-zA-Z]")
	if impl_mult.search(f) != null:
		return FRIENDLY_ERRORS["implicit_multiply"]

	# Detectar paréntesis desbalanceados
	if f.count("(") != f.count(")"):
		return FRIENDLY_ERRORS["unbalanced_parens"]

	return FRIENDLY_ERRORS["generic"]
