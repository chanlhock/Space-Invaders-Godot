extends CharacterBody2D

@export var speed = 300.0
@export var bullet_scene: PackedScene

# Change cooldown to milliseconds (500ms = 0.5 seconds)
var last_fire_time = 0 
var fire_cooldown = 500 

func _physics_process(delta):
	var direction = 0.0
	
	# Keyboard Input
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
		
	# Joystick Input (from Pico W)
	if GameInput.connected:
		# Assume X axis 0.0-0.4 = left, 0.6-1.0 = right, 0.5 = center
		if GameInput.joystick_x < 0.4:
			direction -= 1.0
		elif GameInput.joystick_x > 0.6:
			direction += 1.0
			
		# Fire Button (Using milliseconds for cooldown)
		if GameInput.button_pressed and Time.get_ticks_msec() - last_fire_time > fire_cooldown:
			fire_bullet()
			last_fire_time = Time.get_ticks_msec()

	velocity.x = direction * speed
	move_and_slide()

	# Keep player within screen bounds
	position.x = clamp(position.x, 0, get_viewport_rect().size.x)

func fire_bullet():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, -20)
		
		# Add to the BulletContainer if it exists, otherwise add to parent
		if get_node_or_null("/root/Main/BulletContainer"):
			get_node("/root/Main/BulletContainer").add_child(bullet)
		else:
			get_parent().add_child(bullet)
