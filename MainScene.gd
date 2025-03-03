extends Node3D

@onready var collision_marker: Node3D = $Markers/CollisionMarker

@onready var spring_arm_3d: SpringArm3D = $Camera/SpringArm3D
var mouse_sensitivity = 0.2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	var mouse_movement = event as InputEventMouseMotion
	if mouse_movement:
		spring_arm_3d.rotation_degrees.y -= mouse_movement.relative.x * mouse_sensitivity
		spring_arm_3d.rotation_degrees.x -= mouse_movement.relative.y * mouse_sensitivity
		spring_arm_3d.rotation_degrees.x = clampf(spring_arm_3d.rotation_degrees.x , -75, 75)
