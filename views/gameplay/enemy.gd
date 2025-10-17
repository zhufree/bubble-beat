class_name Enemy
extends Node2D

## 敌人基类
## 单体敌人的完整实现
##
## 设计理念:
## - 单一职责：只处理单个敌人的行为
## - 无分支判断：不关心敌人类型
## - 可扩展：通过继承实现特殊行为

signal defeated(enemy: Enemy, score: int)
signal reached_hinterland(enemy: Enemy)

@export var enemy_data: EnemyData
@export var move_speed: float = 200.0  # 移动速度（像素/秒）
@export var target_y: float = 880.0  # 目标Y坐标（Hinterland位置）

var current_health: float
var is_defeated: bool = false
var is_in_attack_zone: bool = false
var move_tween: Tween

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_area: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if not enemy_data:
		push_error("Enemy data is missing!")
		queue_free()
		return

	_initialize()
	_setup_visual()
	_setup_collision()
	start_moving()

## 初始化基础属性
func _initialize() -> void:
	current_health = enemy_data.health
	is_defeated = false

## 设置视觉元素（虚函数）
## @virtual
func _setup_visual() -> void:
	if sprite and enemy_data.sprite:
		sprite.texture = enemy_data.sprite
		sprite.scale = Vector2.ONE * enemy_data.get_scale_factor()

## 设置碰撞区域
func _setup_collision() -> void:
	if body_area:
		body_area.add_to_group("enemies")
		# 将自己存储在 Area2D 的元数据中，以便攻击检测使用
		body_area.set_meta("enemy_instance", self)

## 开始移动
func start_moving() -> void:
	var distance = target_y - position.y
	var duration = distance / move_speed

	move_tween = create_tween()
	move_tween.tween_property(self, "position:y", target_y, duration)
	move_tween.finished.connect(_on_reached_hinterland)

## 到达 Hinterland
func _on_reached_hinterland() -> void:
	reached_hinterland.emit(self)
	release_after_attack()

## 受到伤害
func take_damage(damage: float, damage_type: EnemyData.DamageType) -> void:
	if is_defeated:
		return

	if damage_type == enemy_data.damage_type:
		current_health -= damage
		_play_hit_effect()
		_check_defeated()

## 播放受伤效果
func _play_hit_effect() -> void:
	if sprite and not is_defeated:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)

## 检查是否被击败
func _check_defeated() -> void:
	if current_health <= 0:
		is_defeated = true
		_on_enemy_defeated()

## 完成对动物的攻击后移除敌人
func release_after_attack() -> void:
	_play_disappear_animation()

## 标记进入攻击区域
func enter_attack_zone() -> void:
	is_in_attack_zone = true

## 标记离开攻击区域
func exit_attack_zone() -> void:
	is_in_attack_zone = false

## 敌人被击败（虚函数）
## @virtual
func _on_enemy_defeated() -> void:
	# 停止移动
	if move_tween:
		move_tween.kill()

	# 发出信号
	defeated.emit(self, enemy_data.score_value)

	# 播放击败动画
	_play_defeat_animation()

## 击败动画（虚函数）
## @virtual
func _play_defeat_animation() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.gravity = Vector2(0, 400)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4

	# 根据敌人类型设置粒子颜色
	var particle_color = _get_particle_color()
	particles.color = particle_color
	add_child(particles)

	# 缩放+旋转+淡出动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", PI * 2, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.finished.connect(queue_free)

## 获取粒子颜色（虚函数）
## @virtual
func _get_particle_color() -> Color:
	if enemy_data.name == "单点":
		return Color(0.4, 1.0, 0.4, 1.0)
	elif enemy_data.name == "巨大化":
		return Color(1.0, 1.0, 0.4, 1.0)
	return Color.WHITE

## 消失动画（到达 Hinterland 时）
func _play_disappear_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
