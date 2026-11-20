class_name Player
extends Area2D

## The player ship. A glowing cyan dart that moves with WASD / arrow keys
## or by dragging with the mouse / touch. Leaves a fading neon trail.

signal died

const SPEED := 460.0
const ACCEL := 2400.0
const MARGIN := 28.0
const TRAIL_LENGTH := 18

var velocity := Vector2.ZERO
var alive := true

var _trail: Line2D
var _trail_points: Array[Vector2] = []


func _ready() -> void:
	add_to_group("player")

	# Soft cyan halo behind the ship (additive = neon glow).
	var halo := Sprite2D.new()
	halo.texture = NeonTextures.glow(Color(0.2, 0.9, 1.0), 160)
	halo.scale = Vector2.ONE * 1.6
	halo.material = NeonTextures.additive_material()
	add_child(halo)

	# Ship body: white dart with a cyan core.
	var ship := Polygon2D.new()
	ship.polygon = PackedVector2Array([
		Vector2(18, 0), Vector2(-12, 12), Vector2(-6, 0), Vector2(-12, -12)
	])
	ship.color = Color(0.95, 1.0, 1.0)
	add_child(ship)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(10, 0), Vector2(-7, 6), Vector2(-3, 0), Vector2(-7, -6)
	])
	core.color = Color(0.15, 0.8, 1.0)
	add_child(core)

	# Neon trail. It lives in world space (child of the Main node) so it
	# does not rotate with the ship.
	_trail = Line2D.new()
	_trail.width = 5.0
	_trail.default_color = Color(0.2, 0.9, 1.0, 0.8)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 0.9, 1.0, 0.9))
	grad.set_color(1, Color(0.2, 0.9, 1.0, 0.0))
	_trail.gradient = grad
	# Drawn above the background (Main draws its background rect first),
	# so the trail stays visible. z_index -1 would hide it behind the bg.
	_trail.z_index = 1
	get_parent().add_child(_trail)

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not alive:
		return

	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	var target := dir.normalized() * SPEED if dir != Vector2.ZERO else Vector2.ZERO
	velocity = velocity.move_toward(target, ACCEL * delta)

	# Drag with mouse / touch: the ship chases the pointer.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to := get_global_mouse_position() - position
		if to.length() > 8.0:
			velocity = to.normalized() * SPEED

	position += velocity * delta

	var vp := get_viewport_rect().size
	position.x = clampf(position.x, MARGIN, vp.x - MARGIN)
	position.y = clampf(position.y, MARGIN, vp.y - MARGIN)

	if velocity.length() > 10.0:
		rotation = lerp_angle(rotation, velocity.angle(), 12.0 * delta)

	_trail_points.push_front(position)
	if _trail_points.size() > TRAIL_LENGTH:
		_trail_points.pop_back()
	_trail.points = PackedVector2Array(_trail_points)


func _on_area_entered(area: Area2D) -> void:
	if not alive:
		return
	if area.is_in_group("pickup"):
		area.collect()
	elif area.is_in_group("enemy"):
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	visible = false
	_trail.visible = false
	set_deferred("monitoring", false)
	died.emit()
