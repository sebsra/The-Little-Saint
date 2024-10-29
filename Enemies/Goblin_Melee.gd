extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player
var speed = 80
var chase = false
var attack = false
var death = false
var hud

func _ready():
	hud = get_node("../../HUD")
	if death == false:
		get_node("AnimatedSprite2D").play("idle")
func _process(delta):
	velocity.y += gravity * delta
	
	if chase == true && death == false:
		player = get_node("../../Player/Player")
		get_node("AnimatedSprite2D").play("walk")
		var direction = (player.position - self.position).normalized()
		if direction.x > 0:
			get_node("AnimatedSprite2D").flip_h = true
		else:
			get_node("AnimatedSprite2D").flip_h = false
		velocity.x = direction.x * speed
		
	if attack == true && death == false:
		player = get_node("../../Player/Player")
		get_node("AnimatedSprite2D").play("attack")
	move_and_slide()

func _on_detection_radius_body_entered(body):
	if body.name == "Player":
		chase = true


func _on_detection_radius_body_exited(body):
	if body.name == "Player":
		chase = false


func _on_attackzone_body_entered(body):
	if body.name == "Player":
		chase = false
		attack = true
		hud.change_life(-1)


func _on_attackzone_body_exited(body):
	if body.name == "Player":
		chase = true
		attack = false


func _on_deathzone_body_entered(body):
	if body.name == "Player":
		death = true
		speed = 0
		chase = false
		attack = false
		$CollisionShape2D.disabled = true
		get_node("AnimatedSprite2D").play("death")
		await get_node("AnimatedSprite2D").animation_finished
		self.queue_free()
