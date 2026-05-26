class_name HUD
extends Control

# === HUD ===
# Interface durante combate: healthbars, timer e combo counter.

@onready var bar_p1: ProgressBar = $HealthBar1
@onready var bar_p2: ProgressBar = $HealthBar2
@onready var label_timer: Label = $TimerLabel
@onready var combo_p1: Label = $ComboLabel1
@onready var combo_p2: Label = $ComboLabel2

var contador_combo_p1: int = 0
var contador_combo_p2: int = 0
var frames_desde_ultimo_hit_p1: int = 999
var frames_desde_ultimo_hit_p2: int = 999

const FRAMES_RESET_COMBO: int = 30  # 0.5s a 60fps

func _ready() -> void:
	combo_p1.text = ""
	combo_p2.text = ""

func _process(_delta: float) -> void:
	frames_desde_ultimo_hit_p1 += 1
	frames_desde_ultimo_hit_p2 += 1
	if frames_desde_ultimo_hit_p1 > FRAMES_RESET_COMBO and contador_combo_p1 > 0:
		contador_combo_p1 = 0
		combo_p1.text = ""
	if frames_desde_ultimo_hit_p2 > FRAMES_RESET_COMBO and contador_combo_p2 > 0:
		contador_combo_p2 = 0
		combo_p2.text = ""

func conectar_fighters(p1: FighterBase, p2: FighterBase) -> void:
	bar_p1.max_value = p1.vida.vida_maxima
	bar_p1.value = p1.vida.vida_atual
	bar_p2.max_value = p2.vida.vida_maxima
	bar_p2.value = p2.vida.vida_atual
	p1.vida.vida_alterada.connect(func(atual, _max): bar_p1.value = atual)
	p2.vida.vida_alterada.connect(func(atual, _max): bar_p2.value = atual)
	p1.combate.acertou.connect(func(_alvo): _registrar_hit(1))
	p2.combate.acertou.connect(func(_alvo): _registrar_hit(2))

func _registrar_hit(jogador: int) -> void:
	if jogador == 1:
		contador_combo_p1 += 1
		frames_desde_ultimo_hit_p1 = 0
		if contador_combo_p1 >= 2:
			combo_p1.text = "%d HITS" % contador_combo_p1
	else:
		contador_combo_p2 += 1
		frames_desde_ultimo_hit_p2 = 0
		if contador_combo_p2 >= 2:
			combo_p2.text = "%d HITS" % contador_combo_p2

func atualizar_timer(segundos: int) -> void:
	label_timer.text = "%02d" % segundos
