extends CharacterBody2D

@onready var vision = $Vision
@onready var vision_collider = $Vision/CollisionShape2D

@export var vision_radius : float = 100


# Called when the node enters the scene tree for the first time.
func _ready():
	var collision_shape = CircleShape2D.new()
	collision_shape.radius = vision_radius
	vision_collider.shape = collision_shape
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()

func _draw():
	# Drone
	draw_circle(Vector2.ZERO, 16, Color.BLACK)
	# Vision radius
	draw_arc(Vector2.ZERO, vision_radius, 0, 2*PI, 32, Color.RED)
