extends Control

const W=1920.0
const H=1080.0
const INK=Color("#272922")
const RED=Color("#8f3028")
const GOLD=Color("#a88a54")
const MENU=["图鉴","设置","进入长安","坊区档案","营造值","任务"]
const LEAVE_SCENE="res://scenes/ChangAnCity.tscn"
const BUTTON_RECTS=[Rect2(1486,72,181,72),Rect2(1684,72,188,72),Rect2(663,838,600,204),Rect2(1510,810,363,66),Rect2(1510,886,168,115),Rect2(1688,886,184,115)]
var song:Font
var sans:Font
var sc=1.0
var off=Vector2.ZERO
var hover=-1
var focus=-1  # 键盘焦点：开机无默认选中，仅悬停或按方向键时才高亮
var elapsed=0.0
var toast=""
var toast_t=0.0
var settings=false
var leaving=false
var trans=0.0
var bg:Texture2D
var paper:Texture2D
var title_art:Texture2D
var subtitle_art:Texture2D
var button_tex:Array=[]

func _ready():
	song=_font(["STSong","SimSun","Noto Serif CJK SC"])
	sans=_font(["Microsoft YaHei","PingFang SC","Noto Sans CJK SC"])
	bg=load("res://assets/ui/home_full.png")
	paper=load("res://assets/ui/ink/ui_paper_fiber_tile.png")
	title_art=load("res://assets/ui/title_changan_works.png") if ResourceLoader.exists("res://assets/ui/title_changan_works.png") else null
	subtitle_art=load("res://assets/ui/subtitle_changan_works.png") if ResourceLoader.exists("res://assets/ui/subtitle_changan_works.png") else null
	for path in ["res://assets/ui/home_codex_button.png","res://assets/ui/home_settings_button.png","res://assets/ui/home_enter_button.png","res://assets/ui/home_archive_button.png","res://assets/ui/home_value_button.png","res://assets/ui/home_task_button.png"]:
		button_tex.append(load(path))
	set_process(true)
	# 首页背景音乐（MusicManager 自动交叉淡入；进入城市时切「长安闲情」）
	MusicManager.play("start")

func _font(names:Array)->Font:
	var f=SystemFont.new()
	f.font_names=PackedStringArray(names)
	f.allow_system_fallback=true
	return f

func _process(d):
	elapsed+=d; toast_t=maxf(0,toast_t-d)
	if leaving:
		trans=minf(1,trans+d/0.65)
		if trans>=1:
			SceneTransition.goto_scene(LEAVE_SCENE)
	queue_redraw()

func _draw():
	sc=minf(size.x/W,size.y/H); off=(size-Vector2(W,H)*sc)*0.5
	draw_set_transform(off,0,Vector2(sc,sc))
	draw_rect(Rect2(0,0,W,H),Color("#07130e"))
	if bg:
		draw_texture_rect(bg,Rect2(0,0,W,H),false,Color.WHITE)
	_draw_menu()
	if settings: _draw_settings()
	if toast_t>0: _draw_toast()
	if leaving: _draw_transition()

func _draw_map():
	pass

func _draw_title():
	var a=clampf((elapsed-0.1)/0.8,0,1)
	if title_art:
		draw_texture_rect(title_art,Rect2(58,96,500,167),false,Color(1,1,1,a))
	else:
		draw_string(song,Vector2(78,190),"长安营造司：百坊城局",0,-1,48,Color(0.93,0.78,0.48,a))
	if subtitle_art:
		draw_texture_rect(subtitle_art,Rect2(70,250,474,158),false,Color(0.94,0.89,0.76,a))
	draw_line(Vector2(78,422),Vector2(532,422),Color(0.78,0.57,0.31,a*.58),2)

func _draw_menu():
	for i in range(MENU.size()):
		var a=clampf((elapsed-.18-i*.05)/.35,0,1)
		var r=BUTTON_RECTS[i]
		var active=(i==hover) or (focus>=0 and i==focus)
		var tint=Color(1.12,1.08,0.88,a) if active else Color(1,1,1,a)
		if i<button_tex.size() and button_tex[i]:
			draw_texture_rect(button_tex[i],r,false,tint)
		if active:
			draw_rect(r.grow(3),Color(0.82,0.62,0.31,0.62),false,2)

func _draw_footer():
	draw_rect(Rect2(0,958,W,122),Color(0.02,0.026,0.025,.76)); draw_line(Vector2(0,958),Vector2(W,958),Color(0.75,0.57,0.34,.5),2)
	draw_string(sans,Vector2(78,1002),"据实而作",0,-1,16,Color("#d86a54"))
	draw_string(song,Vector2(78,1044),"本作基于历史文献、考古资料、历史地图及现代研究构建。",0,-1,22,Color("#eee3c9"))
	draw_string(sans,Vector2(1515,1038),"ENTER 选择  ·  ↑ ↓ 切换",0,-1,16,Color(0.84,0.78,0.66,.82))

func _draw_settings():
	draw_rect(Rect2(0,0,W,H),Color(0.01,0.012,0.01,.7)); var r=Rect2(610,250,700,560)
	draw_rect(r,Color("#e4d8bd")); draw_rect(r,Color("#6e5c38"),false,5)
	draw_string(song,r.position+Vector2(54,76),"游戏设置",0,-1,38,INK)
	draw_line(r.position+Vector2(50,104),r.position+Vector2(650,104),Color(0.38,0.31,0.2,.5),2)
	var rows=[["界面缩放","随窗口自适应"],["动态效果","尊重系统设置"],["音效与存档","原型阶段未接入"]]
	for i in range(3):
		draw_string(sans,r.position+Vector2(54,164+i*70),rows[i][0],0,-1,22,INK); draw_string(sans,r.position+Vector2(460,164+i*70),rows[i][1],0,-1,20,RED if i==2 else Color("#696451"))
	draw_string(song,r.position+Vector2(54,392),"本页仅说明原型状态，不会写入本地设置。",0,-1,22,Color("#696451"))
	draw_rect(Rect2(840,700,240,58),RED); draw_string(song,Vector2(840,739),"返回案卷",1,240,24,Color("#f1e7d2"))

func _draw_toast():
	var r=Rect2(690,852,540,62); draw_rect(r,Color(0.06,0.065,0.055,.96)); draw_rect(r,GOLD,false,2); draw_string(sans,r.position+Vector2(18,40),toast,1,r.size.x-36,20,Color("#e4dac2"))

func _draw_transition():
	var x=W*ease(trans,-2.0); draw_rect(Rect2(0,0,x,H),Color("#151713")); draw_line(Vector2(x,0),Vector2(x,H),GOLD,4)
	if trans>.2: draw_string(song,Vector2(760,566),"舆图展开 · 入司理事",1,400,28,Color(0.87,0.8,0.66,minf(1,trans*2)))

func _gui_input(e):
	if leaving:return
	if e is InputEventMouseMotion: hover=_at(_p(e.position)); queue_redraw()
	elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and not e.pressed:
		var p=_p(e.position)
		if settings:
			if Rect2(840,700,240,58).has_point(p): settings=false
		else:
			var i=_at(p)
			if i>=0:
				_activate(i)
	elif e is InputEventKey and e.pressed and not e.echo:
		if settings and e.keycode==KEY_ESCAPE: settings=false
		elif e.keycode in [KEY_DOWN,KEY_S]: focus=0 if focus<0 else (focus+1)%MENU.size()
		elif e.keycode in [KEY_UP,KEY_W]: focus=(MENU.size()-1) if focus<0 else (focus-1+MENU.size())%MENU.size()
		elif e.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus>=0: _activate(focus)
		queue_redraw()

func _activate(i):
	if i==0: _toast("图鉴将在后续版本开放。")
	elif i==1: settings=true
	elif i==2: leaving=true
	elif i==3: _toast("坊区档案正在整理中。")
	elif i==4: _toast("营造值将在营造方案建立后更新。")
	elif i==5: _toast("当前尚无已领取任务。")

func _at(p):
	for i in range(MENU.size()):
		if BUTTON_RECTS[i].has_point(p):return i
	return -1
func _p(p):return (p-off)/sc
func _toast(t):toast=t;toast_t=2.5
