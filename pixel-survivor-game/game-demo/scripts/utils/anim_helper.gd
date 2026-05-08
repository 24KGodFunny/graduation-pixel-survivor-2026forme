class_name AnimHelper
## 动画工具类 - 为游戏实体提供出生、受击、死亡等动画效果
## 所有动画基于 Tween 实现，无需额外美术资源

## 出生动画：从透明渐现 + 缩放弹跳
static func play_spawn(node: Node2D, duration: float = 0.5, callback: Callable = Callable()):
	var original_scale = node.scale
	node.modulate.a = 0.0
	node.scale = original_scale * 0.3
	
	var tween = node.create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale * 1.2, duration * 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(node, "scale", original_scale, duration * 0.4).set_ease(Tween.EASE_IN_OUT)
	
	if callback.is_valid():
		tween.chain().tween_callback(callback)

## 受击闪白效果
static func play_hit_flash(node: Node2D, duration: float = 0.15):
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", Color(10, 10, 10, 1), duration * 0.3)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.7)

## 受击闪红效果（玩家专用）
static func play_hit_red(node: Node2D, duration: float = 0.2):
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", Color(1.0, 0.3, 0.3, 1.0), duration * 0.4)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.6)

## 死亡动画：闪红 → 缩小 → 淡出
static func play_death(node: Node2D, duration: float = 0.6, callback: Callable = Callable()):
	# 禁用碰撞
	for child in node.get_children():
		if child is CollisionShape2D or child is Area2D:
			child.set_deferred("disabled", true)
	
	var tween = node.create_tween().set_parallel(false)
	# 闪红
	tween.tween_property(node, "modulate", Color(2.0, 0.2, 0.2, 1.0), duration * 0.2)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.1)
	tween.tween_property(node, "modulate", Color(2.0, 0.2, 0.2, 1.0), duration * 0.15)
	# 缩小 + 淡出
	tween.set_parallel(true)
	tween.tween_property(node, "scale", node.scale * 0.1, duration * 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 0.0, duration * 0.4).set_ease(Tween.EASE_IN)
	
	if callback.is_valid():
		tween.chain().tween_callback(callback)
	else:
		tween.chain().tween_callback(node.queue_free)

## Boss 死亡动画：多段闪烁 + 爆炸缩放 + 淡出
static func play_boss_death(node: Node2D, duration: float = 1.5, callback: Callable = Callable()):
	for child in node.get_children():
		if child is CollisionShape2D or child is Area2D:
			child.set_deferred("disabled", true)
	
	var tween = node.create_tween().set_parallel(false)
	# 多段闪烁
	for i in range(4):
		var flash_dur = duration * 0.08 * (1.0 + i * 0.3)
		tween.tween_property(node, "modulate", Color(3.0, 0.5, 0.5, 1.0), flash_dur)
		tween.tween_property(node, "modulate", Color(0.5, 0.5, 0.5, 1.0), flash_dur)
	# 爆炸缩放
	tween.tween_property(node, "scale", node.scale * 1.5, duration * 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ZERO, duration * 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 0.0, duration * 0.3).set_ease(Tween.EASE_IN)
	
	if callback.is_valid():
		tween.chain().tween_callback(callback)
	else:
		tween.chain().tween_callback(node.queue_free)

## Boss 出生动画：更大缩放 + 震屏
static func play_boss_spawn(node: Node2D, duration: float = 1.0, callback: Callable = Callable()):
	var original_scale = node.scale
	node.modulate.a = 0.0
	node.scale = original_scale * 3.0
	
	var tween = node.create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# 震屏效果
	var camera = node.get_viewport().get_camera_2d()
	if camera:
		var cam_tween = node.create_tween()
		for i in range(3):
			var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
			cam_tween.tween_property(camera, "offset", offset, duration * 0.1)
		cam_tween.tween_property(camera, "offset", Vector2.ZERO, duration * 0.15)
	
	if callback.is_valid():
		tween.chain().tween_callback(callback)

## 攻击动画：快速缩放脉冲
static func play_attack(node: Node2D, duration: float = 0.2):
	var original_scale = node.scale
	var tween = node.create_tween()
	tween.tween_property(node, "scale", original_scale * 1.15, duration * 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale, duration * 0.6).set_ease(Tween.EASE_IN_OUT)

## 屏幕震动效果
static func play_screen_shake(node: Node2D, intensity: float = 5.0, duration: float = 0.3):
	var camera = node.get_viewport().get_camera_2d()
	if not camera:
		return
	var original_offset = camera.offset
	var tween = node.create_tween()
	var steps = int(duration / 0.05)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.05)
	tween.tween_property(camera, "offset", original_offset, 0.05)

## 死亡爆裂粒子效果（程序化生成）
static func spawn_death_particles(node: Node2D, color: Color, count: int = 8):
	var parent = node.get_parent()
	if not parent:
		return
	for i in range(count):
		var particle = _create_particle(color)
		particle.global_position = node.global_position
		parent.add_child(particle)
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)
		var dist = randf_range(20, 50)
		var target = node.global_position + Vector2(cos(angle), sin(angle)) * dist
		var tween = particle.create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", target, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		tween.tween_property(particle, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(particle.queue_free)

static func _create_particle(color: Color) -> Sprite2D:
	var particle = Sprite2D.new()
	var img = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(color)
	particle.texture = ImageTexture.create_from_image(img)
	particle.modulate = color
	particle.scale = Vector2(randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	return particle