## TheoryPanel.gd
## ===============
## Displays university-level mathematical theory for each sector topic.
## Uses a RichTextLabel with BBCode for formatting.
class_name TheoryPanel
extends PanelContainer

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal panel_closed

# ---------------------------------------------------------------------------
# Node References
# ---------------------------------------------------------------------------

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _content_label: RichTextLabel = $VBox/ScrollContainer/ContentLabel
@onready var _close_button: Button = $VBox/CloseButton
@onready var _nav_prev: Button = $VBox/NavRow/PrevButton
@onready var _nav_next: Button = $VBox/NavRow/NextButton
@onready var _page_label: Label = $VBox/NavRow/PageLabel

# ---------------------------------------------------------------------------
# Theory Database
## Each entry: { "title": String, "content": String (BBCode) }
# ---------------------------------------------------------------------------

const THEORY: Dictionary = {
	# ── Sector 1 ──────────────────────────────────────────────────────────
	"intro_functions": {
		"title": "What is a Function?",
		"content": """[b]Definition[/b]
A [color=#00ffcc]function[/color] [b]f : D → ℝ[/b] is a rule that assigns to each element [b]x[/b] in the domain [b]D[/b] exactly one value [b]f(x)[/b] in the codomain.

[b]Formal notation:[/b]
  [color=#ffcc00]f(x) = expression involving x[/color]

[b]Vertical Line Test:[/b] A curve in the plane is the graph of a function iff every vertical line intersects it at most once.

[b]Example:[/b]
  f(x) = 2x + 3  → for x = 5,  f(5) = 13

[b]In Planet Waves:[/b] Enter the formula in the HUD input. The Line2D will trace your function across the current domain."""
	},

	"linear_functions": {
		"title": "Linear Functions  y = mx + b",
		"content": """[b]General Form:[/b]  [color=#ffcc00]f(x) = mx + b[/color]

[b]Parameters:[/b]
• [b]m[/b] = slope = rise/run = (y₂ − y₁) / (x₂ − x₁)
• [b]b[/b] = y-intercept (value when x = 0)

[b]Slope sign:[/b]
• m > 0 → increasing
• m < 0 → decreasing
• m = 0 → constant (horizontal line)

[b]Point-Slope Form:[/b]  y − y₁ = m(x − x₁)

[b]Challenge:[/b] Navigate through the asteroid belt by plotting a line that passes through two given waypoints."""
	},

	"domain_range": {
		"title": "Domain & Range",
		"content": """[b]Domain D(f)[/b]
The set of all valid inputs x. Restrictions arise from:
• Division by zero  →  x ≠ 0  for  f(x) = 1/x
• Even roots        →  x ≥ 0  for  f(x) = √x
• Logarithms        →  x > 0  for  f(x) = ln(x)

[b]Range R(f)[/b]
The set of all achievable outputs. To find it, analyse the function's behaviour as x varies over its domain.

[b]Interval Notation:[/b]
• [a, b]  closed (includes endpoints)
• (a, b)  open   (excludes endpoints)
• [a, ∞)  unbounded above

[b]Example:[/b]  f(x) = x²
• Domain: (−∞, ∞)
• Range:  [0, ∞)"""
	},

	# ── Sector 2 ──────────────────────────────────────────────────────────
	"quadratics": {
		"title": "Quadratic Functions  ax² + bx + c",
		"content": """[b]Standard Form:[/b]  [color=#ffcc00]f(x) = ax² + bx + c[/color]  (a ≠ 0)

[b]Shape:[/b] Parabola
• a > 0 → opens upward  (minimum)
• a < 0 → opens downward (maximum)

[b]Vertex Form:[/b]  f(x) = a(x − h)² + k
• h = −b / (2a)
• k = f(h) = c − b²/(4a)

[b]Example:[/b]
  f(x) = x² − 4x + 3
  Vertex: h = 2,  k = f(2) = −1  →  V(2, −1)"""
	},

	"vertex_form": {
		"title": "Vertex & Axis of Symmetry",
		"content": """[b]Vertex[/b]  V = (h, k)
The turning point of the parabola.

[b]Axis of Symmetry:[/b]  x = h = −b / (2a)

[b]Completing the Square:[/b]
  ax² + bx + c
  = a(x² + (b/a)x) + c
  = a(x + b/(2a))² − b²/(4a) + c

[b]Significance:[/b] The vertex gives the maximum or minimum value of the quadratic. This is the gravitational equilibrium point in Sector 2."""
	},

	"roots_discriminant": {
		"title": "Roots & the Discriminant",
		"content": """[b]Quadratic Formula:[/b]
  [color=#ffcc00]x = (−b ± √Δ) / (2a)[/color]
  where  Δ = b² − 4ac

[b]Discriminant Analysis:[/b]
• Δ > 0 → two distinct real roots
• Δ = 0 → one repeated root (tangent to x-axis)
• Δ < 0 → no real roots (complex conjugate pair)

[b]Boss Battle:[/b] To escape the gravity well, find the roots of the gravitational potential function. These are the escape coordinates!"""
	},

	# ── Sector 3 ──────────────────────────────────────────────────────────
	"function_types": {
		"title": "Types of Functions",
		"content": """[b]Constant:[/b]   f(x) = c       → horizontal line
[b]Linear:[/b]     f(x) = mx + b  → straight line
[b]Quadratic:[/b]  f(x) = ax²+bx+c → parabola
[b]Polynomial:[/b] f(x) = aₙxⁿ + … + a₀
[b]Rational:[/b]   f(x) = p(x)/q(x), q(x) ≠ 0
[b]Radical:[/b]    f(x) = ⁿ√(g(x))
[b]Exponential:[/b] f(x) = aˣ
[b]Logarithmic:[/b] f(x) = logₐ(x)
[b]Trigonometric:[/b] sin, cos, tan, …

[b]Piecewise:[/b]
  f(x) = { x²   if x < 0
           { 2x   if x ≥ 0"""
	},

	"shifts": {
		"title": "Shifts (Translations)",
		"content": """[b]Vertical Shift:[/b]   g(x) = f(x) + k
• k > 0 → up by k units
• k < 0 → down by |k| units

[b]Horizontal Shift:[/b]  g(x) = f(x − h)
• h > 0 → right by h units  (counter-intuitive!)
• h < 0 → left by |h| units

[b]Example:[/b]
  Base: f(x) = x²
  g(x) = (x − 3)² + 2  →  right 3, up 2

[b]Challenge:[/b] Tune the pulsar frequency by applying the correct shift to the base waveform."""
	},

	"scaling": {
		"title": "Scaling (Stretches & Compressions)",
		"content": """[b]Vertical Scale:[/b]    g(x) = a·f(x)
• |a| > 1 → vertical stretch
• 0 < |a| < 1 → vertical compression

[b]Horizontal Scale:[/b]  g(x) = f(b·x)
• |b| > 1 → horizontal compression
• 0 < |b| < 1 → horizontal stretch
• Note: b acts inversely on the x-axis

[b]Combined:[/b]  g(x) = a·f(b·x) + k"""
	},

	"reflections": {
		"title": "Reflections",
		"content": """[b]Reflection over X-axis:[/b]  g(x) = −f(x)
Every y-value changes sign: peaks become valleys.

[b]Reflection over Y-axis:[/b]  g(x) = f(−x)
The graph is mirrored left-right.

[b]Combined:[/b]  g(x) = −f(−x)  →  180° rotation

[b]Symmetry:[/b]
• Even function:  f(−x) =  f(x)  (symmetric about y-axis)
• Odd  function:  f(−x) = −f(x)  (symmetric about origin)"""
	},

	# ── Sector 4 ──────────────────────────────────────────────────────────
	"sum_difference": {
		"title": "Sum & Difference of Functions",
		"content": """Given f and g with domains D_f and D_g:

[b]Sum:[/b]        (f + g)(x) = f(x) + g(x)
[b]Difference:[/b] (f − g)(x) = f(x) − g(x)
[b]Domain:[/b]     D_f ∩ D_g

[b]Example:[/b]
  f(x) = x²,  g(x) = 3x − 1
  (f + g)(x) = x² + 3x − 1

[b]Application:[/b] Superimpose two waveforms to create the docking approach vector."""
	},

	"product_quotient": {
		"title": "Product & Quotient of Functions",
		"content": """[b]Product:[/b]  (f·g)(x) = f(x)·g(x)
[b]Quotient:[/b] (f/g)(x) = f(x)/g(x),  g(x) ≠ 0

[b]Quotient Domain:[/b]  D_f ∩ D_g \\ {x : g(x) = 0}

[b]Example:[/b]
  f(x) = x + 1,  g(x) = x − 1
  (f/g)(x) = (x+1)/(x−1),  x ≠ 1

Vertical asymptote at x = 1."""
	},

	"composition": {
		"title": "Function Composition  (f∘g)(x)",
		"content": """[b]Definition:[/b]
  [color=#ffcc00](f∘g)(x) = f(g(x))[/color]

Read as "f composed with g" or "f of g of x".

[b]Order matters:[/b]  f∘g ≠ g∘f  in general

[b]Domain of f∘g:[/b]
  {x ∈ D_g : g(x) ∈ D_f}

[b]Example:[/b]
  f(x) = √x,  g(x) = x² − 4
  (f∘g)(x) = √(x² − 4),  domain: |x| ≥ 2

[b]Boss Battle:[/b] The docking computer requires you to reverse-engineer a composite function to align the airlock."""
	},

	# ── Sector 5 ──────────────────────────────────────────────────────────
	"injectivity": {
		"title": "Injectivity (One-to-One Functions)",
		"content": """[b]Definition:[/b]
f is [color=#00ffcc]injective[/color] (one-to-one) iff:
  f(x₁) = f(x₂)  ⟹  x₁ = x₂

Equivalently: x₁ ≠ x₂  ⟹  f(x₁) ≠ f(x₂)

[b]Horizontal Line Test:[/b]
A function is injective iff every horizontal line intersects its graph at most once.

[b]Examples:[/b]
• f(x) = 2x + 1  → injective
• f(x) = x²       → NOT injective (f(2) = f(−2) = 4)
• f(x) = x³       → injective

[b]Why it matters:[/b] Only injective functions have inverses defined on their full domain."""
	},

	"inverses": {
		"title": "Inverse Functions  f⁻¹",
		"content": """[b]Definition:[/b]
If f is injective, its [color=#ffcc00]inverse[/color] f⁻¹ satisfies:
  f⁻¹(f(x)) = x  and  f(f⁻¹(y)) = y

[b]Finding f⁻¹ analytically:[/b]
  1. Write y = f(x)
  2. Solve for x in terms of y
  3. Swap x and y (optional, for standard notation)

[b]Example:[/b]
  f(x) = 3x − 2
  y = 3x − 2  →  x = (y + 2)/3
  f⁻¹(x) = (x + 2)/3

[b]Graph relationship:[/b]
The graph of f⁻¹ is the reflection of f over the line y = x.

[b]Boss Battle:[/b] The black hole's event horizon is defined by a function. To escape, input its inverse!"""
	},

	"exponentials": {
		"title": "Exponential Functions  aˣ",
		"content": """[b]Natural Exponential:[/b]  [color=#ffcc00]f(x) = eˣ[/color]
where  e ≈ 2.71828… (Euler's number)

[b]Properties:[/b]
• Domain: (−∞, ∞)
• Range:  (0, ∞)
• f(0) = 1,  f(1) = e
• Always positive, always increasing
• Horizontal asymptote: y = 0 as x → −∞

[b]Growth rate:[/b]
  (d/dx) eˣ = eˣ   (the exponential is its own derivative!)

[b]General base:[/b]  aˣ = eˣ·ln(a)"""
	},

	"logarithms": {
		"title": "Logarithms  log & ln",
		"content": """[b]Natural Logarithm:[/b]  [color=#ffcc00]y = ln(x)  ⟺  eʸ = x[/color]

[b]Properties:[/b]
• Domain: (0, ∞)
• Range:  (−∞, ∞)
• ln(1) = 0,  ln(e) = 1
• ln(ab) = ln(a) + ln(b)
• ln(aᵇ) = b·ln(a)
• ln is the inverse of eˣ

[b]Change of base:[/b]
  logₐ(x) = ln(x) / ln(a)

[b]Derivative:[/b]
  (d/dx) ln(x) = 1/x

[b]In Godot:[/b]  Use [color=#ffcc00]log(x)[/color] for natural log."""
	},

	"inverse_trig": {
		"title": "Inverse Trigonometric Functions",
		"content": """[b]arcsin:[/b]  y = arcsin(x)  ⟺  x = sin(y),  y ∈ [−π/2, π/2]
[b]arccos:[/b]  y = arccos(x)  ⟺  x = cos(y),  y ∈ [0, π]
[b]arctan:[/b]  y = arctan(x)  ⟺  x = tan(y),  y ∈ (−π/2, π/2)

[b]Domains:[/b]
• arcsin, arccos: [−1, 1]
• arctan: (−∞, ∞)

[b]Ranges:[/b] Restricted principal values above.

[b]In Godot:[/b]
• asin(x), acos(x), atan(x) — result in radians
• atan2(y, x) — full-circle arctangent

[b]Application:[/b] Calculate precise orbital insertion angles for the final boss battle."""
	},
}

# ---------------------------------------------------------------------------
# Private State
# ---------------------------------------------------------------------------

var _topic_keys: Array[String] = []
var _current_page: int = 0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_nav_prev.pressed.connect(_on_prev_pressed)
	_nav_next.pressed.connect(_on_next_pressed)
	visible = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Shows theory for the given sector index (loads all topics for that sector).
func show_sector_theory(sector_index: int) -> void:
	if sector_index < 1 or sector_index > GameManager.SECTORS.size():
		return
	var data: Dictionary = GameManager.SECTORS[sector_index - 1]
	_topic_keys.clear()
	_topic_keys.assign(data["topics"])
	_current_page = 0
	_update_display()
	visible = true


## Shows a specific theory topic by its key.
func show_topic(topic_key: String) -> void:
	if not THEORY.has(topic_key):
		push_warning("TheoryPanel: unknown topic key '%s'" % topic_key)
		return
	_topic_keys = [topic_key]
	_current_page = 0
	_update_display()
	visible = true


## Hides the theory panel.
func hide_panel() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

func _update_display() -> void:
	if _topic_keys.is_empty():
		return
	var key: String = _topic_keys[_current_page]
	if not THEORY.has(key):
		return
	var entry: Dictionary = THEORY[key]
	_title_label.text = entry["title"]
	_content_label.clear()
	_content_label.append_text(entry["content"])
	_page_label.text = "%d / %d" % [_current_page + 1, _topic_keys.size()]
	_nav_prev.disabled = _current_page == 0
	_nav_next.disabled = _current_page == _topic_keys.size() - 1


func _on_close_pressed() -> void:
	visible = false
	panel_closed.emit()


func _on_prev_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_display()


func _on_next_pressed() -> void:
	if _current_page < _topic_keys.size() - 1:
		_current_page += 1
		_update_display()
