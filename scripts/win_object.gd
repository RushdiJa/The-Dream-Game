extends Area2D

@onready var win_label = $WinLable   # تأكد الاسم مطابق تمامًا لاسم الـ Node بالـ Scene Tree

var already_won = false


func _ready():
	body_entered.connect(_on_body_entered)
	win_label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player") and not already_won:
		already_won = true
		win_label.visible = true
		get_tree().paused = true
