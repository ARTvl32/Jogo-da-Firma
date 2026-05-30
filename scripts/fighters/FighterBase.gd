class_name FighterBase
extends CharacterBody2D

# === FighterBase ===
# Classe base de todos os personagens jogáveis.
# Inputs roteados via player_index (1 ou 2).

@export var player_index: int = 1
@export var velocidade_andar: float = 200.0
@export var velocidade_correr: float = 380.0
@export var forca_pulo: float = -700.0
@export var olhando_direita: bool = true

@export var nome_exibicao: String = "Fighter"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vida: ComponenteVida = $ComponenteVida
@onready var combate: ComponenteCombate = $ComponenteCombate
@onready var animacao: ControladorAnimacao = $ControladorAnimacao
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var hitstop_frames: int = 0
var hitstun_frames: int = 0
var blockstun_frames: int = 0
var knockdown_frames: int = 0
var iframes_restantes: int = 0
var conhece_oponente: FighterBase = null

const KNOCKDOWN_DURACAO: int = 70   # frames no chão (~1.2s)
const IFRAMES_LEVANTADA: int = 30   # frames de invencibilidade ao levantar (~0.5s)

var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var ultimo_tap_direcao: int = 0
var frames_desde_ultimo_tap: int = 999
const JANELA_DUPLO_TAP: int = 15

func _ready() -> void:
	hitbox.dono = self
	hurtbox.dono = self
	hitbox.hit_conectado.connect(_on_hit_conectado)
	combate.estado_alterado.connect(_on_estado_alterado)
	vida.morreu.connect(_on_morreu)
	vida.resetar()
	animacao.tocar_para_estado(combate.estado_atual)
	hitbox.desativar()
	_atualizar_posicao_hitbox()
	sprite.flip_h = not olhando_direita

func _physics_process(delta: float) -> void:
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	_atualizar_facing()

	# --- Knockdown ---
	if knockdown_frames > 0:
		knockdown_frames -= 1
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if not is_on_floor():
			velocity.y += gravidade * delta
		move_and_slide()
		frames_desde_ultimo_tap += 1
		if knockdown_frames == 0:
			_iniciar_levantada()
		return

	# --- Invencibilidade pós-knockdown ---
	if iframes_restantes > 0:
		iframes_restantes -= 1
		if iframes_restantes == 0:
			_terminar_levantada()

	if hitstun_frames > 0:
		hitstun_frames -= 1
		if hitstun_frames == 0 and combate.estado_atual == ComponenteCombate.Estado.HURT:
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
	if blockstun_frames > 0:
		blockstun_frames -= 1
		if blockstun_frames == 0 and combate.estado_atual == ComponenteCombate.Estado.BLOCK:
			if not _input_pressionado("block"):
				combate.mudar_estado(ComponenteCombate.Estado.IDLE)

	if not is_on_floor():
		velocity.y += gravidade * delta

	if hitstun_frames == 0 and blockstun_frames == 0 and iframes_restantes == 0:
		_processar_input()

	combate.tick()
	_atualizar_hitbox_por_combate()
	_atualizar_estado_movimento()

	move_and_slide()

	# Clamp lateral — impede o fighter de sair da tela
	const MARGEM: float = 40.0
	global_position.x = clampf(global_position.x, MARGEM, 1280.0 - MARGEM)

	frames_desde_ultimo_tap += 1

func _iniciar_levantada() -> void:
	combate.mudar_estado(ComponenteCombate.Estado.IDLE)
	iframes_restantes = IFRAMES_LEVANTADA
	# Desativa hurtbox durante os iframes
	var hb_shape: CollisionShape2D = hurtbox.get_node("CollisionShape2D")
	hb_shape.set_deferred("disabled", true)

func _terminar_levantada() -> void:
	var hb_shape: CollisionShape2D = hurtbox.get_node("CollisionShape2D")
	hb_shape.set_deferred("disabled", false)

func _processar_input() -> void:
	if combate.eh_estado_de_ataque(combate.estado_atual):
		if combate.ataque_terminou():
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
			hitbox.desativar()
		else:
			return

	if _input_pressionado("block") and is_on_floor():
		combate.mudar_estado(ComponenteCombate.Estado.BLOCK)
		velocity.x = 0
		return

	# LP e HP funcionam no ar e no chão
	if _input_just_pressed("lp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LP)
		return
	if _input_just_pressed("hp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HP)
		return

	# LK e HK apenas no chão (sem animação de ar na v0.1.2)
	if is_on_floor():
		if _input_just_pressed("lk"):
			_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LK)
			return
		if _input_just_pressed("hk"):
			_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HK)
			return

	if _input_just_pressed("up") and is_on_floor():
		velocity.y = forca_pulo
		combate.mudar_estado(ComponenteCombate.Estado.JUMP)
		GeradorSom.tocar("pulo", -5.0)
		return

	if not is_on_floor():
		var dir_ar: float = _direcao_horizontal()
		velocity.x = dir_ar * velocidade_andar
		return

	if _input_pressionado("down"):
		combate.mudar_estado(ComponenteCombate.Estado.CROUCH)
		velocity.x = 0
		return

	var dir: float = _direcao_horizontal()
	if dir != 0.0:
		_detectar_duplo_tap(int(sign(dir)))
		var correndo: bool = ultimo_tap_direcao == int(sign(dir)) and frames_desde_ultimo_tap < JANELA_DUPLO_TAP * 4
		if correndo:
			velocity.x = dir * velocidade_correr
			combate.mudar_estado(ComponenteCombate.Estado.RUN)
		else:
			velocity.x = dir * velocidade_andar
			combate.mudar_estado(ComponenteCombate.Estado.WALK)
	else:
		velocity.x = 0
		combate.mudar_estado(ComponenteCombate.Estado.IDLE)

func _iniciar_ataque(estado_ataque: int) -> void:
	combate.mudar_estado(estado_ataque)
	if is_on_floor():
		velocity.x = 0  # no ar mantém o momento do pulo

func _atualizar_hitbox_por_combate() -> void:
	if combate.hitbox_ativa:
		hitbox.ativar()
	else:
		hitbox.desativar()

func _atualizar_estado_movimento() -> void:
	var e: int = combate.estado_atual
	if not is_on_floor():
		if velocity.y > 0 and e == ComponenteCombate.Estado.JUMP:
			combate.mudar_estado(ComponenteCombate.Estado.FALL)
	else:
		if e == ComponenteCombate.Estado.FALL or e == ComponenteCombate.Estado.JUMP:
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
			GeradorSom.tocar("aterrissagem", -6.0)

func _atualizar_facing() -> void:
	if not combate.pode_se_mover():
		return
	var deveria_olhar_direita: bool
	var dir: float = _direcao_horizontal()
	if dir != 0.0:
		deveria_olhar_direita = dir > 0.0
	elif conhece_oponente != null:
		deveria_olhar_direita = conhece_oponente.global_position.x >= global_position.x
	else:
		return
	if deveria_olhar_direita != olhando_direita:
		olhando_direita = deveria_olhar_direita
		sprite.flip_h = not olhando_direita
		_atualizar_posicao_hitbox()

func _atualizar_posicao_hitbox() -> void:
	var shape: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	shape.position.x = 60.0 if olhando_direita else -60.0

func _direcao_horizontal() -> float:
	var esq: bool = _input_pressionado("left")
	var dir: bool = _input_pressionado("right")
	if esq and not dir:
		return -1.0
	if dir and not esq:
		return 1.0
	return 0.0

func _detectar_duplo_tap(direcao: int) -> void:
	if not _input_just_pressed("right") and not _input_just_pressed("left"):
		return
	if ultimo_tap_direcao == direcao and frames_desde_ultimo_tap < JANELA_DUPLO_TAP:
		frames_desde_ultimo_tap = 0
	else:
		ultimo_tap_direcao = direcao
		frames_desde_ultimo_tap = 0

func _prefixo() -> String:
	return "p1_" if player_index == 1 else "p2_"

func _input_pressionado(acao: String) -> bool:
	return Input.is_action_pressed(_prefixo() + acao)

func _input_just_pressed(acao: String) -> bool:
	return Input.is_action_just_pressed(_prefixo() + acao)

func _on_hit_conectado(hurtbox_inimiga: Hurtbox) -> void:
	var alvo: FighterBase = hurtbox_inimiga.dono as FighterBase
	if alvo == null:
		return
	# Não acerta durante iframes de levantada
	if alvo.iframes_restantes > 0:
		return
	hitbox.desativar()
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(combate.estado_atual, {})
	if fd.is_empty():
		return
	var dano: int = fd["dano"]
	var hitstun: int = fd["hitstun"]
	var blockstun: int = fd["blockstun"]
	var knockback: Vector2 = fd["knockback"]
	var knockdown: bool = fd.get("knockdown", false)
	if not olhando_direita:
		knockback.x = -knockback.x
	alvo.receber_hit(self, dano, hitstun, blockstun, knockback, knockdown)
	combate.acertou.emit(alvo)
	GeradorSom.tocar("hit_pesado" if dano >= 100 else "hit_leve")

func receber_hit(atacante: FighterBase, dano: int, hitstun: int, blockstun: int, knockback: Vector2, knockdown: bool = false) -> void:
	if combate.estado_atual == ComponenteCombate.Estado.DEATH:
		return
	if combate.estado_atual == ComponenteCombate.Estado.KNOCKDOWN:
		return
	if combate.esta_bloqueando():
		blockstun_frames = blockstun
		velocity.x = knockback.x * 0.3
		_aplicar_hitstop(6)
		GeradorSom.tocar("block")
		if dano >= 100:
			var chip: int = max(1, int(dano * 0.08))
			vida.aplicar_dano(chip, false)
		combate.levou_hit.emit(atacante, 0, knockback)
		return
	vida.aplicar_dano(dano)
	if vida.vida_atual == 0:
		return  # morreu() já vai tratar
	if knockdown:
		velocity = knockback
		knockdown_frames = KNOCKDOWN_DURACAO
		hitstun_frames = 0
		combate.mudar_estado(ComponenteCombate.Estado.KNOCKDOWN)
		_aplicar_hitstop(12)
	else:
		hitstun_frames = hitstun
		velocity = knockback
		combate.mudar_estado(ComponenteCombate.Estado.HURT)
		_aplicar_hitstop(8)
	combate.levou_hit.emit(atacante, dano, knockback)

func _aplicar_hitstop(frames: int) -> void:
	hitstop_frames = frames

func _on_estado_alterado(novo: int) -> void:
	animacao.tocar_para_estado(novo)

func _on_morreu() -> void:
	combate.mudar_estado(ComponenteCombate.Estado.DEATH)
	hitbox.desativar()
	GeradorSom.tocar("morte", 3.0)

func definir_oponente(outro: FighterBase) -> void:
	conhece_oponente = outro
