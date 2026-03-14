## MainMenuController.gd
## ======================
## Handles main menu button interactions.
extends Control

@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _sector2_button: Button = $VBoxContainer/Sector2Button
@onready var _sector3_button: Button = $VBoxContainer/Sector3Button
@onready var _sector4_button: Button = $VBoxContainer/Sector4Button
@onready var _sector5_button: Button = $VBoxContainer/Sector5Button

func _ready() -> void:
_start_button.pressed.connect(func() -> void: GameManager.go_to_sector(1))
_sector2_button.pressed.connect(func() -> void: GameManager.go_to_sector(2))
_sector3_button.pressed.connect(func() -> void: GameManager.go_to_sector(3))
_sector4_button.pressed.connect(func() -> void: GameManager.go_to_sector(4))
_sector5_button.pressed.connect(func() -> void: GameManager.go_to_sector(5))
