extends Node

signal time_changed(hour: float)
signal night_started
signal day_started

const HOURS_PER_DAY: float = 24.0
const SUNRISE_HOUR: float = 6.0
const SUNSET_HOUR: float = 18.0
const NIGHT_SKY: Color = Color(0.02, 0.03, 0.075)
const DAY_SKY: Color = Color(0.55, 0.7, 0.82)
const TWILIGHT_SKY: Color = Color(0.85, 0.38, 0.2)
const NIGHT_AMBIENT: Color = Color(0.3, 0.4, 0.65)
const WARM_SUN: Color = Color(1.0, 0.48, 0.22)
const DAY_SUN: Color = Color(1.0, 0.97, 0.88)

@export_range(1.0, 3600.0, 1.0, "or_greater") var day_length_seconds: float = 300.0
@export_range(0.0, 24.0, 0.25) var start_hour: float = 8.0
@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

var current_hour: float = 8.0
var _environment: Environment
var _last_emitted_minute: int = -1


func _ready() -> void:
	if sun == null or world_environment == null or world_environment.environment == null:
		push_error("DayNightCycle needs a sun and a WorldEnvironment with an Environment.")
		set_process(false)
		return

	_environment = world_environment.environment
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_sky_contribution = 0.0
	current_hour = fposmod(start_hour, HOURS_PER_DAY)
	_update_lighting()
	# Let signal receivers finish their _ready() before publishing the initial state.
	_publish_initial_state.call_deferred()


func _process(delta: float) -> void:
	var end_hour: float = current_hour + delta * HOURS_PER_DAY / maxf(day_length_seconds, 1.0)
	var next_boundary: float = SUNRISE_HOUR + (
		floorf((current_hour - SUNRISE_HOUR) / 12.0) + 1.0
	) * 12.0
	# Emit each crossed sunrise/sunset, including when a long frame spans both.
	while next_boundary <= end_hour:
		current_hour = fposmod(next_boundary, HOURS_PER_DAY)
		_emit_phase_started()
		next_boundary += 12.0

	current_hour = fposmod(end_hour, HOURS_PER_DAY)
	_update_lighting()
	_publish_time()


func _update_lighting() -> void:
	var sun_angle: float = (current_hour - SUNRISE_HOUR) / HOURS_PER_DAY * TAU
	var sun_height: float = sin(sun_angle)
	var daylight: float = smoothstep(-0.15, 0.35, sun_height)
	var direct_light: float = smoothstep(0.0, 0.5, sun_height)
	var twilight: float = 1.0 - smoothstep(0.0, 0.3, absf(sun_height))

	sun.rotation.x = -sun_angle
	sun.light_color = WARM_SUN.lerp(DAY_SUN, direct_light)
	sun.light_energy = direct_light * 1.1
	sun.shadow_enabled = sun_height > 0.02
	# Flat background/ambient colors avoid procedural sky and radiance-map updates.
	_environment.background_color = NIGHT_SKY.lerp(DAY_SKY, daylight).lerp(
		TWILIGHT_SKY, twilight * 0.7
	)
	_environment.ambient_light_color = NIGHT_AMBIENT.lerp(Color.WHITE, daylight).lerp(
		TWILIGHT_SKY, twilight * 0.15
	)
	_environment.ambient_light_energy = lerpf(0.22, 0.6, daylight)


func _emit_phase_started() -> void:
	if current_hour >= SUNRISE_HOUR and current_hour < SUNSET_HOUR:
		day_started.emit()
	else:
		night_started.emit()


func _publish_initial_state() -> void:
	_emit_phase_started()
	_publish_time()


func _publish_time() -> void:
	var minute_of_day: int = int(floorf(current_hour * 60.0))
	if minute_of_day != _last_emitted_minute:
		_last_emitted_minute = minute_of_day
		time_changed.emit(current_hour)
