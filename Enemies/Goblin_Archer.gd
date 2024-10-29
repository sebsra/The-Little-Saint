extends CharacterBody2D

@onready var main = get_node("../../")
@onready var projectile = load("res://rock.tscn")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player
var speed = 60
var chase = false
var attack = false
var death = false

func _ready():
	player = get_node("../../Player/Player")
	if death == false:
		get_node("AnimatedSprite2D").play("idle")
		
func _process(delta):
	velocity.y += gravity * delta
	chaseMode()
	move_and_slide()

func attackMode():
	if attack == true && death == false:
		velocity.x = 0
		player = get_node("../../Player/Player")
		get_node("AnimatedSprite2D").play("attack")
		
func chaseMode():
	if chase == true && death == false && attack == false:
		get_node("AnimatedSprite2D").play("walk")
		var direction = (player.position - self.position).normalized()
		if direction.x > 0:
			get_node("AnimatedSprite2D").flip_h = true
		else:
			get_node("AnimatedSprite2D").flip_h = false
		velocity.x = direction.x * speed
		
func shoot():
	var direction = (player.position - self.position).normalized()
	var instance = projectile.instantiate()
	instance.direction = direction
	instance.spawnPos = global_position
	instance.spawnRot = rotation
	main.add_child.call_deferred(instance)

func _on_detection_radius_3_body_entered(body):
	if body.name == "Player" && attack == false:
		chase = true
		chaseMode()

func _on_detection_radius_3_body_exited(body):
	if body.name == "Player":
		chase = false

func _on_attack_radius_3_body_entered(body):
	if body.name == "Player":
		attack = true
		chase = false
		attackMode()
		while attack == true:
			shoot()
			await get_tree().create_timer(0.7).timeout

func _on_attack_radius_3_body_exited(body):
	if body.name == "Player":
		chase = true
		attack = false
		chaseMode()

func _on_death_radius_3_body_entered(body):
	if body.name == "Player":
		death = true
		speed = 0
		chase = false
		attack = false
		$CollisionShape2D.disabled = true
		get_node("AnimatedSprite2D").play("death")
		await get_node("AnimatedSprite2D").animation_finished
		self.queue_free()
