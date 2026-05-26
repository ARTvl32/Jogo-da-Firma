class_name MDKFighter
extends FighterBase

# === Arthur "MDK" Vieira ===
# Arquétipo: Grappler / Pressão
# Velocidade baixa, alcance curto, dano alto.

func _ready() -> void:
	nome_exibicao = "MDK"
	velocidade_andar = 160.0
	velocidade_correr = 300.0
	forca_pulo = -680.0
	vida.vida_maxima = 1100
	super._ready()
