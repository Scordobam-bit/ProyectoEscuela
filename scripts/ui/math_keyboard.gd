## MathKeyboard.gd
## ===============
## Teclado matemático virtual reutilizable para HUD y Laboratorio.
class_name MathKeyboard
extends PanelContainer

signal key_pressed(text: String)
signal close_requested

const MATH_DELIMITERS: Array[String] = ["+", "-", "*", "/", "^", "(", ")", " "]

const DEFAULT_LAYOUT: Array = [
	{
		"title": "Operaciones",
		"buttons": [
			["x²", "x^2"], ["xⁿ", "^"], ["√", "sqrt("], ["a/b", "/"], ["(", "("], [")", ")"],
		],
	},
	{
		"title": "Funciones",
		"buttons": [
			["sin", "sin("], ["cos", "cos("], ["tan", "tan("], ["log", "log("], ["ln", "log("], ["abs", "abs("],
		],
	},
	{
		"title": "Constantes",
		"buttons": [["x", "x"], ["e", "E"], ["π", "PI"]],
	},
]

var _layout: Array = DEFAULT_LAYOUT.duplicate(true)


func _ready() -> void:
	_apply_style()
	_rebuild()


func set_layout(layout: Array) -> void:
	_layout = layout.duplicate(true)
	if is_inside_tree():
		_rebuild()


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.14, 0.97)
	style.border_color = Color(0.0, 0.9, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	var header_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header_row)

	var title_lbl: Label = Label.new()
	title_lbl.text = "⌨ Teclado Matemático"
	title_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 2)
	header_row.add_child(title_lbl)

	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(42.0, 0.0)
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	header_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	for section in _layout:
		_add_section(vbox, section)


func _add_section(parent: VBoxContainer, section: Dictionary) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)

	var cat_lbl: Label = Label.new()
	cat_lbl.text = section.get("title", "") + ":"
	cat_lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 1.0, 0.9))
	cat_lbl.add_theme_font_size_override("font_size", 11)
	cat_lbl.custom_minimum_size = Vector2(185.0, 0.0)
	cat_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cat_lbl.add_theme_constant_override("outline_size", 2)
	row.add_child(cat_lbl)

	for btn_data: Array in section.get("buttons", []):
		var btn: Button = Button.new()
		btn.text = btn_data[0]
		var insert_text: String = btn_data[1]
		btn.tooltip_text = "Insertar: %s" % insert_text
		btn.custom_minimum_size = Vector2(66.0, 28.0)
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8, 1.0))
		btn.pressed.connect(func() -> void: key_pressed.emit(insert_text))
		row.add_child(btn)
