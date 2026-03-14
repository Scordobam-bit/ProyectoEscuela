## MathEngine.gd  (Autoload — accessible as MathEngine from any script)
## ==========================================================================
## Centralised mathematical utilities for Planet Waves.
##
## University-Level Overview
## --------------------------
## This singleton wraps Godot's Expression class and adds helper routines
## for the five curriculum sectors:
##
##   Sector 1 – Lines          : slope, intercept, domain/range analysis
##   Sector 2 – Quadratics     : discriminant, vertex form, roots (quadratic formula)
##   Sector 3 – Transformations: shift, scale, reflect operations on f(x)
##   Sector 4 – Composition    : (f∘g)(x) = f(g(x)), evaluated symbolically
##   Sector 5 – Inverses/Logs  : numerical inverse approximation, ln, exp, arcsin/arccos
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted whenever a formula is evaluated (for analytics / tutoring feedback).
signal formula_evaluated(formula: String, x: float, result: float)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const EULER_E: float = 2.718281828459045
const GOLDEN_RATIO: float = 1.6180339887498948

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _expr: Expression = Expression.new()

# ---------------------------------------------------------------------------
# Core Evaluation
# ---------------------------------------------------------------------------

## Evaluates a formula string at a given x value.
## Returns NAN on parse or execution failure.
func evaluate(formula: String, x_val: float) -> float:
	var err: Error = _expr.parse(formula, ["x"])
	if err != OK:
		return NAN
	var result: Variant = _expr.execute([x_val])
	if _expr.has_execute_failed():
		return NAN
	var y: float = float(result)
	formula_evaluated.emit(formula, x_val, y)
	return y


## Returns true if the formula parses without error.
func is_valid_formula(formula: String) -> bool:
	return _expr.parse(formula, ["x"]) == OK


## Evaluates a formula over an array of x values.
## Skips NAN / Inf results.
func evaluate_range(formula: String, x_values: PackedFloat64Array) -> PackedFloat64Array:
	var results: PackedFloat64Array = PackedFloat64Array()
	var err: Error = _expr.parse(formula, ["x"])
	if err != OK:
		return results
	for x in x_values:
		var res: Variant = _expr.execute([x])
		if _expr.has_execute_failed():
			results.append(NAN)
		else:
			results.append(float(res))
	return results


## Generates N evenly-spaced x values in [x_min, x_max].
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
# Sector 1 – Linear Functions
# ---------------------------------------------------------------------------

## Extracts slope m and y-intercept b from a linear formula "m*x + b".
## Uses two-point numerical differentiation — works for any differentiable f.
func get_slope_and_intercept(formula: String) -> Dictionary:
	var m: float = numerical_derivative(formula, 0.0)
	var b: float = evaluate(formula, 0.0)
	return {"slope": m, "intercept": b}


## Returns true if f is linear on [x_min, x_max] (second derivative ≈ 0).
func is_linear(formula: String, x_min: float = -5.0, x_max: float = 5.0) -> bool:
	var d2: float = numerical_second_derivative(formula, (x_min + x_max) / 2.0)
	return absf(d2) < 1e-4


# ---------------------------------------------------------------------------
# Sector 2 – Quadratic Functions
# ---------------------------------------------------------------------------

## For f(x) = ax²+bx+c, returns the vertex (h, k) where h = -b/(2a).
## Uses numerical methods: h is where f'(x) = 0.
func find_vertex(formula: String, search_min: float = -50.0,
		search_max: float = 50.0, tolerance: float = 1e-6) -> Vector2:
	# Bisect on f'(x) = 0 in the given range
	var root_x: float = find_root_bisect(
		func(x: float) -> float: return numerical_derivative(formula, x),
		search_min, search_max, tolerance
	)
	var vertex_y: float = evaluate(formula, root_x)
	return Vector2(root_x, vertex_y)


## Returns the real roots of f(x) = 0 in [x_min, x_max] using bisection.
## Multiple roots are found by scanning for sign changes.
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

		# Sign change detected → a root exists in this interval
		if prev_y * curr_y < 0.0:
			var root: float = find_root_bisect(
				func(x: float) -> float: return evaluate(formula, x),
				prev_x, curr_x, tolerance
			)
			if not is_nan(root):
				# Avoid duplicate roots
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


## Classical quadratic formula for ax²+bx+c = 0.
## Returns a Dictionary: {"discriminant": Δ, "roots": [x1, x2] or [x1] or []}
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
# Sector 3 – Function Transformations
# ---------------------------------------------------------------------------

## Returns the formula string for a vertical shift: f(x) + k
func transform_shift_vertical(base_formula: String, k: float) -> String:
	if k >= 0.0:
		return "(%s) + %s" % [base_formula, k]
	return "(%s) - %s" % [base_formula, absf(k)]


## Returns the formula string for a horizontal shift: f(x - h)
func transform_shift_horizontal(base_formula: String, h: float) -> String:
	if h >= 0.0:
		return base_formula.replace("x", "(x - %s)" % h)
	return base_formula.replace("x", "(x + %s)" % absf(h))


## Returns the formula string for vertical scaling: a·f(x)
func transform_scale_vertical(base_formula: String, a: float) -> String:
	return "%s * (%s)" % [a, base_formula]


## Returns the formula string for horizontal scaling: f(b·x)
func transform_scale_horizontal(base_formula: String, b: float) -> String:
	return base_formula.replace("x", "(%s * x)" % b)


## Returns the formula string for reflection over X-axis: -f(x)
func transform_reflect_x(base_formula: String) -> String:
	return "-(%s)" % base_formula


## Returns the formula string for reflection over Y-axis: f(-x)
func transform_reflect_y(base_formula: String) -> String:
	return base_formula.replace("x", "(-x)")


# ---------------------------------------------------------------------------
# Sector 4 – Function Operations & Composition
# ---------------------------------------------------------------------------

## Returns the composite formula string (f∘g)(x) = f(g(x)).
## Replaces every occurrence of "x" in f with "(g_formula)".
## Note: Works best for simple single-variable formulas.
func compose(f_formula: String, g_formula: String) -> String:
	return f_formula.replace("x", "(%s)" % g_formula)


## Returns the sum formula: (f+g)(x)
func operation_sum(f_formula: String, g_formula: String) -> String:
	return "(%s) + (%s)" % [f_formula, g_formula]


## Returns the difference formula: (f-g)(x)
func operation_subtract(f_formula: String, g_formula: String) -> String:
	return "(%s) - (%s)" % [f_formula, g_formula]


## Returns the product formula: (f·g)(x)
func operation_multiply(f_formula: String, g_formula: String) -> String:
	return "(%s) * (%s)" % [f_formula, g_formula]


## Returns the quotient formula: (f/g)(x) — caller must handle division by zero.
func operation_divide(f_formula: String, g_formula: String) -> String:
	return "(%s) / (%s)" % [f_formula, g_formula]


# ---------------------------------------------------------------------------
# Sector 5 – Inverses, Exponentials, Logarithms, Inverse Trig
# ---------------------------------------------------------------------------

## Numerically approximates the inverse of f at a target y value.
## Uses the secant method. Requires f to be strictly monotone near the solution.
## Returns NAN if the method fails to converge.
func find_inverse(formula: String, target_y: float,
		x_guess: float = 0.0, max_iters: int = 100,
		tolerance: float = 1e-8) -> float:
	# Secant method: x_{n+1} = x_n - f(x_n)·(x_n - x_{n-1}) / (f(x_n) - f(x_{n-1}))
	# We define g(x) = f(x) - target_y and find its root.
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


## Checks injectivity (one-to-one) of a formula on [x_min, x_max].
## A function is injective iff it is strictly monotone.
## Returns a Dictionary: {"injective": bool, "monotone_increasing": bool}
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
# Numerical Calculus Helpers
# ---------------------------------------------------------------------------

## Numerical first derivative using central differences: f'(x) ≈ (f(x+h)-f(x-h))/(2h)
func numerical_derivative(formula: String, x_val: float, h: float = 1e-5) -> float:
	var f_plus:  float = evaluate(formula, x_val + h)
	var f_minus: float = evaluate(formula, x_val - h)
	if is_nan(f_plus) or is_nan(f_minus):
		return NAN
	return (f_plus - f_minus) / (2.0 * h)


## Numerical second derivative: f''(x) ≈ (f(x+h) - 2f(x) + f(x-h)) / h²
func numerical_second_derivative(formula: String, x_val: float, h: float = 1e-4) -> float:
	var f_plus:  float = evaluate(formula, x_val + h)
	var f_zero:  float = evaluate(formula, x_val)
	var f_minus: float = evaluate(formula, x_val - h)
	if is_nan(f_plus) or is_nan(f_zero) or is_nan(f_minus):
		return NAN
	return (f_plus - 2.0 * f_zero + f_minus) / (h * h)


## Bisection root-finding for a callable g on [a, b].
## g must be a Callable: func(x: float) -> float
func find_root_bisect(g: Callable, a: float, b: float,
		tolerance: float = 1e-8, max_iters: int = 200) -> float:
	var ga: float = g.call(a)
	var gb: float = g.call(b)
	if is_nan(ga) or is_nan(gb):
		return NAN
	if ga * gb > 0.0:
		return NAN  # No guaranteed root in this interval
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


## Numerical definite integral using Simpson's rule.
## n must be even.
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
# Formula Normalisation / Display
# ---------------------------------------------------------------------------

## Returns a human-readable label for a sector.
func sector_name(sector_index: int) -> String:
	match sector_index:
		1: return "Asteroid Belt"
		2: return "Gravity Wells"
		3: return "Pulsar Tuner"
		4: return "Docking Station"
		5: return "Event Horizon"
		_: return "Unknown Sector"


## Formats a float for display, limiting decimal places.
func format_float(value: float, decimals: int = 3) -> String:
	return "%.*f" % [decimals, value]
