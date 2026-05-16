extends Node2D

# 普通史莱姆的巡逻速度，数值越大移动越快。
const SPEED = 60

# direction 表示当前移动方向：
# 1 代表向右移动，-1 代表向左移动。
var direction = 1

# 获取 AnimatedSprite2D 节点，用来播放史莱姆的帧动画。
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 左右两个 RayCast2D 用来检测史莱姆前方是否碰到墙。
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

func _ready():
	# 场景加载完成后主动播放 default 动画。
	# 如果不调用 play()，AnimatedSprite2D 只会停在某一帧，看起来就不会动。
	animated_sprite.play("default")

func _physics_process(delta):
	# 如果正在向右走，并且右侧射线碰到墙，就转为向左走。
	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	# 如果正在向左走，并且左侧射线碰到墙，就转为向右走。
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	# 根据当前方向和速度移动史莱姆。
	# delta 用来保证不同帧率下移动速度一致。
	position.x += direction * SPEED * delta
