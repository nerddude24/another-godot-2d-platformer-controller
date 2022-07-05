"""
    INPUT ACTIONS: jump, right, left, up, down

    This controller was made for my own games and probably wont 
    work for others, but here it is anyway

    This controller implements smooth movement with friciton and acceleration
    and easy to calculate jumping with Coyote Time and Jump Buffer

    If you are using vscode install colorful comments for clearer code

    Made by: nerddude
"""
extends KinematicBody2D

# * how many units to drop down when dropping down a one way platform
const DROP_DOWN_UNITS = 1

# * this is a delay to register jump x seconds before hitting the ground
# * this makes it possible to bunny hop and makes jumping more fun
const JUMP_BUFFER_TIME = 0.2

# * gives player extra x seconds to jump after leaving platform
const COYOTE_TIME = 0.1

# * when player releases jump button, velocity will be multiplied by STOP_JUMP_RATIO
# * to make it smoother
const STOP_JUMP_RATIO = 0.5

export var max_speed: float
export(float, 0, 1.0) var friction = 0.1
export(float, 0, 1.0) var acceleration = 0.25

# * jump height in units
export var jump_height: float

# * how many seconds you want to peak and to decent from jump
export var jump_time_to_peak: float
export var jump_time_to_decent: float

# * JUMPING VARS AND MATH *
onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
onready var jump_gravity: float = (
	((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak))
	* -1.0
)
onready var fall_gravity: float = (
	((-2.0 * jump_height) / (jump_time_to_decent * jump_time_to_decent))
	* -1.0
)

var velocity = Vector2.ZERO

var is_jumping = false
var can_jump = false

# * jump buffer vars
var will_jump = false
var jump_buffer_timer: float = 0


func get_gravity() -> float:
	return jump_gravity if velocity.y < 0 else fall_gravity


func jump():
	velocity.y = jump_velocity


func get_input(delta):
	# * Movement *
	var dir = 0

	if Input.is_action_pressed("right"):
		dir += 1
	if Input.is_action_pressed("left"):
		dir -= 1

	if dir != 0:
		velocity.x = lerp(velocity.x, dir * max_speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)

	# * JUMPING LOGIC *
	if Input.is_action_just_pressed("jump"):
		if can_jump or is_on_floor():
			# & check if play is pressing down to drop down, else jump
			if Input.is_action_pressed("down"):
				self.position.y += DROP_DOWN_UNITS
			else:
				jump()
		else:
			# & if player is mid air activate buffer jump
			will_jump = true

	# & stop jump when released
	elif (Input.is_action_just_released("jump") and velocity.y < 0) or is_on_ceiling():
		velocity.y *= STOP_JUMP_RATIO

	if not is_on_floor() and can_jump:
		# & activate coyote time for COYOTE_TIME seconds
		yield(get_tree().create_timer(COYOTE_TIME, false), "timeout")
		can_jump = false

	elif is_on_floor():
		# & if buffer jump is activated then jump
		if will_jump:
			will_jump = false
			jump()
			# & adapt jump height if the player is holding jump or not
			# & to avoid full jump without holding the button
			velocity.y = (
				velocity.y
				if Input.is_action_pressed("jump")
				else velocity.y * STOP_JUMP_RATIO
			)
		else:
			# & reset coyote jump
			can_jump = true

		# & reset jump buffer timer
		jump_buffer_timer = JUMP_BUFFER_TIME

	elif will_jump:
		# & if buffer jump is activated reduce the buffer timer
		# & if buffer timer is <= 0 then stop buffer jump
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0:
			will_jump = false


func _physics_process(delta):
	get_input(delta)
	velocity.y += get_gravity() * delta
	velocity = move_and_slide(velocity, Vector2.UP)
