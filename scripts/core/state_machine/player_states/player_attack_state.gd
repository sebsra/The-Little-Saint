class_name PlayerAttackState
extends PlayerBaseState

var attack_timer: float = 0.0
var attack_duration: float = 0.5  # Duration of the attack animation

func enter():
    player.current_animation = player.attack_animation
    player.play_attack_animation = true
    attack_timer = 0.0
    
    # Optionally play attack sound
    # if player.has_node("AttackSound"):
    #     player.get_node("AttackSound").play()

func physics_process(delta: float):
    # Apply gravity
    var velocity = get_velocity()
    velocity.y += player.GRAVITY * delta
    
    # Reduce movement during attack (optional)
    velocity.x = move_toward(velocity.x, 0, 20)
    
    set_velocity(velocity)
    
    # Handle movement for character body
    player.move_and_slide()
    
    # Update attack timer
    attack_timer += delta
    
    # Update outfit
    update_outfit()

func get_next_state() -> String:
    # Check state transitions
    var life_state = check_life()
    if life_state:
        return life_state
    
    # Return to appropriate state after attack finishes
    if attack_timer >= attack_duration:
        player.play_attack_animation = false
        
        if player.is_on_floor():
            var x_input = Input.get_axis("left", "right")
            if x_input != 0:
                return "PlayerWalkState"
            else:
                return "PlayerIdleState"
        else:
            return "PlayerFallState"
    
    # Stay in attack state
    return ""
    
func handle_input(event: InputEvent):
    check_menu_input(event)