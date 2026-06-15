extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

# Fire cooldown (milliseconds)
var last_fire_time = 0 
var fire_cooldown = 500 

# Joystick state
var joystick_direction = 0  # -1 = Left, 0 = Center, 1 = Right
var joystick_intensity = 0.0  # 0-100%
var target_x = 0.0  # Smooth movement target

# Keyboard state
var moving_left = false
var moving_right = false

# For button press debouncing
var button_was_pressed = false

func _ready():
	# Initialize player at bottom center of screen
	var screen_width = get_viewport_rect().size.x
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	var half_width = sprite_width / 2.0
	target_x = clamp(screen_width / 2.0, half_width, screen_width - half_width)
	position = Vector2(target_x, get_viewport_rect().size.y - 80)
	print("Player initialized at center: ", position)

func _physics_process(_delta):
	# 1. Handle keyboard input
	moving_left = Input.is_action_pressed("move_left")
	moving_right = Input.is_action_pressed("move_right")
	
	# 2. Handle joystick input
	if GameInput.is_device_connected():
		var calibrated_x = GameInput.get_calibrated_x()
		
		# Update joystick direction and intensity
		if calibrated_x < -20:
			joystick_direction = -1
			joystick_intensity = min(100, abs(calibrated_x))
		elif calibrated_x > 20:
			joystick_direction = 1
			joystick_intensity = min(100, abs(calibrated_x))
		else:
			joystick_direction = 0
			joystick_intensity = 0
	
	# 3. Apply movement (keyboard overrides joystick)
	var move_amount = 0.0
	
	if moving_left:
		move_amount = -speed
	elif moving_right:
		move_amount = speed
	elif joystick_direction != 0:
		# Scale movement speed based on joystick intensity (20-100%)
		var intensity_factor = max(0.2, joystick_intensity / 100.0)
		move_amount = joystick_direction * speed * intensity_factor
	
	# Apply movement with speed limit
	target_x += move_amount * get_physics_process_delta_time()
	
	# 4. Keep target within bounds
	var screen_width = get_viewport_rect().size.x
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	var half_width = sprite_width / 2.0
	target_x = clamp(target_x, half_width, screen_width - half_width)
	
	# 5. Smooth interpolation
	position.x += (target_x - position.x) * 0.3
	
	# 6. Handle shooting (Keyboard SPACEBAR + Joystick button)
	# Check for keyboard fire action
	var keyboard_fire = Input.is_action_just_pressed("fire")
	
	# Check for joystick button press (edge detection)
	var joystick_fire = false
	if GameInput.is_device_connected():
		var current_button = GameInput.is_button_pressed()
		# Detect button press (transition from released to pressed)
		if not button_was_pressed and current_button:
			joystick_fire = true
		button_was_pressed = current_button
	
	# Fire if either input is triggered
	if (keyboard_fire or joystick_fire) and Time.get_ticks_msec() - last_fire_time > fire_cooldown:
		fire_bullet()
		last_fire_time = Time.get_ticks_msec()
		
		# Debug output
		if keyboard_fire:
			print("🔫 Keyboard fire!")
		elif joystick_fire:
			print("🔫 Joystick fire!")

func fire_bullet():
	if not bullet_scene:
		# Try to auto-load the bullet scene
		if ResourceLoader.exists("res://scenes/Bullet.tscn"):
			bullet_scene = load("res://scenes/Bullet.tscn")
			print("✓ Auto-loaded bullet scene")
		elif ResourceLoader.exists("res://Bullet.tscn"):
			bullet_scene = load("res://Bullet.tscn")
			print("✓ Auto-loaded bullet scene")
		else:
			print("❌ ERROR: bullet_scene is not assigned and couldn't be auto-loaded!")
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
		# Fallback: add to parent
		get_parent().add_child(bullet)
		print("⚠ Bullet added to parent (BulletContainer not found)")

# Optional: Debug function
func _input(event):
	# Press 'D' key to debug joystick state
	if event is InputEventKey and event.keycode == KEY_D and event.pressed:
		print("=== Player Debug ===")
		print("Position: ", position)
		print("Target X: ", target_x)
		print("Joystick Direction: ", joystick_direction)
		print("Joystick Intensity: ", joystick_intensity)
		print("Moving Left: ", moving_left)
		print("Moving Right: ", moving_right)
		print("GameInput Connected: ", GameInput.is_device_connected())
		if GameInput.is_device_connected():
			print("Calibrated X: ", GameInput.get_calibrated_x())
