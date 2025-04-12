class_name AttackState
extends EnemyState

var attack_timer: float = 0.0
var attack_duration: float = 0.5
var has_dealt_damage: bool = false

func _init():
    name = "Attack"
    
func enter():
    super.enter()
    play_animation("attack")
    
    attack_timer = 0.0
    has_dealt_damage = false
    
    # Stop movement during attack
    enemy.velocity.x = 0
    
    # Face target
    flip_to_target()
        
    print(enemy.name + " entered attack state")

func physics_process(delta: float):
    attack_timer += delta
    
    # Deal damage in middle of animation
    if not has_dealt_damage and attack_timer >= attack_duration * 0.5:
        deal_damage()
        has_dealt_damage = true

func deal_damage():
    if not target or not is_target_in_attack_range():
        return
    
    # Use enemy's execute_attack method
    enemy.execute_attack(target, enemy.attack_damage)
    
    print(enemy.name + " dealt damage to " + target.name)

func get_next_state() -> String:
    var next = super.get_next_state()
    if next:
        return next
        
    # After attack is complete
    if attack_timer >= attack_duration:
        # If target out of range, chase
        if not is_target_in_attack_range():
            return "Chase"
        # If target in range but can't attack yet
        elif not enemy.can_attack:
            return "Chase"
        # If target in range and we can attack, stay in attack state
    
    return ""
