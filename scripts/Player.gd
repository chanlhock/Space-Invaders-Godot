extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

# Change cooldown to milliseconds (500ms = 0.5 seconds)
var last_fire_time = 0 
var fire_cooldown = 500 

func _ready():
	# Initialize player at bottom center of screen
	position = Vector2(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y - 80)

func _physics_process(_delta):
	var direction = 0.0

	# 1. Keyboard Input (Prioritized)
	if Input.is_action_pressed("move_left"):
		#print("⬅️ LEFT KEY PRESSED!")
		direction -= 1.0
	elif Input.is_action_pressed("move_right"):
		#print("➡️ RIGHT KEY PRESSED!")
		direction += 1.0
	else:
		# 2. Joystick Input (Only used if NO keyboard keys are pressed)
		if GameInput.connected:
			if GameInput.joystick_x < 0.4:
				direction -= 1.0
			elif GameInput.joystick_x > 0.6:
				direction += 1.0

	# 3. Fire Button (Keyboard OR Joystick)
	var should_fire = GameInput.button_pressed or Input.is_action_just_pressed("fire")
	if should_fire and Time.get_ticks_msec() - last_fire_time > fire_cooldown:
		#print("Fire bullet!")
		fire_bullet()
		last_fire_time = Time.get_ticks_msec()

	velocity.x = direction * speed
	move_and_slide()

	# 4. Keep player within screen bounds (Fixed to account for sprite width)
	# This stops the exact edge of the ship from touching the wall, rather than the center of the ship
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	var half_width = sprite_width / 2.0
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, half_width, screen_width - half_width)
	#print("Pos X: ", position.x, " | Dir: ", direction, " | Vel X: ", velocity.x  )
			
func fire_bullet():
	if not bullet_scene:
		print("❌ ERROR: bullet_scene is not assigned!")
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.position = position + Vector2(0, -30)
		
	# Get the BulletContainer and add bullet
	var main = get_node_or_null("/root/Main")
	if main and main.has_node("BulletContainer"):
		var container = main.get_node("BulletContainer")
		container.add_child(bullet)
		print("✓ Bullet added to BulletContainer")
		# Play bullet sound effect
		if main.has_node("AudioPlayers/ShootPlayer"):
			main.get_node("AudioPlayers/ShootPlayer").play()
			print("🔊 Playing shoot sound")
	else:
		print("❌ ERROR: BulletContainer not found!")
		
	
