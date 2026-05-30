class_name ComponenteCombate
extends Node

# === ComponenteCombate ===
# Máquina de estados do fighter (FSM).
# Responsável por validar transições e ativar/desativar hitboxes.

signal estado_alterado(novo_estado: int)
signal acertou(alvo: Node)
signal levou_hit(atacante: Node, dano: int, knockback: Vector2)

enum Estado {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	CROUCH,
	ATTACK_LP,
	ATTACK_LK,
	ATTACK_HP,
	ATTACK_HK,
	BLOCK,
	HURT,
	KNOCKDOWN,
	DEATH
}

# Frame data por tipo de ataque (em frames de 60 FPS).
# Estrutura: { startup, active, recovery, dano, hitstun, blockstun, knockback, knockdown }
# Vantagem no hit = hitstun - (active + recovery)
# LP: 8 - (2+6) = 0  → neutro, não encadeia em si mesmo
# LK: 10 - (3+8) = -1 → minus, não encadeia
# HP/HK: causam knockdown — hitstun irrelevante
const FRAME_DATA: Dictionary = {
	Estado.ATTACK_LP: { "startup": 3, "active": 2, "recovery": 6,  "dano": 60,  "hitstun": 8,  "blockstun": 6,  "knockback": Vector2(100, 0),    "knockdown": false },
	Estado.ATTACK_LK: { "startup": 4, "active": 3, "recovery": 8,  "dano": 70,  "hitstun": 10, "blockstun": 8,  "knockback": Vector2(130, 0),    "knockdown": false },
	Estado.ATTACK_HP: { "startup": 8, "active": 3, "recovery": 14, "dano": 120, "hitstun": 0,  "blockstun": 14, "knockback": Vector2(400, -200), "knockdown": true  },
	Estado.ATTACK_HK: { "startup": 10,"active": 4, "recovery": 18, "dano": 140, "hitstun": 0,  "blockstun": 16, "knockback": Vector2(460, -240), "knockdown": true  },
}

var estado_atual: int = Estado.IDLE
var frames_no_estado: int = 0
var hitbox_ativa: bool = false

func _ready() -> void:
	mudar_estado(Estado.IDLE)

func mudar_estado(novo: int) -> void:
	if novo == estado_atual:
		return
	estado_atual = novo
	frames_no_estado = 0
	estado_alterado.emit(novo)

func tick() -> void:
	# Chamado em _physics_process do FighterBase
	frames_no_estado += 1
	_atualizar_hitbox_por_frame_data()

func _atualizar_hitbox_por_frame_data() -> void:
	if not FRAME_DATA.has(estado_atual):
		hitbox_ativa = false
		return
	var fd: Dictionary = FRAME_DATA[estado_atual]
	var startup: int = fd["startup"]
	var active: int = fd["active"]
	hitbox_ativa = frames_no_estado >= startup and frames_no_estado < startup + active

func ataque_terminou() -> bool:
	if not FRAME_DATA.has(estado_atual):
		return true
	var fd: Dictionary = FRAME_DATA[estado_atual]
	var total: int = fd["startup"] + fd["active"] + fd["recovery"]
	return frames_no_estado >= total

func eh_estado_de_ataque(e: int) -> bool:
	return e in [Estado.ATTACK_LP, Estado.ATTACK_LK, Estado.ATTACK_HP, Estado.ATTACK_HK]

func pode_se_mover() -> bool:
	return estado_atual in [Estado.IDLE, Estado.WALK, Estado.RUN]

func pode_atacar() -> bool:
	return estado_atual in [Estado.IDLE, Estado.WALK, Estado.RUN, Estado.JUMP, Estado.FALL, Estado.CROUCH]

func esta_bloqueando() -> bool:
	return estado_atual == Estado.BLOCK

func esta_em_knockdown() -> bool:
	return estado_atual == Estado.KNOCKDOWN
