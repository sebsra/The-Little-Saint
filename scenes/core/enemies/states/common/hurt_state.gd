class_name HurtState
extends EnemyState

var hurt_timer: float = 0.0
var hurt_duration: float = 0.3

func _init():
    name = "Hurt"
    
func enter():
    super.enter()
    play_animation("hurt")
    
    # Stop movement
    enemy.velocity.x = 0
        
    hurt_timer = 0.0
    print(enemy.name + " entered hurt state")

func physics_process(delta: float):
    hurt_timer += delta

func get_next_state() -> String:
    var next = super.get_next_state()
    if next:
        return next
        
    # After hurt animation
    if hurt_timer >= hurt_duration:
        if target:
            if is_target_in_attack_range() and enemy.can_attack:
                return "Attack"
            else:
                return "Chase"
        else:
            return "Patrol"
    
    return ""
