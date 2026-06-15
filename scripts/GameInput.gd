# res://scripts/GameInput.gd
extends Node

# Joystick raw values (0-1 range from Pico)
var raw_joystick_x = 0.5
var raw_joystick_y = 0.5

# Calibrated values (-100 to 100 range, matching your Python code)
var calibrated_joystick_x = 0.0
var calibrated_joystick_y = 0.0

# Button state
var button_pressed = false
var device_connected = false
var receive_count = 0

# UDP using PacketPeerUDP
var udp = PacketPeerUDP.new()
var listen_port = 9000
var last_packet_time = 0

# Calibration parameters (matching your Python code)
var x_center = 0.77  # From your logs - adjust if needed
var x_min = 0.0
var x_max = 1.0
var x_deadzone = 0.08  # 8% deadzone

# Auto-calibration
var is_calibrating = false
var calibration_samples = []

func _ready():
	print("GameInput: Starting UDP listener on port ", listen_port)
	var error = udp.bind(listen_port, "0.0.0.0")
	if error == OK:
		print("GameInput: UDP socket bound successfully")
		# Auto-calibrate after 2 seconds
		call_deferred("auto_calibrate")
	else:
		print("GameInput: Failed to bind UDP port - error ", error)

func auto_calibrate():
	print("GameInput: Auto-calibrating joystick... Please center the joystick")
	is_calibrating = true
	calibration_samples = []
	
	# Collect samples for 2 seconds
	for i in range(60):
		await get_tree().create_timer(0.033).timeout
	
	if calibration_samples.size() > 0:
		var sum = 0.0
		for sample in calibration_samples:
			sum += sample
		x_center = sum / calibration_samples.size()
		print("GameInput: Calibration complete - Center: ", x_center)
		
		# Set min and max based on expected range
		x_min = x_center - 0.5
		x_max = x_center + 0.5
	
	is_calibrating = false

# Calibration function matching your Python code exactly
func calibrate_joystick(raw_value: float) -> float:
	"""Convert raw joystick value to calibrated value (-100 to 100)"""
	if abs(raw_value - x_center) < x_deadzone:
		return 0
	
	if raw_value < x_center:
		if raw_value <= x_min:
			return -100
		return -((x_center - raw_value) / (x_center - x_min)) * 100
	else:
		if raw_value >= x_max:
			return 100
		return ((raw_value - x_center) / (x_max - x_center)) * 100

func _process(delta):
	# Check for incoming packets
	if udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var data_string = packet.get_string_from_utf8()
		receive_count += 1
		
		# Parse CSV: x_val,y_val,x_percent,y_percent,button
		var parts = data_string.split(",")
		if parts.size() >= 5:
			var x_percent = float(parts[2]) / 100.0  # Convert to 0-1 range
			var y_percent = float(parts[3]) / 100.0
			var button_val = int(parts[4])
			
			# Store raw values
			raw_joystick_x = x_percent
			raw_joystick_y = y_percent
			
			# Collect samples for calibration
			if is_calibrating:
				calibration_samples.append(x_percent)
			
			# Calculate calibrated values (matching your Python code)
			calibrated_joystick_x = calibrate_joystick(x_percent)
			calibrated_joystick_y = calibrate_joystick(y_percent)
			
			# Update button state (1 = pressed in your format)
			button_pressed = (button_val == 1)
			
			if not device_connected:
				device_connected = true
				print("GameInput: ✅ Connected to Pi Pico W! (Packet ", receive_count, ")")
			
			# Print occasional debug info (matching your Python code)
			if receive_count % 10 == 0:
				var direction = "CENTER"
				if calibrated_joystick_x < -10:
					direction = "LEFT"
				elif calibrated_joystick_x > 10:
					direction = "RIGHT"
				
				#print("DEBUG - Raw X=", x_percent, " | Calibrated=", calibrated_joystick_x, " | ", direction)
			
			last_packet_time = Time.get_ticks_msec()
	
	# Timeout after 2 seconds of no data
	if device_connected and Time.get_ticks_msec() - last_packet_time > 2000:
		device_connected = false
		print("GameInput: Disconnected - timeout")

# Public functions matching your Python interface
func get_raw_x() -> float:
	return raw_joystick_x

func get_raw_y() -> float:
	return raw_joystick_y

func get_calibrated_x() -> float:
	return calibrated_joystick_x

func get_calibrated_y() -> float:
	return calibrated_joystick_y

# Legacy functions for compatibility
func get_joystick_x() -> float:
	return calibrated_joystick_x / 100.0

func get_joystick_y() -> float:
	return calibrated_joystick_y / 100.0

func is_button_pressed() -> bool:
	return button_pressed

func is_device_connected() -> bool:
	return device_connected

func get_packet_count() -> int:
	return receive_count

func get_movement_vector() -> Vector2:
	return Vector2(get_joystick_x(), -get_joystick_y())

func _exit_tree():
	if udp:
		udp.close()
		print("GameInput: UDP socket closed")
