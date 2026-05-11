extends Node
## AudioManager autoload - handles BGM and SFX playback
## All BGM loops by default. Volume is controlled via set_*_volume() methods.

signal bgm_changed(track_name: String)

var bgm_player: AudioStreamPlayer
var bgm_crossfade_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var _current_bgm_path: String = ""

## SFX throttling: tracks last play time per stream path
var _sfx_last_play: Dictionary = {}  # { stream_path: float (timestamp) }

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# Crossfade BGM player
	bgm_crossfade_player = AudioStreamPlayer.new()
	bgm_crossfade_player.bus = "Master"
	add_child(bgm_crossfade_player)
	
	# Create SFX pool (16 slots for concurrent sounds)
	for i in range(16):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

## ── BGM ────────────────────────────────────────────────────

func play_bgm(stream_path: String):
	"""Play a BGM track. Loops by default. Skips if already playing same track."""
	if stream_path == _current_bgm_path and bgm_player.playing:
		return
	_current_bgm_path = stream_path
	if not ResourceLoader.exists(stream_path):
		push_warning("BGM resource not found: " + stream_path)
		return
	var res = load(stream_path)
	if res:
		# Duplicate to avoid modifying the cached imported resource
		var stream = res.duplicate()
		# Enable loop for all BGM
		_set_stream_loop(stream, true)
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()
		bgm_changed.emit(stream_path)
		print("[AudioManager] BGM started: ", stream_path, " playing=", bgm_player.playing, " loop_mode=", stream.loop_mode if stream is AudioStreamWAV else "N/A")

func stop_bgm():
	bgm_player.stop()
	bgm_crossfade_player.stop()
	_current_bgm_path = ""

func crossfade_bgm(stream_path: String, fade_time: float = 0.6):
	"""Smoothly crossfade to a new BGM track."""
	if stream_path == _current_bgm_path and bgm_player.playing:
		return
	_current_bgm_path = stream_path
	if not ResourceLoader.exists(stream_path):
		push_warning("BGM resource not found: " + stream_path)
		return
	var res = load(stream_path)
	if not res:
		return
	var stream = res.duplicate()
	_set_stream_loop(stream, true)
	var old_player = bgm_player
	var new_player = bgm_crossfade_player
	# Swap references so next call fades from current
	bgm_player = new_player
	bgm_crossfade_player = old_player
	new_player.stream = stream
	new_player.volume_db = linear_to_db(0.001)
	new_player.play()
	var target_db = linear_to_db(bgm_volume * master_volume)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(new_player, "volume_db", target_db, fade_time).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(old_player, "volume_db", linear_to_db(0.001), fade_time).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(old_player.stop)
	bgm_changed.emit(stream_path)

## ── SFX ────────────────────────────────────────────────────

func play_sfx(stream_path: String, volume_offset_db: float = 0.0):
	"""Play a one-shot SFX. Pool of 16 concurrent players.
	volume_offset_db: additional dB offset (negative = quieter)."""
	if not ResourceLoader.exists(stream_path):
		return
	var stream = load(stream_path)
	if stream:
		var final_db = linear_to_db(sfx_volume * master_volume) + volume_offset_db
		for p in sfx_players:
			if not p.playing:
				p.stream = stream
				p.volume_db = final_db
				p.play()
				return
		# All busy, steal oldest (first in pool)
		sfx_players[0].stop()
		sfx_players[0].stream = stream
		sfx_players[0].volume_db = final_db
		sfx_players[0].play()

## ── Volume Controls ────────────────────────────────────────

func set_master_volume(vol: float):
	master_volume = vol
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(vol, 0.001)))
	# Also update currently playing BGM volume explicitly
	_refresh_bgm_volume()

func get_master_volume() -> float:
	return master_volume

func set_bgm_volume(vol: float):
	bgm_volume = vol
	_refresh_bgm_volume()

func _refresh_bgm_volume():
	"""Apply bgm_volume * master_volume to current BGM player."""
	if bgm_player.playing:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	if bgm_crossfade_player.playing:
		bgm_crossfade_player.volume_db = linear_to_db(bgm_volume * master_volume)

func get_bgm_volume() -> float:
	return bgm_volume

func set_sfx_volume(vol: float):
	sfx_volume = vol

func get_sfx_volume() -> float:
	return sfx_volume

## ── Utility ────────────────────────────────────────────────

func _set_stream_loop(stream, loop: bool):
	"""Enable or disable loop on AudioStreamWAV / AudioStreamOggVorbis."""
	if stream is AudioStreamWAV:
		if loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			# 使用 get_length() * mix_rate 正确计算采样数
			# 这对压缩格式（IMA-ADPCM）也能正确工作
			# 因为 get_length() 返回的是音频实际时长（秒）
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamMP3:
		stream.loop = loop

func is_bgm_playing() -> bool:
	"""Check if any BGM is currently playing."""
	return bgm_player.playing

func play_sfx_throttled(stream_path: String, min_interval: float = 0.08, volume_offset_db: float = 0.0):
	"""Play SFX with throttling to avoid ear-piercing overlap from rapid calls."""
	var now = Time.get_ticks_msec() / 1000.0
	if _sfx_last_play.has(stream_path):
		if now - _sfx_last_play[stream_path] < min_interval:
			return
	_sfx_last_play[stream_path] = now
	play_sfx(stream_path, volume_offset_db)
