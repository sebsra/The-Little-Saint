class_name TeleportState
extends MageState

var teleport_timer: float = 0.0
var teleport_duration: float = 0.5
var has_teleported: bool = false

func _init():
    name = "Teleport"

func enter():
    super.enter()
    play_animation("idle")
    
    enemy.velocity = Vector2.ZERO
        
    teleport_timer = 0.0
    has_teleported = false
    
    print(enemy.name + " entered teleport state")

func physics_process(delta: float):
    teleport_timer += delta
    
    # Teleport halfway through state duration
    if not has_teleported and teleport_timer >= teleport_duration * 0.5:
        _perform_teleport()
        has_teleported = true

func _perform_teleport():
    var mage = enemy as GoblinMage
    if not mage:
        return
        
    # Use mage's teleport method
    mage.teleport()
    
    # Update target after teleport
    update_target()

func get_next_state() -> String:
    var next = super.get_next_state()
    if next:
        return next
        
    # After teleport is complete
    if has_teleported and teleport_timer >= teleport_duration:
        var mage = enemy as GoblinMage
        if not mage:
            return "Patrol"
        
        # Return to appropriate state
        if target:
            # If enough mana to cast and in range, cast
            if mage.current_mana >= mage.spell_mana_cost and get_distance_to_target() <= enemy.attack_radius:
                return "Cast"
            else:
                return "Chase"
        else:
            return "Patrol"
    
    return ""
