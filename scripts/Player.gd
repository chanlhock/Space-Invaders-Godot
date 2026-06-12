extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

# Change cooldown to milliseconds (500ms = 0.5 seconds)
var last_fire_time = 0 
var fire_cooldown = 500 

func _physics_process(_delta):
	var direction = 0.0

	# 1. Keyboard Input (Prioritized)
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	elif Input.is_action_pressed("move_right"):
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
		fire_bullet()
		last_fire_time = Time.get_ticks_msec()

	velocity.x = direction * speed
	move_and_slide()

	# 4. Keep player within screen bounds (Fixed to account for sprite width)
	# This stops the exact edge of the ship from touching the wall, rather than the center of the ship
	var half_width = $Sprite2D.texture.get_width() / 2.0
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, half_width, screen_width - half_width)

#func fire_bullet():
#	if bullet_scene:
#		var bullet = bullet_scene.instantiate()
#		bullet.position = position + Vector2(0, -20)
#		
#		# Add to the BulletContainer if it exists, otherwise add to parent
#		if get_node_or_null("/root/Main/BulletContainer"):
#			get_node("/root/Main/BulletContainer").add_child(bullet)
#		else:
#			get_parent().add_child(bullet)
			
func fire_bullet():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, -20)
		
		# Add to the BulletContainer if it exists, otherwise add to parent
		var main = get_node_or_null("/root/Main")
		if main and main.has_node("BulletContainer"):
			main.get_node("BulletContainer").add_child(bullet)
		else:
			# Create BulletContainer if it doesn't exist
			if main and not main.has_node("BulletContainer"):
				var container = Node2D.new()
				container.name = "BulletContainer"
				main.add_child(container)
				container.add_child(bullet)
			else:
				get_parent().add_child(bullet)
