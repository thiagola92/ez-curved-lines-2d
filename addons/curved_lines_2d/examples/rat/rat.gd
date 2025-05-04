class_name Rat
extends CharacterBody2D


func _ready() -> void:
	$AnimationPlayer.play("run")
	velocity.x = 800.0


func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func disappear():
	velocity.x = 0
	$AnimationPlayer.play("disappear")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "disappear":
		queue_free()
