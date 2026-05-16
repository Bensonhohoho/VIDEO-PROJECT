extends Node2D

# 射击史莱姆的巡逻速度。
# 它不会追玩家，只会保持左右巡逻。
const SPEED = 40

# 玩家进入这个范围内时，史莱姆会按冷却时间发射子弹。
@export var attack_range = 160.0

# 两次射击之间的间隔时间，单位是秒。
@export var shoot_cooldown = 1.2

# 子弹场景。发射时会实例化这个 PackedScene。
@export var bullet_scene: PackedScene = preload("res://scenes/slime_bullet.tscn")

# 当前巡逻方向：1 向右，-1 向左。
var direction = 1

# 保存玩家节点引用。
var player: Node2D

# 当前剩余冷却时间。
# 大于 0 时不能开火，等减到 0 后才能发射下一颗子弹。
var cooldown_timer = 0.0

# 播放史莱姆动画的节点。
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 左右射线用来检测巡逻时是否撞墙。
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

# 子弹生成的位置。
# 调整 ShootingSlime 场景里的 ShootPoint，就能改变子弹从哪里发射。
@onready var shoot_point: Marker2D = $ShootPoint

func _ready():
	# 播放 default 动画，让射击史莱姆的身体动起来。
	animated_sprite.play("default")
	# 通过 player group 找玩家，避免依赖固定路径。
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# 每帧减少冷却时间，最低不低于 0。
	cooldown_timer = max(cooldown_timer - delta, 0.0)

	# 射击史莱姆永远正常巡逻，不会因为看见玩家就追踪或停住。
	patrol(delta)

	# 只要玩家在射程内，并且冷却结束，就发射子弹。
	if can_shoot_player():
		shoot_at_player()

func patrol(delta):
	# 向右走时如果右侧射线碰墙，就转向左。
	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	# 向左走时如果左侧射线碰墙，就转向右。
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	# 按当前方向进行水平巡逻移动。
	position.x += direction * SPEED * delta

func shoot_at_player():
	# 冷却还没结束时不发射。
	if cooldown_timer > 0.0:
		return

	# 创建一颗新的子弹实例。
	var bullet = bullet_scene.instantiate()

	# 把子弹加到当前主场景下，而不是加到史莱姆下面。
	# 这样子弹不会跟着史莱姆移动。
	get_tree().current_scene.add_child(bullet)

	# 设置子弹出生位置为 ShootPoint 的全局位置。
	bullet.global_position = shoot_point.global_position

	# 计算从发射点到玩家身体中心的方向，并交给子弹。
	# 使用玩家碰撞体中心，可以避免子弹瞄准脚底导致打偏。
	bullet.setup((get_player_target_position() - shoot_point.global_position).normalized())

	# 发射后重置冷却时间。
	cooldown_timer = shoot_cooldown

func get_player_target_position():
	# 优先瞄准主场景里 Player 下的 CollisionShape2D。
	# 这个位置通常更接近玩家身体中心。
	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		# 如果某个玩家场景把碰撞体放在 AnimatedSprite2D 下面，就用这个备用路径。
		collision_shape = player.get_node_or_null("AnimatedSprite2D/CollisionShape2D")

	if collision_shape != null:
		# 返回碰撞体的全局坐标，让子弹真正瞄准玩家身体。
		return collision_shape.global_position

	# 如果找不到碰撞体，就退回到玩家节点本身的位置。
	return player.global_position

func can_shoot_player():
	# 没找到玩家时不能射击。
	if player == null:
		return false

	# 玩家和史莱姆之间的距离小于等于 attack_range 时，可以尝试射击。
	# 注意：这里不检测墙，只按范围开火，避免出现“只有玩家跳起来才射击”的问题。
	return global_position.distance_to(player.global_position) <= attack_range
