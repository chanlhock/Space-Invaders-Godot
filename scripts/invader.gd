extends Area2D

func _ready():
	# Connect the signal to detect when a bullet hits this invader
	area_entered.connect(_on_area_entered)
	# 2. Connect signal for Player collision (NEW)
	body_entered.connect(_on_body_entered)
	
func _on_area_entered(area):
	# Check if the object that hit us is a bullet
	# Note: You MUST add your Bullet scene to the "bullets" group in Godot!
	if area.is_in_group("bullets"):
		take_damage()

func _on_body_entered(body):
	# Check if the body that hit us is the Player
	# Note: This requires your Player node to be named exactly "Player"
	if body.name == "Player":
		# Tell the Main script to trigger Game Over
		get_node("/root/Main").game_over()

func take_damage():
	# Find the Main node to update the score
	var main = get_node("/root/Main")
	if main:
		main.score += 10
		main.update_score()
		
		# Check if all invaders are dead to spawn a new wave
		# FIX: Changed main.$InvaderContainer to main.get_node("InvaderContainer")
		if main.get_node("InvaderContainer").get_child_count() <= 1:
			main.spawn_invaders()
			main.invader_speed += 5.0 # Make the next wave faster!
			
	# Destroy this invader
	queue_free()
