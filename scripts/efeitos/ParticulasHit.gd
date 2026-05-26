class_name ParticulasHit
extends Node2D

# === ParticulasHit ===
# Burst de partículas instanciado no ponto de contato. Auto-destrói ao terminar.

@onready var particulas: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	particulas.emitting = true
	await get_tree().create_timer(particulas.lifetime + 0.1).timeout
	queue_free()
