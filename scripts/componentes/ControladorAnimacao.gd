class_name ControladorAnimacao
extends Node

# === ControladorAnimacao ===
# Mapeia estado do ComponenteCombate para animações no AnimatedSprite2D.

signal animacao_terminou

@export var sprite_path: NodePath
var sprite: AnimatedSprite2D

const MAPA_ANIMACAO: Dictionary = {
	ComponenteCombate.Estado.IDLE:       "idle",
	ComponenteCombate.Estado.WALK:       "walk",
	ComponenteCombate.Estado.RUN:        "run",
	ComponenteCombate.Estado.JUMP:       "jump",
	ComponenteCombate.Estado.FALL:       "fall",
	ComponenteCombate.Estado.CROUCH:     "crouch",
	ComponenteCombate.Estado.ATTACK_LP:  "attack_lp",
	ComponenteCombate.Estado.ATTACK_LK:  "attack_lk",
	ComponenteCombate.Estado.ATTACK_HP:  "attack_hp",
	ComponenteCombate.Estado.ATTACK_HK:  "attack_hk",
	ComponenteCombate.Estado.BLOCK:      "block",
	ComponenteCombate.Estado.HURT:       "hurt",
	ComponenteCombate.Estado.KNOCKDOWN: "hurt",
	ComponenteCombate.Estado.DEATH:      "death",
}

func _ready() -> void:
	if sprite_path:
		sprite = get_node(sprite_path)
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)

func tocar_para_estado(estado: int) -> void:
	if sprite == null:
		return
	var nome: String = MAPA_ANIMACAO.get(estado, "idle")
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(nome):
		if sprite.animation != nome:
			sprite.play(nome)
	else:
		# Fallback: usa idle se animação não existir (placeholder safe)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _on_animation_finished() -> void:
	animacao_terminou.emit()
