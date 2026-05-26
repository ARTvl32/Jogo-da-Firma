class_name Hurtbox
extends Area2D

# === Hurtbox ===
# Área vulnerável do fighter. Passiva — apenas é detectada.

@export var dono: Node

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 0b1000  # bit 4 (Hurtbox)
	collision_mask  = 0        # não monitora nada
