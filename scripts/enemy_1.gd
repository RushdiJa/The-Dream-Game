extends CharacterBody2D

# --- Movement ---
@export var min_chase_speed: float = 120.0
@export var max_chase_speed: float = 200.0
@export var detection_range: float = 400.0
@export var jump_chance: float = 0.25
@export var direction_accuracy: float = 0.9  # احتمال 90% ياخذ الاتجاه الصح نحو اللاعب

const ACCELERATION = 1200.0
const JUMP_VELOCITY = -350.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var chase_speed: float  # تتحدد عشوائيًا لكل عدو عند البداية
var player_ref: Node2D = null
var facing_dir = 1
var has_rolled_jump = false

# متغيرات العشوائية بالاتجاه
var current_direction_sign = 1.0
var direction_reroll_timer = 0.0
const DIRECTION_REROLL_TIME = 1.0  # كل ثانية يعيد حساب هل ياخذ اتجاه صح أو عشوائي

@onready var animated_sprite = $AnimatedSprite2D
@onready var catch_area = $CatchArea


func _ready():
	catch_area.body_entered.connect(_on_catch_area_body_entered)
	call_deferred("_find_player")

	# كل عدو ياخذ سرعة عشوائية مختلفة عند بداية اللعبة
	chase_speed = randf_range(min_chase_speed, max_chase_speed)


func _find_player():
	player_ref = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	_apply_gravity(delta)
	_chase(delta)
	move_and_slide()
	_update_animation()


func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# اسمح بالسرعة السالبة (القفز أو الارتداد)
		if velocity.y > 0:  # صفر فقط لو السرعة لتحت
			velocity.y = 0


func _chase(delta):
	if not is_instance_valid(player_ref):
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		return

	var distance_to_player = global_position.distance_to(player_ref.global_position)

	if distance_to_player > detection_range:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		return

	# --- إعادة حساب الاتجاه كل فترة (مو كل فريم) ---
	direction_reroll_timer -= delta
	if direction_reroll_timer <= 0:
		direction_reroll_timer = DIRECTION_REROLL_TIME
		_reroll_direction()

	facing_dir = current_direction_sign
	velocity.x = move_toward(velocity.x, current_direction_sign * chase_speed, ACCELERATION * delta)

	_update_facing()

	# --- Y axis: random jump chance if player is above ---
	if is_on_floor():
		if player_ref.global_position.y < global_position.y:
			if not has_rolled_jump:
				has_rolled_jump = true
				if randf() < jump_chance:
					velocity.y = JUMP_VELOCITY
		else:
			has_rolled_jump = false
	else:
		has_rolled_jump = false


func _reroll_direction():
	var correct_dir = 1.0 if player_ref.global_position.x > global_position.x else -1.0

	if randf() < direction_accuracy:
		# ياخذ الاتجاه الصحيح نحو اللاعب (احتمال 90%)
		current_direction_sign = correct_dir
	else:
		# ياخذ اتجاه عشوائي غلط (يبعد عن اللاعب) - احتمال 10%
		current_direction_sign = -correct_dir


func _update_facing():
	animated_sprite.flip_h = facing_dir < 0


func _update_animation():
	if not is_on_floor():
		if velocity.y < -10:
			animated_sprite.play("jump")
		elif velocity.y > 10:
			animated_sprite.play("fall")
		return

	if abs(velocity.x) > 10:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")


func _on_catch_area_body_entered(body):
	if body.is_in_group("player"):
		body.die()
