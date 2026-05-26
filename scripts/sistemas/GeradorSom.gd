class_name GeradorSom
extends Node

# === GeradorSom ===
# Autoload — sintetiza sons de jogo de forma procedural (AudioStreamWAV).
# Sem assets externos. Seeds determinísticas para reprodutibilidade.

const TAXA_AMOSTRA: int = 44100

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
const NUM_PLAYERS: int = 8
var _idx: int = 0

func _ready() -> void:
	for i in NUM_PLAYERS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_gerar_todos()

func _gerar_todos() -> void:
	# Impactos: (duracao, freq_inicio, freq_fim, decaimento, mix_ruido)
	_streams["hit_leve"]     = _gerar_impacto(0.08, 950.0, 320.0, 30.0, 0.72)
	_streams["hit_pesado"]   = _gerar_impacto(0.18, 360.0,  75.0, 13.0, 0.82)
	_streams["block"]        = _gerar_metalico(0.10)
	_streams["pulo"]         = _gerar_whoosh(0.18, 100.0, 400.0)
	_streams["aterrissagem"] = _gerar_impacto(0.07, 100.0,  35.0, 38.0, 0.58)
	_streams["morte"]        = _gerar_impacto(0.45, 220.0,  50.0,  8.5, 0.88)
	_streams["menu"]         = _gerar_bip(0.06, 880.0)

func tocar(nome: String, volume_db: float = 0.0) -> void:
	if not _streams.has(nome):
		return
	var p: AudioStreamPlayer = _players[_idx % NUM_PLAYERS]
	_idx += 1
	p.stream = _streams[nome]
	p.volume_db = volume_db
	p.play()

# --- Síntese ---

# Impacto genérico: ruído + seno com frequência caindo e envelope exponencial
func _gerar_impacto(dur: float, f0: float, f1: float, decai: float, mix_r: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0 * 7.0 + f1 * 3.0 + decai)
	for i in n:
		var t: float = float(i) / TAXA_AMOSTRA
		var env: float = exp(-decai * t)
		var freq: float = lerp(f0, f1, float(i) / float(n))
		var ruido: float = rng.randf_range(-1.0, 1.0)
		var tom: float = sin(TAU * freq * t)
		_write(data, i, (ruido * mix_r + tom * (1.0 - mix_r)) * env)
	return _stream(data)

# Block metálico: soma de harmônicos com ruído, decay rápido
func _gerar_metalico(dur: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for i in n:
		var t: float = float(i) / TAXA_AMOSTRA
		var env: float = exp(-34.0 * t)
		var ruido: float = rng.randf_range(-1.0, 1.0)
		var metal: float = (
			sin(TAU * 760.0  * t) * 0.38 +
			sin(TAU * 1240.0 * t) * 0.30 +
			sin(TAU * 1950.0 * t) * 0.20 +
			sin(TAU * 2900.0 * t) * 0.12
		)
		_write(data, i, (ruido * 0.42 + metal * 0.58) * env)
	return _stream(data)

# Whoosh de pulo: seno com frequência crescente + ruído, envelope sino
func _gerar_whoosh(dur: float, f0: float, f1: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var fase: float = 0.0
	for i in n:
		var prog: float = float(i) / float(n)
		var env: float = sin(PI * prog) * 0.80
		fase += TAU * lerp(f0, f1, prog) / TAXA_AMOSTRA
		var ruido: float = rng.randf_range(-1.0, 1.0)
		_write(data, i, (sin(fase) * 0.55 + ruido * 0.45) * env)
	return _stream(data)

# Bip de UI: seno puro com envelope sino
func _gerar_bip(dur: float, freq: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: float = float(i) / TAXA_AMOSTRA
		var env: float = sin(PI * float(i) / float(n))
		_write(data, i, sin(TAU * freq * t) * env * 0.65)
	return _stream(data)

# --- Auxiliares ---

func _write(data: PackedByteArray, idx: int, valor: float) -> void:
	var v: int = clampi(int(valor * 32767.0), -32768, 32767)
	data[idx * 2]     = v & 0xFF
	data[idx * 2 + 1] = (v >> 8) & 0xFF

func _stream(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.data = data
	s.format = AudioStreamWAV.FORMAT_16_BIT
	s.mix_rate = TAXA_AMOSTRA
	s.stereo = false
	return s
