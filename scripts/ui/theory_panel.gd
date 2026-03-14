## TheoryPanel.gd
## ===============
## Muestra teoría matemática a nivel universitario para cada tema de sector.
## Usa un RichTextLabel con BBCode para el formato.
class_name TheoryPanel
extends PanelContainer

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

signal panel_closed

# ---------------------------------------------------------------------------
# Referencias de Nodos
# ---------------------------------------------------------------------------

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _content_label: RichTextLabel = $VBox/ScrollContainer/ContentLabel
@onready var _close_button: Button = $VBox/CloseButton
@onready var _nav_prev: Button = $VBox/NavRow/PrevButton
@onready var _nav_next: Button = $VBox/NavRow/NextButton
@onready var _page_label: Label = $VBox/NavRow/PageLabel

# ---------------------------------------------------------------------------
# Base de Datos de Teoría
## Cada entrada: { "title": String, "content": String (BBCode) }
# ---------------------------------------------------------------------------

const THEORY: Dictionary = {
	# ── Sector 1 ──────────────────────────────────────────────────────────
	"intro_functions": {
		"title": "¿Qué es una Función?",
		"content": """[b]Definición[/b]
Una [color=#00ffcc]función[/color] [b]f : D → ℝ[/b] es una regla que asigna a cada elemento [b]x[/b] del dominio [b]D[/b] exactamente un valor [b]f(x)[/b] en el codominio.

[b]Notación formal:[/b]
  [color=#ffcc00]f(x) = expresión en términos de x[/color]

[b]Prueba de la Línea Vertical:[/b] Una curva en el plano es la gráfica de una función sii toda línea vertical la intersecta a lo sumo una vez.

[b]Ejemplo:[/b]
  f(x) = 2x + 3  → para x = 5,  f(5) = 13

[b]En Planet Waves:[/b] Ingresa la fórmula en el campo de entrada del HUD. La Line2D trazará tu función a lo largo del dominio actual."""
	},

	"linear_functions": {
		"title": "Funciones Lineales  y = mx + b",
		"content": """[b]Forma General:[/b]  [color=#ffcc00]f(x) = mx + b[/color]

[b]Parámetros:[/b]
• [b]m[/b] = pendiente = incremento/avance = (y₂ − y₁) / (x₂ − x₁)
• [b]b[/b] = ordenada al origen (valor cuando x = 0)

[b]Signo de la pendiente:[/b]
• m > 0 → creciente
• m < 0 → decreciente
• m = 0 → constante (línea horizontal)

[b]Forma Punto-Pendiente:[/b]  y − y₁ = m(x − x₁)

[b]Desafío:[/b] Navega por el cinturón de asteroides trazando una línea que pase por dos puntos de referencia dados."""
	},

	"domain_range": {
		"title": "Dominio y Rango",
		"content": """[b]Dominio D(f)[/b]
El conjunto de todas las entradas válidas x. Las restricciones surgen de:
• División por cero  →  x ≠ 0  para  f(x) = 1/x
• Raíces de índice par →  x ≥ 0  para  f(x) = √x
• Logaritmos          →  x > 0  para  f(x) = ln(x)

[b]Rango R(f)[/b]
El conjunto de todas las salidas alcanzables. Para encontrarlo, analiza el comportamiento de la función cuando x varía sobre su dominio.

[b]Notación de Intervalos:[/b]
• [a, b]  cerrado (incluye extremos)
• (a, b)  abierto  (excluye extremos)
• [a, ∞)  no acotado superiormente

[b]Ejemplo:[/b]  f(x) = x²
• Dominio: (−∞, ∞)
• Rango:   [0, ∞)"""
	},

	# ── Sector 2 ──────────────────────────────────────────────────────────
	"quadratics": {
		"title": "Funciones Cuadráticas  ax² + bx + c",
		"content": """[b]Forma Estándar:[/b]  [color=#ffcc00]f(x) = ax² + bx + c[/color]  (a ≠ 0)

[b]Forma:[/b] Parábola
• a > 0 → se abre hacia arriba  (mínimo)
• a < 0 → se abre hacia abajo  (máximo)

[b]Forma Vértice:[/b]  f(x) = a(x − h)² + k
• h = −b / (2a)
• k = f(h) = c − b²/(4a)

[b]Ejemplo:[/b]
  f(x) = x² − 4x + 3
  Vértice: h = 2,  k = f(2) = −1  →  V(2, −1)"""
	},

	"vertex_form": {
		"title": "Vértice y Eje de Simetría",
		"content": """[b]Vértice[/b]  V = (h, k)
El punto de inflexión de la parábola.

[b]Eje de Simetría:[/b]  x = h = −b / (2a)

[b]Completar el Cuadrado:[/b]
  ax² + bx + c
  = a(x² + (b/a)x) + c
  = a(x + b/(2a))² − b²/(4a) + c

[b]Importancia:[/b] El vértice proporciona el valor máximo o mínimo de la cuadrática. Representa el punto de equilibrio gravitacional en el Sector 2."""
	},

	"roots_discriminant": {
		"title": "Raíces y el Discriminante",
		"content": """[b]Fórmula Cuadrática:[/b]
  [color=#ffcc00]x = (−b ± √Δ) / (2a)[/color]
  donde  Δ = b² − 4ac

[b]Análisis del Discriminante:[/b]
• Δ > 0 → dos raíces reales distintas
• Δ = 0 → una raíz repetida (tangente al eje x)
• Δ < 0 → sin raíces reales (par conjugado complejo)

[b]Batalla Final:[/b] Para escapar del pozo gravitatorio, encuentra las raíces de la función de potencial gravitacional. ¡Esas son las coordenadas de escape!"""
	},

	# ── Sector 3 ──────────────────────────────────────────────────────────
	"function_types": {
		"title": "Tipos de Funciones",
		"content": """[b]Constante:[/b]    f(x) = c       → línea horizontal
[b]Lineal:[/b]       f(x) = mx + b  → línea recta
[b]Cuadrática:[/b]   f(x) = ax²+bx+c → parábola
[b]Polinomial:[/b]   f(x) = aₙxⁿ + … + a₀
[b]Racional:[/b]     f(x) = p(x)/q(x), q(x) ≠ 0
[b]Radical:[/b]      f(x) = ⁿ√(g(x))
[b]Exponencial:[/b]  f(x) = aˣ
[b]Logarítmica:[/b]  f(x) = logₐ(x)
[b]Trigonométrica:[/b] sen, cos, tan, …

[b]A Trozos (Piecewise):[/b]
  f(x) = { x²   si x < 0
           { 2x   si x ≥ 0"""
	},

	"shifts": {
		"title": "Desplazamientos (Traslaciones)",
		"content": """[b]Desplazamiento Vertical:[/b]   g(x) = f(x) + k
• k > 0 → sube k unidades
• k < 0 → baja |k| unidades

[b]Desplazamiento Horizontal:[/b]  g(x) = f(x − h)
• h > 0 → desplaza a la derecha h unidades  (¡contra-intuitivo!)
• h < 0 → desplaza a la izquierda |h| unidades

[b]Ejemplo:[/b]
  Base: f(x) = x²
  g(x) = (x − 3)² + 2  →  3 unidades a la derecha, 2 arriba

[b]Desafío:[/b] Ajusta la frecuencia del púlsar aplicando el desplazamiento correcto a la forma de onda base."""
	},

	"scaling": {
		"title": "Escalado (Estiramiento y Compresión)",
		"content": """[b]Escala Vertical:[/b]    g(x) = a·f(x)
• |a| > 1 → estiramiento vertical
• 0 < |a| < 1 → compresión vertical

[b]Escala Horizontal:[/b]  g(x) = f(b·x)
• |b| > 1 → compresión horizontal
• 0 < |b| < 1 → estiramiento horizontal
• Nota: b actúa de forma inversa sobre el eje x

[b]Combinado:[/b]  g(x) = a·f(b·x) + k"""
	},

	"reflections": {
		"title": "Reflexiones",
		"content": """[b]Reflexión sobre el eje X:[/b]  g(x) = −f(x)
Cada valor y cambia de signo: los máximos se vuelven mínimos.

[b]Reflexión sobre el eje Y:[/b]  g(x) = f(−x)
La gráfica se refleja de izquierda a derecha.

[b]Combinada:[/b]  g(x) = −f(−x)  →  rotación de 180°

[b]Simetría:[/b]
• Función par:   f(−x) =  f(x)  (simétrica respecto al eje y)
• Función impar: f(−x) = −f(x)  (simétrica respecto al origen)"""
	},

	# ── Sector 4 ──────────────────────────────────────────────────────────
	"sum_difference": {
		"title": "Suma y Diferencia de Funciones",
		"content": """Dadas f y g con dominios D_f y D_g:

[b]Suma:[/b]       (f + g)(x) = f(x) + g(x)
[b]Diferencia:[/b] (f − g)(x) = f(x) − g(x)
[b]Dominio:[/b]    D_f ∩ D_g

[b]Ejemplo:[/b]
  f(x) = x²,  g(x) = 3x − 1
  (f + g)(x) = x² + 3x − 1

[b]Aplicación:[/b] Superpone dos formas de onda para crear el vector de aproximación de acoplamiento."""
	},

	"product_quotient": {
		"title": "Producto y Cociente de Funciones",
		"content": """[b]Producto:[/b]  (f·g)(x) = f(x)·g(x)
[b]Cociente:[/b] (f/g)(x) = f(x)/g(x),  g(x) ≠ 0

[b]Dominio del Cociente:[/b]  D_f ∩ D_g \\ {x : g(x) = 0}

[b]Ejemplo:[/b]
  f(x) = x + 1,  g(x) = x − 1
  (f/g)(x) = (x+1)/(x−1),  x ≠ 1

Asíntota vertical en x = 1."""
	},

	"composition": {
		"title": "Composición de Funciones  (f∘g)(x)",
		"content": """[b]Definición:[/b]
  [color=#ffcc00](f∘g)(x) = f(g(x))[/color]

Se lee "f compuesta con g" o "f de g de x".

[b]El orden importa:[/b]  f∘g ≠ g∘f  en general

[b]Dominio de f∘g:[/b]
  {x ∈ D_g : g(x) ∈ D_f}

[b]Ejemplo:[/b]
  f(x) = √x,  g(x) = x² − 4
  (f∘g)(x) = √(x² − 4),  dominio: |x| ≥ 2

[b]Batalla Final:[/b] La computadora de acoplamiento requiere que deduzcas la función compuesta inversa para alinear la esclusa de aire."""
	},

	# ── Sector 5 ──────────────────────────────────────────────────────────
	"injectivity": {
		"title": "Inyectividad (Funciones Uno a Uno)",
		"content": """[b]Definición:[/b]
f es [color=#00ffcc]inyectiva[/color] (uno a uno) sii:
  f(x₁) = f(x₂)  ⟹  x₁ = x₂

Equivalentemente: x₁ ≠ x₂  ⟹  f(x₁) ≠ f(x₂)

[b]Prueba de la Línea Horizontal:[/b]
Una función es inyectiva sii toda línea horizontal intersecta su gráfica a lo sumo una vez.

[b]Ejemplos:[/b]
• f(x) = 2x + 1  → inyectiva
• f(x) = x²       → NO inyectiva (f(2) = f(−2) = 4)
• f(x) = x³       → inyectiva

[b]¿Por qué importa?[/b] Solo las funciones inyectivas tienen inversas definidas en todo su dominio."""
	},

	"inverses": {
		"title": "Funciones Inversas  f⁻¹",
		"content": """[b]Definición:[/b]
Si f es inyectiva, su [color=#ffcc00]inversa[/color] f⁻¹ satisface:
  f⁻¹(f(x)) = x  y  f(f⁻¹(y)) = y

[b]Encontrar f⁻¹ analíticamente:[/b]
  1. Escribir y = f(x)
  2. Despejar x en términos de y
  3. Intercambiar x e y (opcional, para notación estándar)

[b]Ejemplo:[/b]
  f(x) = 3x − 2
  y = 3x − 2  →  x = (y + 2)/3
  f⁻¹(x) = (x + 2)/3

[b]Relación gráfica:[/b]
La gráfica de f⁻¹ es el reflejo de f sobre la recta y = x.

[b]Batalla Final:[/b] El horizonte de sucesos del agujero negro está definido por una función. ¡Para escapar, ingresa su inversa!"""
	},

	"exponentials": {
		"title": "Funciones Exponenciales  aˣ",
		"content": """[b]Exponencial Natural:[/b]  [color=#ffcc00]f(x) = eˣ[/color]
donde  e ≈ 2.71828… (número de Euler)

[b]Propiedades:[/b]
• Dominio: (−∞, ∞)
• Rango:   (0, ∞)
• f(0) = 1,  f(1) = e
• Siempre positiva, siempre creciente
• Asíntota horizontal: y = 0 cuando x → −∞

[b]Tasa de crecimiento:[/b]
  (d/dx) eˣ = eˣ   (¡la exponencial es su propia derivada!)

[b]Base general:[/b]  aˣ = eˣ·ln(a)"""
	},

	"logarithms": {
		"title": "Logaritmos  log y ln",
		"content": """[b]Logaritmo Natural:[/b]  [color=#ffcc00]y = ln(x)  ⟺  eʸ = x[/color]

[b]Propiedades:[/b]
• Dominio: (0, ∞)
• Rango:   (−∞, ∞)
• ln(1) = 0,  ln(e) = 1
• ln(ab) = ln(a) + ln(b)
• ln(aᵇ) = b·ln(a)
• ln es la inversa de eˣ

[b]Cambio de base:[/b]
  logₐ(x) = ln(x) / ln(a)

[b]Derivada:[/b]
  (d/dx) ln(x) = 1/x

[b]En Godot:[/b]  Usa [color=#ffcc00]log(x)[/color] para el logaritmo natural."""
	},

	"inverse_trig": {
		"title": "Funciones Trigonométricas Inversas",
		"content": """[b]arcsen:[/b]  y = arcsen(x)  ⟺  x = sen(y),  y ∈ [−π/2, π/2]
[b]arccos:[/b]  y = arccos(x)  ⟺  x = cos(y),  y ∈ [0, π]
[b]arctan:[/b]  y = arctan(x)  ⟺  x = tan(y),  y ∈ (−π/2, π/2)

[b]Dominios:[/b]
• arcsen, arccos: [−1, 1]
• arctan: (−∞, ∞)

[b]Rangos:[/b] Valores principales restringidos indicados arriba.

[b]En Godot:[/b]
• asin(x), acos(x), atan(x) — resultado en radianes
• atan2(y, x) — arcotangente de círculo completo

[b]Aplicación:[/b] Calcula ángulos precisos de inserción orbital para la batalla final."""
	},
}

# ---------------------------------------------------------------------------
# Estado Privado
# ---------------------------------------------------------------------------

var _topic_keys: Array[String] = []
var _current_page: int = 0

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_nav_prev.pressed.connect(_on_prev_pressed)
	_nav_next.pressed.connect(_on_next_pressed)
	visible = false


# ---------------------------------------------------------------------------
# API Pública
# ---------------------------------------------------------------------------

## Muestra la teoría para el índice de sector dado (carga todos los temas de ese sector).
func show_sector_theory(sector_index: int) -> void:
	if sector_index < 1 or sector_index > GameManager.SECTORS.size():
		return
	var data: Dictionary = GameManager.SECTORS[sector_index - 1]
	_topic_keys.clear()
	_topic_keys.assign(data["topics"])
	_current_page = 0
	_update_display()
	visible = true


## Muestra un tema de teoría específico por su clave.
func show_topic(topic_key: String) -> void:
	if not THEORY.has(topic_key):
		push_warning("TheoryPanel: clave de tema desconocida '%s'" % topic_key)
		return
	_topic_keys = [topic_key]
	_current_page = 0
	_update_display()
	visible = true


## Oculta el panel de teoría.
func hide_panel() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Auxiliares Privados
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
