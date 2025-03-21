# Fix for player_jump_state.gd - Correct class name
class_name PlayerJumpState
extends PlayerBaseState

func enter():
	# player.current_animation = "idle"  # You may want to use a jump animation

	# Apply initial jump velocity
	var velocity = get_velocity()
	var y_input = Input.get_axis("down", "up")
	velocity.y = player.JUMP_VELOCITY * y_input
	set_velocity(velocity)

	# Update jump counter
	player.jump_counter += 1
	player.ready_for_jump = false
	
	if player.debug_mode:
		print("Entered Jump State")

func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta

	# Read horizontal input
	var x_input = Input.get_axis("left", "right")

	# Apply horizontal movement
	if x_input != 0:
		velocity.x = x_input * player.SPEED
		player.current_animation = "walking"
	else:
		velocity.x = move_toward(velocity.x, 0, 30)

	set_velocity(velocity)

	# Handle movement for character body
	player.move_and_slide()

	# Reset jump readiness when input is released
	var y_input = Input.get_axis("down", "up")
	if y_input < 0.4:
		player.ready_for_jump = true

	# Update outfit
	update_outfit()

func get_next_state() -> String:
	# Check state transitions
	var life_state = check_life()
	if life_state:
		return life_state

	# Check for attack input
	if Input.is_action_just_pressed("attack"):
		return "PlayerAttackState"

	# Fly state transition
	if player.mode == "fly":
		return "PlayerFlyState"

	# Landing transition
	if player.is_on_floor():
		player.jump_counter = 0
		player.ready_for_jump = true

		# Check if still moving
		var x_input = Input.get_axis("left", "right")
		if x_input != 0:
			return "PlayerWalkState"
		else:
			return "PlayerIdleState"

	# Falling transition
	if get_velocity().y > 0:
		return "PlayerFallState"

	# Stay in jump state
	return ""

func handle_input(event: InputEvent):
	check_menu_input(event)
