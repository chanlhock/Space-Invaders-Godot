extends Node2D

# --- Game State Variables ---
var score = 0
var game_active = false
var is_at_edge = false 

# ... (replace your old _process function with this one) ...
# --- Invader Group Movement Variables ---
var invader_direction = 1  # 1 = Right, -1 = Left
var invader_speed = 100.0   # Starting speed
var drop_amount = 10.0     # How far they drop when hitting the edge
var edge_limit = 20.0      # Distance from screen edge to trigger turn
var formation_width = 720.0 # 12 invaders * 60 spacing = 720 pixels wide
var invader_count = 36
var waiting_for_input = false  # NEW: Track if we're waiting for key press
var loading_wheel = null  # Reference to the loading wheel
var rotation_speed = 2.0  # Radians per second

# --- Grid Settings ---
@export var rows = 3
@export var cols = 12
@export var invader_scene: PackedScene

func _ready():
	# Initial UI Setup
	$UILayer/SplashScreen.visible = true
	$Player.visible = false
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = false
	
	# Create the loading wheel on the splash screen
	create_loading_wheel()
	
	# Ensure GameInput exists
	if not has_node("/root/GameInput"):
		push_error("GameInput autoload not found! Please add it in Project Settings -> Autoload")
	
	# Connect restart button if it exists
	#if $UILayer/GameOverScreen.has_node("RestartButton"):
	#	$UILayer/GameOverScreen/RestartButton.pressed.connect(restart_game)
		
	# Start the Bluetooth search process
	start_bluetooth_search()

func create_loading_wheel():
	# Create an AnimatedSprite2D for the loading wheel
	loading_wheel = Sprite2D.new()
	loading_wheel.name = "LoadingWheel"
	
	# Create a simple circle texture using a Polygon2D approach
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw simple circle using set_pixel (slow but works for small textures)
	var center = Vector2(32, 32)
	var radius = 28
	
	for x in range(64):
		for y in range(64):
			var dx = x - center.x
			var dy = y - center.y
			var dist = sqrt(dx*dx + dy*dy)
			if abs(dist - radius) < 2:
				image.set_pixel(x, y, Color.ORANGE_RED)
			elif dist < radius and dist > radius - 4:
				# Create a dotted effect for animation
				if int((x + y) * 0.5) % 4 < 2:
					image.set_pixel(x, y, Color.GRAY)
	
	var texture = ImageTexture.create_from_image(image)
	loading_wheel.texture = texture
	loading_wheel.centered = true
	
	# Position between invader and player sprites
	var screen_size = get_viewport().get_visible_rect().size
	loading_wheel.position = Vector2(screen_size.x / 2, screen_size.y / 2 - 50)
	
	$UILayer/SplashScreen.add_child(loading_wheel)
	loading_wheel.visible = false
	
func start_bluetooth_search():
	# Show the loading wheel
	if loading_wheel:
		loading_wheel.visible = true
		
	# 1. Update the UI to tell the user we are searching
	if $UILayer/SplashScreen.has_node("ConnectionLabel"):
		$UILayer/SplashScreen/ConnectionLabel.text = "Searching for Bluetooth Joystick...\n(Please turn on your Pico W)"
	
	# Set waiting_for_input flag to true
	waiting_for_input = true
	# 2. Safely check if the timer exists before starting it
	if has_node("ConnectionTimer"):
		$ConnectionTimer.start()
	else:
		# If the timer is missing, warn us in the Output panel and just start the game
		push_warning("ConnectionTimer node not found in Main scene! Skipping Bluetooth search.")
		start_game()

# This function is automatically called when the 10 seconds run out!
func _on_ConnectionTimer_timeout():
		# Hide the loading wheel when search completes
	if loading_wheel:
		loading_wheel.visible = false
		
	# STOP THE TIMER SO IT NEVER FIRES AGAIN!
	if has_node("ConnectionTimer"):
		$ConnectionTimer.stop() 
	# 3. Check if the joystick connected in time
	#if GameInput.connected:
	#	if $UILayer/SplashScreen.has_node("ConnectionLabel"):
	#		$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Connected! Starting Game..."
	#	print("Bluetooth Joystick Connected Successfully!")
	#else:
#		if $UILayer/SplashScreen.has_node("ConnectionLabel"):
	#		$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Not Found.\nPress ENTER for Keyboard mode..."
	#		print("Bluetooth Timeout! Falling back to Keyboard controls.")
	
	# 3. Check if the joystick connected in time - FIXED: Use is_device_connected() or GameInput.connected
	var is_joystick_connected = false
	if has_node("/root/GameInput"):
		# Try both methods to check connection
		is_joystick_connected = GameInput.is_device_connected()
	
	if is_joystick_connected:
		if $UILayer/SplashScreen.has_node("ConnectionLabel"):
			$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Connected! Starting Game..."
		print("Pico W Joystick Connected Successfully!")
	else:
		if $UILayer/SplashScreen.has_node("ConnectionLabel"):
			$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Not Found.\nPress ENTER for Keyboard mode..."
		print("Connection Timeout! Falling back to Keyboard controls.")
		
	# 4. Wait 2 seconds so the user can read the message, then start the game
	#await get_tree().create_timer(2.0).timeout
	#start_game()
	
func _process(delta):
		# Rotate the loading wheel if it exists and visible
	if loading_wheel and loading_wheel.visible:
		loading_wheel.rotation += rotation_speed * delta
		
		# Update the arc positions for animation
		update_loading_wheel_animation()
		
	if waiting_for_input:
		# Check for ENTER key
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER):
			waiting_for_input = false
			print("Enter pressed! Starting game... Good luck!")
			
			# Stop the timer if it exists
			if has_node("ConnectionTimer") and $ConnectionTimer.is_stopped() == false:
				$ConnectionTimer.stop()
			
			# Start the game
			start_game()
		
		# Check for ESC key
		elif Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
			print("ESC pressed! Quit game...")
			get_tree().quit()
		
		# Don't process game logic while waiting for input
		return
			
	# Handle game over screen input
	if not game_active and $UILayer/GameOverScreen.visible:
		if Input.is_action_just_pressed("restart"):
			print("R pressed! Restarting game... Good luck!")
			restart_game()
		elif Input.is_action_just_pressed("quit"):
			print("ESC pressed! Quit game...")
			get_tree().quit()
			
	# 1. Move the container horizontally
	$InvaderContainer.position.x += invader_direction * invader_speed * delta
	
	var screen_width = get_viewport_rect().size.x
	# Calculate the actual right edge of the invaders
	var right_edge_of_invaders = $InvaderContainer.position.x + formation_width
	
	# 2. Check Right Edge (using the actual invader position)
	if right_edge_of_invaders > screen_width - 20.0: 
		if not is_at_edge: 
			invader_direction = -1 # Bounce left
			$InvaderContainer.position.y += drop_amount
			#print("Invader Position Y:",$InvaderContainer.position.y)
			invader_speed += 8.0
			is_at_edge = true 
			
	# 3. Check Left Edge (Invaders start at x=50 inside container, so check < 30)
	elif $InvaderContainer.position.x < 20.0:
		if not is_at_edge: 
			invader_direction = 1 # Bounce right
			$InvaderContainer.position.y += drop_amount
			#print("Invader Position Y:",$InvaderContainer.position.y)
			invader_speed += 8.0
			is_at_edge = true 
			
	# 4. Reset the lock when they move away from the edge
	else:
		is_at_edge = false

	# 5. Game Over check
	if $InvaderContainer.position.y > 500.0: 
		game_over()

func update_loading_wheel_animation():
	# Simple rotation is enough for now
	pass
	
func start_game():
	# Hide loading wheel if it's still visible
	if loading_wheel:
		loading_wheel.visible = false
	
	waiting_for_input = false
	$UILayer/SplashScreen.visible = false
	$Player.visible = true
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = true
	
	game_active = true
	score = 0
	invader_speed = 100.0 # Reset speed
	invader_direction = 1
	invader_count = 36
	$InvaderContainer.position = Vector2(2, 20) 
	
	update_score()
	update_mode()
	sound_status()
	spawn_invaders()

func spawn_invaders():
	var start_x = 30
	var start_y = 50
	var spacing_x = 60
	var spacing_y = 50

	for r in range(rows):
		for c in range(cols):
			var invader = invader_scene.instantiate()
			invader.position = Vector2(start_x + c * spacing_x, start_y + r * spacing_y)
			$InvaderContainer.add_child(invader)

func update_score():
	# Update the label in the HUD
	$UILayer/HUD/ScoreLabel.text = "Score: %d" % score
	
func update_mode():
	# Update the label in the HUD - FIXED: Check connection properly
	var is_connected = false
	if has_node("/root/GameInput"):
		is_connected = GameInput.is_device_connected()
	
	if is_connected:
		$UILayer/HUD/ModeLabel.text = "PICO W MODE" 
	else:
		$UILayer/HUD/ModeLabel.text = "KEYBOARD MODE"
	
func is_bus_muted(bus_name: String = "Master") -> bool:
	var bus_index = AudioServer.get_bus_index(bus_name)
	var is_explicitly_muted = AudioServer.is_bus_mute(bus_index)
	var volume_db = AudioServer.get_bus_volume_db(bus_index)
	return is_explicitly_muted or volume_db <= -80.0

func sound_status():
	# Update the label in the HUD
	if is_bus_muted("Master"):
		$UILayer/HUD/SoundLabel.text = "SOUND OFF" 
	else:
		$UILayer/HUD/SoundLabel.text = "SOUND ON" 
		
func check_all_invaders_destroyed():
	"""Check if all invaders have been destroyed"""
	#var invader_count = $InvaderContainer.get_child_count()
	invader_count = invader_count - 1
	print("Invader Count:",invader_count) 
	if invader_count == 0:
		game_won()

func game_won():
	"""Called when player destroys all invaders"""
	game_active = false
	$UILayer/GameOverScreen.visible = true
	$UILayer/GameOverScreen/GameOverLabel.text = "YOU WIN!\nFinal Score: %d\nPress R to Restart or ESC to Quit" % score
	
func game_over():
	game_active = false
	$UILayer/GameOverScreen.visible = true
	$UILayer/HUD.visible = false
	get_node("AudioPlayers/ExplosionPlayer").play()
	print("🔊 Playing explosion sound")
	$UILayer/GameOverScreen/GameOverLabel.text = "GAME OVER!\nAlas, You only scored: %d\nPress R to Restart or ESC to Quit" % score
	
func restart_game():
	# Clear existing invaders
	for child in $InvaderContainer.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Reset game state
	game_active = false
	start_game()
