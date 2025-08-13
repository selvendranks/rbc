extends VehicleBody3D

# --- Movement tuning ---
@export var max_engine_force: float = 10.0    # per-wheel drive force
@export var max_brake_force: float = 60.0
@export var engine_ramp: float = 6.0          # smoothing for engine force changes

# --- Steering tuning ---
@export var normal_steer_limit: float = 0.5        # ~28°
@export var crab_steer_limit: float = PI / 2.0     # 90°
@export var steer_response: float = 5.0
@export var steer_deadzone: float = 0.02

# Crab mode hold-to-adjust rate
@export var crab_steer_rate: float = 1.2           # radians/sec

# --- Wheel assignment ---
@export var steering_wheels: Array[NodePath] = []  # normal mode steering wheels
@export var drive_wheels: Array[NodePath] = []     # wheels with traction
@export var all_wheels: Array[NodePath] = []       # all 8 wheels

# Optional HUD speed label
@export var hud_speed_label: NodePath

# Internal refs
var _steer_wheels_normal: Array[VehicleWheel3D] = []
var _drive_wheels: Array[VehicleWheel3D] = []
var _all_wheels: Array[VehicleWheel3D] = []
var _active_steer_wheels: Array[VehicleWheel3D] = []
var _hud_label: Label = null

# Mode/state
var crab_mode: bool = false
var _current_steer_limit: float = 0.5
var _crab_angle_target: float = 0.0

func _ready() -> void:
	_all_wheels = _resolve_wheels(all_wheels)
	_steer_wheels_normal = _resolve_wheels(steering_wheels)
	_drive_wheels = _resolve_wheels(drive_wheels)
	if hud_speed_label != NodePath(""):
		_hud_label = get_node_or_null(hud_speed_label) as Label

	# Clear steering & traction, set up drive wheels
	for w in _all_wheels:
		if w:
			w.use_as_steering = false
			w.use_as_traction = false
			w.engine_force = 0.0  # reset

	for w in _drive_wheels:
		if w:
			w.use_as_traction = true

	crab_mode = false
	_apply_mode()

func _physics_process(delta: float) -> void:
	# Toggle crab mode
	if Input.is_action_just_pressed("crab"):
		crab_mode = !crab_mode
		_apply_mode()

	# Inputs
	var steer_input := Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	var accel_input := Input.get_action_strength("ui_up")
	var reverse_input := Input.get_action_strength("ui_down")
	var brake_input := Input.get_action_strength("brake")

	# --- Steering ---
	if crab_mode:
		if abs(steer_input) >= steer_deadzone:
			_crab_angle_target += steer_input * crab_steer_rate * delta
			_crab_angle_target = clamp(_crab_angle_target, -crab_steer_limit, crab_steer_limit)
		for w in _active_steer_wheels:
			if w:
				w.steering = move_toward(w.steering, _crab_angle_target, steer_response * delta)
	else:
		if abs(steer_input) < steer_deadzone:
			steer_input = 0.0
		var steer_target := steer_input * normal_steer_limit
		for w in _active_steer_wheels:
			if w:
				w.steering = move_toward(w.steering, steer_target, steer_response * delta)

	# --- Drive force applied per wheel ---
	var throttle := reverse_input - accel_input
	var desired_force := throttle * max_engine_force

	for w in _drive_wheels:
		if w:
			# Smooth change
			w.engine_force = lerp(w.engine_force, desired_force, clamp(engine_ramp * delta, 0.0, 1.0))

	# --- Brakes ---
	brake = brake_input * max_brake_force
	if brake_input <= 0.0 and Input.is_action_pressed("ui_select"):
		brake = max_brake_force

	# --- HUD speed ---
	if _hud_label:
		_hud_label.text = str(round(linear_velocity.length() * 3.6)) + " km/h"

func _apply_mode() -> void:
	# Reset steering flags & angles for wheels not steering
	for w in _all_wheels:
		if w:
			w.use_as_steering = false
			if not crab_mode and not (w in _steer_wheels_normal):
				w.steering = 0.0

	if crab_mode:
		_active_steer_wheels = _all_wheels
		_current_steer_limit = crab_steer_limit
		_crab_angle_target = _average_steer(_all_wheels)
	else:
		_active_steer_wheels = _steer_wheels_normal
		_current_steer_limit = normal_steer_limit

	for w in _active_steer_wheels:
		if w:
			w.use_as_steering = true

func _average_steer(wheels: Array[VehicleWheel3D]) -> float:
	var sum := 0.0
	var count := 0
	for w in wheels:
		if w:
			sum += w.steering
			count += 1
	return sum / count if count > 0 else 0.0

func _resolve_wheels(paths: Array[NodePath]) -> Array[VehicleWheel3D]:
	var out: Array[VehicleWheel3D] = []
	out.resize(paths.size())
	for i in paths.size():
		var n = get_node_or_null(paths[i])
		out[i] = n as VehicleWheel3D
	return out
