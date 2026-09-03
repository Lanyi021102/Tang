extends Control

const W=1920.0
const H=1080.0
const TOP=104.0
const BOTTOM=150.0
const LEFT=124.0
const RIGHT=460.0
const INK=Color("#292b25")
const PAPER=Color("#dfd3b8")
const PAPER2=Color("#c9bb98")
const RED=Color("#92372f")
const GOLD=Color("#9d8150")
const JADE=Color("#526b61")
const TOOLS=["置坊","修路","理水","设门","查证","推演","回溯"]
const ICONS=["坊","路","水","门","证","演","溯"]
const OBJECTS=[
	{"name":"安仁坊","type":"里坊","period":"唐开元年间","precision":"坊级定位","state":"历史证据","fact":"位于外郭城朱雀大街东侧的里坊之一。","inference":"坊内道路与院落布局仍需更多考古材料校核。","todo":"补充坊内寺观与居住单元的直接证据。","pos":Vector2(835,475),"kind":"fang"},
	{"name":"朱雀大街","type":"道路","period":"隋唐时期","precision":"轴线可信","state":"历史证据","fact":"贯通皇城南向，是长安中轴线的重要组成。","inference":"不同时期道路使用强度可能存在变化。","todo":"补充路面分期与道路排水材料。","pos":Vector2(780,690),"kind":"road"},
	{"name":"永安渠（示意段）","type":"水渠","period":"唐代","precision":"走向概略","state":"学术推断","fact":"长安城水系承担供水、园林与排水等功能。","inference":"本段走向为依据研究成果所作空间示意。","todo":"核对具体河段位置与沿线设施。","pos":Vector2(1010,580),"kind":"water"},
	{"name":"明德门","type":"城门","period":"隋唐时期","precision":"遗址级定位","state":"历史证据","fact":"外郭城正南门，与朱雀大街共同构成南北轴线。","inference":"交通组织呈现礼制轴线与日常通行的叠合。","todo":"补充门道使用与南郊道路衔接证据。","pos":Vector2(780,832),"kind":"gate"}
]
var song:Font
var sans:Font
var sc=1.0
var off=Vector2.ZERO
var selected=-1
var tool=4
var hover_tool=-1
var hover_obj=-1
var camera=Vector2.ZERO
var zoom=1.0
var dragging=false
var drag_from=Vector2.ZERO
var camera_from=Vector2.ZERO
var toast=""
var toast_t=0.0
var elapsed=0.0
var show_settings=false
var ai_tip=true
var history:Array=[]
var history_pos=-1
var paper_tex:Texture2D
var ink_tex:Texture2D
var ring_tex:Texture2D
var fang_tex:Array=[]

func _ready():
	song=_font(["STSong","SimSun","Noto Serif CJK SC"]); sans=_font(["Microsoft YaHei","PingFang SC","Noto Sans CJK SC"])
	paper_tex=load("res://assets/ui/ink/ui_paper_fiber_tile.png"); ink_tex=load("res://assets/ui/ink/ui_ink_panel_noise_tile.png"); ring_tex=load("res://assets/ui/ink/ui_selection_ink_ring.png")
	for path in ["res://assets/fang/安仁坊.png","res://assets/fang/西市.png","res://assets/fang/东市.png"]:
		fang_tex.append(load(path))
	set_process(true); _push_history("进入案卷")

func _font(names:Array)->Font:
	var f=SystemFont.new()
	f.font_names=PackedStringArray(names)
	f.allow_system_fallback=true
	return f

func _process(d): elapsed+=d; toast_t=maxf(0,toast_t-d); queue_redraw()

func _draw():
	sc=minf(size.x/W,size.y/H); off=(size-Vector2(W,H)*sc)*.5; draw_set_transform(off,0,Vector2(sc,sc))
	draw_rect(Rect2(0,0,W,H),Color("#20231e")); _draw_scene(); _draw_top(); _draw_tools(); _draw_right(); _draw_bottom()
	if toast_t>0:_draw_toast()
	if show_settings:_draw_settings()

func _draw_top():
	draw_rect(Rect2(0,0,W,TOP),Color("#262820")); draw_line(Vector2(0,TOP),Vector2(W,TOP),GOLD,2)
	draw_rect(Rect2(28,20,66,66),RED); draw_string(song,Vector2(28,63),"营造",1,66,20,Color("#eadfc5"))
	draw_string(song,Vector2(112,50),"长安营造司",0,-1,30,Color("#eadfc8")); draw_string(sans,Vector2(112,78),"案卷 · 南城通行之议",0,-1,17,Color("#a99f86"))
	_metric(472,"时期","唐开元二十四年","证据")
	_metric(690,"证据完整度","62%","证据")
	_metric(920,"城市通达度","74%","模拟")
	_metric(1150,"水系覆盖度","58%","模拟")
	_metric(1380,"坊市协调度","81%","模拟")
	_button(Rect2(1744,25,142,54),"设置",false,show_settings)

func _metric(x,label,value,tag):
	draw_string(sans,Vector2(x,38),label,0,-1,15,Color("#aaa189")); draw_string(song,Vector2(x,72),value,0,-1,23,Color("#eee3c8"))
	var c=RED if tag=="证据" else JADE; draw_rect(Rect2(x+138,23,52,24),c); draw_string(sans,Vector2(x+138,41),tag,1,52,13,Color("#f3ead7"))

func _draw_tools():
	draw_rect(Rect2(0,TOP,LEFT,H-TOP-BOTTOM),Color("#292b24")); draw_line(Vector2(LEFT,TOP),Vector2(LEFT,H-BOTTOM),GOLD,2)
	draw_string(sans,Vector2(0,140),"营造工具",1,LEFT,15,Color("#bdb294"))
	for i in range(TOOLS.size()):
		var r=Rect2(14,164+i*105,96,88); var active=i==tool; var hot=i==hover_tool
		draw_rect(r,Color("#753129") if active else (Color("#3d4035") if hot else Color("#30322a")))
		draw_rect(r,GOLD if active else Color(0.55,0.48,0.34,.45),false,2)
		draw_circle(r.position+Vector2(48,31),19,Color(0.75,0.66,0.47,.12)); draw_string(song,r.position+Vector2(0,40),ICONS[i],1,96,22,Color("#ded2b5"))
		draw_string(sans,r.position+Vector2(0,70),TOOLS[i],1,96,17,Color("#ded2b5"))

func _draw_scene():
	var r=Rect2(LEFT,TOP,W-LEFT-RIGHT,H-TOP-BOTTOM); draw_rect(r,Color("#a99d7d"))
	draw_style_box(_paper_box(Color("#b8aa87"),Color.TRANSPARENT,0),r)
	var center=r.get_center()+camera
	# 2.5D city sand-table, deliberately schematic and tied to the four demo records.
	var cols=11; var rows=10; var cw=96.0*zoom; var ch=53.0*zoom; var start=center-Vector2(cols*cw*.5,rows*ch*.5)
	for rr in range(rows):
		for cc in range(cols):
			var x=start.x+cc*cw; var y=start.y+rr*ch
			var p=PackedVector2Array([Vector2(x,y+ch*.22),Vector2(x+cw*.45,y),Vector2(x+cw*.9,y+ch*.22),Vector2(x+cw*.45,y+ch*.44)])
			var tint=Color("#968b69") if (rr+cc)%3 else Color("#8b805f")
			draw_colored_polygon(p,tint); draw_polyline(p,tint.lightened(.15),1.0)
			if (rr+cc)%4==0: _house(Vector2(x+cw*.45,y+ch*.12),zoom)
	# central avenue and canal
	var ax=center.x; draw_colored_polygon(PackedVector2Array([Vector2(ax-34*zoom,start.y),Vector2(ax+34*zoom,start.y),Vector2(ax+250*zoom,start.y+rows*ch),Vector2(ax+180*zoom,start.y+rows*ch)]),Color("#c7b991"))
	draw_line(Vector2(ax+320*zoom,start.y+40),Vector2(ax+82*zoom,start.y+rows*ch-20),Color("#607b75"),12*zoom)
	# south gate
	_gate(Vector2(ax+215*zoom,start.y+rows*ch-12),zoom)
	# Reuse the project's authored 2.5D blocks as low-opacity sand-table models.
	var art_positions=[Vector2(-250,-125),Vector2(245,-65),Vector2(-285,115)]
	for i in range(fang_tex.size()):
		if fang_tex[i]:
			var ap=center+art_positions[i]*zoom
			draw_texture_rect(fang_tex[i],Rect2(ap-Vector2(105,60)*zoom,Vector2(210,120)*zoom),false,Color(1,1,1,.52))
	for i in range(OBJECTS.size()):
		var p=_obj_screen(i); var c=_kind_color(OBJECTS[i].kind)
		if i==selected:
			draw_circle(p,38,Color(c.r,c.g,c.b,.18)); draw_circle(p,31,c,false,4)
		draw_circle(p,13,c); draw_circle(p,18,Color("#eee2c3"),false,2)
		draw_string(sans,p+Vector2(22,7),OBJECTS[i].name,0,-1,17,Color("#282a24"))
	# scene legend
	draw_rect(Rect2(LEFT+22,TOP+20,290,40),Color(0.12,0.13,0.11,.76)); draw_string(sans,Vector2(LEFT+38,TOP+47),"拖拽平移 · 滚轮缩放 · 点击查证",0,-1,16,Color("#e2d7bd"))
	draw_string(sans,Vector2(W-RIGHT-130,H-BOTTOM-24),"缩放 %d%%"%int(zoom*100),0,-1,15,Color("#393b32"))

func _house(p,s):
	var pts=PackedVector2Array([p+Vector2(-20,8)*s,p+Vector2(0,-3)*s,p+Vector2(20,8)*s,p+Vector2(0,18)*s]); draw_colored_polygon(pts,Color("#7e3c32")); draw_rect(Rect2(p+Vector2(-12,8)*s,Vector2(24,16)*s),Color("#69543a"))

func _gate(p,s):
	draw_rect(Rect2(p-Vector2(56,35)*s,Vector2(112,42)*s),Color("#754038")); draw_rect(Rect2(p-Vector2(68,41)*s,Vector2(136,14)*s),Color("#433d32")); draw_rect(Rect2(p-Vector2(13,12)*s,Vector2(26,20)*s),Color("#25261f"))

func _draw_right():
	var x=W-RIGHT; draw_rect(Rect2(x,TOP,RIGHT,H-TOP-BOTTOM),PAPER); draw_line(Vector2(x,TOP),Vector2(x,H-BOTTOM),GOLD,3)
	if paper_tex: draw_texture_rect(paper_tex,Rect2(x,TOP,RIGHT,H-TOP-BOTTOM),true,Color(1,1,1,.18))
	if selected<0:_draw_case(x)
	else:_draw_object(x,OBJECTS[selected])

func _draw_case(x):
	draw_string(sans,Vector2(x+34,148),"当前案卷",0,-1,16,RED); draw_string(song,Vector2(x+34,197),"南城通行之议",0,-1,35,INK)
	draw_line(Vector2(x+34,220),Vector2(W-32,220),Color(0.37,0.31,0.2,.45),2)
	_draw_wrapped("南部城门与城内道路应当怎样连接，才能形成清晰的城市通行体系？",Vector2(x+34,260),380,24,INK)
	draw_string(sans,Vector2(x+34,382),"任务目标",0,-1,17,RED)
	var goals=["查看指定城门","识别连接的主要道路","检查目标坊区通达情况","提交至少一项证据依据"]
	for i in range(goals.size()):
		draw_circle(Vector2(x+46,424+i*44),10,Color(0.58,0.48,0.29,.25)); draw_string(sans,Vector2(x+42,430+i*44),str(i+1),1,8,12,GOLD); draw_string(sans,Vector2(x+68,431+i*44),goals[i],0,-1,19,INK)
	_draw_ai(x,650)

func _draw_ai(x,y):
	draw_rect(Rect2(x+30,y,400,146),Color("#c8bea5")); draw_rect(Rect2(x+30,y,400,146),Color("#8b7545"),false,2)
	draw_string(sans,Vector2(x+50,y+34),"营造参军 · 建议",0,-1,17,Color("#735326"))
	_draw_wrapped("先查明德门与朱雀大街的关系，再判断支路是否能覆盖目标坊区。此建议属于模拟辅助，不构成史实。",Vector2(x+50,y+68),360,18,INK)

func _draw_object(x,o):
	draw_string(sans,Vector2(x+34,148),"对象信息卡  /  返回案卷 Esc",0,-1,16,RED); draw_string(song,Vector2(x+34,195),o.name,0,-1,34,INK)
	_badge(Vector2(x+34,218),o.type,GOLD); _badge(Vector2(x+128,218),o.state,RED if o.state=="历史证据" else Color("#8b7545"))
	draw_string(sans,Vector2(x+34,285),"所属时期",0,-1,15,Color("#756e5c")); draw_string(song,Vector2(x+154,285),o.period,0,-1,20,INK)
	draw_string(sans,Vector2(x+34,322),"位置精度",0,-1,15,Color("#756e5c")); draw_string(song,Vector2(x+154,322),o.precision,0,-1,20,INK)
	_info_block(x,364,"已确认事实",o.fact,RED); _info_block(x,492,"研究推断",o.inference,Color("#8b7545")); _info_block(x,620,"待补证内容",o.todo,JADE)
	var labels=["查看证据","查看关系","加入案卷","提交疑问"]
	for i in range(4):_button(Rect2(x+30+(i%2)*202,760+(i/2)*62,190,50),labels[i],false,false)

func _info_block(x,y,label,text,c):
	draw_rect(Rect2(x+30,y,400,108),Color(0.45,0.4,0.29,.08)); draw_rect(Rect2(x+30,y,5,108),c)
	draw_string(sans,Vector2(x+50,y+28),label,0,-1,16,c); _draw_wrapped(text,Vector2(x+50,y+56),350,18,INK)

func _draw_bottom():
	var y=H-BOTTOM; draw_rect(Rect2(0,y,W,BOTTOM),Color("#24261f")); draw_line(Vector2(0,y),Vector2(W,y),GOLD,2)
	draw_string(sans,Vector2(34,y+39),"当前工具",0,-1,15,Color("#9f967e")); draw_string(song,Vector2(34,y+78),TOOLS[tool],0,-1,27,Color("#e5dac0"))
	draw_string(sans,Vector2(190,y+39),"操作说明",0,-1,15,Color("#9f967e")); draw_string(song,Vector2(190,y+78),_tool_help(),0,-1,20,Color("#d0c6ae"))
	draw_string(sans,Vector2(690,y+39),"当前选中",0,-1,15,Color("#9f967e")); draw_string(song,Vector2(690,y+78),"未选择" if selected<0 else OBJECTS[selected].name,0,-1,21,Color("#e5dac0"))
	var actions=["撤销","重做","保存方案","开始推演","提交案卷"]
	for i in range(actions.size()):_button(Rect2(1030+i*166,y+44,150,58),actions[i],i<2 and ((i==0 and history_pos<=0) or (i==1 and history_pos>=history.size()-1)),i==3)

func _button(r,label,disabled=false,accent=false):
	draw_rect(r,Color("#5d312a") if accent else (Color("#33352d") if not disabled else Color("#2b2d27"))); draw_rect(r,GOLD if not disabled else Color("#55564d"),false,2)
	draw_string(sans,r.position+Vector2(0,37),label,1,r.size.x,18,Color("#e7dcc3") if not disabled else Color("#77786d"))

func _badge(p,label,c):
	var w=maxf(82,label.length()*18+24); draw_rect(Rect2(p,Vector2(w,30)),c); draw_string(sans,p+Vector2(0,21),label,1,w,14,Color("#f4ead4"))

func _draw_wrapped(text,p,width,font_size,color):
	var chars=maxi(8,int(width/(font_size+2))); var line=0
	for i in range(0,text.length(),chars):
		draw_string(song,p+Vector2(0,line*(font_size+10)),text.substr(i,chars),0,width,font_size,color); line+=1

func _draw_toast():
	var r=Rect2(690,830,540,58); draw_rect(r,Color(0.08,0.085,0.07,.96)); draw_rect(r,GOLD,false,2); draw_string(sans,r.position+Vector2(18,38),toast,1,r.size.x-36,18,Color("#e7dcc3"))

func _draw_settings():
	draw_rect(Rect2(0,0,W,H),Color(0.01,0.012,0.01,.65)); var r=Rect2(700,300,520,420); draw_rect(r,PAPER); draw_rect(r,GOLD,false,4)
	draw_string(song,r.position+Vector2(40,62),"界面设置",0,-1,34,INK); draw_string(sans,r.position+Vector2(40,122),"滚轮缩放范围",0,-1,18,INK); draw_string(sans,r.position+Vector2(330,122),"70% — 145%",0,-1,18,Color("#655e4e"))
	draw_string(sans,r.position+Vector2(40,176),"动态效果",0,-1,18,INK); draw_string(sans,r.position+Vector2(330,176),"缓慢且克制",0,-1,18,Color("#655e4e"))
	draw_string(sans,r.position+Vector2(40,230),"数据说明",0,-1,18,INK); draw_string(sans,r.position+Vector2(330,230),"证据 / 推断 / 模拟分列",0,-1,18,Color("#655e4e"))
	_button(Rect2(850,635,220,54),"返回城局",false,true)

func _gui_input(e):
	var p=_p(e.position) if e is InputEventMouse else Vector2.ZERO
	if e is InputEventMouseMotion:
		hover_tool=_tool_at(p); hover_obj=_object_at(p)
		if dragging: camera=camera_from+(p-drag_from); camera.x=clampf(camera.x,-280,280); camera.y=clampf(camera.y,-190,190)
	elif e is InputEventMouseButton:
		if e.button_index==MOUSE_BUTTON_WHEEL_UP and _scene_rect().has_point(p):zoom=clampf(zoom+.08,.7,1.45)
		elif e.button_index==MOUSE_BUTTON_WHEEL_DOWN and _scene_rect().has_point(p):zoom=clampf(zoom-.08,.7,1.45)
		elif e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed:
				dragging=_scene_rect().has_point(p); drag_from=p; camera_from=camera
			else:
				var moved=p.distance_to(drag_from); dragging=false
				if show_settings and Rect2(850,635,220,54).has_point(p):show_settings=false
				elif Rect2(1744,25,142,54).has_point(p):show_settings=true
				elif _tool_at(p)>=0:_select_tool(_tool_at(p))
				elif moved<8 and _object_at(p)>=0:_select_object(_object_at(p))
				else:_bottom_click(p)
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode==KEY_ESCAPE:
			if show_settings:show_settings=false
			elif selected>=0:selected=-1
			else:get_tree().change_scene_to_file("res://scenes/Start.tscn")
	queue_redraw()

func _select_tool(i):tool=i;_push_history("选择"+TOOLS[i]);_toast("已切换至「"+TOOLS[i]+"」工具。")
func _select_object(i):selected=i;_push_history("查证"+OBJECTS[i].name);_toast("已打开「"+OBJECTS[i].name+"」信息卡。")

func _bottom_click(p):
	var y=H-BOTTOM+44
	for i in range(5):
		if Rect2(1030+i*166,y,150,58).has_point(p):
			if i==0:_undo()
			elif i==1:_redo()
			elif i==2:_toast("方案保存尚未接入，本次原型不会写入存档。")
			elif i==3:_toast("推演预览：当前通达度 74%，结果仅属模拟。")
			else:_toast("尚需加入至少一项证据，暂不能提交案卷。")

func _push_history(label):
	if history_pos<history.size()-1:history=history.slice(0,history_pos+1)
	history.append({"label":label,"tool":tool,"selected":selected});history_pos=history.size()-1
func _undo():
	if history_pos<=0:
		_toast("没有可撤销的操作。")
		return
	history_pos-=1;tool=history[history_pos].tool;selected=history[history_pos].selected;_toast("已撤销上一步。")
func _redo():
	if history_pos>=history.size()-1:
		_toast("没有可重做的操作。")
		return
	history_pos+=1;tool=history[history_pos].tool;selected=history[history_pos].selected;_toast("已重做操作。")

func _tool_help():
	return ["选择坊区并查看布局条件","标记道路连接与通行关系","查看水渠覆盖与走向","核对城门与道路衔接","查看对象证据与研究状态","预览方案的模拟指标","回看本次案卷操作"][tool]
func _scene_rect():return Rect2(LEFT,TOP,W-LEFT-RIGHT,H-TOP-BOTTOM)
func _tool_at(p):
	for i in range(TOOLS.size()):
		if Rect2(14,164+i*105,96,88).has_point(p):return i
	return -1
func _object_at(p):
	if not _scene_rect().has_point(p):return -1
	for i in range(OBJECTS.size()):
		if p.distance_to(_obj_screen(i))<34:return i
	return -1
func _obj_screen(i):
	var base=OBJECTS[i].pos
	var c=_scene_rect().get_center()
	return c+(base-c)*zoom+camera
func _kind_color(k):return {"fang":RED,"road":GOLD,"water":JADE,"gate":Color("#4f5147")}.get(k,RED)
func _p(p):return (p-off)/sc
func _toast(t):toast=t;toast_t=2.5
func _paper_box(fill,border,width):
	var b=StyleBoxFlat.new()
	b.bg_color=fill
	b.border_color=border
	b.set_border_width_all(int(width))
	return b
