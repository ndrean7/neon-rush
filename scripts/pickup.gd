class_name Pickup
extends Area2D

## Energy orb. Floats, spins and pulses. Collect it for points.
## Disappears after LIFETIME seconds (blinks for the last 2 seconds).

signal collected(pickup: Pickup)

const LIFETIME := 9.0

var value := 10

var _time := 0.0
var _gem: Polygon2D
var _glow: Sprite2D
var _dead := false


func _ready() -> void:
	add_to_group("pickup")

	_glow = Sprite2D.new()
	_glow.texture = NeonTextures.glow(Color(1.0, 0.8, 0.25), 128)
	_glow.scale = Vector2.ONE * 1.1
	_glow.material = NeonTextures.additive_material()
	add_child(_glow)

	_gem = Polygon2D.new()
	_gem.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, 0), Vector2(0, 14), Vector2(-10, 0)
	])
	_gem.color = Color(1.0, 0.95, 0.6)
	add_child(_gem)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	_gem.rotation += 1.5 * delta
	var bob := sin(_time * 3.0) * 3.0
	_gem.position.y = bob
	_glow.position.y = bob
	var s := 1.0 + sin(_time * 4.0) * 0.12
	_gem.scale = Vector2.ONE * s
	if _time > LIFETIME - 2.0:
		visible = sin(_time * 12.0) > 0.0
	if _time >= LIFETIME:
		queue_free()


func collect() -> void:
	if _dead:
		return
	_dead = true
	collected.emit(self)
	queue_free()
