class_name Hitbox
extends Area2D

# === Hitbox ===
# Área ofensiva ativa durante frames de ataque.
# Detecta Hurtboxes inimigas e dispara sinal.

signal hit_conectado(hurtbox: Hurtbox)

@export var dono: Node  # Fighter dono dessa hitbox

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	# Layer: Hitbox (3=bit 4), Mask: Hurtbox (4=bit 8)
	collision_layer = 0b0100
	collision_mask  = 0b1000

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hb: Hurtbox = area
		# Evita auto-hit (hitbox e hurtbox do mesmo fighter)
		if hb.dono == dono:
			return
		hit_conectado.emit(hb)

func ativar() -> void:
	monitoring = true
	$CollisionShape2D.disabled = false

func desativar() -> void:
	monitoring = false
	$CollisionShape2D.disabled = true
