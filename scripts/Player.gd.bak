extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

var last_fire_time = 0 
var fire_cooldown = 500 

func _physics_process(_delta):
	# DEBUG 1: Check if script is running
	# print("Player script is running...") 

	var direction = 0.0

	# DEBUG 2: Check Keyboard
	if Input.is_action_just_pressed("move_left"):
		print("✅ LEFT KEY DETECTED!")
		direction -= 1.0
	elif Input.is_action_just_pressed("move_right"):
		print("✅ RIGHT KEY DETECTED!")
		direction += 1.0

	# DEBUG 3: Check Fire
	if Input.is_action_just_pressed("fire"):
		print("🔥 FIRE KEY DETECTED!")
		if bullet_scene == null:
			print("❌ ERROR: Bullet Scene is empty in Inspector!")
		else:
			fire_bullet()

	velocity.x = direction * speed
	move_and_slide()
	
	# Keep player within screen bounds
	var half_width = 20.0 # Fallback if texture is missing
	if $Sprite2D.texture:
		half_width = $Sprite2D.texture.get_width() / 2.0
		
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, half_width, screen_width - half_width)

func fire_bullet():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, -20)
		
		var main = get_node_or_null("/root/Main")
		if main:
			if not main.has_node("BulletContainer"):
				var container = Node2D.new()
				container.name = "BulletContainer"
				main.add_child(container)
			main.get_node("BulletContainer").add_child(bullet)
