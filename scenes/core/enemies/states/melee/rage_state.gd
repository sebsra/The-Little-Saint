class_name RageState
extends MeleeState

var rage_timer: float = 0.0
var rage_duration: float = 0.8  # Faster attack in rage mode
var has_dealt_damage: bool = false

func _init():
    name = "Rage"

func enter():
    super.enter()
    play_animation("attack")
    
    # Stop movement during attack
    enemy.velocity.x = 0
        
    rage_timer = 0.0
    has_dealt_damage = false
    
    print(enemy.name + " entered rage attack state")

func physics_process(delta: float):
    rage_timer += delta
    
    # Deal damage faster than normal attack
    if not has_dealt_damage and rage_timer >= rage_duration * 0.3:
        deal_rage_damage()
        has_dealt_damage = true

func deal_rage_damage():
    if not target or not is_target_in_attack_range():
        return
        
    var melee = enemy as GoblinMelee
    if not melee:
        return
        
    # Execute attack with rage bonus
    var rage_damage = enemy.attack_damage
    enemy.execute_attack(target, rage_damage)
    
    print(enemy.name + " dealt RAGE damage to " + target.name)

func get_next_state() -> String:
    var next = super.get_next_state()
    if next:
        return next
        
    # After rage attack completes
    if rage_timer >= rage_duration:
        # Chase with rage speed if target not in range
        if not is_target_in_attack_range():
            return "RageChase"
    
    return ""
