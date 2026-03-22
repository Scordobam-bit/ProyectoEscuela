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

	"composite_functions": {
		"title": "Funciones Compuestas y el Horizonte de Sucesos",
		"content": """[b]Función Compuesta:[/b]  [color=#ffcc00](f∘g)(x) = f(g(x))[/color]

[b]Algoritmo de Cálculo:[/b]
  1. Evalúa g(x) primero
  2. Usa el resultado como entrada de f
  3. El dominio es {x ∈ D_g : g(x) ∈ D_f}

[b]Horizonte de Sucesos — Función Gravitacional:[/b]
  f(x) = eˣ − 2   (función de escape del agujero negro)
  g(x) = ln(x + 2) (inversa de f)

[b]Función Compuesta Final:[/b]
  (f∘g)(x) = e^(ln(x+2)) − 2 = x + 2 − 2 = x
  ¡Confirma que f y g son inversas mutuas!

[b]Para estabilizar el Horizonte:[/b]
  Ingresa la composición simplificada: f(g(x)) = e^(ln(x+2)) − 2 = (x+2) − 2 = x
  La función compuesta f(f⁻¹(x)) = x representa la identidad — el punto de fuga."""
	},
}

# ---------------------------------------------------------------------------
# Briefings de Misión Inmersivos
# ---------------------------------------------------------------------------

## Diccionario de briefings lúdicos. Clave: "s{sector}_c{challenge}".
## Cada entrada: { "title": String, "content": String (BBCode) }
const MISSION_BRIEFINGS: Dictionary = {
	# ── Tutoriales obligatorios por sector ─────────────────────────────────
	"s1_tutorial": {
		"title": "🚀 Sector 1 — ¿Qué es una Función? (El Sistema de Navegación)",
		"content": """[b]Concepto:[/b]
Una [color=#00ffcc]función[/color] es una máquina: entra un número [b]X[/b], la máquina aplica una regla y sale un único [b]Y[/b].
Si una misma X tuviera dos Y diferentes, ¡la nave colapsaría!

[b]Regla clave:[/b] una sola salida por cada entrada.

[b]Cómo jugar:[/b]
Escribe tu primera función simple. Si escribes [color=#ffcc00]x[/color], la nave subirá un metro por cada metro que avance.

[i]Pulsa “EJECUTAR TRAYECTORIA” para iniciar la ruta.[/i]"""
	},
	"s2_tutorial": {
		"title": "🛰️ Sector 2 — El Dominio (El Mapa de Vuelo)",
		"content": """[b]Concepto:[/b]
El [color=#00ffcc]Dominio[/color] son todos los valores de X que la máquina puede procesar.
Con raíces cuadradas o divisiones hay zonas donde la nave no puede existir.

[b]Cómo jugar:[/b]
Observa el radar: hay valores de X no válidos.
Ajusta tu función para que la trayectoria pase solo por el dominio seguro."""
	},
	"s3_tutorial": {
		"title": "📈 Sector 3 — Funciones Lineales y Constantes",
		"content": """[b]Concepto:[/b]
Las funciones lineales son cables rectos.
La pendiente decide qué tan rápido subes o bajas.

[b]Cómo jugar:[/b]
Usa multiplicadores como [color=#ffcc00]2*x[/color] para esquivar asteroides en diagonal."""
	},
	"s4_tutorial": {
		"title": "🌙 Sector 4 — Potencias y Parábolas",
		"content": """[b]Concepto:[/b]
Las potencias como [color=#ffcc00]x²[/color] crean curvas (parábolas), ideales para rodear obstáculos circulares.

[b]Cómo jugar:[/b]
Usa el teclado matemático para elevar la X.
Una parábola te permite hacer giros suaves en U."""
	},
	"s5_tutorial": {
		"title": "🌀 Sector 5 — Funciones Racionales y Asíntotas",
		"content": """[b]Concepto:[/b]
Funciones como [color=#ffcc00]1/x[/color] crean muros invisibles llamados asíntotas.
La nave se acerca infinitamente, pero nunca las toca.

[b]Cómo jugar:[/b]
Escribe fracciones como [color=#ffcc00]x/(x+3)[/color] para navegar pasajes estrechos finales."""
	},

	# ── Sector 1 — Cinturón de Asteroides ────────────────────────────────
	"s1_c0": {
		"title": "⚠ BRIEFING DE MISIÓN — Cinturón de Asteroides #1",
		"content": """[color=#ffcc00][b]Alerta Nivel Alfa — Cinturón de Kolvar[/b][/color]

Capitán, nuestra nave ha entrado en el Cinturón de Asteroides de Kolvar. Los sensores detectan [color=#ff6622]fragmentos de roca a alta velocidad[/color] bloqueando nuestra ruta de escape.

[b]Situación:[/b]
Los asteroides forman una barrera. Solo hay un corredor seguro: la trayectoria lineal que pasa exactamente por los puntos de referencia A(−4, −3) y B(4, 5).

[b]Procedimiento:[/b]
1. Calcula la pendiente: [color=#00ffcc]m = (y₂ − y₁) / (x₂ − x₁)[/color]
2. Determina la ordenada al origen: [color=#00ffcc]b = y₁ − m·x₁[/color]
3. Ingresa la función lineal [color=#ffcc00]f(x) = mx + b[/color] en el HUD

[i]Si tu trayectoria impacta un asteroide, el escudo se desactivará. ¡Sé preciso![/i]

[b]Manuales de Referencia:[/b] Consulta la sección «Funciones Lineales» abajo."""
	},
	"s1_c1": {
		"title": "⚠ BRIEFING DE MISIÓN — Cinturón de Asteroides #2",
		"content": """[color=#ffcc00][b]Sector Densificado — Corredor Omega[/b][/color]

Capitán, los sensores de navegación requieren calibración manual. El sistema de autopiloto necesita una función con parámetros específicos:

[b]Especificaciones de Trayectoria:[/b]
• [color=#ff6622]Pendiente requerida:[/color] −2 (descenso pronunciado)
• [color=#ff6622]Ordenada al origen:[/color] 3 (cruce del eje vertical en y = 3)

[b]Procedimiento:[/b]
Ingresa directamente la función lineal con estos valores de m y b.
Recuerda: [color=#00ffcc]f(x) = m·x + b[/color]

[i]Los asteroides flanquean el corredor — solo la pendiente y ordenada exactas te sacarán ileso.[/i]"""
	},
	"s1_c2": {
		"title": "🔴 JEFE — Cinturón de Asteroides: ¡Evasión Total!",
		"content": """[color=#ff3300][b]ALERTA MÁXIMA — Enjambre de Asteroides Denso[/b][/color]

¡Capitán, el enjambre principal bloquea TODA la ruta! Es el cinturón más denso jamás registrado en los archivos del Consejo Galáctico.

[b]Vector de Escape:[/b]
Los ingenieros de vuelo han calculado que la única ruta viable pasa por el punto (0, −5) con una inclinación de [color=#ffcc00]3/2[/color].

[b]Procedimiento:[/b]
1. La ordenada al origen es directamente legible: b = −5
2. La pendiente es la fracción 3/2 = [color=#00ffcc]1.5[/color]
3. Ingresa: [color=#ffcc00]f(x) = 1.5·x − 5[/color]

[color=#ff3300][b]¡No hay tiempo! Cada segundo nos acerca más al núcleo del cinturón.[/b][/color]

¡Al saltar al hiperespacial se abrirá el Sector 2: Pozos Gravitatorios!"""
	},

	# ── Sector 2 — Pozos Gravitatorios ───────────────────────────────────
	"s2_c0": {
		"title": "⚠ BRIEFING DE MISIÓN — Pozos Gravitatorios #1",
		"content": """[color=#aa44ff][b]Anomalía Gravitacional Detectada — Cuadrícula 7-Gamma[/b][/color]

Capitán, hemos caído bajo la influencia de un campo gravitatorio parabólico. Los sensores muestran que la curvatura del espacio-tiempo sigue la función:

[b]Potencial Gravitacional:[/b]  [color=#ffcc00]f(x) = x² − 4[/color]

Para mapear con precisión el campo y planear la ruta de escape, necesitamos que la computadora de navegación grafique esta parábola exactamente.

[b]Procedimiento:[/b]
Ingresa la función cuadrática tal como está definida en los sensores.

[b]Manuales de Referencia:[/b] Sección «Funciones Cuadráticas» — forma ax² + bx + c.

[i]El pozo gravitatorio visualmente indica las zonas de atracción máxima. ¡Mantente alejado del vértice![/i]"""
	},
	"s2_c1": {
		"title": "⚠ BRIEFING DE MISIÓN — Pozos Gravitatorios #2",
		"content": """[color=#aa44ff][b]Cálculo del Punto de Equilibrio Orbital[/b][/color]

Capitán, para insertar la nave en una órbita de escape estable alrededor del pozo gravitacional, los ingenieros necesitan conocer el [color=#ffcc00]punto de equilibrio[/color]: el vértice de la función de potencial.

[b]Función de Potencial:[/b]  [color=#ffcc00]f(x) = 2x² − 8x + 5[/color]

El vértice define el [color=#00ffcc]eje de simetría del pozo[/color]. Ingresa únicamente la coordenada x del vértice como función constante.

[b]Fórmula del Vértice:[/b]  [color=#ffcc00]h = −b / (2a)[/color]

[i]Identifica a, b, c en la ecuación y aplica la fórmula. ¡El tiempo de cómputo es limitado![/i]"""
	},
	"s2_c2": {
		"title": "🔴 JEFE — Pozos Gravitatorios: ¡Velocidad de Escape!",
		"content": """[color=#ff3300][b]ALERTA CRÍTICA — Captura Gravitacional Inminente[/b][/color]

¡Capitán, la nave está siendo jalada hacia el núcleo del pozo! La gravedad del potencial:
[color=#ffcc00][b]g(x) = x² − 5x + 4[/b][/color]

Solo podemos escapar pasando por los [color=#00ffcc]puntos de cruce con el eje x[/color] — las raíces — donde la energía gravitacional es CERO.

[b]Procedimiento:[/b]
Aplica la fórmula cuadrática con a=1, b=−5, c=4.
Ingresa la raíz MENOR como función constante.

[color=#ff3300][b]¡Los pozos gravitatorios están marcados en rojo! Solo las raíces correctas abren el corredor de escape.[/b][/color]"""
	},

	# ── Sector 3 — Sintonizador de Púlsares ──────────────────────────────
	"s3_c0": {
		"title": "⚠ BRIEFING DE MISIÓN — Sintonizador de Púlsares #1",
		"content": """[color=#ff44cc][b]Interferencia de Señal de Púlsar — Zona Kappa[/b][/color]

Capitán, la nave ha entrado en el campo de radiación del Púlsar KX-7. Su emisión bloquea todas las comunicaciones. Para [color=#ffcc00]sintonizar nuestra frecuencia[/color] y pasar a través de su zona de exclusión, debemos igualar su patrón de onda.

[b]Función Base del Púlsar:[/b]  [color=#00ffcc]sin(x)[/color]

[b]Transformación Requerida:[/b]
• Desplazar a la DERECHA por π
• Desplazar hacia ARRIBA por 2

[b]Fórmula de Desplazamiento:[/b]
  [color=#ffcc00]g(x) = sin(x − h) + k[/color]

Identifica h y k para las transformaciones requeridas.

[b]Manuales de Referencia:[/b] Sección «Desplazamientos» — traslaciones horizontal/vertical."""
	},
	"s3_c1": {
		"title": "⚠ BRIEFING DE MISIÓN — Sintonizador de Púlsares #2",
		"content": """[color=#ff44cc][b]Inversión de Amplitud — Protocolo de Cancelación[/b][/color]

Capitán, el Púlsar Delta-9 emite en una frecuencia comprimida e invertida. Para cancelar su interferencia y abrirse paso, la nave debe emitir la [color=#ffcc00]señal anti-fase[/color] exacta.

[b]Señal Base:[/b]  [color=#00ffcc]cos(x)[/color]

[b]Transformaciones Requeridas:[/b]
• Comprimir verticalmente por factor [color=#ffcc00]0.5[/color]
• Reflejar sobre el eje x (invertir la señal)

[b]Procedimiento:[/b]
  Escala vertical: a·f(x) con a = 0.5
  Reflexión eje x: negar el resultado
  Resultado: [color=#ffcc00]g(x) = −(0.5·cos(x))[/color]"""
	},
	"s3_c2": {
		"title": "🔴 JEFE — Púlsar Misterioso: ¡Sincronización Total!",
		"content": """[color=#ff3300][b]ALERTA MÁXIMA — Pulsar Omega Desconocido[/b][/color]

¡Capitán, un púlsar de clasificación desconocida bloquea el salto al hiperespacial! Su forma de onda aparece en [color=#aa44ff]MORADO[/color] en la pantalla.

[b]Tu misión:[/b] Analizar visualmente la forma de onda e ingresar la función que la reproduce exactamente.

[b]Pistas de Análisis:[/b]
• [color=#ffcc00]Amplitud:[/color] distancia desde el centro hasta el pico
• [color=#ffcc00]Período:[/color] P = 2π/b (¿cuánto espacio ocupa un ciclo completo?)
• [color=#ffcc00]Desplazamiento vertical:[/color] ¿está centrada en y=0?

[color=#ff3300][b]¡Solo una función matemáticamente idéntica sincronizará con el púlsar y abrirá el corredor de escape![/b][/color]"""
	},

	# ── Sector 4 — Estación de Acoplamiento ──────────────────────────────
	"s4_c0": {
		"title": "⚠ BRIEFING DE MISIÓN — Estación de Acoplamiento #1",
		"content": """[color=#00cc44][b]Solicitud de Acoplamiento — Puerto Alfa-7[/b][/color]

Capitán, la Estación Espacial Kepler-IV solicita acoplamiento. El sistema de guía automática requiere que nuestras computadoras calculen el [color=#ffcc00]vector de aproximación combinado[/color].

[b]Funciones del Sistema:[/b]
  f(x) = x²       (curvatura de la bahía de acoplamiento)
  g(x) = 3x − 1   (vector lineal de aproximación)

[b]Vector Combinado:[/b]  [color=#ffcc00](f + g)(x) = f(x) + g(x)[/color]

Suma algebraicamente las dos funciones para obtener el trayecto de acoplamiento.

[b]Manuales de Referencia:[/b] Sección «Suma y Diferencia de Funciones»."""
	},
	"s4_c1": {
		"title": "⚠ BRIEFING DE MISIÓN — Estación de Acoplamiento #2",
		"content": """[color=#00cc44][b]Verificación de Razón de Transferencia de Combustible[/b][/color]

Capitán, antes de completar el acoplamiento, el ingeniero de sistemas requiere calcular la razón de transferencia de combustible entre dos depósitos.

[b]Funciones:[/b]
  f(x) = x + 1   (depósito principal)
  g(x) = x − 1   (depósito auxiliar)

[b]Razón de Transferencia:[/b]  [color=#ffcc00](f/g)(x) = f(x) / g(x)[/color]

[color=#ff6622]⚠ Advertencia:[/color] Existe un valor prohibido donde la división no está definida. Identifica la [color=#ffcc00]asíntota vertical[/color] en tu respuesta.

[i]Una división por cero crearía un bucle de retroalimentación que podría desestabilizar los sistemas de la estación.[/i]"""
	},
	"s4_c2": {
		"title": "🔴 JEFE — Esclusa de Aire: ¡Función Compuesta!",
		"content": """[color=#ff3300][b]EMERGENCIA — Sistema de Esclusa Bloqueado[/b][/color]

¡Capitán, la esclusa de aire de la estación está bloqueada por un fallo de software! El sistema de desbloqueo requiere la evaluación de una [color=#ffcc00]función compuesta[/color].

[b]Funciones de Desbloqueo:[/b]
  f(x) = √x         (función de raíz cuadrada)
  g(x) = x² − 4     (función del sensor de presión)

[b]Código de Desbloqueo:[/b]  [color=#ffcc00](f∘g)(x) = f(g(x))[/color]

[b]Procedimiento:[/b]
  1. Identifica g(x)
  2. Sustituye g(x) dentro de f: f(g(x)) = √(g(x))
  3. Ingresa la función compuesta completa

[color=#ff3300][b]¡El tiempo de vida de la esclusa es limitado! Calcula la composición y transmite el código.[/b][/color]

[b]Manuales de Referencia:[/b] Sección «Composición de Funciones»."""
	},

	# ── Sector 5 — Horizonte de Sucesos ──────────────────────────────────
	"s5_c0": {
		"title": "⚠ BRIEFING DE MISIÓN — Horizonte de Sucesos #1",
		"content": """[color=#ff2222][b]ZONA DE NO RETORNO — Agujero Negro Cygnus-X[/b][/color]

Capitán, ¡hemos cruzado peligrosamente cerca del Horizonte de Sucesos de Cygnus-X! Esta es la región donde el espacio-tiempo pierde su [color=#ffcc00]inyectividad[/color] — el punto de no retorno matemático.

[b]Primera Prueba:[/b]
Para calibrar los escudos de distorsión, necesitamos determinar si la función gravitacional x³ es inyectiva en nuestro sector.

[b]Procedimiento:[/b]
• Aplica la Prueba de la Línea Horizontal
• Responde: '1' = Sí, la función es inyectiva
•           '0' = No, la función NO es inyectiva

[b]Manuales de Referencia:[/b] Sección «Inyectividad» — funciones uno a uno.

[i]De la inyectividad depende si existe una función inversa para escapar del horizonte.[/i]"""
	},
	"s5_c1": {
		"title": "⚠ BRIEFING DE MISIÓN — Horizonte de Sucesos #2",
		"content": """[color=#ff2222][b]Cálculo de Trayectoria de Escape — Módulo Inverso[/b][/color]

Capitán, el módulo de escape requiere la [color=#ffcc00]función inversa[/color] del vector de atracción gravitacional para computar la ruta de salida.

[b]Función de Atracción:[/b]  [color=#ffcc00]f(x) = 2x + 4[/color]

[b]Procedimiento para Hallar la Inversa:[/b]
  1. Escribe y = 2x + 4
  2. Despeja x: x = (y − 4) / 2
  3. Intercambia x e y para la notación estándar
  4. Ingresa f⁻¹(x)

[b]Verificación Visual:[/b] La gráfica de f⁻¹ debe ser el reflejo de f sobre la línea y = x (la línea gris en pantalla).

[i]La función inversa nos indica exactamente cómo revertir el efecto gravitacional.[/i]"""
	},
	"s5_c2": {
		"title": "⚠ BRIEFING DE MISIÓN — Horizonte de Sucesos #3",
		"content": """[color=#ff2222][b]Inversión Logarítmica — Contención del Campo Exponencial[/b][/color]

Capitán, los generadores de campo del agujero negro emiten radiación exponencial según la función:

[b]Función de Radiación:[/b]  [color=#ffcc00]f(x) = eˣ − 2[/color]

Los ingenieros confirman que la [color=#00ffcc]función logarítmica natural[/color] es la inversa exacta de la exponencial.

[b]Procedimiento:[/b]
  f(x) = eˣ − 2
  Para hallar la inversa: y = eˣ − 2  →  eˣ = y + 2  →  x = ln(y + 2)
  Por tanto: [color=#ffcc00]f⁻¹(x) = ln(x + 2)[/color]

[b]En Godot:[/b]  ln(x) se escribe como [color=#ffcc00]log(x)[/color]

[b]Manuales de Referencia:[/b] Secciones «Exponenciales» y «Logaritmos»."""
	},
	"s5_c3": {
		"title": "🔴 BATALLA FINAL — Horizonte de Sucesos: ¡Estabilización Total!",
		"content": """[color=#ff0000][b]⚡ PROTOCOLO DE EMERGENCIA OMEGA — TODOS LOS SISTEMAS[/b][/color]

¡CAPITÁN! El núcleo del agujero negro Cygnus-X ha comenzado a colapsar. El Horizonte de Sucesos se está expandiendo. En minutos todo el sistema quedará atrapado.

[b]Fórmula Gravitacional del Agujero Negro:[/b]
  [color=#ff4444][b]f(x) = eˣ − 2[/b][/color]

La única forma de contrarrestar su fuerza es generar el [color=#00ff88]campo de contra-gravedad inverso[/color]:

[b]Función de Escape:[/b]  [color=#00ff88][b]f⁻¹(x) = ln(x + 2)[/b][/color]

Esta es la INVERSA EXACTA de la gravedad del agujero negro. Al ingresar esta función, los motores de distorsión generarán un campo opuesto que [color=#00ffcc]cancela la atracción gravitacional[/color] y estabiliza el Horizonte de Sucesos.

[color=#ffcc00][b]Recuerda: ln(x + 2) → en Godot escribe:  log(x + 2)[/b][/color]

[color=#ff3300][b]¡Esta es tu última oportunidad, Capitán! El destino de Planet Waves depende de ti.[/b][/color]"""
	},
	"s5_c4": {
		"title": "⚡ SECUENCIA FINAL — Función Compuesta del Horizonte",
		"content": """[color=#ff0000][b]PROTOCOLO SIGMA — COMPOSICIÓN TRASCENDENTAL[/b][/color]

¡Capitán! Un segundo pliegue dimensional emerge del núcleo. El Consejo Galáctico transmite el protocolo definitivo:

[b]Función de Transformación:[/b]     [color=#00ff88]f(x) = ln(x)[/color]  → en Godot: [color=#ffcc00]log(x)[/color]
[b]Función de Campo Gravitacional:[/b] [color=#ff8844]g(x) = eˣ + 2[/color]  → en Godot: [color=#ffcc00]exp(x) + 2[/color]

Para estabilizar el Horizonte de Sucesos, calcula la [color=#ffcc00]función compuesta[/color]:

[b][color=#ffcc00](f∘g)(x) = f(g(x)) = ln(eˣ + 2)[/color][/b]

[b]Pasos:[/b]
1. Sustituye g(x) dentro de f:  f(g(x)) = ln(g(x))
2. Reemplaza g(x) = eˣ + 2:    f(g(x)) = ln(eˣ + 2)

[b]Tu misión:[/b] Ingresa la función compuesta resultante:
  [color=#ffcc00][b]log(exp(x) + 2)[/b][/color]

[color=#ff3300][b]¡La composición perfecta estabilizará el Horizonte y salvará Planet Waves![/b][/color]"""
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

## Muestra un briefing de misión lúdico antes de un desafío con animación de deslizamiento.
## briefing_key : clave del diccionario MISSION_BRIEFINGS (ej. "s1_c0").
## Si la clave no existe, no hace nada.
func show_mission_briefing(briefing_key: String) -> void:
	if not MISSION_BRIEFINGS.has(briefing_key):
		return
	var entry: Dictionary = MISSION_BRIEFINGS[briefing_key]
	_title_label.text = entry["title"]
	_content_label.clear()
	_content_label.append_text(entry["content"])
	_page_label.text = "Briefing"
	_nav_prev.disabled = true
	_nav_next.disabled = true
	_show_animated()


## Muestra la teoría para el índice de sector dado (carga todos los temas de ese sector).
func show_sector_theory(sector_index: int) -> void:
	if sector_index < 1 or sector_index > GameManager.SECTORS.size():
		return
	var data: Dictionary = GameManager.SECTORS[sector_index - 1]
	_topic_keys.clear()
	_topic_keys.assign(data["topics"])
	_current_page = 0
	_update_display()
	_show_animated()


## Muestra un tema de teoría específico por su clave.
func show_topic(topic_key: String) -> void:
	if not THEORY.has(topic_key):
		push_warning("TheoryPanel: clave de tema desconocida '%s'" % topic_key)
		return
	_topic_keys = [topic_key]
	_current_page = 0
	_update_display()
	_show_animated()


## Oculta el panel de teoría.
func hide_panel() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Auxiliares Privados
# ---------------------------------------------------------------------------

## Desplazamiento vertical (en píxeles) para la animación de deslizamiento del panel.
## El panel comienza fuera de pantalla por esta distancia hacia arriba antes de deslizarse.
const SLIDE_OFFSET: float = 560.0

## Duración de la animación de deslizamiento de entrada en segundos.
const SLIDE_DURATION: float = 0.35

## Duración de la animación de fundido de entrada en segundos.
const FADE_DURATION: float = 0.25


## Muestra el panel con una animación de deslizamiento desde la parte superior.
## Da un toque de tecnología espacial moderno a la interfaz educativa.
func _show_animated() -> void:
	# Posicionar el panel fuera de la pantalla hacia arriba antes de mostrarlo
	var original_pos: Vector2 = position
	position = Vector2(position.x, position.y - SLIDE_OFFSET)
	modulate.a = 0.0
	visible = true

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", original_pos, SLIDE_DURATION)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)


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
