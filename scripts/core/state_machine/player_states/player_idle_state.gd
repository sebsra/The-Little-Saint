class_name PlayerIdleState
extends PlayerBaseState

func enter():
	player.current_animation = "idle"
	# Reset horizontal velocity
	var velocity = get_velocity()
	velocity.x = 0
	set_velocity(velocity)
	
	if player.debug_mode:
		print("Entered Idle State")

func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	set_velocity(velocity)
	
	# Handle movement for character body
	player.move_and_slide()
	
	# Update outfit
	update_outfit()

func get_next_state() -> String:
	# Check for death
	var life_state = check_life()
	if life_state != "":
		return life_state
	
	# Check input for state transitions
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Check for attack
	if Input.is_action_just_pressed("attack"):
		return "PlayerAttackState"
	
	# Check for movement
	if x_input != 0:
		return "PlayerWalkState"
	
	# Check for jumping
	if y_input > 0.4 and player.is_on_floor():
		return "PlayerJumpState"
	
	# Check for falling
	if !player.is_on_floor():
		return "PlayerFallState"
	
	# No transition
	return ""

func handle_input(event: InputEvent):
	check_menu_input(event)
