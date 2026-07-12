extends CharacterBody2D

# --- Movement tuning ---
const SPEED = 220.0
const ACCELERATION = 1500.0
const FRICTION = 1800.0
const AIR_ACCELERATION = 1000.0
var died = false
var cur = ""
# --- Jump tuning ---
@export var max_jumps: int = 3  # 0 = can't jump, 1 = single jump, 2 = double jump, 3 = triple jump...
@export var can_wall_slide: bool = true  # true = wall slide/wall jump enabled, false = disabled
const JUMP_VELOCITY = -300.0
const WALL_JUMP_VELOCITY = -270.0
const WALL_JUMP_PUSH = 220.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
const MAX_FALL_SPEED = 700.0

# --- Wall slide tuning ---
const WALL_SLIDE_SPEED = 100.0

# --- Feel/forgiveness ---
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var jumps_used = 0  # tracks how many jumps performed since last floor touch
var is_hit = false
var is_wall_sliding = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var wall_check_right = $WallCheckRight
@onready var wall_check_left = $WallCheckLeft
@onready var camera = $Camera2D
@onready var music = $AudioStreamPlayer2D
@onready var jumpSound = $jumpSound

	

func _on_finished():
	music.play()

func _ready():
	music.finished.connect(_on_finished)
	music.play()
	floor_snap_length = 1.0
@export var death_y: float = 1000.0  # غيّر هذا الرقم من الـ Inspector حسب مستواك

func _check_death():
	if global_position.y > death_y:
		die()
func _physics_process(delta):
	if died:
		return
	if is_hit:
		move_and_slide()
		return

	_apply_gravity(delta)
	_handle_timers(delta)
	_handle_jump_input()
	_handle_movement(delta)
	_handle_wall_slide()
	_handle_wall_jump()

	move_and_slide()
	_update_animation()
	_check_death()



func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		# اسمح بوجود سرعة عمودية (مثل الارتداد من المنصة)
		if velocity.y >= 0:  # فقط إذا كان بينزل
			velocity.y = 0
		jumps_used = 0

func _handle_timers(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0)

	if Input.is_action_just_pressed("ui_up"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0)


func _handle_jump_input():
	if max_jumps <= 0:
		jump_buffer_timer = 0
		return

	var wants_jump = jump_buffer_timer > 0

	# First jump (from floor or coyote time)
	if wants_jump and coyote_timer > 0 and jumps_used == 0:
		velocity.y = JUMP_VELOCITY
		jumps_used = 1
		jump_buffer_timer = 0
		coyote_timer = 0
		jumpSound.play(0);
		

	# Extra air jumps (2nd, 3rd, etc.) as long as under max_jumps
	elif wants_jump and jumps_used < max_jumps and jumps_used > 0 and not is_wall_sliding:
		velocity.y = JUMP_VELOCITY * 0.9
		jumps_used += 1
		jump_buffer_timer = 0
		animated_sprite.play(cur+"double_jump")
		#jumpSound.play(0);


	# Edge case: jumped off ledge without pressing jump on floor (coyote expired), still allow air jumps
	elif wants_jump and jumps_used == 0 and not is_on_floor() and max_jumps > 1 and not is_wall_sliding:
		velocity.y = JUMP_VELOCITY * 0.9
		jumps_used = 2
		jump_buffer_timer = 0
		animated_sprite.play(cur+"double_jump")
		#jumpSound.play(0);



func _handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		if not is_wall_sliding:
			animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)


func _handle_wall_slide():
	is_wall_sliding = false

	if not can_wall_slide:
		return

	if is_on_floor():
		return

	var touching_wall_right = wall_check_right.is_colliding()
	var touching_wall_left = wall_check_left.is_colliding()
	var direction = Input.get_axis("ui_left", "ui_right")

	var pressing_into_wall = (touching_wall_right and direction > 0) or (touching_wall_left and direction < 0)

	if (touching_wall_right or touching_wall_left) and pressing_into_wall and velocity.y > 0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		jumps_used = 0  # refresh jumps while wall sliding (optional — feels good for platformers)
		animated_sprite.flip_h = touching_wall_left


func _handle_wall_jump():
	if not can_wall_slide:
		return

	if is_on_floor() or max_jumps <= 0:
		return

	var touching_wall_right = wall_check_right.is_colliding()
	var touching_wall_left = wall_check_left.is_colliding()

	if (touching_wall_right or touching_wall_left) and Input.is_action_just_pressed("ui_up"):
		velocity.y = WALL_JUMP_VELOCITY

		var push_dir = -1.0 if touching_wall_right else 1.0
		velocity.x = push_dir * WALL_JUMP_PUSH
		animated_sprite.flip_h = push_dir < 0

		jumps_used = 1  # counts as first jump after leaving wall
		is_wall_sliding = false
		animated_sprite.play(cur+"wall_jump")
		jump_buffer_timer = 0


func _update_animation():
	if is_hit:
		return

	if is_wall_sliding:
		animated_sprite.play(cur+"wall_jump")
		return

	if not is_on_floor():
		if velocity.y < -10:
			if animated_sprite.animation != cur+"double_jump" and animated_sprite.animation != cur+"wall_jump":
				animated_sprite.play(cur+"jump")
				
		elif velocity.y > 10:
			animated_sprite.play(cur+"fall")
		return

	if abs(velocity.x) > 20:
		animated_sprite.play(cur+"run")
	else:
		animated_sprite.play(cur+"idle")


func take_hit():
	is_hit = true
	animated_sprite.play(cur+"hit")
	velocity = Vector2.ZERO
	await animated_sprite.animation_finished
	is_hit = false


func _on_timer_timeout() -> void:
	die()


func die():
	died = true
	
	animated_sprite.play(cur+"hit")
	await get_tree().create_timer(0.5).timeout

	cur = ""
	max_jumps = 3
	died = false
	get_tree().reload_current_scene()
