class_name PlayerWalkState
extends PlayerBaseState

func enter():
	player.current_animation = "walking"  # Walk animation
	
	if player.debug_mode:
		print("Entered Walk State")

func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	
	# Read the input
	var x_input = Input.get_axis("left", "right")
	
	# Apply horizontal movement
	if x_input != 0:
		velocity.x = x_input * player.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
		
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
		
	# Check for attack
	if Input.is_action_just_pressed("attack"):
		return "PlayerAttackState"
	
	# Read inputs
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Stop walking
	if x_input == 0:
		return "PlayerIdleState"
	
	# Jump while moving
	if y_input > 0.4 and player.is_on_floor():
		return "PlayerJumpState"
		
	# Fall transition
	if !player.is_on_floor():
		return "PlayerFallState"
	
	# Stay in walk state
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
