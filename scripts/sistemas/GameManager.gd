extends Node

# === GameManager ===
# Singleton autoload responsável por:
# - Estado global da partida
# - Transições de cena
# - Configurações persistentes

# Personagens escolhidos pelo P1 e P2 (preenchido na seleção)
var personagem_p1: String = ""
var personagem_p2: String = ""

# Placar (rounds vencidos)
var rounds_p1: int = 0
var rounds_p2: int = 0

# Vencedor da última partida (preenchido pela Arena ao terminar)
var vencedor: int = 0  # 0 = ninguém, 1 = P1, 2 = P2

# Configurações
var rounds_para_vencer: int = 2  # best-of-3

func _ready() -> void:
	print("[GameManager] Inicializado.")

func resetar_partida() -> void:
	rounds_p1 = 0
	rounds_p2 = 0
	vencedor = 0

func ir_para_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/MenuPrincipal.tscn")

func ir_para_selecao() -> void:
	resetar_partida()
	get_tree().change_scene_to_file("res://scenes/menus/SelecaoPersonagem.tscn")

func ir_para_arena() -> void:
	get_tree().change_scene_to_file("res://scenes/arena/Arena.tscn")

func ir_para_resultado() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/TelaResultado.tscn")
