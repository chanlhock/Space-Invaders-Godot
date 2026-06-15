# res://scripts/GameInput.gd
extends Node

# Joystick values
var joystick_x = 0.5
var joystick_y = 0.5
var joystick_x_norm = 0.0
var joystick_y_norm = 0.0
var button_pressed = false
var device_connected = false

# UDP using PacketPeerUDP (works on Linux/Raspberry Pi)
var udp = PacketPeerUDP.new()
var listen_port = 9000
var last_packet_time = 0
var packet_count = 0

func _ready():
	print("GameInput: Starting UDP listener on port ", listen_port)
	var error = udp.bind(listen_port, "0.0.0.0")
	if error == OK:
		print("GameInput: UDP socket bound successfully to port ", listen_port)
		print("GameInput: Waiting for Pico W data...")
	else:
		print("GameInput: Failed to bind UDP port - error ", error)
		print("GameInput: Make sure no other program is using port ", listen_port)

func _process(delta):
	# Check for incoming packets
	if udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var data_string = packet.get_string_from_utf8()
		packet_count += 1
		
		# Parse the data
		parse_data(data_string)
		
		if not device_connected:
			device_connected = true
			print("GameInput: ✅ Connected to Pico W! (Packet ", packet_count, ")")
			print("GameInput: First packet: ", data_string)
		
		last_packet_time = Time.get_ticks_msec()
	
	# Timeout after 2 seconds of no data
	if device_connected and Time.get_ticks_msec() - last_packet_time > 2000:
		device_connected = false
		print("GameInput: Disconnected - timeout")

func parse_data(data: String):
	# Parse CSV: x_val,y_val,x_percent,y_percent,button
	var parts = data.split(",")
	if parts.size() >= 5:
		var x_percent = float(parts[2])
		var y_percent = float(parts[3])
		var button_val = int(parts[4])
		
		joystick_x = x_percent / 100.0
		joystick_y = y_percent / 100.0
		joystick_x_norm = (joystick_x * 2.0) - 1.0
		joystick_y_norm = (joystick_y * 2.0) - 1.0
		button_pressed = (button_val == 1)

# Public functions
func get_joystick_x() -> float:
	return joystick_x

func get_joystick_y() -> float:
	return joystick_y

func get_joystick_x_normalized() -> float:
	return joystick_x_norm

func get_joystick_y_normalized() -> float:
	return joystick_y_norm

func is_button_pressed() -> bool:
	return button_pressed

func is_device_connected() -> bool:
	return device_connected

func get_packet_count() -> int:
	return packet_count

func get_movement_vector() -> Vector2:
	return Vector2(joystick_x_norm, -joystick_y_norm)

func _exit_tree():
	if udp:
		udp.close()
		print("GameInput: UDP socket closed")
