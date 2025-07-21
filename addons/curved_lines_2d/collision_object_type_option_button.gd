@tool
extends OptionButton

enum CollisionObjectType {
	NONE,
	STATIC_BODY_2D,
	AREA_2D,
	ANIMATABLE_BODY_2D,
	RIGID_BODY_2D,
	CHARACTER_BODY_2D,
	PHYSICAL_BONE_2D
}

signal created(collision_object : CollisionObject2D)
signal unassigned()

func _on_item_selected(index: int) -> void:
	match index:
		CollisionObjectType.STATIC_BODY_2D:
			created.emit(StaticBody2D.new())
		CollisionObjectType.AREA_2D:
			created.emit(Area2D.new())
		CollisionObjectType.ANIMATABLE_BODY_2D:
			created.emit(AnimatableBody2D.new())
		CollisionObjectType.RIGID_BODY_2D:
			created.emit(RigidBody2D.new())
		CollisionObjectType.CHARACTER_BODY_2D:
			created.emit(CharacterBody2D.new())
		CollisionObjectType.PHYSICAL_BONE_2D:
			created.emit(PhysicalBone2D.new())
		_, CollisionObjectType.NONE:
			unassigned.emit()
