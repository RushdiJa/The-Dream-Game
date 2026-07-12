extends Label

@onready var timer = $"../../Timer"
func _ready():
	add_theme_font_size_override("font_size", 40)

	add_theme_color_override("font_color", Color.RED)

	add_theme_constant_override("outline_size", 5)
	add_theme_color_override("font_outline_color", Color.BLACK)


func _process(_delta):
	var t := int(timer.time_left)
	text = "%02d:%02d" % [t / 60, t % 60]
