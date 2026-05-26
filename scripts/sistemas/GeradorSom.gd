extends Node

const TAXA_AMOSTRA: int = 44100
const TAXA_MUSICA: int = 22050
const NUM_PLAYERS: int = 8
# sons do jogo tocam a 70% (dial 100%) — linear_to_db(0.7) ≈ -3.1 dB
const OFFSET_SFX_DB: float = -3.1

var _streams: Dictionary = {}
var _players: Array = []
var _musica_player: AudioStreamPlayer
var _idx: int = 0

func _ready() -> void:
	for i in range(NUM_PLAYERS):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_musica_player = AudioStreamPlayer.new()
	_musica_player.volume_db = -6.0
	add_child(_musica_player)
	_gerar_todos()
	_musica_player.stream = _gerar_musica_epica()
	_musica_player.play()

func _gerar_todos() -> void:
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
	var p: AudioStreamPlayer = _players[_idx % NUM_PLAYERS] as AudioStreamPlayer
	_idx += 1
	p.stream = _streams[nome]
	p.volume_db = volume_db + OFFSET_SFX_DB
	p.play()

# --- Musica de fundo epica ---
# Am-F-G-Am, BPM=110, 8s loop, 22050 Hz
# Bass pulsado + pad de acordes + melodia pentatonica + kick/snare
func _gerar_musica_epica() -> AudioStreamWAV:
	const BPM: float = 110.0
	const BEAT: float = 60.0 / BPM
	const BARS: int = 4
	var dur: float = float(BARS) * 4.0 * BEAT
	var n: int = int(TAXA_MUSICA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	# Progressao Am - F - G - Am
	var bass_hz: Array = [110.0, 87.5, 98.0, 110.0]
	var chord_hz: Array = [
		[220.0, 261.0, 330.0],
		[175.0, 220.0, 261.0],
		[196.0, 247.0, 294.0],
		[220.0, 261.0, 330.0]
	]
	# Melodia pentatonica menor Am (1 nota por beat)
	var melody_hz: Array = [
		[440.0, 440.0, 523.0, 659.0],
		[659.0, 587.0, 523.0, 440.0],
		[523.0, 659.0, 784.0, 659.0],
		[587.0, 523.0, 440.0, 330.0]
	]

	var bar_dur: float = 4.0 * BEAT

	for i in range(n):
		var t: float = float(i) / float(TAXA_MUSICA)
		var bar: int = min(int(t / bar_dur), BARS - 1)
		var t_bar: float = t - float(bar) * bar_dur
		var beat: int = min(int(t_bar / BEAT), 3)
		var t_beat: float = t_bar - float(beat) * BEAT

		# --- Baixo (bass pulsado) ---
		var bf: float = float(bass_hz[bar])
		var bass_env: float = exp(-3.5 * t_beat) * 0.55 + 0.15
		var bass: float = sin(TAU * bf * t) * bass_env * 0.38
		bass += sin(TAU * bf * 0.5 * t) * bass_env * 0.18  # sub-oitava

		# --- Pad (acorde sustentado) ---
		var cf: Array = chord_hz[bar]
		var tp: float = t_bar / bar_dur
		var pad_env: float = clampf(tp * 8.0, 0.0, 1.0) * clampf((1.0 - tp) * 6.0, 0.0, 1.0)
		var vib: float = sin(TAU * 4.8 * t) * 0.004
		var pad: float = (
			sin(TAU * float(cf[0]) * (1.0 + vib) * t) * 0.50 +
			sin(TAU * float(cf[1]) * (1.0 + vib) * t) * 0.35 +
			sin(TAU * float(cf[2]) * (1.0 + vib) * t) * 0.22
		) * pad_env * 0.28

		# --- Melodia ---
		var mf: float = float((melody_hz[bar] as Array)[beat])
		var mel_env: float = 0.0
		if t_beat < BEAT * 0.75:
			mel_env = clampf(t_beat * 30.0, 0.0, 1.0) * (1.0 - t_beat / (BEAT * 0.75))
		var mel: float = (sin(TAU * mf * t) * 0.6 + sin(TAU * mf * 2.0 * t) * 0.15) * mel_env * 0.18

		# --- Kick (beats 0 e 2) ---
		var kick: float = 0.0
		if (beat == 0 or beat == 2) and t_beat < 0.14:
			var ke: float = exp(-28.0 * t_beat)
			var kf: float = lerp(110.0, 38.0, t_beat / 0.14)
			kick = sin(TAU * kf * t_beat) * ke * 0.60

		# --- Snare (beats 1 e 3) ---
		var snare: float = 0.0
		if (beat == 1 or beat == 3) and t_beat < 0.09:
			var se: float = exp(-38.0 * t_beat)
			snare = rng.randf_range(-1.0, 1.0) * se * 0.38

		var mix: float = clampf(bass + pad + mel + kick + snare, -1.0, 1.0)
		var v: int = clampi(int(mix * 32767.0), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF

	var s := AudioStreamWAV.new()
	s.data = data
	s.format = 1  # FORMAT_16_BIT
	s.mix_rate = TAXA_MUSICA
	s.stereo = false
	s.loop_mode = 1  # LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n - 1
	return s

# --- SFX ---

func _gerar_impacto(dur: float, f0: float, f1: float, decai: float, mix_r: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0 * 7.0 + f1 * 3.0 + decai)
	for i in range(n):
		var t: float = float(i) / float(TAXA_AMOSTRA)
		var env: float = exp(-decai * t)
		var freq: float = lerp(f0, f1, float(i) / float(n))
		var ruido: float = rng.randf_range(-1.0, 1.0)
		var tom: float = sin(TAU * freq * t)
		var val: float = (ruido * mix_r + tom * (1.0 - mix_r)) * env
		var v: int = clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _fazer_stream(data)

func _gerar_metalico(dur: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for i in range(n):
		var t: float = float(i) / float(TAXA_AMOSTRA)
		var env: float = exp(-34.0 * t)
		var ruido: float = rng.randf_range(-1.0, 1.0)
		var metal: float = sin(TAU * 760.0 * t) * 0.38 + sin(TAU * 1240.0 * t) * 0.30 + sin(TAU * 1950.0 * t) * 0.20 + sin(TAU * 2900.0 * t) * 0.12
		var val: float = (ruido * 0.42 + metal * 0.58) * env
		var v: int = clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _fazer_stream(data)

func _gerar_whoosh(dur: float, f0: float, f1: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var fase: float = 0.0
	for i in range(n):
		var prog: float = float(i) / float(n)
		var env: float = sin(PI * prog) * 0.80
		fase += TAU * lerp(f0, f1, prog) / float(TAXA_AMOSTRA)
		var ruido: float = rng.randf_range(-1.0, 1.0)
		var val: float = (sin(fase) * 0.55 + ruido * 0.45) * env
		var v: int = clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _fazer_stream(data)

func _gerar_bip(dur: float, freq: float) -> AudioStreamWAV:
	var n: int = int(TAXA_AMOSTRA * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(TAXA_AMOSTRA)
		var env: float = sin(PI * float(i) / float(n))
		var val: float = sin(TAU * freq * t) * env * 0.65
		var v: int = clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _fazer_stream(data)

func _fazer_stream(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.data = data
	s.format = 1  # FORMAT_16_BIT
	s.mix_rate = TAXA_AMOSTRA
	s.stereo = false
	return s
