class_name Arena
extends Node2D

# === Arena ===
# Cena de combate. Gerencia round, timer, fighters, câmera e juice.

signal round_terminou(vencedor: int)

const PARTICULAS_HIT_SCENE: PackedScene = preload("res://scenes/efeitos/ParticulasHit.tscn")
const CENA_VIP: PackedScene = preload("res://scenes/fighters/personagens/VIP/VIP.tscn")
const CENA_MDK: PackedScene = preload("res://scenes/fighters/personagens/MDK/MDK.tscn")

@export var duracao_round_segundos: int = 99

@onready var camera: Camera2D = $Camera2D
@onready var screen_shake: ScreenShake = $Camera2D/ScreenShake
@onready var hud: Control = $HUD
@onready var timer_round: Timer = $TimerRound
@onready var fighters_node: Node2D = $Fighters

var fighter1: FighterBase
var fighter2: FighterBase
var tempo_restante: int = 99
var round_em_andamento: bool = false

func _ready() -> void:
	_instanciar_fighters()
	tempo_restante = duracao_round_segundos
	fighter1.definir_oponente(fighter2)
	fighter2.definir_oponente(fighter1)
	fighter1.vida.morreu.connect(func(): _ao_fighter_morrer(2))
	fighter2.vida.morreu.connect(func(): _ao_fighter_morrer(1))
	if hud and hud.has_method("conectar_fighters"):
		hud.conectar_fighters(fighter1, fighter2)
	timer_round.timeout.connect(_on_timer_tick)
	fighter1.combate.acertou.connect(_on_acerto.bind(fighter1))
	fighter2.combate.acertou.connect(_on_acerto.bind(fighter2))
	_iniciar_round()

func _instanciar_fighters() -> void:
	# Limpar filhos existentes (Fighter1/Fighter2 estáticos da cena, se houver)
	for f in fighters_node.get_children():
		f.queue_free()

	var nome_p1: String = GameManager.personagem_p1 if GameManager.personagem_p1 != "" else "VIP"
	var nome_p2: String = GameManager.personagem_p2 if GameManager.personagem_p2 != "" else "MDK"

	var cena_p1: PackedScene = CENA_VIP if nome_p1 == "VIP" else CENA_MDK
	var cena_p2: PackedScene = CENA_VIP if nome_p2 == "VIP" else CENA_MDK

	fighter1 = cena_p1.instantiate() as FighterBase
	fighter1.player_index = 1
	fighter1.global_position = Vector2(400, 460)
	fighters_node.add_child(fighter1)

	fighter2 = cena_p2.instantiate() as FighterBase
	fighter2.player_index = 2
	fighter2.olhando_direita = false
	fighter2.global_position = Vector2(880, 460)
	fighters_node.add_child(fighter2)

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
	if fighter1 == null or fighter2 == null:
		return
	var meio_x: float = (fighter1.global_position.x + fighter2.global_position.x) * 0.5
	camera.global_position.x = lerp(camera.global_position.x, meio_x, 0.1)

func _on_acerto(_alvo: Node, atacante: FighterBase) -> void:
	var pos: Vector2 = (atacante.global_position + atacante.conhece_oponente.global_position) * 0.5
	pos.y -= 60.0
	var parts: Node2D = PARTICULAS_HIT_SCENE.instantiate()
	parts.global_position = pos
	add_child(parts)
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(atacante.combate.estado_atual, {})
	if not fd.is_empty():
		var dano: int = fd.get("dano", 60)
		var forca: float = 0.3 if dano < 100 else 0.6
		screen_shake.tremer(forca)
