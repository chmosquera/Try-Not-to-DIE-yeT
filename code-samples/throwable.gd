## The Throwable component can be added to objects which are meant to be thrown by the player
class_name Throwable
extends CharacterBody2D

@onready var stabbed_timer = $StabbedTimer
@onready var food_stabbed_vfx = $FoodStabbedVFX
@onready var scream = $Scream

@export var max_distance : float = 250.0
@export var throw_velocity : float = 500.0
@export var sprites : Array[Resource] = []

var carried : bool = false
var collision : CollisionObject2D = null
var player_spawn_position : Vector2

var _direction : Vector2
var _is_moving : bool = false
var _distance_traveled : float = 0.0

func _ready():
	while position.distance_to(player_spawn_position) < 100:
		change_spawn()
	%Sprite2D.texture = sprites.pick_random()

func _process(delta):
	set_collision_layer_value(1, (_is_moving or carried))

func _physics_process(delta):
	if _is_moving == true:
		var motion = _direction * throw_velocity * delta
		var kinematic_body = move_and_collide(motion)
		_distance_traveled += motion.length()
		
		if kinematic_body != null: 
			collision = kinematic_body.get_collider()
	
		# Throwable stops moving if collides with an object, unless
		# object is Player. Throwable is expected to be colliding with player
		# during duration of throw.
		if collision and (collision.collision_layer != 1): # Layer 1 is player
				print("Throwable collided with something")
				var collision_pos =  collision.get_position()
				velocity = Vector2.ZERO
				_is_moving = false
				collision = null
		else: 
			if _distance_traveled > max_distance:
				velocity = Vector2.ZERO
				_is_moving = false
				_distance_traveled = 0.0
	
## Throws this object at the position of the mouse. 
## When object is thrown, it moves along the thrown direction until it 
## collides with an object or has reached the max_distance.
func try_throw():
	var target_position = get_global_mouse_position()
	_direction = target_position - position
	_direction = _direction.normalized()
	
	_is_moving = true

## Defines the behavior for when this object is stabbed by another object.
func stab():
	food_stabbed_vfx.emitting = true
	scream.play()
	stabbed_timer.timeout.connect(stop_vfx)
	stabbed_timer.start(0.5)
	if carried:
		Player.clear_pickup()

## A callback function for when object is done being stabbed.
func stop_vfx():
	food_stabbed_vfx.emitting = false

## Destroys this object and releases memory.
func kill():
	queue_free()

## Randomly chooses a spawn point within world boundaries
func change_spawn():
	var new_position = Vector2(randi_range(-920, 920), randi_range(-500, 500))
	position = new_position