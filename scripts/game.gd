extends Node2D

const W=720.0
const H=1280.0
const FLOOR=1035.0
const LANES=[120.0,360.0,600.0]
const SAVE_PATH="user://baddie_runner.cfg"

var state="menu"
var mode=""
var map_id=0
var score=0
var coins=0
var gems=0
var combo=0
var best={}
var speed=430.0
var difficulty=1.0
var lane=1
var py=FLOOR
var vy=0.0
var slide_t=0.0
var ability_t=0.0
var ability_ready=true
var spawn_t=0.0
var item_t=0.0
var baddie_t=0.0
var time=0.0
var objects=[]
var particles=[]
var toast=""
var toast_t=0.0
var dialog=""
var dialog_t=0.0
var selected=0
var rng=RandomNumberGenerator.new()
var touch_start=Vector2.ZERO
var touch=false
var music:AudioStreamPlayer
var sfx:AudioStreamPlayer
var font=ThemeDB.fallback_font

var names=["RUDRA","LAKSHYA","ARSH"]
var girl_names=["MAYA","RIYA","TARA","ZARA"]
var girl_colors=[Color("#ff6fae"),Color("#a56cff"),Color("#ff9b5c"),Color("#48c9b0")]
var colors=[Color("#ef4b4b"),Color("#3d8cff"),Color("#43d27c")]
var map_names=["NEON BAZAAR","ROOFTOP MAYHEM","CANDY CANYON","SUNSET ROAD"]

func _ready():
    rng.randomize()
    load_save()
    music=AudioStreamPlayer.new(); add_child(music)
    sfx=AudioStreamPlayer.new(); add_child(sfx)
    show_menu()
    queue_redraw()

func load_save():
    var c=ConfigFile.new()
    if c.load(SAVE_PATH)==OK:
        for n in names: best[n]=int(c.get_value("scores",n,0))
    else:
        for n in names: best[n]=0

func save_score():
    var c=ConfigFile.new()
    for n in names: c.set_value("scores",n,int(best.get(n,0)))
    c.save(SAVE_PATH)

func label(t,pos,size,col=Color.WHITE):
    var l=Label.new(); l.text=t; l.position=pos; l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",col); $"."
    return l

func clear_ui():
    for c in get_children():
        if c is CanvasLayer: c.queue_free()
    var layer=CanvasLayer.new(); layer.name="UI"; add_child(layer)
    return layer

func button(layer,t,pos,sz=Vector2(500,92)):
    var b=Button.new(); b.text=t; b.position=pos; b.size=sz
    b.add_theme_font_size_override("font_size",28); layer.add_child(b); return b

func add_label(layer,t,pos,size,col=Color.WHITE,w=680):
    var l=Label.new(); l.text=t; l.position=pos; l.size=Vector2(w,100)
    l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",col)
    layer.add_child(l); return l

func show_menu():
    state="menu"; var u=clear_ui()
    add_label(u,"BADDIE RUNNER",Vector2(0,75),64,Color("#ffd84a"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"THREE FRIENDS • THREE WAYS TO RUN",Vector2(0,150),22,Color("#b9bed0"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"THE BADDIES ARE GIRLS — AND THEY ARE EVERYWHERE 😂",Vector2(0,192),20,Color("#ff91c8"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var y=265
    for i in 3:
        var b=button(u,("🔴 " if i==0 else "🔵 " if i==1 else "🟢 ")+names[i]+" — "+(["RUN FOR","RUN FROM","RUN BETWEEN"][i]),Vector2(110,y))
        b.pressed.connect(func(): select_char(i)); y+=125
    add_label(u,"Best scores:  R %d   L %d   A %d"%[best["RUDRA"],best["LAKSHYA"],best["ARSH"]],Vector2(0,675),22,Color("#9ea5ba"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var q=button(u,"HOW TO PLAY",Vector2(110,770),Vector2(240,70)); q.pressed.connect(show_help)
    var s=button(u,"SETTINGS",Vector2(370,770),Vector2(240,70)); s.pressed.connect(show_settings)
    add_label(u,"Cartoon chaos • original procedural art • original generated audio",Vector2(0,930),19,Color("#777e93"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"Android-ready prototype",Vector2(0,1160),20,Color("#5f6678"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func show_help():
    var u=clear_ui(); add_label(u,"HOW TO PLAY",Vector2(0,80),52,Color("#ffd84a"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"SWIPE ← →   CHANGE LANES\nSWIPE ↑     JUMP\nSWIPE ↓     SLIDE\nTAP         SPECIAL ABILITY\n\nCollect coins and power-ups.\nBuild combos by avoiding trouble.\nEvery character has a different objective.",Vector2(85,220),28,Color("#e9ebf2"),550)
    var b=button(u,"BACK",Vector2(110,870)); b.pressed.connect(show_menu)

func show_settings():
    var u=clear_ui(); add_label(u,"SETTINGS",Vector2(0,90),52,Color("#ffd84a"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"BADDIE RUNNER uses original procedural graphics and audio.\nBADDIES = GIRL NPCs. No monsters — just funny cartoon chaos!",Vector2(70,250),25,Color("#d8dbe5"),580)
    var b=button(u,"BACK",Vector2(110,700)); b.pressed.connect(show_menu)

func select_char(i):
    selected=i; mode=names[i]; state="select"; var u=clear_ui()
    add_label(u,mode,Vector2(0,80),58,colors[i],720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var desc=[
        "RUN FOR THE BADDIES.\nCatch the girls for big points.\nDodge their goofy tricks.",
        "RUN FROM THE BADDIES.\nThe girls are chasing you!\nJump, slide and survive.",
        "RUN BETWEEN THE BADDIES.\nGirls arrive from every lane.\nStay in the chaos and grab loot."
    ][i]
    add_label(u,desc,Vector2(90,190),30,Color("#eceef5"),540).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"SPECIAL: "+["BADDIE MAGNET","TURBO ESCAPE","DISGUISE CHAOS"][i],Vector2(0,440),24,Color("#ffd84a"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"Choose your map",Vector2(0,535),25,Color("#9da5bb"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    for m in 4:
        var b=button(u,map_names[m],Vector2(110+(m%2)*255,590+(m/2)*105),Vector2(245,78))
        b.pressed.connect(func(): start_game(m))

func start_game(m):
    map_id=m; state="play"; score=0; coins=0; gems=0; combo=0; speed=430; difficulty=1; lane=1
    py=FLOOR; vy=0; slide_t=0; ability_t=0; ability_ready=true; spawn_t=0; item_t=.5; baddie_t=.8
    objects=[]; particles=[]; time=0; toast=""; dialog=""; dialog_t=0
    clear_ui()
    say(["Rudra: Wait up! 😂","Lakshya: WHY ARE THEY CHASING ME?!","Arsh: Left, right—GIRLS EVERYWHERE! 😂"][selected])
    queue_redraw()

func _process(dt):
    if state!="play": queue_redraw(); return
    time+=dt; difficulty+=dt*.016; speed=min(900,430+difficulty*45); score+=int(dt*(8+difficulty*2))
    spawn_t-=dt; item_t-=dt; baddie_t-=dt
    slide_t=max(0,slide_t-dt); ability_t=max(0,ability_t-dt); toast_t=max(0,toast_t-dt); dialog_t=max(0,dialog_t-dt)
    if not ability_ready and ability_t<=0: ability_ready=true
    if mode=="RUDRA": update_rudra(dt)
    elif mode=="LAKSHYA": update_lakshya(dt)
    else: update_arsh(dt)
    update_objects(dt)
    update_particles(dt)
    queue_redraw()

func update_player(dt):
    vy+=1900*dt; py+=vy*dt
    if py>FLOOR: py=FLOOR; vy=0

func update_rudra(dt):
    update_player(dt)
    if spawn_t<=0: spawn_obstacle(); spawn_t=max(.45,1.0-difficulty*.02)
    if baddie_t<=0: spawn_baddie(); baddie_t=max(.42,1.0-difficulty*.018)
    if Input.is_action_just_pressed("jump") and py==FLOOR: vy=-800

func update_lakshya(dt):
    update_player(dt)
    if spawn_t<=0: spawn_obstacle(); spawn_t=max(.32,.82-difficulty*.018)
    if item_t<=0: spawn_item(); item_t=.65
    if Input.is_action_just_pressed("jump") and py==FLOOR: vy=-800
    if Input.is_action_just_pressed("slide"): slide_t=.5

func update_arsh(dt):
    if spawn_t<=0: spawn_obstacle(); spawn_t=max(.28,.72-difficulty*.015)
    if baddie_t<=0: spawn_baddie(); baddie_t=max(.3,.7-difficulty*.012)
    if item_t<=0: spawn_item(); item_t=.8

func spawn_obstacle():
    var l=rng.randi_range(0,2); objects.append({"t":"obs","x":LANES[l],"y":-90.0,"l":l,"s":rng.randi_range(65,105)})
func spawn_baddie():
    var l=rng.randi_range(0,2); objects.append({"t":"girl","x":LANES[l],"y":-100.0,"l":l,"s":82.0,"g":rng.randi_range(0,3)})
func spawn_item():
    var l=rng.randi_range(0,2); var t="coin" if rng.randf()<.78 else ("gem" if rng.randf()<.5 else "power")
    objects.append({"t":t,"x":LANES[l],"y":-70.0,"l":l,"s":45.0})

func update_objects(dt):
    var keep=[]
    for o in objects:
        var mult=1.0 if o.t!="girl" else 1.07
        o.y+=speed*dt*mult
        var hit=abs(o.x-LANES[lane])<90 and abs(o.y-py)<95
        if hit:
            if o.t=="coin": coins+=1; score+=60; combo+=1; burst(o.x,o.y,Color("#ffd84a")); continue
            if o.t=="gem": gems+=1; score+=180; combo+=1; burst(o.x,o.y,Color("#62eaff")); continue
            if o.t=="power": ability_ready=true; score+=120; say("POWER UP!"); continue
            if o.t=="girl":
                if mode=="RUDRA": score+=350+combo*10; combo+=1; say("GOTCHA! +350"); burst(o.x,o.y,Color("#ff5b62")); continue
                if mode=="ARSH": score+=180; combo+=1; say("CHAOS DODGED!"); continue
                end_game(); return
            if o.t=="obs":
                if mode=="LAKSHYA" and (py<FLOOR-120 or slide_t>0): combo+=1; score+=75; continue
                if mode=="ARSH" and ability_t>0: continue
                if mode=="RUDRA" and py<FLOOR-100: continue
                end_game(); return
        if o.y<H+120: keep.append(o)
    objects=keep

func _unhandled_input(e):
    if state!="play": return
    if e is InputEventScreenTouch:
        if e.pressed: touch=true; touch_start=e.position
        elif touch:
            touch=false; var d=e.position-touch_start
            if d.length()<45: use_ability()
            elif abs(d.x)>abs(d.y):
                if d.x<0: lane=max(0,lane-1)
                else: lane=min(2,lane+1)
            elif d.y<0 and py==FLOOR: vy=-800
            else: slide_t=.5
    if e is InputEventKey and e.pressed:
        if e.keycode==KEY_E: use_ability()
        if e.keycode==KEY_ESCAPE: pause_game()

func use_ability():
    if not ability_ready: return
    ability_ready=false; ability_t=1.8
    if mode=="RUDRA": say("BADDIE MAGNET!"); score+=150
    elif mode=="LAKSHYA": say("TURBO ESCAPE!"); score+=150
    else: say("DISGUISE CHAOS!"); score+=250
    burst(LANES[lane],py,colors[selected])

func say(t): dialog=t; dialog_t=2.2
func burst(x,y,c):
    for i in 16:
        particles.append({"p":Vector2(x,y),"v":Vector2(rng.randf_range(-180,180),rng.randf_range(-300,50)),"t":.7,"c":c})

func update_particles(dt):
    for i in range(particles.size()-1,-1,-1):
        particles[i].t-=dt; particles[i].p+=particles[i].v*dt; particles[i].v.y+=500*dt
        if particles[i].t<=0: particles.remove_at(i)

func pause_game():
    if state!="play": return
    state="pause"; var u=clear_ui(); add_label(u,"PAUSED",Vector2(0,250),60,Color("#ffd84a"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var b=button(u,"RESUME",Vector2(110,430)); b.pressed.connect(func(): state="play"; clear_ui())
    var m=button(u,"QUIT TO MENU",Vector2(110,540)); m.pressed.connect(show_menu)

func end_game():
    state="gameover"; best[mode]=max(best.get(mode,0),score); save_score()
    var u=clear_ui(); add_label(u,"RUN OVER",Vector2(0,190),64,Color("#ff626b"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_label(u,"%s\nSCORE  %d\nCOINS  %d   GEMS  %d\nBEST   %d"%[mode,score,coins,gems,best[mode]],Vector2(0,320),32,Color("#edf0f8"),720).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var r=button(u,"RUN AGAIN",Vector2(110,620)); r.pressed.connect(func(): start_game(map_id))
    var m=button(u,"CHARACTER SELECT",Vector2(110,730)); m.pressed.connect(func(): select_char(selected))

func _draw():
    draw_rect(Rect2(0,0,W,H),Color("#101322"))
    if state=="menu" or state=="select" or state=="pause" or state=="gameover": return
    draw_background()
    # road
    draw_rect(Rect2(0,FLOOR+35,W,H-FLOOR),Color("#171a25"))
    for x in LANES: draw_line(Vector2(x,FLOOR+10),Vector2(x,H),Color("#3b4050"),5)
    for o in objects: draw_obj(o)
    draw_player()
    for p in particles: draw_circle(p.p,6,p.c)
    if dialog_t>0: draw_rect(Rect2(40,185,640,70),Color(0.03,0.04,0.07,.85)); draw_string(font,Vector2(60,232),dialog,HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
    draw_string(font,Vector2(24,48),"%s  •  SCORE %06d  •  🪙 %d  💎 %d"%[mode,score,coins,gems],HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
    draw_string(font,Vector2(24,1080),"SWIPE  ← →  ↑  ↓     TAP = SPECIAL",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#c5cad9"))
    draw_string(font,Vector2(24,1150),"BADDIES: GIRL NPCs",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ff91c8"))

func draw_background():
    var sky=[Color("#201b3d"),Color("#172b4d"),Color("#4b244c"),Color("#ff9a52")][map_id]
    draw_rect(Rect2(0,0,W,H),sky)
    for i in 10:
        var x=fmod(i*150-time*35*(1+i%2),W+200)-100
        var h=180+(i%4)*75
        draw_rect(Rect2(x,FLOOR-h,90,h),Color(0.08,0.09,0.14,.85))
    # map landmarks
    if map_id==0:
        for i in 6:
            draw_circle(Vector2(90+i*125,280+(i%2)*35),28,Color("#ffd84a"))
    elif map_id==1:
        draw_line(Vector2(0,520),Vector2(W,520),Color("#aeb7ca"),8)
    elif map_id==2:
        for i in 8: draw_circle(Vector2(60+i*90,420+(i%3)*30),22,Color("#ff72ad"))
    else:
        draw_circle(Vector2(600,240),65,Color("#ffd36b"))

func draw_obj(o):
    var p=Vector2(o.x,o.y)
    if o.t=="coin":
        draw_circle(p,23,Color("#ffd84a")); draw_circle(p,12,Color("#fff1a2"))
    elif o.t=="gem":
        var pts=PackedVector2Array([p+Vector2(0,-28),p+Vector2(22,0),p+Vector2(0,28),p+Vector2(-22,0)])
        draw_colored_polygon(pts,Color("#62eaff"))
    elif o.t=="power":
        draw_circle(p,28,Color("#9b7cff")); draw_string(font,p+Vector2(-11,10),"★",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
    elif o.t=="obs":
        draw_rect(Rect2(p-Vector2(o.s/2,o.s/2),Vector2(o.s,o.s)),Color("#ff635f"))
        draw_string(font,p+Vector2(-12,10),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
    elif o.t=="girl":
        draw_girl(p,int(o.get("g",0)))

func draw_girl(p:Vector2, style:int):
    var c=girl_colors[style % girl_colors.size()]
    # Hair/back silhouette
    draw_circle(p+Vector2(0,-35),39,Color("#3a2634"))
    draw_rect(Rect2(p.x-36,p.y-35,72,62),Color("#3a2634"))
    # Face and hair bangs
    draw_circle(p+Vector2(0,-38),30,Color("#f2c39b"))
    draw_arc(p+Vector2(0,-45),31,PI,TAU,18,Color("#3a2634"),12)
    # Eyes
    draw_circle(p+Vector2(-11,-41),3,Color("#171722"))
    draw_circle(p+Vector2(11,-41),3,Color("#171722"))
    # Smile
    draw_arc(p+Vector2(0,-31),9,.15,2.95,12,Color("#8b3b57"),3)
    # Outfit
    draw_rect(Rect2(p.x-31,p.y-7,62,52),c)
    draw_circle(p+Vector2(-22,3),7,c)
    draw_circle(p+Vector2(22,3),7,c)
    # Legs / shoes
    draw_line(p+Vector2(-12,45),p+Vector2(-24,78),Color("#242634"),10)
    draw_line(p+Vector2(12,45),p+Vector2(24,78),Color("#242634"),10)
    draw_line(p+Vector2(-24,78),p+Vector2(-38,78),Color("#171722"),8)
    draw_line(p+Vector2(24,78),p+Vector2(38,78),Color("#171722"),8)

func draw_player():
    var x=LANES[lane]; var c=colors[selected]
    draw_circle(Vector2(x,py-78),31,Color("#f2c39b"))
    draw_rect(Rect2(x-31,py-47,62,72),c)
    draw_line(Vector2(x-12,py+25),Vector2(x-28,py+65),Color("#151722"),11)
    draw_line(Vector2(x+12,py+25),Vector2(x+28,py+65),Color("#151722"),11)
    draw_line(Vector2(x-28,py-25),Vector2(x-58,py+3),c,12)
    draw_line(Vector2(x+28,py-25),Vector2(x+58,py+3),c,12)
    if slide_t>0: draw_arc(Vector2(x,py),70,0,PI,20,Color.WHITE,7)
