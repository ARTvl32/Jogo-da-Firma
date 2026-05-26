class_name EfeitoHit
extends Node2D

# === EfeitoHit ===
# Spark visual instanciado no ponto de contato. Auto-destrói ao terminar.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")
	sprite.animation_finished.connect(queue_free)
