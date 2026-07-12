extends Area2D

@onready var anim = $AnimatedSprite2D
@export var bounce_force := -600.0  # تحديد النوع كـ float

func _ready():
	body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)

func _on_body_entered(body):
	if body is CharacterBody2D:
		# تغيير مباشر للسرعة العمودية
		body.velocity.y = bounce_force
		# إيقاف أي حركة هابطة
		if body.velocity.y > 0:
			body.velocity.y = 0
		anim.stop()
		anim.play("jump")

func _on_animation_finished(anim_name):
	if anim_name == "jump":
		anim.play("idle")
