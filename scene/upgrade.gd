extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# ترجيع كل الإعدادات للطبيعي
		body.cur = "2"  # غيرها للقيمة الأصلية
		body.max_jumps = 100000  # غيرها لعدد القفزات الأصلي
		
		# ترجيع الإضاءة
		var modulate = get_tree().current_scene.get_node_or_null("CanvasModulate")
		if modulate:
			modulate.color = Color.WHITE
		
		# ترجيع صوت النطة
		if body.has_node("jumpSound"):
			body.jumpSound.volume_db = 0
		
		# إعادة تشغيل الموسيقى
		var music = body.get_node_or_null("AudioStreamPlayer2D")
		if music and not music.playing:
			music.play()
		var timer = get_tree().current_scene.get_node_or_null("Timer")
		if timer:
			timer.wait_time = 75.0
			timer.start()
		body.global_position = Vector2(0, -1000)
