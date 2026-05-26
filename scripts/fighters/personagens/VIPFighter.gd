class_name VIPFighter
extends FighterBase

# === Vinicius "VIP" Pessoa ===
# Arquétipo: Shoto / All-rounder
# Velocidade alta, alcance curto, dano médio.

func _ready() -> void:
	nome_exibicao = "VIP"
	velocidade_andar = 220.0
	velocidade_correr = 420.0
	forca_pulo = -720.0
	vida.vida_maxima = 1000
	super._ready()
