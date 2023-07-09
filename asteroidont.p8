pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--asteroidon't

--by treveron

function _init()
	poke(0x5f2d,1)
	
	cur={
		x=64,
		y=64,
		bt=0,
		spt=1,
		tax=0,
		tay=0
	}
	h_score=0
	score=0
	btn_released=true
--	_upd=upd_title
--_drw=drw_title
	_upd=upd_over
	_drw=drw_over
end

function _update60()
	upd_cursor()
	_upd()
end

function start_game()
asteroids={}
	ships={}
	bullets={}
	shwaves={}
	sparks={}		

--possible power up variables
	ast_div=2
	maxdir_timer=30
	dir_timer=maxdir_timer
	ast_spd=1.5
	maxaspawn_t=600
	aspawn_t=0
	amp_r=0
	cmaxr=2
--ast_hp
		
	sposx=0
	sposy=0
	spw_sw=false
		
--debuffs for ships
	base_sspawn_t=180
	maxsspawn_t=180
	sspawn_t=0
	shoot_t=0
	shoot_tl=120
	bullet_sl=1
	bulspddiv=2
	
	power_ups={}
	pow_n=2
	pow_id={1,2,3,4,5,6}
	pow_txt={"faster asteroids",
		"slower bullets",
		"⬆️ asteroid spawn",
		"⬆️ direction time",
		"⬆️asteroid radius",
		"more options"
	}
	pow_spr={2,3,4,5,6,7}
		
	ast_spawn_loc={
		{x=-(8+amp_r),y=nil},
		{x=127+(8+amp_r),y=nil},
		{x=nil,y=-(8+amp_r)},
		{x=nil,y=127+(8+amp_r)}
	}
	lvl=1
	xp=0
	next_lvl=3
	score=0
	
	spawn_ast(10,10)
	spawn_ship(84,84)
	spawn_ship(44,44)
	
	_upd=upd_game
	_drw=drw_game
end

function upd_title()
	if(cur.bt==1 and btn_released)start_game()
end

function upd_game()
	upd_ast()
	ast_select()
	upd_ships()
	upd_shwaves()
	upd_sparks()
	upd_bullets()
	if(count_maxr()<cmaxr)spawn_timer()
	spawn_ship_timer()
	check_xp()
end

function upd_dir()
	dir_timer-=1
	stir(get_ast())
	if cur.bt!=1 or dir_timer<=0 then
		_upd=upd_game
		_drw=drw_game
	end
end

function upd_over()
	if cur.bt==1 and btn_released then
		btn_released=false
		_upd=upd_title
		_drw=drw_title
	end
end

function drw_game()
	drw_elements()
end

function drw_dir()
	drw_elements()
	line(cur.x,cur.y,cur.tax,cur.tay,7)
	show_timer(get_ast())
end

function drw_title()
	print("asteroh you better don't!",10,64,7)
end

function drw_over()
	print("game over...",20,64,7)	
	if score>h_score then
		print("new high score!",20,84,7)
	end
		print("score: "..score,20,94,7)	
end

function drw_elements()
	drw_ast()
	drw_ships()
	drw_shwaves()
	drw_sparks()
	drw_bullets()
	display_xp()
end

function _draw()
	cls()
	_drw()
	drw_cursor()
	--debug
--print(maxsspawn_t,111,111,7)
end

-->8
--cursor

function upd_cursor()
	cur.x=stat(32)
	cur.y=stat(33)
	cur.bt=stat(34)
	if(cur.bt==0)btn_released=true
	ast_clic()
end

function drw_cursor()
	spr(cur.spt, cur.x, cur.y)
end

function ast_select()
	for a in all(asteroids)do
		if dist(cur.x,cur.y,a.x,a.y)<a.r+amp_r then
			a.sel=true
		else
			a.sel=false
		end
	end 
end

function ast_clic()
	for a in all(asteroids)do
		if cur.bt==1 and a.sel and dir_timer==maxdir_timer then
			cur.tax,cur.tay=a.x,a.y
			_upd=upd_dir
			_drw=drw_dir
		elseif cur.bt==0 then
			dir_timer=maxdir_timer
		end
	end
end


-->8
--tools

function dist(p1x,p1y,p2x,p2y)
	return sqrt(((p1x-p2x)/10)^2+((p1y-p2y)/10)^2)*10
end

function checkastpos(o)
	if(o.x<-o.r+8)o.x=o.r+128
	if(o.x>o.r+128)o.x=-o.r+8
	if(o.y<-o.r)o.y=o.r+128
	if(o.y>o.r+128)o.y=-o.r
end



-->8
--asteroids

function spawn_ast(_x,_y,_r)
	if(not _r)_r=8
	local a={
		x=_x,
		y=_y,
		r=_r
	}
	stir(a,rnd())
	add(asteroids,a)
end

function upd_ast()
	for a in all(asteroids) do
		a.x+=a.dx
		a.y+=a.dy
		checkastpos(a)
	end
end

function drw_ast()
	for a in all(asteroids) do
		circfill(a.x,a.y,a.r+amp_r,7)
		circ(a.x,a.y,a.r+1+amp_r,0)
		if(a.sel)circ(a.x,a.y,a.r+2+amp_r,7)
	end
end

function get_ast()
	for a in all(asteroids) do
		if(a.sel)return a
	end
	return false
end

function stir(ast,ang)
	if(not ang)ang=atan2(cur.y-ast.y,cur.x-ast.x)
	ast.dx=sin(ang)/4*ast_spd
	ast.dy=cos(ang)/4*ast_spd
end

function dmg_ast(ast)
	if ast.r==8 then
		for i=1,ast_div do
			spawn_ast(ast.x,ast.y,4)
		end
	elseif ast.r==4 then
		for i=1,ast_div do
			spawn_ast(ast.x,ast.y,2)
		end	
	end
	explode(ast)
	del(asteroids,ast)
	checkend()
end

function show_timer(ast)
	local r=ast.r
	local x,y=ast.x-r,ast.y-r
	if(ast.x<64)x+=r*2
	if(ast.y<64)y+=r*2
	local bar=flr(dir_timer*5/maxdir_timer)
	rectfill(x-2,y-2,x+3,y+6,0)
	rectfill(x-1,y+5-bar,x+2,y+5,7)
	rect(x-1,y-1,x+2,y+5,7)
end

function spawn_timer()
	aspawn_t+=1
	if aspawn_t>=maxaspawn_t then		
		local pos=rnd(ast_spawn_loc)
		if (pos.x==nil)	pos.x=flr(rnd(119)+8)	
		if (pos.y==nil)	pos.y=flr(rnd(127))	
		aspawn_t=0
		spawn_ast(pos.x,pos.y)
	end
end

function count_maxr()
	local c=0
	for a in all(asteroids)do
		if (a.r==8)c+=1
	end
	return c
end
-->8
-- ships

function spawn_ship(_x,_y)
	local sh={
		x=_x,
		y=_y,
		r=4,
		rot=0,
		px={0,0,0,0},
		py={0,0,0,0},
		pang={0,.4,.5,-.4},
		poff={0,0,1,0},
		typ=1,
		hp=1,
		flash=0,
		points=100,
		xp=1
	}
	add(ships,sh)
end

function spawn_ship2(_x,_y)
	local sh={
		x=_x,
		y=_y,
		r=4,
		rot=0,
		px={0,0,0,0,0,0,0,0},
		py={0,0,0,0,0,0,0,0},
		pang={0,.25,.25,.375,.5,.655,.75,.75},
		poff={0,-1,1.5,0,3,0,1.5,-1},
		typ=2,
		hp=2,
		flash=0,
		xp=3,
		points=300
	}
	add(ships,sh)
end

function spawn_ship_timer()
	sspawn_t+=1
	if sspawn_t>=maxsspawn_t-20 and not spw_sw then
		spw_sw=true
		sposx,sposy=rnd(120)+16,rnd(120)+7
		local overlap=false
		for s in all(ships)do
			overlap=check_overlap(s.x,s.y,s.r,sposx,sposy,4)
		end
		while overlap do
			sposx,sposy=rnd(120)+16,rnd(120)+7
			for s in all(ships)do
				overlap=check_overlap(s.x,s.y,s.r,sposx,sposy,4)
			end
		end
		add_shwave(sposx,sposy,15,0)
	elseif sspawn_t>=maxsspawn_t then		
		sspawn_t=0
		if lvl<=5 then
			spawn_ship(sposx,sposy)
		elseif lvl<=10 then
			local n=rnd()
			if n>.5 then
				spawn_ship(sposx,sposy)
			else
				spawn_ship2(sposx,sposy)
			end
		elseif lvl>10 then
			spawn_ship2(sposx,sposy)
		end
		spw_sw=false
	end
end

function upd_ships()
	shoot_t+=1
	for s in all(ships)do
		if(s.flash>0)s.flash-=1
		if(#asteroids>0)s.rot=aim(s)
		if(shoot_t==shoot_tl-5)then
			add_shwave(s.px[1],s.py[1],5,0)
		elseif shoot_t==shoot_tl then
			if s.typ==1 then
				shoot(s)
			else
				shoot3(s)
			end
		end
		for i=1,#s.pang do
			s.px[i]=sin(s.rot+s.pang[i])*(s.r-s.poff[i])+s.x
			s.py[i]=cos(s.rot+s.pang[i])*(s.r-s.poff[i])+s.y
			local ast=ship_col(s.px[i],s.py[i])
			if ast and s.flash==0 then 
				s.hp-=1
				if s.hp<=0 then
					explode(s)
					xp+=s.xp
					score+=s.points
				else
					s.flash+=60
					dmg_ast(ast)
				end
			end
		end
	end
	if (shoot_t==shoot_tl)shoot_t=0
end

function drw_ships()
	for s in all(ships)do
		if s.flash==0 or (s.flash>0 and sin(time()*8)>0) then
   for i=1,#s.pang do
				local off=1
				if(i==#s.pang)off=(#s.pang-1)*-1
				line(s.px[i],s.py[i],s.px[i+off],s.py[i+off],7)
			end
  end
	end
end

function aim(s)
	local sx,sy,d,ast=s.x,s.y,999,nil
	for a in all(asteroids) do
		local d2=dist(sx,sy,a.x,a.y)
		if d2<d then 
			d=d2
			ast=a
		end
	end
	return .5+atan2((sy-ast.y),(sx-ast.x))
end

function ship_col(x,y)
	for a in all(asteroids) do
		if(dist(x,y,a.x,a.y)<a.r+amp_r)return a
	end
	return false
end

function explode(s)
	add_shwave(s.x,s.y,0,20)
	add_sparks(s.x,s.y,40)
	del(ships,s)
end

function shoot(s)
	local b={
		x=s.px[1],
		y=s.py[1],
		dx=(-sin(s.rot*-1)*s.r+s.x*.005)/bulspddiv,
		dy=(cos(s.rot*-1)*s.r+s.y*.005)/bulspddiv,
		r=1
	}
	add(bullets,b)
end

function shoot3(s)
	local offset=-.05
	for i=1,3 do
		local b={
			x=s.px[1],
			y=s.py[1],
			dx=(-sin(s.rot*-1+offset)*s.r+s.x*.005)/bulspddiv,
			dy=(cos(s.rot*-1+offset)*s.r+s.y*.005)/bulspddiv,
			r=1
		}
		add(bullets,b)
		offset+=.05
	end
end

function upd_bullets()
	for b in all(bullets)do
		b.x+=b.dx
		b.y+=b.dy 
		if b.x>127
		or b.x<8
		or b.y>127
		or b.y<0 then
			del(bullets,b)
		end
		check_bull(b)
	end
end

function drw_bullets()
	for b in all(bullets)do
		circfill(b.x,b.y,b.r,7)
	end
end

function check_bull(b)
	for a in all(asteroids)do
		if dist(b.x,b.y,a.x,a.y)<a.r then
			dmg_ast(a)
			del(bullets,b)
		end
	end
end

function check_overlap(x1,y1,r1,x2,y2,r2)
	return dist(x1,y1,x2,y2)<r2+r1+4
end
-->8
--particles

function add_shwave(_x,_y,_r,_tr)
	local sh={
		x=_x,
		y=_y,
		r=_r,
		tr=_tr,
		col=7
	}
	add(shwaves,sh)	
end

function upd_shwaves()
	for s in all(shwaves) do
		if s.tr>s.r then
			s.r+=.5
		else
			s.r-=.5
		end
		if(s.r==s.tr)then
			del(shwaves,s)			
		end
	end
end

function drw_shwaves()
	for s in all(shwaves)do
		circ(s.x,s.y,s.r,s.col)
	end
end

function add_sparks(_x,_y,n)
	for i=1,n do
		local s={
			x=_x,
			y=_y,
			dx=(rnd()-.5)*4,
			dy=(rnd()-.5)*4,
			age=rnd()*5+20
		}
		add(sparks,s)
	end
end

function upd_sparks()
	for s in all(sparks)do
		s.x+=s.dx
		s.y+=s.dy
		s.age-=1
		if(s.age<=0)del(sparks,s)
	end
end

function drw_sparks()
	for s in all(sparks)do
		pset(s.x,s.y,7)
	end
end

-->8
--ui

function display_xp()
	rectfill(0,0,8,127,0)
	print("xp",1,1,7)
	rect(1,8,6,126,7)
	local bar = xp/next_lvl*118
	rectfill(1,126-bar,6,126,7)
end
-->8
--gameplay

function check_xp()
	if xp>=next_lvl then
		lvl+=1
		xp=next_lvl-xp
		next_lvl*=1.5
		load_pows()
		_upd=upd_lvl
		_drw=drw_lvl
		maxsspawn_t*=.9
	end
end

function upd_lvl()
	cursor_pow()
	if cur.bt==1 and get_selpow() then
		_upd=upd_game
		_drw=drw_game
		level_up(get_selpow().id)
		power_ups={}
	elseif cur.bt==1 then
	--sfx duduh
	end
end

function drw_lvl()
	drw_elements()
	local windx,windy,windx2,windy2=35,30,115,35+pow_n*10+10
	rect(windx-1,windy-1,windx2+1,windy2+1,7)
	rectfill(windx,windy,windx2,windy2,0)
	print("level "..lvl.."!",windx+2,windy+2,7)
	for i=1,pow_n do
		local _x,_y=2+windx,windy+12*i
		local col=7
		if(power_ups[i].sel)col=10
		rect(_x-1,_y-1,_x+8,_y+8,col)
		spr(power_ups[i].spt,_x,_y)
		print(power_ups[i].txt,_x+10,_y+2,col)		
		power_ups[i].x,power_ups[i].y=_x,_y
	end
end

function load_pows()
	for i=1,pow_n do
		local n=flr(rnd(6))+1
		while pow_n==4 and n==6 do
			n=flr(rnd(6))+1
		end
		local p={
			id=pow_id[n],
			txt=pow_txt[n],
			spt=pow_spr[n],
			sel=false,
			x=0,
			y=0
		}
		add(power_ups,p)
	end
end

function cursor_pow()
	for p in all(power_ups)do
		if cur.x<p.x
		or cur.x>p.x+100 
		or cur.y<p.y
		or cur.y>p.y+7 then
			p.sel=false
		else
			p.sel=true
		end
	end
end

function get_selpow()
	for p in all(power_ups) do
		if(p.sel)return p
	end
	return false
end

function level_up(id)
	if id==1 then
		ast_spd*=1.1
		debug=ast_spd
	elseif id==2 then
		bulspddiv*=1.1
		debug=bulspddiv
	elseif id==3 then
		maxaspawn_t*=.9
		debug=maxaspawn_t
	elseif id==4 then
		maxdir_timer*=1.1
		debug=maxdir_timer
	elseif id==5 then
		amp_r+=.5
		debug=amp_r
	elseif id==6 then
		pow_n+=1
		debug=pow_n
	end
end

function checkend()
	if #asteroids==0 then
		if(not cur.bt==0)btn_released=false
		_upd=upd_over
		_drw=drw_over
	end
end

__gfx__
00000000666660000550000000055000600000066666666600666600666000000000666666660000000066666666000000000000000000000000000000000000
00000000666600005005000000055000007777000666666006555560666066600666000000006660066600000000666000000000000000000000000000000000
00700700666600005006600000000000070000700065560065555556666000006000000000000006600000000000000600000000000000000000000000000000
00077000666660000560060000066000070000700006600065555556000000006606060606060606606060606060606600000000000000000000000000000000
00077000600666000060077000066000070000700006600065555556666066606000000000000006600000000000000600000000000000000000000000000000
00700700000066000006700700600600070000700065560065555556666066606000000000000006600000000000000600000000000000000000000000000000
00000000000000000000700700600600007777000655556006555560666066600666000000006660066600000000666000000000000000000000000000000000
00000000000000000000077006000060600000066555555600666600000000000000666666660000000066666666000000000000000000000000000000000000
00000000000000000066660000077000050005000000000000000000000000000000600000060000000000066000000000000000000000000000000000000000
00000000000000000660066000700700000500050000000000000000000000000006000000006000000000066000000000000000000000000000000000000000
00000000000000006660066600700700050005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006000000600077000000500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006000000607700770050005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006660066670077007000500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000660066070077007050005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066660007700770000500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
