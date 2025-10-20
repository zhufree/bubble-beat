class_name Boss
extends Node2D

## BOSS类
## 强大的敌人，拥有血量条和可配置的属性
##
## 设计理念:
## - 独立的BOSS实体，不依赖Enemy类
## - 属性通过export暴露给场景编辑器，可由gameplay传递数据
## - 简单的demo实现

signal defeated(boss: Boss, score: int)
signal health_changed(current_health: float, max_health: float)

# ==================== 可配置属性 ====================
@export var boss_name: String = "神秘BOSS"
@export var max_health: float = 100.0
@export var score_value: int = 100

# ==================== 运行时状态 ====================
var current_health: float
var is_defeated: bool = false
var move_tween: Tween
var attack_timer: float = 0.0

# ==================== 节点引用 ====================
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	_initialize()
	_setup_visual()
	_setup_health_bar()

## 初始化基础属性
func _initialize() -> void:
	current_health = max_health
	is_defeated = false
	attack_timer = 0.0

## 设置视觉元素
func _setup_visual() -> void:
	if sprite:
		# 使用占位符颜色
		sprite.modulate = Color(0.8, 0.2, 0.2, 1.0)  # 红色表示BOSS

## 设置血量条
func _setup_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

## 受到伤害
func take_damage(damage: float) -> void:
	if is_defeated:
		return

	current_health -= damage
	current_health = max(0, current_health)

	_update_health_bar()
	_play_hit_effect()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_on_boss_defeated()

## 更新血量条
func _update_health_bar() -> void:
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current_health, 0.2)

## 播放受伤效果
func _play_hit_effect() -> void:
	if sprite and not is_defeated:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 0.5, 1), 0.05)
		tween.tween_property(sprite, "modulate", Color(0.8, 0.2, 0.2, 1.0), 0.05)

## BOSS被击败
func _on_boss_defeated() -> void:
	is_defeated = true

	# 停止移动
	if move_tween:
		move_tween.kill()

	# 发出信号
	defeated.emit(self, score_value)

	# 播放击败动画
	_play_defeat_animation()

## 击败动画
func _play_defeat_animation() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.2
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 300
	particles.gravity = Vector2(0, 500)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(1.0, 0.2, 0.2, 1.0)
	add_child(particles)

	# 缩放+旋转+淡出动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", PI * 2, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.finished.connect(queue_free)

## 消失动画（到达 Hinterland 时）
func _play_disappear_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)
