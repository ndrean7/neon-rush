class_name Enemy
extends Area2D

## Hostile drone. Two kinds:
## - chaser: a red spiked star that steers toward the player.
## - drifter: an orange spiked star that flies straight and bounces off
##   the arena edges.

const KIND_CHASER := "chaser"
const KIND_DRIFTER := "drifter"

var kind := KIND_CHASER
var speed := 150.0
var direction := Vector2.RIGHT

var _time := 0.0
var _spin := 1.5
var _star: Polygon2D


func setup(p_kind: String, p_speed: float, start_pos: Vector2, target: Vector2) -> void:
	kind = p_kind
	speed = p_speed
	position = start_pos
	direction = (target - start_pos).normalized()
	if kind == KIND_DRIFTER:
		direction = direction.rotated(randf_range(-0.6, 0.6))


func _ready() -> void:
	add_to_group("enemy")

	var col := Color(1.0, 0.25, 0.45) if kind == KIND_CHASER else Color(1.0, 0.55, 0.2)
	var halo := Sprite2D.new()
	halo.texture = NeonTextures.glow(col, 160)
	halo.scale = Vector2.ONE * 1.4
	halo.material = NeonTextures.additive_material()
	add_child(halo)

	# Spiked star body.
	_star = Polygon2D.new()
	var pts := PackedVector2Array()
	var spikes := 8
	for i in range(spikes * 2):
		var ang := TAU * float(i) / float(spikes * 2)
		var r := 20.0 if i % 2 == 0 else 9.0
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	_star.polygon = pts
	_star.color = Color(1.0, 1.0, 1.0) if kind == KIND_CHASER else Color(1.0, 0.85, 0.4)
	add_child(_star)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	_star.rotation += _spin * delta
	var pulse := 1.0 + sin(_time * 6.0) * 0.08
	_star.scale = Vector2.ONE * pulse

	if kind == KIND_CHASER:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null and player.alive:
			direction = (player.global_position - global_position).normalized()

	position += direction * speed * delta

	var vp := get_viewport_rect().size
	if kind == KIND_DRIFTER:
		if position.x < 20.0 or position.x > vp.x - 20.0:
			direction.x *= -1.0
		if position.y < 20.0 or position.y > vp.y - 20.0:
			direction.y *= -1.0
		position.x = clampf(position.x, 20.0, vp.x - 20.0)
		position.y = clampf(position.y, 20.0, vp.y - 20.0)
	else:
		# Chasers that drift far off-screen are removed so the arena
		# never clogs up.
		if position.x < -80.0 or position.x > vp.x + 80.0:
			queue_free()
		elif position.y < -80.0 or position.y > vp.y + 80.0:
			queue_free()
