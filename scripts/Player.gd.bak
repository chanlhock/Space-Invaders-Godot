extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

# Change cooldown to milliseconds (500ms = 0.5 seconds)
var last_fire_time = 0 
var fire_cooldown = 500 

# Joystick dead zone (ignore small movements)
var joystick_deadzone = 0.15  # 15% dead zone
# Calibrate these values based on your joystick
# From your logs: resting position is around 0.77 (77%)
var joystick_center = 0.77  # Adjust this to your joystick's resting position
var joystick_min = 0.0
var joystick_max = 1.0

func _ready():
	# Initialize player at bottom center of screen
	position = Vector2(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y - 80)
	print("Player initialized at center: ", position)
	await get_tree().create_timer(2.0).timeout
	if GameInput.is_device_connected():
		calibrate_joystick()
		
func calibrate_joystick():
	# Take 30 samples to find resting position
	var samples = 0.0
	for i in range(30):
		samples += GameInput.get_joystick_x()
		await get_tree().create_timer(0.033).timeout
	
	joystick_center = samples / 30.0
	print("Joystick calibrated - Center: ", joystick_center)
	
func _physics_process(_delta):
	var direction = 0.0

	# 1. Keyboard Input (Prioritized)
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	elif Input.is_action_pressed("move_right"):
		direction += 1.0
	else:
		# 2. Joystick Input (Only used if NO keyboard keys are pressed)
		if GameInput.is_device_connected():
			# Get joystick X value using the getter function
			var joy_x = GameInput.get_joystick_x()
			
			# Convert to centered value (-0.5 to 0.5 range, then multiply by 2 for -1 to 1)
			# Since 0.5 is center, values below 0.5 are left, above 0.5 are right
			var centered_x = (joy_x - 0.5) * 2.0
			
			# Apply dead zone (ignore small movements near center)
			if abs(centered_x) > joystick_deadzone:
				direction = centered_x
			else:
				direction = 0.0
			
			# Debug output (uncomment for testing)
			# if Engine.get_process_frames() % 60 == 0:  # Print once per second
			# 	print("Joy X: ", joy_x, " Centered: ", centered_x, " Direction: ", direction)

	# 3. Fire Button (Keyboard OR Joystick)
	var should_fire = GameInput.is_button_pressed() or Input.is_action_just_pressed("fire")
	if should_fire and Time.get_ticks_msec() - last_fire_time > fire_cooldown:
		fire_bullet()
		last_fire_time = Time.get_ticks_msec()

	# Apply movement
	velocity.x = direction * speed
	move_and_slide()

	# Keep player within screen bounds
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	var half_width = sprite_width / 2.0
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, half_width, screen_width - half_width)

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
		# Play bullet sound effect
		if main.has_node("AudioPlayers/ShootPlayer"):
			main.get_node("AudioPlayers/ShootPlayer").play()
	else:
		print("❌ ERROR: BulletContainer not found!")
