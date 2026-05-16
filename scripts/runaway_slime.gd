extends Node2D

# 平时巡逻速度。
const SPEED = 60

# 逃跑速度。这里设置为普通速度的 2 倍，让玩家靠近时反应更明显。
const FLEE_SPEED = 120

# 玩家进入这个距离内，且中间没有墙挡住时，史莱姆开始逃跑。
# 这里的 80 像素约等于 5 个 16px tile，可以在 Godot 编辑器中直接调整。
@export var flee_distance = 80.0

# 当前移动方向：1 向右，-1 向左。
var direction = 1

# 保存玩家节点引用，避免每一帧都重新查找玩家。
var player: Node2D

# 播放史莱姆动画的节点。
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 左右射线用来检测墙，防止史莱姆继续往墙里走。
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

func _ready():
	# 开始播放 default 动画，让逃跑史莱姆动起来。
	animated_sprite.play("default")
	# 通过 player group 找到玩家。
	# 玩家场景中已经添加 groups=["player"]，所以这里不依赖具体节点路径。
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# 每个物理帧判断玩家是否在逃跑范围内，并且是否能被史莱姆看见。
	var is_fleeing = can_see_player_in_flee_range()

	if is_fleeing:
		# 逃跑方向 = 史莱姆位置 - 玩家位置。
		# 玩家在左边时结果为正，史莱姆向右跑；玩家在右边时结果为负，史莱姆向左跑。
		direction = sign(global_position.x - player.global_position.x)
		if direction == 0:
			# 如果玩家和史莱姆 x 坐标完全重合，给一个默认方向，避免 direction 变成 0 不移动。
			direction = 1

	# 即使正在逃跑，也要检测墙。
	# 如果逃跑方向前方是墙，就立刻反向，避免卡进墙里。
	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	# 在逃跑状态使用 FLEE_SPEED，否则使用普通巡逻速度。
	var speed = FLEE_SPEED if is_fleeing else SPEED

	# 执行水平移动。
	position.x += direction * speed * delta

func can_see_player_in_flee_range():
	# 如果没找到玩家，就不进入逃跑状态。
	if player == null:
		return false

	# 超出逃跑范围时，不需要继续做射线检测，直接返回 false。
	if global_position.distance_to(player.global_position) > flee_distance:
		return false

	# 从史莱姆位置向玩家位置打一条射线。
	# collision_mask = 3 表示检测第 1 层墙体和第 2 层玩家。
	# 这样如果中间有墙，射线会先打到墙，就不会认为“看见玩家”。
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 3

	# intersect_ray 返回射线第一个碰到的物体。
	var result = get_world_2d().direct_space_state.intersect_ray(query)

	# 只有射线第一个碰到的是玩家时，才算真的看见玩家。
	return not result.is_empty() and result["collider"] == player
