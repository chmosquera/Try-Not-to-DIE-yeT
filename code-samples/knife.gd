class_name Knife extends Node2D

@export var start_point : Vector2 = Vector2(0,0)
@export var end_point : Vector2 = Vector2(100,100)
@export var activate_timer_length : float = 3
@export var deactivate_timer_length : float = 2


@onready var player = Player
@onready var animation_player = $AnimationPlayer
@onready var activate_timer = $ActivateTimer
@onready var deactivate_timer = $DeactivateTimer
@onready var shadow : Line2D = $Shadow
@onready var knife_body = $KnifeBody
@onready var sprite2d = $KnifeBody/Sprite2D
@onready var collision_shape = $KnifeBody/CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	get_points_with_raycast()
	disable_barrier()
	
	# Set up timer
	activate_timer.one_shot = true
	activate_timer.timeout.connect(_on_activate_timer_timeout)
	activate_timer.start(activate_timer_length)
	
	# Set up the knife shadow and body. Shadow is drawn with a line and requires
	# points. Body is a sprite and collider that rotates to align with shadow.
	var mid_point = start_point + end_point / 2.0	
	var points_array = [
		Vector2(start_point),
		Vector2(mid_point),
		Vector2(end_point)
	]
	shadow.points = points_array
	knife_body.start_point = start_point
	knife_body.end_point = end_point
	knife_body.rotate_to_line()
	
	## Shadow animation
	animation_player.play("knife_shadow")


## Get the start and end points of the knife. The first raycast points to
## the player, while the second raycast points in the opposite direction.
## The points are where the raycasts intersect with the walls.
func get_points_with_raycast():
	
	var raycast_front = RayCast2D.new()
	raycast_front.position = self.global_position
	raycast_front.target_position = player.global_position * 100 # Arbitrary number to make the raycast beyond the boundaries
	
	var raycast_back = RayCast2D.new()
	raycast_back.position = self.global_position
	raycast_back.target_position = (player.global_position * 100) * -1
	
	raycast_front.collision_mask = 1 << 2 # Layer "walls" is bit value 2
	raycast_back.collision_mask = 1 << 2
	
	add_child(raycast_front)
	add_child(raycast_back)
	
	raycast_front.enabled = true
	raycast_back.enabled = true
	
	raycast_front.force_raycast_update()
	raycast_back.force_raycast_update()
	
	if raycast_front.is_colliding() == true:
		start_point = raycast_front.get_collision_point()
		print(raycast_front.get_collider().name)
	
	if raycast_back.is_colliding() == true:
		end_point = raycast_back.get_collision_point()
		print(raycast_back.get_collider().name)
	else:
		print("Knife couldn't detect a world boundary. Make sure the scene contains a world boundary with layer 'walls'.")
		queue_free()
		
	print("Knife end point: (%d, %d), start point: (%d, %d)" % [end_point.x, end_point.y, start_point.x, start_point.y])
	remove_child(raycast_front)	
	remove_child(raycast_back)

## Draw a raycast from the start to end points. If the player is hit by the
## raycast, they are killed. 
func attempt_kill_player():
	var raycast = RayCast2D.new()
	raycast.position = start_point
	raycast.target_position = end_point * 100 # Arbitrary number to make the raycast beyond the boundaries
	
	raycast.collision_mask = 1 << 0 # Layer "player" is bit value 0
	add_child(raycast)
	raycast.enabled = true
	raycast.force_raycast_update()
	
	print(player.global_position)
	
	if raycast.is_colliding():
		player.kill()
		print("Knife killed player!")
		
	remove_child(raycast)

## Shows the knife and enables its collisions.
func enable_barrier():
	knife_body.visible = true
	knife_body.set_process(true)
	knife_body.set_physics_process(true)
	knife_body.process_mode = Node.PROCESS_MODE_INHERIT
	

## Hides the knife and disables its collisions.
func disable_barrier():
	knife_body.visible = false
	knife_body.set_process(false)
	knife_body.set_physics_process(false)
	knife_body.process_mode = Node.PROCESS_MODE_DISABLED

## Callback function that makes the shadow disappear and knife appear.
func _on_activate_timer_timeout():
	shadow.visible = false
	enable_barrier()
	
	# Note: Bug - This doesn't trigger. However, it is triggered by the Knife animation player
	# attempt_kill_player()
	
	# Set up timer to deactivate
	deactivate_timer.one_shot = true
	deactivate_timer.timeout.connect(_on_deactivate_timer_timeout)
	deactivate_timer.start(deactivate_timer_length)

func _on_deactivate_timer_timeout():
	animation_player.play("knife_exit")

## Callback function that frees the knife instance from the scene.
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "knife_exit":
		queue_free()