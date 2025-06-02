extends Node2D

func _ready() -> void:
	$Rectangle/AnimationPlayer.play("heart_beat")
