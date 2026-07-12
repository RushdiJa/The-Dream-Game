extends Area2D

var triggered = false  # متغير للتأكد إنها اشتغلت مرة واحدة

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not triggered:
		triggered = true  # نخليها true عشان ما تشتغلش تاني
		
		# 1. تطفي الأغاني
		var music_player = body.get_node_or_null("AudioStreamPlayer2D")
		if music_player:
			music_player.stop()
		
		var scene_music = get_tree().current_scene.get_node_or_null("AudioStreamPlayer2D")
		if scene_music:
			scene_music.stop()
		
		# 2. تطفي صوت النطة وتخلي音量 صفر
		if body.has_node("jumpSound"):
			body.jumpSound.stop()
			body.jumpSound.volume_db = -80  # صفر (صامت تماماً)
		
		# 3. تخفيف الإضاءة للرعب
		var modulate = get_tree().current_scene.get_node_or_null("CanvasModulate")
		if not modulate:
			modulate = CanvasModulate.new()
			modulate.name = "CanvasModulate"
			get_tree().current_scene.add_child(modulate)
		
		# لون رعب (إضاءة 10% فقط)
		modulate.color = Color(0.1, 0.1, 0.15)
		
		#var original_speed = body.camera.position_smoothing_speed
		#body.camera.position_smoothing_speed = 10000  # سرعة فائقة
		
		body.global_position = Vector2(-6100, -10)
		
		await get_tree().create_timer(0.2).timeout
		#body.camera.position_smoothing_speed = original_speed  # رجع السرعة الأصلية
		
		# 4. تعطيل المنطقة بالكامل (اختياري)
		set_deferred("monitoring", false)  # يوقف استقبال الإشارات
