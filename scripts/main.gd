extends Node2D

## Neon Rush — game controller.
## Spawns pickups and enemies, tracks score / combo / best, draws the
## neon grid background, and handles game over + restart.

const PickupScene := preload("res://pickup.tscn")
const EnemyScene := preload("res://enemy.tscn")
const PlayerScene := preload("res://player.tscn")

const ARENA_MARGIN := 60.0
const MAX_PICKUPS := 7
const BEST_SAVE_PATH := "user://neon_rush_best.save"

var score := 0
var best := 0
var combo := 0
var combo_timer := 0.0
var playing := false
var elapsed := 0.0
var enemy_interval := 1.7
var enemy_speed := 150.0

var player: Player
var shake := 0.0
var _stars: Array[Vector2] = []

@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel

var _spawn_pickup_in := 0.4
var _spawn_enemy_in := 1.2


func _ready() -> void:
	randomize()
	best = _load_best()

	# Precompute starfield dots for the background.
	var vp := get_viewport_rect().size
	for i in range(90):
		_stars.append(Vector2(randf() * vp.x, randf() * vp.y))
	queue_redraw()

	player = PlayerScene.instantiate() as Player
	player.position = vp * 0.5
	add_child(player)
	player.died.connect(_on_player_died)

	playing = true
	_update_hud()

	# Hint fades out after a few seconds.
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.0)


func _draw() -> void:
	var vp := get_viewport_rect().size
	# Deep-space background.
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.03, 0.09))
	# Neon grid.
	var grid_col := Color(0.25, 0.5, 0.9, 0.10)
	var step := 64.0
	var x := 0.0
	while x <= vp.x:
		draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_col, 1.0)
		x += step
	var y := 0.0
	while y <= vp.y:
		draw_line(Vector2(0, y), Vector2(vp.x, y), grid_col, 1.0)
		y += step
	# Stars.
	for s in _stars:
		draw_circle(s, 1.5, Color(1, 1, 1, 0.45))
	# Arena frame.
	draw_rect(Rect2(Vector2(8, 8), vp - Vector2(16, 16)), Color(0.2, 0.9, 1.0, 0.35), false, 2.0)


func _process(delta: float) -> void:
	if playing:
		elapsed += delta
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

		_spawn_pickup_in -= delta
		if _spawn_pickup_in <= 0.0:
			_spawn_pickup()
			_spawn_pickup_in = randf_range(0.7, 1.2)

		_spawn_enemy_in -= delta
		if _spawn_enemy_in <= 0.0:
			_spawn_enemy()
			enemy_interval = maxf(0.65, 1.7 - elapsed * 0.012)
			_spawn_enemy_in = enemy_interval

	if shake > 0.0:
		shake -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 30.0
		if shake <= 0.0:
			camera.offset = Vector2.ZERO

	if not playing and Input.is_key_pressed(KEY_R):
		_restart()


func _spawn_pickup() -> void:
	if get_tree().get_nodes_in_group("pickup").size() >= MAX_PICKUPS:
		return
	var p := PickupScene.instantiate() as Pickup
	var vp := get_viewport_rect().size
	p.position = Vector2(
		randf_range(ARENA_MARGIN, vp.x - ARENA_MARGIN),
		randf_range(ARENA_MARGIN, vp.y - ARENA_MARGIN)
	)
	p.collected.connect(_on_pickup_collected)
	add_child(p)


func _spawn_enemy() -> void:
	var e := EnemyScene.instantiate() as Enemy
	var vp := get_viewport_rect().size
	var edge := randi() % 4
	var pos := Vector2.ZERO
	match edge:
		0:
			pos = Vector2(randf() * vp.x, -40.0)
		1:
			pos = Vector2(randf() * vp.x, vp.y + 40.0)
		2:
			pos = Vector2(-40.0, randf() * vp.y)
		_:
			pos = Vector2(vp.x + 40.0, randf() * vp.y)
	var kind := Enemy.KIND_DRIFTER if randf() < 0.25 else Enemy.KIND_CHASER
	var speed := minf(340.0, enemy_speed + elapsed * 1.5)
	e.setup(kind, speed, pos, player.position if player != null else vp * 0.5)
	add_child(e)


func _on_pickup_collected(pickup: Pickup) -> void:
	combo += 1
	combo_timer = 3.0
	var gained := 10 + (combo - 1) * 5
	score += gained
	_burst(pickup.position, Color(1.0, 0.8, 0.25))
	_popup(pickup.position, "+%d" % gained, Color(1.0, 0.9, 0.5))
	_update_hud()


func _on_player_died() -> void:
	playing = false
	shake = 0.35
	_burst(player.position, Color(0.2, 0.9, 1.0))
	if score > best:
		best = score
		_save_best()
	final_score_label.text = "Score: %d   •   Best: %d" % [score, best]
	game_over_panel.visible = true


func _on_play_again_pressed() -> void:
	_restart()


func _restart() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	score_label.text = "SCORE  %d" % score
	if combo > 1:
		score_label.text += "   x%d COMBO" % combo
	best_label.text = "BEST  %d" % best


func _burst(pos: Vector2, color: Color) -> void:
	var p := GPUParticles2D.new()
	p.amount = 24
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.9
	p.position = pos
	p.texture = NeonTextures.glow(color, 64)
	p.material = NeonTextures.additive_material()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 320.0
	mat.damping_min = 60.0
	mat.damping_max = 120.0
	mat.scale_min = 0.4
	mat.scale_max = 0.9
	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	mat.color_ramp = tex
	p.process_material = mat
	add_child(p)
	p.emitting = true
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(p.queue_free)


func _popup(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.position = pos + Vector2(-12, -24)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func _load_best() -> int:
	if FileAccess.file_exists(BEST_SAVE_PATH):
		var f := FileAccess.open(BEST_SAVE_PATH, FileAccess.READ)
		if f != null:
			return int(f.get_as_text())
	return 0


func _save_best() -> void:
	var f := FileAccess.open(BEST_SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(str(best))
