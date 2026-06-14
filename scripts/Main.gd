extends Node2D

# --- Game State Variables ---
var score = 0
var game_active = false
var is_at_edge = false 

# ... (replace your old _process function with this one) ...
# --- Invader Group Movement Variables ---
var invader_direction = 1  # 1 = Right, -1 = Left
var invader_speed = 60.0   # Starting speed
var drop_amount = 10.0     # How far they drop when hitting the edge
var edge_limit = 20.0      # Distance from screen edge to trigger turn
var formation_width = 720.0 # 12 invaders * 60 spacing = 720 pixels wide
var invader_count = 36

# --- Grid Settings ---
@export var rows = 3
@export var cols = 12
@export var invader_scene: PackedScene

func _ready():
	# Initial UI Setup
	$UILayer/SplashScreen.visible = true
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = false
	
	# Ensure GameInput exists
	if not has_node("/root/GameInput"):
		push_error("GameInput autoload not found! Please add it in Project Settings -> Autoload")
	
	# Connect restart button if it exists
	if $UILayer/GameOverScreen.has_node("RestartButton"):
		$UILayer/GameOverScreen/RestartButton.pressed.connect(restart_game)
		
	# Start the Bluetooth search process
	start_bluetooth_search()

func start_bluetooth_search():
	# 1. Update the UI to tell the user we are searching
	if $UILayer/SplashScreen.has_node("ConnectionLabel"):
		$UILayer/SplashScreen/ConnectionLabel.text = "Searching for Bluetooth Joystick...\n(Please turn on your Pico W)"

	# 2. Safely check if the timer exists before starting it
	if has_node("ConnectionTimer"):
		$ConnectionTimer.start()
	else:
		# If the timer is missing, warn us in the Output panel and just start the game
		push_warning("ConnectionTimer node not found in Main scene! Skipping Bluetooth search.")
		start_game()

# This function is automatically called when the 10 seconds run out!
func _on_ConnectionTimer_timeout():
	# STOP THE TIMER SO IT NEVER FIRES AGAIN!
	if has_node("ConnectionTimer"):
		$ConnectionTimer.stop() 
	# 3. Check if the joystick connected in time
	if GameInput.connected:
		if $UILayer/SplashScreen.has_node("ConnectionLabel"):
			$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Connected! Starting Game..."
		print("Bluetooth Joystick Connected Successfully!")
	else:
		if $UILayer/SplashScreen.has_node("ConnectionLabel"):
			$UILayer/SplashScreen/ConnectionLabel.text = "Joystick Not Found.\nUsing Keyboard Controls..."
		print("Bluetooth Timeout! Falling back to Keyboard controls.")

	# 4. Wait 2 seconds so the user can read the message, then start the game
	#await get_tree().create_timer(2.0).timeout
	start_game()

func _process(delta):
	if not game_active:
		return
		
	# Handle game over screen input
	if not game_active and $UILayer/GameOverScreen.visible:
		if Input.is_action_just_pressed("restart"):
			restart_game()
		elif Input.is_action_just_pressed("quit"):
			get_tree().quit()
			
	# 1. Move the container horizontally
	$InvaderContainer.position.x += invader_direction * invader_speed * delta
	
	var screen_width = get_viewport_rect().size.x
	#print("Screen Width:",screen_width)
	# Calculate the actual right edge of the invaders
	var right_edge_of_invaders = $InvaderContainer.position.x + formation_width
	#print("right_edge_of_invaders:",right_edge_of_invaders)
	
	# 2. Check Right Edge (using the actual invader position)
	if right_edge_of_invaders > screen_width - 20.0: 
		if not is_at_edge: 
			invader_direction = -1 # Bounce left
			$InvaderContainer.position.y += drop_amount
			print("Invader Position Y:",$InvaderContainer.position.y)
			invader_speed += 5.0
			is_at_edge = true 
			#print("Is at edge:",is_at_edge)
			
	# 3. Check Left Edge (Invaders start at x=50 inside container, so check < 30)
	elif $InvaderContainer.position.x < 20.0:
		#print("Invader Position X:",$InvaderContainer.position.x)
		if not is_at_edge: 
			invader_direction = 1 # Bounce right
			$InvaderContainer.position.y += drop_amount
			#print("Invader Position Y:",$InvaderContainer.position.y)
			invader_speed += 5.0
			is_at_edge = true 
			#print("Is at edge:",is_at_edge)
			
	# 4. Reset the lock when they move away from the edge
	else:
		is_at_edge = false

	# 5. Game Over check
	if $InvaderContainer.position.y > 500.0: 
		game_over()

func start_game():
	$UILayer/SplashScreen.visible = false
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = true
	
	game_active = true
	score = 0
	invader_speed = 60.0 # Reset speed
	invader_direction = 1
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
	# Update the label in the HUD
	if GameInput.connected:
		$UILayer/HUD/ModeLabel.text = "JOYSTICK MODE" 
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

#func restart_game():
#	# Clear existing invaders
#	for child in $InvaderContainer.get_children():
#		child.queue_free()
#	start_game()
func restart_game():
	# Clear existing invaders
	for child in $InvaderContainer.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Reset game state
	game_active = false
	start_game()
