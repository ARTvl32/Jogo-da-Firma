class_name ComponenteVida
extends Node

# === ComponenteVida ===
# Gerencia HP do fighter. Emite sinais quando vida muda ou chega a 0.

signal vida_alterada(vida_atual: int, vida_maxima: int)
signal morreu

@export var vida_maxima: int = 1000

var vida_atual: int

func _ready() -> void:
	vida_atual = vida_maxima
	vida_alterada.emit(vida_atual, vida_maxima)

func aplicar_dano(quantidade: int, pode_matar: bool = true) -> void:
	if vida_atual <= 0:
		return
	vida_atual = max(0 if pode_matar else 1, vida_atual - quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		morreu.emit()

func curar(quantidade: int) -> void:
	vida_atual = min(vida_maxima, vida_atual + quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)

func resetar() -> void:
	vida_atual = vida_maxima
	vida_alterada.emit(vida_atual, vida_maxima)

func esta_vivo() -> bool:
	return vida_atual > 0
