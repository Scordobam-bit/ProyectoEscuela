# ProyectoEscuela (Godot 4.x)

Juego educativo en Godot 4.x donde la trayectoria de la nave se define con funciones matemáticas ingresadas por el jugador.

## Funciones y sintaxis soportadas

### Variable y operadores
- Variable: `x`
- Operadores: `+`, `-`, `*`, `/`, `^`
- Potencia: `a^b` se reescribe internamente como `pow(a, b)` antes de evaluar.

### Funciones matemáticas
- Trigonométricas: `sin(x)`, `cos(x)`, `tan(x)`
- Trigonométricas inversas: `asin(x)`, `acos(x)`, `atan(x)`
- Alias aceptados: `arcsin(x)`, `arccos(x)`, `arctan(x)` (normalizados a `asin/acos/atan`)
- Logaritmos:
  - Natural: `log(x)` (también `ln(x)`, alias a `log(x)`)
  - Con base: `log(base, x)` (reescritura obligatoria por cambio de base):
    - `log(base, x) = log(x) / log(base)`
- Otras: `sqrt(x)`, `exp(x)`, `abs(x)`, `pow(a,b)`

### Constantes
- `PI`
- `E`
- `TAU`

## Flujo técnico del sistema (UI → lógica de juego)

1. **UI (HUD)**
   - El jugador escribe la fórmula en `LineEdit`.
   - El botón **EJECUTAR TRAYECTORIA** emite señales por código (en `_ready()`), sin depender de conexiones del editor.
   - Nodos no interactivos del HUD usan `mouse_filter = MOUSE_FILTER_IGNORE` para no bloquear clics.

2. **MathEngine**
   - Recibe la fórmula y ejecuta un pipeline de normalización:
     - Alias de funciones (`ln`, `arcsin/arccos/arctan`)
     - Constantes (`PI`, `E`, `TAU`)
     - `log(base,x)` por cambio de base
     - `^` a `pow(a,b)` de forma robusta
   - Evalúa con `Expression.parse()` y `Expression.execute()` en modo seguro.
   - `evaluate()` devuelve:
     - `{"ok": bool, "value": Variant, "error": String}`

3. **Graficación**
   - `FunctionPlotter` usa la fórmula normalizada para generar puntos de trayectoria.
   - También puede construir un `Path2D` para movimiento continuo.

4. **Movimiento de nave**
   - `ShipController` sigue la trayectoria con `PathFollow2D`.
   - La nave se añade al grupo `player_ship`.
   - Antes de iniciar el vuelo, la nave se teletransporta al primer punto de la curva para evitar saltos visuales.
   - Al terminar el recorrido sin colisión con el portal, emite `trajectory_completed` para que el sector gestione "Trayectoria Fallida" y reset.

5. **Colisión y desbloqueo**
   - Cada sector usa `MetaArea` (`Area2D`) para detectar entrada de cuerpos del grupo `player_ship`.
   - `SectorBase` conecta `body_entered` por código en `_ready()`.
   - Al detectar la nave, llama `GameManager.unlock_next_level()`.

6. **Progresión**
   - `GameManager` define las escenas en orden y avanza al siguiente sector.
   - Si no hay más sectores, vuelve al menú principal.

## Estructura principal

- `scripts/ui/hud.gd`
- `scripts/autoloads/math_engine.gd`
- `scripts/nodes/function_plotter.gd`
- `scripts/nodes/ship_controller.gd`
- `scripts/sectors/sector_base.gd`
- `scripts/autoloads/game_manager.gd`

## Pruebas mínimas esperadas

- `MathEngine.evaluate("2^3", 0.0)` debe producir `{"ok": true, "value": 8.0, ...}`
- `MathEngine.evaluate("log(2, 8)", 0.0)` debe producir `{"ok": true, "value": 3.0, ...}`
- En caso de error de parseo/ejecución, `evaluate()` devuelve `ok=false` con `error` descriptivo y una salida segura.
