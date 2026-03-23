## math_engine_test.gd
## ===================
## Pruebas unitarias para MathEngine (Autoload).
##
## Cómo ejecutar:
## 1. Abre el proyecto en Godot 4.6.1.
## 2. En el editor, abre esta escena (o adjunta este script a un nodo raíz Node).
## 3. Ejecuta la escena (F5 / Ctrl+F5).
##    Todos los resultados aparecen en la consola de Godot.
##
## Alternativa CLI (headless):
##   godot --headless --script tests/math_engine_test.gd
##
## Cada prueba imprime PASS o FAIL con un mensaje descriptivo.
extends Node


const TOLERANCE: float = 1e-5


func _ready() -> void:
	print("=== MathEngine Unit Tests ===")
	var passed: int = 0
	var failed: int = 0

	var tests: Array[Callable] = [
		test_evaluate_basic,
		test_evaluate_sin,
		test_evaluate_inverse_trig,
		test_evaluate_inverse_trig_out_of_domain,
		test_evaluate_ln_alias,
		test_evaluate_constants_pi_e,
		test_evaluate_log_with_base,
		test_evaluate_power_operator_rewrite,
		test_evaluate_power_operator_nested_right_associative,
		test_evaluate_rational_continuous_fraction,
		test_evaluate_non_standard_ambiguous_division_as_rational,
		test_compose_no_corrupt_exp,
		test_compose_no_corrupt_sin,
		test_compose_simple,
		test_compose_quadratic_in_sin,
		test_transform_shift_horizontal_exp,
		test_transform_shift_horizontal_sin,
		test_transform_scale_horizontal_exp,
		test_transform_reflect_y_exp,
		test_transform_reflect_y_sin,
		test_transform_shift_vertical,
		test_transform_scale_vertical,
		test_find_roots_quadratic,
		test_numerical_derivative,
		test_linspace,
		test_find_inverse,
	]

	for t: Callable in tests:
		var result: bool = t.call()
		if result:
			passed += 1
		else:
			failed += 1

	print("=== Resultados: %d aprobados, %d fallados ===" % [passed, failed])
	if failed == 0:
		print("✓ TODAS LAS PRUEBAS APROBADAS")
	else:
		print("✗ ALGUNAS PRUEBAS FALLARON — revisa los mensajes anteriores")
	get_tree().quit()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _assert(condition: bool, test_name: String, detail: String = "") -> bool:
	if condition:
		print("  PASS  %s" % test_name)
	else:
		print("  FAIL  %s%s" % [test_name, (": " + detail if not detail.is_empty() else "")])
	return condition


func _approx_equal(a: float, b: float, tol: float = TOLERANCE) -> bool:
	return abs(a - b) <= tol


# ---------------------------------------------------------------------------
# Pruebas de evaluate()
# ---------------------------------------------------------------------------

func test_evaluate_basic() -> bool:
	var result: float = MathEngine.evaluate("2*x + 1", 3.0)
	return _assert(_approx_equal(result, 7.0), "evaluate('2*x+1', 3) == 7",
		"got %s" % result)


func test_evaluate_sin() -> bool:
	var result: float = MathEngine.evaluate("sin(x)", PI / 2.0)
	return _assert(_approx_equal(result, 1.0, 1e-6), "evaluate('sin(x)', PI/2) ≈ 1",
		"got %s" % result)


func test_evaluate_inverse_trig() -> bool:
	var asin_val: float = MathEngine.evaluate("asin(x)", 0.5)
	var acos_val: float = MathEngine.evaluate("acos(x)", 0.5)
	var atan_val: float = MathEngine.evaluate("atan(x)", 1.0)
	var ok: bool = _approx_equal(asin_val, PI / 6.0, 1e-6) \
		and _approx_equal(acos_val, PI / 3.0, 1e-6) \
		and _approx_equal(atan_val, PI / 4.0, 1e-6)
	return _assert(ok, "evaluate soporta asin/acos/atan",
		"asin=%s acos=%s atan=%s" % [asin_val, acos_val, atan_val])


func test_evaluate_inverse_trig_out_of_domain() -> bool:
	var asin_val: float = MathEngine.evaluate("asin(x)", 2.0)
	var acos_val: float = MathEngine.evaluate("acos(x)", -2.0)
	return _assert(is_nan(asin_val) and is_nan(acos_val),
		"evaluate asin/acos fuera de dominio devuelve NAN",
		"asin=%s acos=%s" % [asin_val, acos_val])


func test_evaluate_ln_alias() -> bool:
	var result: float = MathEngine.evaluate("ln(x)", MathEngine.EULER_E)
	return _assert(_approx_equal(result, 1.0, 1e-6),
		"evaluate('ln(x)', e) ≈ 1",
		"got %s" % result)


func test_evaluate_constants_pi_e() -> bool:
	var pi_result: float = MathEngine.evaluate("PI", 0.0)
	var e_result: float = MathEngine.evaluate("E", 0.0)
	var ok: bool = _approx_equal(pi_result, 3.141592, 1e-6) and _approx_equal(e_result, 2.718281, 1e-6)
	return _assert(ok, "evaluate reconoce PI y E como constantes",
		"PI=%s E=%s" % [pi_result, e_result])


func test_evaluate_log_with_base() -> bool:
	var result: float = MathEngine.evaluate("log(2, x)", 8.0)
	return _assert(_approx_equal(result, 3.0, 1e-6),
		"evaluate('log(2, x)', 8) == 3",
		"got %s" % result)


func test_evaluate_power_operator_rewrite() -> bool:
	var result: float = MathEngine.evaluate("sin(x)^2", PI / 2.0)
	return _assert(_approx_equal(result, 1.0, 1e-6),
		"evaluate('sin(x)^2', PI/2) == 1",
		"got %s" % result)


func test_evaluate_power_operator_nested_right_associative() -> bool:
	var result: float = MathEngine.evaluate("x^x^2", 2.0)
	return _assert(_approx_equal(result, 16.0, 1e-6),
		"evaluate('x^x^2', 2) == 16 (asociatividad derecha)",
		"got %s" % result)


func test_evaluate_rational_continuous_fraction() -> bool:
	var value: float = MathEngine.evaluate("x/(x+3)", 3.0)
	return _assert(_approx_equal(value, 0.5, 1e-6),
		"evaluate('x/(x+3)', 3) == 0.5",
		"got %s" % value)


func test_evaluate_non_standard_ambiguous_division_as_rational() -> bool:
	## Este proyecto normaliza intencionalmente "x/x+3" como "x/(x+3)"
	## para reforzar la lectura de fracción continua en el currículo.
	var value: float = MathEngine.evaluate("x/x+3", 3.0)
	return _assert(_approx_equal(value, 0.5, 1e-6),
		"evaluate('x/x+3', 3) se interpreta como x/(x+3)",
		"got %s" % value)


# ---------------------------------------------------------------------------
# Pruebas de compose() — verificar que identificadores con 'x' no se corrompen
# ---------------------------------------------------------------------------

func test_compose_no_corrupt_exp() -> bool:
	## compose("exp(x)", "x^2") debe dar "exp((x^2))", NO "e(x^2)p((x^2))"
	var composed: String = MathEngine.compose("exp(x)", "x^2")
	var expected: String = "exp((x^2))"
	return _assert(composed == expected, "compose('exp(x)', 'x^2') == 'exp((x^2))'",
		"got '%s'" % composed)


func test_compose_no_corrupt_sin() -> bool:
	## compose("sin(x)", "x^2") debe dar "sin((x^2))"
	var composed: String = MathEngine.compose("sin(x)", "x^2")
	var expected: String = "sin((x^2))"
	return _assert(composed == expected, "compose('sin(x)', 'x^2') == 'sin((x^2))'",
		"got '%s'" % composed)


func test_compose_simple() -> bool:
	## compose("x^2", "x + 1") debe dar "((x + 1))^2"
	var composed: String = MathEngine.compose("x^2", "x + 1")
	var expected: String = "((x + 1))^2"
	return _assert(composed == expected, "compose('x^2', 'x+1') == '((x + 1))^2'",
		"got '%s'" % composed)


func test_compose_quadratic_in_sin() -> bool:
	## Verificar que la evaluación del resultado compuesto también es correcta.
	## sin(x^2) con x=sqrt(PI/2) ≈ 1
	var composed: String = MathEngine.compose("sin(x)", "x^2")
	# sin((sqrt(PI/2))^2) = sin(PI/2) = 1
	var val: float = MathEngine.evaluate(composed, sqrt(PI / 2.0))
	return _assert(_approx_equal(val, 1.0, 1e-5),
		"eval(compose('sin(x)','x^2'), sqrt(PI/2)) ≈ 1",
		"got %s from formula '%s'" % [val, composed])


# ---------------------------------------------------------------------------
# Pruebas de transform_shift_horizontal()
# ---------------------------------------------------------------------------

func test_transform_shift_horizontal_exp() -> bool:
	## transform_shift_horizontal("exp(x)", 1.0) debe dar "exp((x - 1.0))"
	var result: String = MathEngine.transform_shift_horizontal("exp(x)", 1.0)
	var expected: String = "exp((x - 1.0))"
	return _assert(result == expected,
		"transform_shift_horizontal('exp(x)', 1) == 'exp((x - 1.0))'",
		"got '%s'" % result)


func test_transform_shift_horizontal_sin() -> bool:
	## Verificar evaluación: sin(x-PI/2) en x=PI = sin(PI/2) = 1
	var formula: String = MathEngine.transform_shift_horizontal("sin(x)", PI / 2.0)
	var val: float = MathEngine.evaluate(formula, PI)
	return _assert(_approx_equal(val, 1.0, 1e-5),
		"eval(transform_shift_horizontal('sin(x)', PI/2), PI) ≈ 1",
		"got %s from formula '%s'" % [val, formula])


# ---------------------------------------------------------------------------
# Pruebas de transform_scale_horizontal()
# ---------------------------------------------------------------------------

func test_transform_scale_horizontal_exp() -> bool:
	## transform_scale_horizontal("exp(x)", 2.0) debe dar "exp((2.0 * x))"
	var result: String = MathEngine.transform_scale_horizontal("exp(x)", 2.0)
	var expected: String = "exp((2.0 * x))"
	return _assert(result == expected,
		"transform_scale_horizontal('exp(x)', 2.0) == 'exp((2.0 * x))'",
		"got '%s'" % result)


# ---------------------------------------------------------------------------
# Pruebas de transform_reflect_y()
# ---------------------------------------------------------------------------

func test_transform_reflect_y_exp() -> bool:
	## transform_reflect_y("exp(x)") debe dar "exp((-x))"
	var result: String = MathEngine.transform_reflect_y("exp(x)")
	var expected: String = "exp((-x))"
	return _assert(result == expected,
		"transform_reflect_y('exp(x)') == 'exp((-x))'",
		"got '%s'" % result)


func test_transform_reflect_y_sin() -> bool:
	## transform_reflect_y("sin(x)") debe dar "sin((-x))"
	var result: String = MathEngine.transform_reflect_y("sin(x)")
	var expected: String = "sin((-x))"
	return _assert(result == expected,
		"transform_reflect_y('sin(x)') == 'sin((-x))'",
		"got '%s'" % result)


# ---------------------------------------------------------------------------
# Pruebas de transform_shift_vertical() y transform_scale_vertical()
# ---------------------------------------------------------------------------

func test_transform_shift_vertical() -> bool:
	var result: String = MathEngine.transform_shift_vertical("x^2", 3.0)
	var expected: String = "(x^2) + 3.0"
	return _assert(result == expected,
		"transform_shift_vertical('x^2', 3) == '(x^2) + 3.0'",
		"got '%s'" % result)


func test_transform_scale_vertical() -> bool:
	var result: String = MathEngine.transform_scale_vertical("sin(x)", 2.0)
	var expected: String = "2.0 * (sin(x))"
	return _assert(result == expected,
		"transform_scale_vertical('sin(x)', 2.0) == '2.0 * (sin(x))'",
		"got '%s'" % result)


# ---------------------------------------------------------------------------
# Pruebas de find_roots()
# ---------------------------------------------------------------------------

func test_find_roots_quadratic() -> bool:
	## x^2 - 1 = 0 → raíces en x = ±1
	var roots: PackedFloat64Array = MathEngine.find_roots("x^2 - 1", -2.0, 2.0)
	var has_pos: bool = false
	var has_neg: bool = false
	for r: float in roots:
		if _approx_equal(r, 1.0, 1e-4):
			has_pos = true
		if _approx_equal(r, -1.0, 1e-4):
			has_neg = true
	return _assert(has_pos and has_neg,
		"find_roots('x^2-1') contiene ±1",
		"roots: %s" % str(Array(roots)))


# ---------------------------------------------------------------------------
# Pruebas de numerical_derivative()
# ---------------------------------------------------------------------------

func test_numerical_derivative() -> bool:
	## d/dx[x^2] en x=3 = 6
	var deriv: float = MathEngine.numerical_derivative("x^2", 3.0)
	return _assert(_approx_equal(deriv, 6.0, 1e-4),
		"numerical_derivative('x^2', 3) ≈ 6",
		"got %s" % deriv)


# ---------------------------------------------------------------------------
# Pruebas de linspace()
# ---------------------------------------------------------------------------

func test_linspace() -> bool:
	var pts: PackedFloat64Array = MathEngine.linspace(0.0, 1.0, 5)
	var ok: bool = (pts.size() == 5
		and _approx_equal(pts[0], 0.0)
		and _approx_equal(pts[2], 0.5)
		and _approx_equal(pts[4], 1.0))
	return _assert(ok, "linspace(0, 1, 5) tiene 5 puntos correctos",
		"got %s" % str(Array(pts)))


# ---------------------------------------------------------------------------
# Pruebas de find_inverse()
# ---------------------------------------------------------------------------

func test_find_inverse() -> bool:
	## Inversa de x^3 en y=8 → x=2
	var x_inv: float = MathEngine.find_inverse("x^3", 8.0, 1.5)
	return _assert(_approx_equal(x_inv, 2.0, 1e-5),
		"find_inverse('x^3', 8) ≈ 2",
		"got %s" % x_inv)
