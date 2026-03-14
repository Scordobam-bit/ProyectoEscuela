# 🌊 Planet Waves

**An Educational Space-Exploration Game Teaching Mathematical Functions**

> From zero to university level — Inverses, Logs, Trigonometry.

---

## Overview

Planet Waves is a Godot 4.6 educational game where players pilot a spaceship through five cosmic sectors, each dedicated to a progressively deeper topic in the mathematics of functions. The ship's trajectory is defined by the player's own mathematical formulas, rendered in real time using a `FunctionPlotter` node powered by Godot's `Expression` class.

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Engine | Godot 4.6.1 (Stable) |
| Language | GDScript 2.0 (static typing throughout) |
| Math engine | Godot `Expression` class |
| Trajectory rendering | `Line2D` + `Path2D` |
| UI | Space-themed `CanvasLayer` HUD |
| Architecture | Signal-based decoupled nodes |

---

## Project Structure

```
Planet Waves/
├── project.godot                      # Godot 4.6 project configuration
├── icon.svg                           # Project icon
│
├── scenes/
│   ├── main_menu.tscn                 # Title screen with demo plotter
│   └── sectors/
│       ├── sector_1_asteroid_belt.tscn   # Lines & Functions
│       ├── sector_2_gravity_wells.tscn   # Quadratics
│       ├── sector_3_pulsar_tuner.tscn    # Transformations
│       ├── sector_4_docking_station.tscn # Operations & Composition
│       └── sector_5_event_horizon.tscn   # Inverses, Logs, Trig
│
└── scripts/
    ├── autoloads/
    │   ├── game_manager.gd            # Global state, sector nav, validation
    │   └── math_engine.gd             # Expression parser & math utilities
    ├── nodes/
    │   ├── function_plotter.gd        # ★ CORE — renders f(x) as Line2D
    │   └── ship_controller.gd         # Ship movement along trajectory
    ├── sectors/
    │   ├── sector_base.gd             # Abstract base for all sectors
    │   ├── sector_1.gd                # Asteroid Belt logic
    │   ├── sector_2.gd                # Gravity Wells logic
    │   ├── sector_3.gd                # Pulsar Tuner logic
    │   ├── sector_4.gd                # Docking Station logic
    │   └── sector_5.gd                # Event Horizon logic
    └── ui/
        ├── hud.gd                     # Space-themed HUD
        ├── theory_panel.gd            # University-level theory viewer
        └── main_menu_controller.gd    # Main menu buttons
```

---

## Core Architecture: `FunctionPlotter`

The heart of the game. Given a formula string and a domain range, it:

1. **Parses** the formula using Godot's `Expression` class with variable `x`.
2. **Samples** N points uniformly across `[domain_min, domain_max]`.
3. **Converts** math coordinates → screen coordinates (flipping the Y axis).
4. **Renders** the curve as a `Line2D` polyline, handling discontinuities.
5. **Exports** the trajectory as a `Path2D` for `PathFollow2D`-based ship movement.

```gdscript
# Example usage
var plotter := FunctionPlotter.new()
plotter.formula      = "sin(x) * x"
plotter.domain_min   = -2.0 * PI
plotter.domain_max   =  2.0 * PI
plotter.scale_factor = 60.0
add_child(plotter)
plotter.plot()

# Get Path2D for ship movement
var path: Path2D = plotter.build_path2d()
```

**Key signals:**
- `plot_completed(points: PackedVector2Array)` — fired on success
- `plot_failed(error_message: String)` — fired on parse/eval error

---

## Curriculum Sectors

| # | Name | Location | Topics | Boss Battle |
|---|------|----------|--------|-------------|
| 1 | **Asteroid Belt** | `sector_1.gd` | Intro to functions, `y=mx+b`, Domain & Range | Navigate waypoints with a precise linear formula |
| 2 | **Gravity Wells** | `sector_2.gd` | Quadratics, vertex form, discriminant, roots | Find the escape roots of a gravitational potential |
| 3 | **Pulsar Tuner** | `sector_3.gd` | Constant/rational/piecewise types; shifts, scaling, reflections | Match a mystery waveform with the right transformation chain |
| 4 | **Docking Station** | `sector_4.gd` | Sum, subtraction, quotient; function composition `f∘g` | Reverse-engineer a composite to align the airlock |
| 5 | **Event Horizon** | `sector_5.gd` | Injectivity, inverses `f⁻¹`, `eˣ`, `ln`, inverse trig | Input the inverse of a black hole's gravitational formula |

---

## Theory System

Each sector has a **Theory Panel** (press `📖 Theory` in the HUD) with university-level explanations in BBCode. Topics covered:

- What is a function? (formal definition, vertical line test)
- Linear functions and slope-intercept form
- Domain & range (interval notation, restrictions)
- Quadratic functions, vertex form, completing the square
- Quadratic formula and discriminant analysis
- Function types (constant, rational, piecewise, exponential, logarithmic, trig)
- Translations, scaling, reflections
- Function operations: sum, difference, product, quotient
- Composition `(f∘g)(x) = f(g(x))` — domain, non-commutativity
- Injectivity (one-to-one), horizontal line test
- Inverse functions — analytic derivation, graph symmetry over `y=x`
- Natural exponential `eˣ` and natural logarithm `ln(x)`
- Inverse trigonometric functions (arcsin, arccos, arctan)

---

## How to Run

1. Open **Godot 4.6.1** (stable).
2. Import the project: **Project → Import** → select the `project.godot` file.
3. Press **F5** or the Play button to start from the main menu.
4. Alternatively, open any sector scene directly and press **F6**.

---

## Formula Syntax

Planet Waves uses Godot's `Expression` class. Supported syntax:

| Math | GDScript / Expression |
|------|-----------------------|
| `x²` | `x^2` or `x*x` |
| `√x` | `sqrt(x)` |
| `eˣ` | `exp(x)` |
| `ln(x)` | `log(x)` |
| `sin(x)` | `sin(x)` |
| `arctan(x)` | `atan(x)` |
| `π` | `PI` |
| `2π` | `TAU` or `2*PI` |
| `\|x\|` | `abs(x)` |

---

## MathEngine API (Autoload)

```gdscript
# Evaluate at a point
MathEngine.evaluate("x^2 - 4", 3.0)           # → 5.0

# Composition
MathEngine.compose("sqrt(x)", "x^2 - 4")       # → "sqrt((x^2 - 4))"

# Quadratic formula
MathEngine.quadratic_formula(1.0, -5.0, 4.0)   # → {discriminant:9, roots:[1,4]}

# Numerical inverse
MathEngine.find_inverse("exp(x) - 2", 5.0)     # → ln(7) ≈ 1.946

# Injectivity check
MathEngine.check_injectivity("x^3")            # → {injective:true, monotone_increasing:true}
```

---

## Design Patterns

- **`@export` + setters with `auto_plot`** — FunctionPlotter re-renders in the editor whenever a property changes.
- **Signals for decoupling** — HUD, Plotter, Ship, and GameManager communicate exclusively through signals.
- **Static typing everywhere** — all variables declare their type (`var x: float`).
- **SectorBase pattern** — each sector extends `SectorBase` and only overrides `_setup_challenges()` and `_on_challenge_begin()`.

---

## Extending the Game

To add a new sector:
1. Create `scripts/sectors/sector_N.gd` extending `SectorBase`.
2. Override `_setup_challenges()` with your `_challenges` array.
3. Duplicate a sector `.tscn`, point the root script to your new `.gd`.
4. Register the sector in `GameManager.SECTORS`.
