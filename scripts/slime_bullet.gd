extends Area2D

# 子弹飞行速度，数值越大飞得越快。
@export var speed = 180.0

# 子弹最多存在多少秒。
# 如果没有碰到任何东西，时间到后自动删除，避免场景里堆积太多子弹。
@export var life_time = 3.0

# 子弹当前飞行方向。
# 默认向右，真正发射时会由 shooting_slime.gd 的 setup() 传入新的方向。
var direction = Vector2.RIGHT

# 记录是否已经命中过目标，避免同一颗子弹重复造成伤害。
var has_hit_target = false

func _ready():
	# 连接 Area2D 的 body_entered 信号。
	# 当子弹碰到玩家或墙体等 PhysicsBody2D 时，会调用 _on_body_entered()。
	body_entered.connect(_on_body_entered)

	# 等待 life_time 秒。
	await get_tree().create_timer(life_time).timeout

	# 如果这颗子弹没有命中过目标，到时间后删除自己。
	if not has_hit_target:
		queue_free()

func _physics_process(delta):
	# 子弹每个物理帧沿 direction 方向前进。
	global_position += direction * speed * delta

func setup(new_direction: Vector2):
	# 由发射者传入方向，并 normalize 成单位向量。
	# 这样无论目标距离多远，子弹速度都保持一致。
	direction = new_direction.normalized()

func _on_body_entered(body: Node2D):
	# 如果已经命中过目标，就忽略后续碰撞，避免重复造成伤害。
	if has_hit_target:
		return

	if body.has_method("take_damage"):
		hit_target(body)
	else:
		# 碰到墙、地面或其他物体时，子弹消失。
		queue_free()


func hit_target(target: Node) -> void:
	# 标记已经命中目标。
	has_hit_target = true

	# 关闭子弹的碰撞检测，避免死亡过程中再次触发 body_entered。
	monitoring = false

	# 停止子弹继续移动。
	set_physics_process(false)

	# 隐藏子弹，表现为命中后消失。
	hide()

	target.take_damage(1, self)
	queue_free()
