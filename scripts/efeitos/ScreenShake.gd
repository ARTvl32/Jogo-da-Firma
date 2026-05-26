class_name ScreenShake
extends Node

# === ScreenShake ===
# Anexo à Camera2D. Aplica deslocamento com RNG seedada (determinístico).

@export var camera_path: NodePath
var camera: Camera2D

var trauma: float = 0.0
const TRAUMA_DECAIMENTO: float = 5.0
const FORCA_MAX: float = 12.0
const ROTACAO_MAX: float = 0.05

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 42
	if camera_path:
		camera = get_node(camera_path)
	elif get_parent() is Camera2D:
		camera = get_parent() as Camera2D

func _process(delta: float) -> void:
	if camera == null:
		return
	if trauma > 0.0:
		trauma = max(trauma - TRAUMA_DECAIMENTO * delta, 0.0)
		var amount: float = trauma * trauma
		camera.offset = Vector2(
			rng.randf_range(-1.0, 1.0) * FORCA_MAX * amount,
			rng.randf_range(-1.0, 1.0) * FORCA_MAX * amount
		)
		camera.rotation = rng.randf_range(-1.0, 1.0) * ROTACAO_MAX * amount
	else:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0

func tremer(forca: float) -> void:
	trauma = min(trauma + forca, 1.0)
