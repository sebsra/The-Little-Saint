class_name RageChaseState
extends MeleeState

func _init():
    name = "RageChase"

func enter():
    super.enter()
    play_animation("walk")
    
    print(enemy.name + " entered rage chase state")

func physics_process(delta: float):
    # Update target
    update_target()
    
    if not target:
        enemy.velocity.x = 0
        return
    
    # Direction to player
    var direction = target.global_position.x - enemy.global_position.x
    var normalized_dir = sign(direction)
    
    # Use rage speed bonus
    var melee = enemy as GoblinMelee
    var speed_multiplier = melee.rage_speed_bonus if melee else 1.3
    
    # Apply movement with rage bonus
    enemy.velocity.x = normalized_dir * enemy.chase_speed * speed_multiplier
    
    # Flip sprite
    if enemy.animated_sprite:
        enemy.animated_sprite.flip_h = normalized_dir > 0

func get_next_state() -> String:
    var next = super.get_next_state()
    if next:
        return next
        
    # Return to patrol if no target
    if not target:
        return "Patrol"
    
    # Switch to rage attack if in range
    if is_target_in_attack_range() and enemy.can_attack:
        return "Rage"
    
    return ""
