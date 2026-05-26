class_name Arena
extends Node2D

# === Arena ===
# Cena de combate. Gerencia round, timer, fighters, câmera e juice.

signal round_terminou(vencedor: int)

const EFEITO_HIT_SCENE: PackedScene = preload("res://scenes/efeitos/EfeitoHit.tscn")
const PARTICULAS_HIT_SCENE: PackedScene = preload("res://scenes/efeitos/ParticulasHit.tscn")

@export var duracao_round_segundos: int = 99

@onready var fighter1: FighterBase = $Fighters/Fighter1
@onready var fighter2: FighterBase = $Fighters/Fighter2
@onready var camera: Camera2D = $Camera2D
@onready var screen_shake: ScreenShake = $Camera2D/ScreenShake
@onready var hud: Control = $HUD
@onready var timer_round: Timer = $TimerRound

var tempo_restante: int = 99
var round_em_andamento: bool = false

func _ready() -> void:
	tempo_restante = duracao_round_segundos
	# Conecta fighters entre si
	fighter1.definir_oponente(fighter2)
	fighter2.definir_oponente(fighter1)
	fighter1.vida.morreu.connect(func(): _ao_fighter_morrer(2))
	fighter2.vida.morreu.connect(func(): _ao_fighter_morrer(1))
	# Configura HUD
	if hud and hud.has_method("conectar_fighters"):
		hud.conectar_fighters(fighter1, fighter2)
	# Timer
	timer_round.timeout.connect(_on_timer_tick)
	# Juice: conecta sinais de acerto para efeitos visuais
	fighter1.combate.acertou.connect(_on_acerto.bind(fighter1))
	fighter2.combate.acertou.connect(_on_acerto.bind(fighter2))
	_iniciar_round()

func _process(_delta: float) -> void:
	_atualizar_camera()

func _iniciar_round() -> void:
	round_em_andamento = true
	tempo_restante = duracao_round_segundos
	timer_round.start(1.0)

func _on_timer_tick() -> void:
	if not round_em_andamento:
		return
	tempo_restante -= 1
	if hud and hud.has_method("atualizar_timer"):
		hud.atualizar_timer(tempo_restante)
	if tempo_restante <= 0:
		_resolver_round_por_timeout()

func _resolver_round_por_timeout() -> void:
	var vencedor: int = 0
	if fighter1.vida.vida_atual > fighter2.vida.vida_atual:
		vencedor = 1
	elif fighter2.vida.vida_atual > fighter1.vida.vida_atual:
		vencedor = 2
	_encerrar_round(vencedor)

func _ao_fighter_morrer(quem_venceu: int) -> void:
	if not round_em_andamento:
		return
	_encerrar_round(quem_venceu)

func _encerrar_round(vencedor: int) -> void:
	round_em_andamento = false
	timer_round.stop()
	print("[Arena] Round encerrado. Vencedor: P%d" % vencedor)
	if vencedor == 1:
		GameManager.rounds_p1 += 1
	elif vencedor == 2:
		GameManager.rounds_p2 += 1
	round_terminou.emit(vencedor)
	await get_tree().create_timer(2.0).timeout
	if GameManager.rounds_p1 >= GameManager.rounds_para_vencer:
		GameManager.vencedor = 1
		GameManager.ir_para_resultado()
	elif GameManager.rounds_p2 >= GameManager.rounds_para_vencer:
		GameManager.vencedor = 2
		GameManager.ir_para_resultado()
	else:
		get_tree().reload_current_scene()

func _atualizar_camera() -> void:
	# Posiciona câmera no ponto médio horizontal dos dois fighters
	var meio_x: float = (fighter1.global_position.x + fighter2.global_position.x) * 0.5
	camera.global_position.x = lerp(camera.global_position.x, meio_x, 0.1)

func _on_acerto(_alvo: Node, atacante: FighterBase) -> void:
	# Ponto de impacto: meio entre atacante e oponente, na altura do tronco
	var pos: Vector2 = (atacante.global_position + atacante.conhece_oponente.global_position) * 0.5
	pos.y -= 60.0
	# Spark
	var spark: Node2D = EFEITO_HIT_SCENE.instantiate()
	spark.global_position = pos
	add_child(spark)
	# Partículas
	var parts: Node2D = PARTICULAS_HIT_SCENE.instantiate()
	parts.global_position = pos
	add_child(parts)
	# Screen shake — mais forte em heavy hits
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(atacante.combate.estado_atual, {})
	if not fd.is_empty():
		var dano: int = fd.get("dano", 60)
		var forca: float = 0.3 if dano < 100 else 0.6
		screen_shake.tremer(forca)
