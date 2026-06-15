# res://scripts/HUD.gd
extends Control

# FPS variables
var fps_history = []
var last_fps_update = 0.0
var update_interval = 0.5

# UI elements
@onready var score_label = $ScoreLabel
@onready var mode_label = $ModeLabel
@onready var sound_label = $SoundLabel
@onready var fps_label = $FPSLabel

# New UI elements for joystick data
@onready var wifi_status_label = $WiFiConnectLabel
@onready var raw_data_label = $RawWiFiDataLabel
@onready var button_status_label = $ButtonStatusLabel
@onready var calib_label = $CalibLabel
@onready var packet_label = $PacketLabel

# Joystick position bar variables
var joystick_bar = null
var joystick_indicator = null
var joystick_center_line = null

func _ready():
	# Initialize FPS tracking
	last_fps_update = Time.get_ticks_msec() / 1000.0
	
	# Create FPS label if it doesn't exist
	if not fps_label:
		fps_label = Label.new()
		fps_label.name = "FPSLabel"
		add_child(fps_label)
	
	# Style the FPS label
	fps_label.add_theme_color_override("font_color", Color.GREEN)
	fps_label.add_theme_font_size_override("font_size", 16)
	
	# Create WiFi status label if it doesn't exist
	if not wifi_status_label:
		wifi_status_label = Label.new()
		wifi_status_label.name = "WiFiConnectLabel"
		add_child(wifi_status_label)
		wifi_status_label.add_theme_font_size_override("font_size", 14)
	
	# Create raw data label if it doesn't exist
	if not raw_data_label:
		raw_data_label = Label.new()
		raw_data_label.name = "RawWiFiDataLabel"
		add_child(raw_data_label)
		raw_data_label.add_theme_font_size_override("font_size", 12)
	
	# Create button status label if it doesn't exist
	if not button_status_label:
		button_status_label = Label.new()
		button_status_label.name = "ButtonStatusLabel"
		add_child(button_status_label)
		button_status_label.add_theme_font_size_override("font_size", 12)
	
	# Create calibration label if it doesn't exist
	if not calib_label:
		calib_label = Label.new()
		calib_label.name = "CalibLabel"
		add_child(calib_label)
		calib_label.add_theme_font_size_override("font_size", 12)
	
	# Create packet label if it doesn't exist
	if not packet_label:
		packet_label = Label.new()
		packet_label.name = "PacketLabel"
		add_child(packet_label)
		packet_label.add_theme_font_size_override("font_size", 12)
	
	# Create joystick position bar
	create_joystick_bar()
	
	# Position all labels
	await get_tree().process_frame
	position_labels()

func create_joystick_bar():
	"""Create the visual joystick position bar"""
	# Create container for the bar
	joystick_bar = ColorRect.new()
	joystick_bar.name = "JoystickBar"
	joystick_bar.color = Color(0.2, 0.2, 0.2)  # Dark gray background
	add_child(joystick_bar)
	
	# Create indicator (the position marker)
	joystick_indicator = ColorRect.new()
	joystick_indicator.name = "JoystickIndicator"
	joystick_indicator.color = Color.YELLOW
	joystick_bar.add_child(joystick_indicator)
	
	# Create center line
	joystick_center_line = ColorRect.new()
	joystick_center_line.name = "CenterLine"
	joystick_center_line.color = Color.WHITE
	joystick_bar.add_child(joystick_center_line)

func position_labels():
	"""Position all labels properly"""
	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# FPS label at top-right
	if fps_label:
		fps_label.position = Vector2(screen_width - 100, 2)
	
	# WiFi status at bottom-left area
	if wifi_status_label:
		wifi_status_label.position = Vector2(8, screen_height - 145)
	
	# Raw data label below WiFi status
	if raw_data_label:
		raw_data_label.position = Vector2(8, screen_height - 124)
	
	# Calibration label below raw data
	if calib_label:
		calib_label.position = Vector2(8, screen_height - 105)
	
	# Position joystick bar below calibration label
	if joystick_bar:
		var bar_width = 200
		var bar_height = 15
		var bar_x = 8
		var bar_y = screen_height - 76
		joystick_bar.position = Vector2(bar_x, bar_y)
		joystick_bar.size = Vector2(bar_width, bar_height)
		
		# Position center line
		if joystick_center_line:
			joystick_center_line.position = Vector2(bar_width / 2 - 1, -2)
			joystick_center_line.size = Vector2(2, bar_height + 4)
	
	# Button status label below joystick bar
	if button_status_label:
		button_status_label.position = Vector2(8, screen_height - 56)
	
	# Packet label below button status
	if packet_label:
		packet_label.position = Vector2(8, screen_height - 37)

func update_joystick_bar(calibrated_x: float):
	"""Update the joystick position bar based on calibrated value (-100 to 100)"""
	if not joystick_bar or not joystick_indicator:
		return
	
	var bar_width = joystick_bar.size.x
	var bar_height = joystick_bar.size.y
	
	# Calculate position (-100 to 100 -> 0 to bar_width)
	# calibrated_x: -100 = left, 0 = center, 100 = right
	var pos = int(((calibrated_x + 100) / 200) * bar_width)
	pos = clamp(pos, 0, bar_width)
	
	# Set indicator color based on intensity
	var indicator_color = Color.YELLOW
	if abs(calibrated_x) > 50:
		indicator_color = Color.RED
	elif abs(calibrated_x) > 20:
		indicator_color = Color.ORANGE
	else:
		indicator_color = Color.YELLOW
	
	# Update indicator position and color
	joystick_indicator.position = Vector2(pos - 2, -2)
	joystick_indicator.size = Vector2(4, bar_height + 4)
	joystick_indicator.color = indicator_color

func _process(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Update FPS every 0.5 seconds
	if current_time - last_fps_update >= update_interval:
		var current_fps = Engine.get_frames_per_second()
		fps_history.append(current_fps)
		
		# Keep only last 10 samples
		while fps_history.size() > 10:
			fps_history.pop_front()
		
		last_fps_update = current_time
		update_fps_display()
	
	# Update joystick data display
	update_joystick_display()
	
	# Update position if window is resized
	if get_viewport().get_visible_rect().size.x != (fps_label.position.x + 100 if fps_label else 0):
		position_labels()

func update_fps_display():
	if fps_history.is_empty():
		if fps_label:
			fps_label.text = "FPS: 0"
		return
	
	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_history:
		avg_fps += fps
	avg_fps /= fps_history.size()
	
	# Color based on performance
	var fps_color = Color.GREEN
	if avg_fps < 30:
		fps_color = Color.RED
	elif avg_fps < 50:
		fps_color = Color.YELLOW
	
	if fps_label:
		fps_label.add_theme_color_override("font_color", fps_color)
		fps_label.text = "FPS: %.1f" % avg_fps

func update_joystick_display():
	"""Update WiFi status, raw data, button status, calibration, and packet count displays"""
	# Check if GameInput exists and is connected
	var is_connected = false
	var raw_x = 0.0
	var raw_y = 0.0
	var calibrated_x = 0.0
	var button_pressed = false
	var packet_count = 0
	
	if has_node("/root/GameInput"):
		is_connected = GameInput.is_device_connected()
		raw_x = GameInput.get_raw_x()
		raw_y = GameInput.get_raw_y()
		calibrated_x = GameInput.get_calibrated_x()
		button_pressed = GameInput.is_button_pressed()
		packet_count = GameInput.get_packet_count()
	
	# Update WiFi status label
	if wifi_status_label:
		if is_connected:
			wifi_status_label.text = "WiFi: RECEIVING DATA"
			wifi_status_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		else:
			wifi_status_label.text = "WiFi: NO DATA"
			wifi_status_label.add_theme_color_override("font_color", Color.RED)
	
	# Update raw data label
	if raw_data_label:
		if is_connected:
			# Convert raw values (0-1 range) back to 0-65535 range for display
			var raw_x_int = int(raw_x * 65535)
			var raw_y_int = int(raw_y * 65535)
			var x_percent = int(raw_x * 100)
			var y_percent = int(raw_y * 100)
			raw_data_label.text = "Raw X: %5d (%3d%%)  Y: %5d (%3d%%)" % [raw_x_int, x_percent, raw_y_int, y_percent]
		else:
			raw_data_label.text = "Raw X: 32768 Y: 32768"
	
	# Update calibration label
	if calib_label:
		if is_connected:
			# Show calibrated value (-100 to 100 range)
			var direction = ""
			if calibrated_x < -10:
				direction = "LEFT"
			elif calibrated_x > 10:
				direction = "RIGHT"
			else:
				direction = "CENTER"
			
			calib_label.text = "Calib: %+6.1f%%  [%s]" % [calibrated_x, direction]
			
			# Color based on intensity
			if abs(calibrated_x) > 50:
				calib_label.add_theme_color_override("font_color", Color.RED)
			elif abs(calibrated_x) > 20:
				calib_label.add_theme_color_override("font_color", Color.ORANGE)
			else:
				calib_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			calib_label.text = "Calib: +0.0%"
			calib_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Update joystick position bar
	if is_connected:
		update_joystick_bar(calibrated_x)
	elif joystick_indicator:
		# Reset to center when disconnected
		update_joystick_bar(0)
	
	# Update button status label
	if button_status_label:
		if is_connected:
			if button_pressed:
				button_status_label.text = "Button: PRESSED"
				button_status_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				button_status_label.text = "Button: RELEASED"
				button_status_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			button_status_label.text = "Button: RELEASED"
	
	# Update packet label
	if packet_label:
		if is_connected:
			packet_label.text = "Packets: %d" % packet_count
			packet_label.add_theme_color_override("font_color", Color.CYAN)
		else:
			packet_label.text = "Packets: 0"
			packet_label.add_theme_color_override("font_color", Color.GRAY)

# Update score (existing function)
func update_score(score: int):
	if score_label:
		score_label.text = "Score: %d" % score

# Update mode (existing function)
func update_mode(mode: String):
	if mode_label:
		mode_label.text = mode

# Update sound status (existing function)
func update_sound_status(sound_on: bool):
	if sound_label:
		sound_label.text = "SOUND ON" if sound_on else "SOUND OFF"
