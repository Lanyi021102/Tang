extends Node2D
# 天空云朵（占位）：远景时飘过古风祥云。
# 暂无贴图资源，先用程序化祥云形状占位；后续换真贴图时只需改 _draw_cloud 内部。

var map

var _clouds: Array = []
var _visible := 0.0

const PUFFS: Array = [
	[Vector2(0, 0), 26.0],
	[Vector2(18, -8), 20.0],
	[Vector2(24, 2), 16.0],
	[Vector2(16, 10), 13.0],
	[Vector2(6, 8), 10.0],
	[Vector2(2, -2), 14.0],
	[Vector2(-14, -4), 20.0],
	[Vector2(-32, -8), 14.0],
	[Vector2(-48, -11), 9.0],
	[Vector2(-62, -13), 5.0],
]

func _ready() -> void:
	map = get_parent().get_parent()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in range(6):
		_clouds.append({
			"x": rng.randf_range(0.0, 1280.0),
			"y": rng.randf_range(20.0, 240.0),
			"speed": rng.randf_range(10.0, 24.0) * (1.0 if i % 2 == 0 else -1.0),
			"scale": rng.randf_range(0.7, 1.7),
			"shade": rng.randf_range(0.82, 0.97),
		})

func _process(delta: float) -> void:
	var target := 0.0
	if map != null and map._zoom_idx == 0:
		target = 1.0
	_visible = lerpf(_visible, target, delta * 3.0)
	modulate.a = _visible
	for c in _clouds:
		c["x"] += c["speed"] * delta
		var w: float = 220.0 * c["scale"]
		if c["speed"] > 0.0 and c["x"] > 1280.0 + w:
			c["x"] = -w
		elif c["speed"] < 0.0 and c["x"] < -w:
			c["x"] = 1280.0 + w
	if _visible > 0.01:
		queue_redraw()

func _draw() -> void:
	if _visible <= 0.01:
		return
	for c in _clouds:
		_draw_cloud(Vector2(c["x"], c["y"]), c["scale"], c["shade"])

func _draw_cloud(pos: Vector2, scl: float, shade: float) -> void:
	var col := Color(shade, shade * 0.99, shade * 0.94, 1.0)
	draw_set_transform(pos, 0.0, Vector2(scl, scl))
	for p in PUFFS:
		var off: Vector2 = p[0]
		var rad: float = p[1]
		draw_circle(off, rad, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
