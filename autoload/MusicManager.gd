extends Node
# 全局背景音乐：两个 AudioStreamPlayer 交叉淡入淡出，切换场景时不中断、不重头爆音。
# 用法：MusicManager.play("start") 或 MusicManager.play("city")。

const TRACKS := {
	"start": "res://assets/music/changan_dawn.mp3",
	"city": "res://assets/music/changan_xianqing.mp3",
}
const TARGET_DB := -9.0   # 正常播放音量
const MUTE_DB := -80.0
const FADE_SEC := 1.2     # 淡入/淡出时长

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current := ""

func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = MUTE_DB
		p.finished.connect(_on_finished.bind(i))
		add_child(p)
		_players.append(p)

func _on_finished(idx: int) -> void:
	if idx == _active:
		_players[idx].play()  # 循环

func play(id: String, fade := FADE_SEC) -> void:
	if not TRACKS.has(id):
		return
	if _current == id and _players[_active].playing:
		return  # 已在此曲且正在淡入/播放，不重复打断
	var stream: AudioStream = load(TRACKS[id]) as AudioStream
	if stream == null:
		return
	var next := 1 - _active
	_players[next].stream = stream
	_players[next].volume_db = MUTE_DB
	_players[next].play()
	_current = id
	_active = next
	_crossfade(fade)

func _crossfade(fade: float) -> void:
	var outgoing := _players[1 - _active]
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_players[_active], "volume_db", TARGET_DB, fade)
	t.tween_property(outgoing, "volume_db", MUTE_DB, fade)
