class_name PlayerFallState
extends PlayerState

func enter():
	# player.current_animation = "idle"  # You may want a falling animation
	
	# Mark as not ready for jump
	if player.jump_counter == 0:
		player.ready_for_jump = false
		
func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	
	# Read the input
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Apply horizontal movement
	if x_input != 0:
		velocity.x = x_input * player.SPEED
		player.current_animation = "walking"
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
	
	# Check for double jump if allowed
	if y_input > 0.4 && player.jump_counter < player.allowed_jumps && player.ready_for_jump:
		velocity.y = player.JUMP_VELOCITY * y_input
		player.jump_counter += 1
		player.ready_for_jump = false
	elif y_input < 0.4:
		player.ready_for_jump = true
		
	set_velocity(velocity)
	
	# Handle movement for character body
	player.move_and_slide()
	
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
		
	# Check for fly mode
	if player.mode == "fly":
		return "PlayerFlyState"
	
	# Landing transition
	if player.is_on_floor():
		player.jump_counter = 0
		player.ready_for_jump = true
		player.passed_fly_time = 0.0
		
		# Check if still moving
		var x_input = Input.get_axis("left", "right")
		if x_input != 0:
			return "PlayerWalkState"
		else:
			return "PlayerIdleState"
			
	# Double jump transition
	var y_input = Input.get_axis("down", "up")
	if y_input > 0.4 && player.jump_counter < player.allowed_jumps && player.ready_for_jump:
		return "PlayerJumpState"
	
	# Stay in fall state
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
