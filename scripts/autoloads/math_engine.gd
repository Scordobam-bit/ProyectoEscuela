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
const PI_VALUE: float = 3.141592653589793
const GOLDEN_RATIO: float = 1.6180339887498948
const _CHAR_CODE_0: int = 48
const _CHAR_CODE_9: int = 57
const _CHAR_CODE_UPPER_A: int = 65
const _CHAR_CODE_UPPER_Z: int = 90
const _CHAR_CODE_LOWER_A: int = 97
const _CHAR_CODE_LOWER_Z: int = 122
const _CHAR_CODE_UNDERSCORE: int = 95
const _CHAR_CODE_DOT: int = 46

# ---------------------------------------------------------------------------
# Estado privado
# ---------------------------------------------------------------------------

var _expr: Expression = Expression.new()
var _power_rightmost_caret_regex: RegEx = null

# ---------------------------------------------------------------------------
# Evaluación Principal
# ---------------------------------------------------------------------------

## Evalúa una cadena de fórmula en un valor x dado.
## Devuelve {"ok": bool, "value": Variant, "error": String}
func evaluate(formula: String, x_val: float = 0.0) -> Dictionary:
	var normalized: String = _normalize_formula(formula)
	var err: Error = _expr.parse(normalized, ["x"])
	if err != OK:
		var parse_error: String = "Expression.parse error: %s" % _expr.get_error_text()
		push_warning(parse_error)
		return {
			"ok": false,
			"value": NAN,
			"error": parse_error,
		}
	var result: Variant = _expr.execute([x_val])
	if _expr.has_execute_failed():
		push_warning("Expression.execute failed")
		return {
			"ok": false,
			"value": NAN,
			"error": "Expression.execute failed",
		}
	if not (result is float or result is int):
		push_warning("Resultado no numérico")
		return {
			"ok": false,
			"value": NAN,
			"error": "Resultado no numérico",
		}
	var y: float = float(result)
	if is_nan(y) or is_inf(y):
		push_warning("Error de dominio matemático (p. ej. asin/acos fuera de rango o log no válido).")
		return {
			"ok": false,
			"value": NAN,
			"error": "Error de dominio matemático (p. ej. asin/acos fuera de rango o log no válido).",
		}
	formula_evaluated.emit(normalized, x_val, y)
	return {"ok": true, "value": y, "error": ""}


func evaluate_value(formula: String, x_val: float = 0.0) -> float:
	var result: Dictionary = evaluate(formula, x_val)
	if not bool(result.get("ok", false)):
		return NAN
	return float(result.get("value", NAN))


## Devuelve true si la fórmula se analiza sin errores.
func is_valid_formula(formula: String) -> bool:
	return _expr.parse(_normalize_formula(formula), ["x"]) == OK


## Devuelve la fórmula normalizada que realmente consume Expression.
## Útil para componentes visuales (p. ej. FunctionPlotter) que deben
## soportar la misma sintaxis amigable que evaluate().
func normalize_formula(formula: String) -> String:
	return _normalize_formula(formula)


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
			var y: float = float(res)
			results.append(y if (not is_nan(y) and not is_inf(y)) else NAN)
	return results


## Normaliza entradas de usuario para reducir errores comunes de precedencia y cociente.
## Ejemplo educativo: "x/x+3" -> "(x)/(x+3)" y "x/x-3" -> "(x)/(x-3)".
func _normalize_formula(formula: String) -> String:
	var f: String = formula.strip_edges()
	f = _ensure_non_empty_formula(f)
	f = _rewrite_math_constants(f)
	f = _rewrite_function_aliases(f)
	f = _rewrite_log_with_base(f)
	f = _rewrite_power_operator(f)
	var simple_rational: RegEx = RegEx.new()
	simple_rational.compile("^([\\w\\(\\)\\^\\*\\+\\-]+)\\/([\\w\\(\\)\\^\\*\\+\\-]+)([\\+\\-])([\\w\\(\\)\\^\\*\\+\\-]+)$")
	var match: RegExMatch = simple_rational.search(f)
	if match != null:
		var numerator: String = match.get_string(1).strip_edges()
		var denominator_base: String = match.get_string(2).strip_edges()
		var denominator_op: String = match.get_string(3).strip_edges()
		var denominator_tail: String = match.get_string(4).strip_edges()
		if not numerator.is_empty() and not denominator_base.is_empty() and not denominator_tail.is_empty():
			return _ensure_non_empty_formula("(%s)/(%s%s%s)" % [numerator, denominator_base, denominator_op, denominator_tail])
	return _ensure_non_empty_formula(f)


func _rewrite_math_constants(formula: String) -> String:
	var output: PackedStringArray = []
	var i: int = 0
	while i < formula.length():
		var code: int = formula.unicode_at(i)
		if not ((code >= _CHAR_CODE_UPPER_A and code <= _CHAR_CODE_UPPER_Z) \
			or (code >= _CHAR_CODE_LOWER_A and code <= _CHAR_CODE_LOWER_Z) \
			or code == _CHAR_CODE_UNDERSCORE):
			output.append(formula.substr(i, 1))
			i += 1
			continue
		var start: int = i
		i += 1
		while i < formula.length() and _is_identifier_or_number_code(formula.unicode_at(i)):
			i += 1
		var token: String = formula.substr(start, i - start)
		if token == "PI":
			output.append(str(PI_VALUE))
			continue
		if token == "TAU":
			output.append(str(TAU))
			continue
		if token == "E" and not _is_scientific_exponent_marker(formula, start, i):
			output.append(str(EULER_E))
			continue
		output.append(token)
	return _ensure_non_empty_formula("".join(output))


func _is_scientific_exponent_marker(formula: String, token_start: int, token_end: int) -> bool:
	if token_start <= 0 or token_end >= formula.length():
		return false
	var prev_code: int = formula.unicode_at(token_start - 1)
	var next_char: String = formula.substr(token_end, 1)
	var prev_is_digit: bool = prev_code >= _CHAR_CODE_0 and prev_code <= _CHAR_CODE_9
	var next_is_sign_or_digit: bool = next_char == "+" or next_char == "-" \
		or (next_char.length() == 1 and next_char.unicode_at(0) >= _CHAR_CODE_0 and next_char.unicode_at(0) <= _CHAR_CODE_9)
	return prev_is_digit and next_is_sign_or_digit


func _rewrite_function_aliases(formula: String) -> String:
	var output: String = formula
	var alias_regex: RegEx = RegEx.new()
	alias_regex.compile("(?i)\\bln\\s*\\(")
	output = alias_regex.sub(output, "log(", true)
	alias_regex.compile("(?i)\\barcsin\\s*\\(")
	output = alias_regex.sub(output, "asin(", true)
	alias_regex.compile("(?i)\\barccos\\s*\\(")
	output = alias_regex.sub(output, "acos(", true)
	alias_regex.compile("(?i)\\barctan\\s*\\(")
	output = alias_regex.sub(output, "atan(", true)
	return _ensure_non_empty_formula(output)


func _rewrite_log_with_base(formula: String) -> String:
	var output: PackedStringArray = []
	var i: int = 0
	while i < formula.length():
		if not _is_log_call_start(formula, i):
			output.append(formula.substr(i, 1))
			i += 1
			continue
		var open_paren: int = i + 3
		var close_paren: int = _find_matching_paren(formula, open_paren)
		if close_paren == -1:
			output.append(formula.substr(i, 1))
			i += 1
			continue
		var inner: String = formula.substr(open_paren + 1, close_paren - open_paren - 1)
		var comma_idx: int = _find_top_level_comma(inner)
		if comma_idx == -1:
			output.append(formula.substr(i, close_paren - i + 1))
			i = close_paren + 1
			continue
		var base_expr: String = _rewrite_log_with_base(inner.substr(0, comma_idx).strip_edges())
		var value_expr: String = _rewrite_log_with_base(inner.substr(comma_idx + 1).strip_edges())
		if base_expr.is_empty() or value_expr.is_empty():
			output.append(formula.substr(i, close_paren - i + 1))
			i = close_paren + 1
			continue
		output.append("(log(%s)/log(%s))" % [value_expr, base_expr])
		i = close_paren + 1
	return _ensure_non_empty_formula("".join(output))


func _rewrite_power_operator(formula: String) -> String:
	var rewritten: String = formula
	if _power_rightmost_caret_regex == null:
		_power_rightmost_caret_regex = RegEx.new()
		_power_rightmost_caret_regex.compile("\\^(?!.*\\^)")
	var max_passes: int = 128
	# Límite de seguridad para evitar bucles infinitos en expresiones malformadas.
	for _pass in range(max_passes):
		var match: RegExMatch = _power_rightmost_caret_regex.search(rewritten)
		if match == null:
			break
		var idx: int = match.get_start()
		var left_part: Dictionary = _extract_power_left(rewritten, idx - 1)
		var right_part: Dictionary = _extract_power_right(rewritten, idx + 1)
		if left_part.is_empty() or right_part.is_empty():
			break
		var left_expr: String = left_part["expr"]
		var right_expr: String = right_part["expr"]
		var start_idx: int = left_part["start"]
		var end_idx: int = right_part["end"]
		rewritten = rewritten.left(start_idx) + "pow(%s, %s)" % [left_expr, right_expr] + rewritten.substr(end_idx + 1)
	return _ensure_non_empty_formula(rewritten)


func _ensure_non_empty_formula(value: String) -> String:
	if value.strip_edges().is_empty():
		push_warning("MathEngine: normalización produjo fórmula vacía; se usa expresión segura '0'.")
		return "0"
	return value


func _extract_power_left(formula: String, start_idx: int) -> Dictionary:
	var i: int = start_idx
	while i >= 0 and formula.unicode_at(i) <= 32:
		i -= 1
	if i < 0:
		return {}
	var ch: String = formula.substr(i, 1)
	if ch == ")":
		var open_idx: int = _find_matching_paren_reverse(formula, i)
		if open_idx == -1:
			return {}
		var expr_start: int = open_idx
		var fn_end: int = open_idx - 1
		while fn_end >= 0 and formula.unicode_at(fn_end) <= 32:
			fn_end -= 1
		if fn_end >= 0 and _is_identifier_or_number_code(formula.unicode_at(fn_end)):
			var fn_start: int = fn_end
			while fn_start >= 0 and _is_identifier_or_number_code(formula.unicode_at(fn_start)):
				fn_start -= 1
			fn_start += 1
			if fn_start <= fn_end:
				expr_start = fn_start
		return {"start": expr_start, "expr": formula.substr(expr_start, i - expr_start + 1)}
	var begin: int = i
	while begin >= 0 and _is_identifier_or_number_code(formula.unicode_at(begin)):
		begin -= 1
	begin += 1
	if begin > i:
		return {}
	return {"start": begin, "expr": formula.substr(begin, i - begin + 1)}


func _extract_power_right(formula: String, start_idx: int) -> Dictionary:
	var i: int = start_idx
	while i < formula.length() and formula.unicode_at(i) <= 32:
		i += 1
	if i >= formula.length():
		return {}
	var sign: String = ""
	if formula.substr(i, 1) == "-":
		sign = "-"
		i += 1
		while i < formula.length() and formula.unicode_at(i) <= 32:
			i += 1
		if i >= formula.length():
			return {}
	var ch: String = formula.substr(i, 1)
	if ch == "(":
		var close_idx: int = _find_matching_paren(formula, i)
		if close_idx == -1:
			return {}
		return {
			"end": close_idx,
			"expr": sign + formula.substr(i, close_idx - i + 1),
		}
	var end_idx: int = i
	while end_idx < formula.length() and _is_identifier_or_number_code(formula.unicode_at(end_idx)):
		end_idx += 1
	end_idx -= 1
	if end_idx < i:
		return {}
	var after_token: int = end_idx + 1
	while after_token < formula.length() and formula.unicode_at(after_token) <= 32:
		after_token += 1
	if after_token < formula.length() and formula.substr(after_token, 1) == "(":
		var fn_close_idx: int = _find_matching_paren(formula, after_token)
		if fn_close_idx == -1:
			return {}
		end_idx = fn_close_idx
	return {
		"end": end_idx,
		"expr": sign + formula.substr(i, end_idx - i + 1),
	}


func _is_identifier_or_number_code(code: int) -> bool:
	return (code >= _CHAR_CODE_0 and code <= _CHAR_CODE_9) \
		or (code >= _CHAR_CODE_UPPER_A and code <= _CHAR_CODE_UPPER_Z) \
		or (code >= _CHAR_CODE_LOWER_A and code <= _CHAR_CODE_LOWER_Z) \
		or code == _CHAR_CODE_UNDERSCORE \
		or code == _CHAR_CODE_DOT


func _is_log_call_start(formula: String, index: int) -> bool:
	if index < 0 or index + 3 >= formula.length():
		return false
	if formula.substr(index, 3).to_lower() != "log":
		return false
	if formula.substr(index + 3, 1) != "(":
		return false
	if index == 0:
		return true
	return not _is_identifier_or_number_code(formula.unicode_at(index - 1))


func _find_matching_paren(formula: String, open_idx: int) -> int:
	if open_idx < 0 or open_idx >= formula.length() or formula.substr(open_idx, 1) != "(":
		return -1
	var depth: int = 0
	for i in range(open_idx, formula.length()):
		var ch: String = formula.substr(i, 1)
		if ch == "(":
			depth += 1
		elif ch == ")":
			depth -= 1
			if depth == 0:
				return i
	return -1


func _find_matching_paren_reverse(formula: String, close_idx: int) -> int:
	if close_idx < 0 or close_idx >= formula.length() or formula.substr(close_idx, 1) != ")":
		return -1
	var depth: int = 0
	for i in range(close_idx, -1, -1):
		var ch: String = formula.substr(i, 1)
		if ch == ")":
			depth += 1
		elif ch == "(":
			depth -= 1
			if depth == 0:
				return i
	return -1


func _find_top_level_comma(content: String) -> int:
	var depth: int = 0
	for i in range(content.length()):
		var ch: String = content.substr(i, 1)
		if ch == "(":
			depth += 1
		elif ch == ")":
			depth -= 1
		elif ch == "," and depth == 0:
			return i
	return -1


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
	var b: float = evaluate_value(formula, 0.0)
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
	var vertex_y: float = evaluate_value(formula, root_x)
	return Vector2(root_x, vertex_y)


## Devuelve las raíces reales de f(x) = 0 en [x_min, x_max] usando bisección.
## Se encuentran múltiples raíces buscando cambios de signo.
func find_roots(formula: String, x_min: float = -10.0, x_max: float = 10.0,
		steps: int = 1000, tolerance: float = 1e-6) -> PackedFloat64Array:
	var roots: PackedFloat64Array = PackedFloat64Array()
	var step: float = (x_max - x_min) / float(steps)
	var prev_x: float = x_min
	var prev_y: float = evaluate_value(formula, x_min)

	for i in range(1, steps + 1):
		var curr_x: float = x_min + step * float(i)
		var curr_y: float = evaluate_value(formula, curr_x)

		if is_nan(prev_y) or is_nan(curr_y):
			prev_x = curr_x
			prev_y = curr_y
			continue

		# Se detectó un cambio de signo → existe una raíz en este intervalo
		if prev_y * curr_y < 0.0:
			var root: float = find_root_bisect(
				func(x: float) -> float: return evaluate_value(formula, x),
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
	var g0: float = evaluate_value(formula, x0) - target_y
	var g1: float = evaluate_value(formula, x1) - target_y

	for _i in range(max_iters):
		if is_nan(g0) or is_nan(g1):
			return NAN
		if absf(g1 - g0) < 1e-15:
			return NAN
		var x2: float = x1 - g1 * (x1 - x0) / (g1 - g0)
		var g2: float = evaluate_value(formula, x2) - target_y
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
	var f_plus:  float = evaluate_value(formula, x_val + h)
	var f_minus: float = evaluate_value(formula, x_val - h)
	if is_nan(f_plus) or is_nan(f_minus):
		return NAN
	return (f_plus - f_minus) / (2.0 * h)


## Segunda derivada numérica: f''(x) ≈ (f(x+h) - 2f(x) + f(x-h)) / h²
func numerical_second_derivative(formula: String, x_val: float, h: float = 1e-4) -> float:
	var f_plus:  float = evaluate_value(formula, x_val + h)
	var f_zero:  float = evaluate_value(formula, x_val)
	var f_minus: float = evaluate_value(formula, x_val - h)
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
	var total: float = evaluate_value(formula, a) + evaluate_value(formula, b)
	for i in range(1, n):
		var x: float = a + h * float(i)
		var fx: float = evaluate_value(formula, x)
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
