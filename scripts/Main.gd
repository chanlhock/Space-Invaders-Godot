extends Node2D

# --- Game State Variables ---
var score = 0
var game_active = false
var is_at_edge = false 

# ... (replace your old _process function with this one) ...
# --- Invader Group Movement Variables ---
var invader_direction = 1  # 1 = Right, -1 = Left
var invader_speed = 30.0   # Starting speed
var drop_amount = 8.0     # How far they drop when hitting the edge
var edge_limit = 50.0      # Distance from screen edge to trigger turn
var formation_width = 660.0 # 11 invaders * 60 spacing = 660 pixels wide

# --- Grid Settings ---
@export var rows = 3
@export var cols = 11
@export var invader_scene: PackedScene

func _ready():
	# Initial UI Setup
	$UILayer/SplashScreen.visible = true
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = false
	
	# Simulate startup delay, then start game
	await get_tree().create_timer(2.0).timeout
	start_game()

func _process(delta):
	if not game_active:
		return

	# 1. Move the container horizontally
	$InvaderContainer.position.x += invader_direction * invader_speed * delta
	
	var screen_width = get_viewport_rect().size.x
	
	# Calculate the actual right edge of the invaders
	var right_edge_of_invaders = $InvaderContainer.position.x + formation_width
	
	# 2. Check Right Edge (using the actual invader position)
	if right_edge_of_invaders > screen_width - 20: 
		if not is_at_edge: 
			invader_direction = -1 # Bounce left
			$InvaderContainer.position.y += drop_amount
			invader_speed += 5.0
			is_at_edge = true 
			
	# 3. Check Left Edge (Invaders start at x=50 inside container, so check < 30)
	elif $InvaderContainer.position.x < 20:
		if not is_at_edge: 
			invader_direction = 1 # Bounce right
			$InvaderContainer.position.y += drop_amount
			invader_speed += 5.0
			is_at_edge = true 
			
	# 4. Reset the lock when they move away from the edge
	else:
		is_at_edge = false

	# 5. Game Over check
	if $InvaderContainer.position.y > 400: 
		game_over()

func start_game():
	$UILayer/SplashScreen.visible = false
	$UILayer/GameOverScreen.visible = false
	$UILayer/HUD.visible = true
	
	game_active = true
	score = 0
	invader_speed = 30.0 # Reset speed
	invader_direction = 1
	$InvaderContainer.position = Vector2(2, 20) 
	
	update_score()
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

func game_over():
	game_active = false
	$UILayer/GameOverScreen.visible = true
	$UILayer/HUD.visible = false

func restart_game():
	# Clear existing invaders
	for child in $InvaderContainer.get_children():
		child.queue_free()
	start_game()
