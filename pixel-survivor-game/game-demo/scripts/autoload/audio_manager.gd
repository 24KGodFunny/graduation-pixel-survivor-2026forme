extends Node
## AudioManager autoload - handles BGM and SFX playback

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	# Create SFX pool
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func play_bgm(stream_path: String):
	if not ResourceLoader.exists(stream_path):
		return
	var stream = load(stream_path)
	if stream:
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()

func stop_bgm():
	bgm_player.stop()

func play_sfx(stream_path: String):
	if not ResourceLoader.exists(stream_path):
		return
	var stream = load(stream_path)
	if stream:
		for p in sfx_players:
			if not p.playing:
				p.stream = stream
				p.volume_db = linear_to_db(sfx_volume)
				p.play()
				return
		# All busy, use first
		sfx_players[0].stream = stream
		sfx_players[0].volume_db = linear_to_db(sfx_volume)
		sfx_players[0].play()

func set_bgm_volume(vol: float):
	bgm_volume = vol
	bgm_player.volume_db = linear_to_db(vol)

func set_sfx_volume(vol: float):
	sfx_volume = vol