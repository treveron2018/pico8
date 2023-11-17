pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--asteroidoesn't

--by treveron

--todo

function _init()	
	p={
		x=64,
		y=64,
		dx=0,
		dy=0,
		r=5,
		px={0,0,0,0,0,0},
		py={0,0,0,0,0,0},
		pang={0,.38,.5,-.38,.5,0},
		poff={0,0,-4,0,1,10},
		rot=1,
		rotspd=.02,
		hp=3,
		acc=.05,
		spd=0,
		frc=.01,
		vmax=1.5,
		vmin=-1.5,
		bull_lim=3,
		isdead=false,
		rsp=150,
		rspt=0,
		rspx=64,
		rspy=64
	}
	scan={
		x=0,
		y=0,
		r=12,
		px={0,0,0},
		py={0,0,0},
		pang={0,.4,-.4}
	}
	scanning=false
	s_timer=0
	s_target=nil
	loading=false
	bullets={}
	propeller={}
	bullets={}
	particles={}
	shwaves={}
	msg_wind={
		x=0,
		ox=0, 
		y=97,
		oy=0, 
		w=128, 
		h=30,
		txt=nil,
		on=false,
		t=0,
		closing=false
	}	
	doors={}
	d_x={4,0}
	d_y={0,-4}
	d_w={1,2}
	d_h={2,1}
	d_o1={4,8}
	d_o2={8,4}
	comps={}
	t=0
	upd=upd_game
	drw=drw_game
	dirx={-1,1,0,0}
	diry={0,0,-1,1}
	
	cx=0
	cy=0
	tcx=0
	tcy=0
	
	enemies={}
	
end

function _update60()
	t+=1
	upd()
end

function _draw()
	cls()
	drw()
end

function upd_game()
	camera_cntrl()
	if(not p.isdead) then
		upd_shp()
		upd_scan()
		move_shp()
	else
		respawn()
	end
	upd_prop()
	upd_bul()
	upd_part()
	upd_shw()
	spawn_map_elements()
	upd_doors()
	if scanning then 
		checkscan()
	else 
		s_timer=0
		s_target=nil
	end
	upd_enemies()
end

function drw_game()
	map()
	if not p.isdead then
		drw_shp()
		drw_scan()
	end
	drw_prop()
	drw_bul()
	drw_part()
	drw_shw()
	drw_doors()
	drw_comps()
	drw_msg()
	if(loading)scan_load()
	drw_enemies()
	--debug
	--outline(tcy,p.x-10,p.y-10, 10)

end
-->8
--ship

function upd_shp()	
	p=upd_trig(p)
	for i=1,6 do
		local e=check_enemies({x=p.px[i],y=p.py[i]})
		if i!=6 and (check_walls(p.px[i],p.py[i]) or e) and not p.isdead then
			p.isdead=true
			scanning=false
			explode(p)
		end		
	end
	p.x+=p.dx
	p.y+=p.dy
end

function drw_shp()
	drw_poly(p,4)
end

function upd_scan()
	scan.x,scan.y=p.px[6],p.py[6]
	for i=1,3 do
		scan.px[i]=sin(p.rot+scan.pang[i]+.5)*(scan.r)+scan.x
		scan.py[i]=cos(p.rot+scan.pang[i]+.5)*(scan.r)+scan.y
	end
end

function drw_scan()
	if scanning then
		for i=1,3 do
			local o=1
			if(i==3)o=-2
			if(i!=2 and sin(time()*8)>0)line(scan.px[i],scan.py[i],scan.px[i+o],scan.py[i+o],7)
		end
	end
end

function move_shp()
	if(btn(⬅️))p.rot-=p.rotspd
	if(btn(➡️))p.rot+=p.rotspd
	if(p.rot>1)p.rot=-1
	if btn(⬆️) then
		thrust()
		propel()
	end
	if(btnp(❎))shoot()
	if btn(🅾️) then
		scanning=true
	else
		scanning=false
		loading=false
	end

	if(p.dx>0)p.dx-=p.frc
	if(p.dx<0)p.dx+=p.frc
	if(p.dy>0)p.dy-=p.frc
	if(p.dy<0)p.dy+=p.frc
	
	--check_pos(p)
end

function check_pos(c)
	if(c.x<0)c.x=128
	if(c.x>128)c.x=0
	if(c.y<0)c.y=128
	if(c.y>128)c.y=0
end

function thrust()
	p.dx+=-sin(p.rot*-1)*p.acc	
	p.dx=min(p.dx,1.5)
	p.dx=max(p.dx,-1.5)
	p.dy+=cos(p.rot*-1)*p.acc
	p.dy=min(p.dy,1.5)
	p.dy=max(p.dy,-1.5)
end

function propel()
	if t%4==0 then
		local c={
		x=p.px[5],
		y=p.py[5],
		r=2,
		age=10}
		add(propeller,c)
	end
end

function upd_prop()
	for c in all(propeller) do
		c.age-=1
		if c.age<=0 then
			c.r-=.25
			if(c.r<=0)del(propeller,c)
		end
	end
end

function drw_prop()
	for c in all(propeller) do
		circ(c.x,c.y,c.r,7)
	end
end

function shoot()
	if #bullets<p.bull_lim then
		local b={
			x=p.px[1],
			y=p.py[1],
			dx=-sin(p.rot*-1)*p.r+p.x*.005,
			dy=cos(p.rot*-1)*p.r+p.y*.005,
			r=1,
			age=15,
			att=1
		}
		add(bullets,b)
	end
end

function upd_bul()
	for b in all(bullets) do
		b.age-=1
		if(b.age==0)del(bullets,b)
		b.x+=b.dx
		b.y+=b.dy
	--	check_pos(b)
		if check_walls(b.x,b.y) then
			sparks(b,5)
			del(bullets,b)
		end
		local e=check_enemies(b)
		if e then 
			hit(b,e)
			del(bullets,b)
		end 
	end
end

function drw_bul()
	for b in all(bullets) do
		circfill(b.x,b.y,b.r,7)
	end
end

function respawn()
	p.rspt+=1
	if p.rspt==p.rsp-30 then
		p.x,p.y=p.rspx,p.rspy
		upd_shp()
		add_shwave(p,20,0)
	end
	if p.rspt>=p.rsp then
		p.isdead,p.rspt,p.dx,p.dy=false,0,0,0
	end
end

function checkscan()
	local c1={
		x=scan.x, 
		y=scan.y,
		r=scan.r/1.75
	}
	for i=1,#comps do
		local c=comps[i]
		local c2={
			x=c.x+4, 
			y=c.y+4,
			r=4
		}
		if(circxcirc(c1,c2)) then
			s_timer+=1
			s_target={c}
			loading=true
			if s_timer>=60 then
				msg_wind.txt=c2.x.." "..c2.y.." "..c2.r			
				msg_wind.on=true
				upd=upd_msg
				s_timer=0
				s_target=nil
				loading=false
			end
			return
		else
			loading=false 
			if i==#comps then
				s_timer=0
				s_target=nil
			end
		end 
	end
end

function scan_load()
	local px,py,t = p.x, p.y,s_timer*8/60
	rectfill(px-11, py-11, px-6, py-1,0)
	rect(px-10, py-10, px-7,py-2,7)
	rectfill(px-9,py-2-t, px-8,py-2,7)
end
-->8
--tools

function check_walls(x,y)
	if (fget(mget(x/8,y/8),0))return true
	return false
end

function dist(p1,p2)
	return sqrt(((p1.x-p2.x)/10)^2+((p1.y-p2.y)/10)^2)*10
end

function camera_cntrl()
	if p.x>cx+127 then
		tcx=cx
		cx+=128
	elseif p.x<cx then
		tcx=cx
		cx-=128
	end
	if p.y>cy+127 then
		tcy=cy
		cy+=128
	elseif p.y<cy then
		tcy=cy
		cy-=128
	end
	
	if(tcx>cx)tcx-=4
	if(tcx<cx)tcx+=4
	if(tcy>cy)tcy-=4
	if(tcy<cy)tcy+=4
	
	camera(tcx,tcy)	
	upd_wind(cx,cy)
end

function circxcirc(c1,c2)
	if (dist(c1,c2)<c1.r+c2.r)then
		return true
	end
	return false
end

function upd_trig(o)
	for i=1,#o.px do
		o.px[i]=sin(o.rot+o.pang[i])*(o.r+o.poff[i])+o.x
		o.py[i]=cos(o.rot+o.pang[i])*(o.r+o.poff[i])+o.y
	end
	return o
end

function drw_poly(o,ps)
	for i=1,ps do
		local off=1
		if(i==ps)off=-(ps-1)
		line(o.px[i],o.py[i],o.px[i+off],o.py[i+off],7)
	end
end

function explode(o)
	sparks(o,50)
	add_shwave(o,0,20)
end

function hit(d,r)
	r.hp-=d.att
	sparks(r,5)
	add_shwave(r,0,5)
end
-->8
--map

function spawn_map_elements()
	for x=0, 31 do
		for y=0, 31 do
			local tle=mget(x,y)
			if tle>1 then
				if tle==2 then
					add_door(x,y,6,1,2,4,8)
				elseif tle==3 then
					add_door(x,y,4,2,1,8,4)
				elseif tle==7 then
					add_comp(x*8,y*8)
				elseif tle==8 then
					add_enemy(x*8,y*8,1,0)
				elseif tle==9 then
					add_enemy(x*8,y*8,0,1)	
				end
			mset(x,y,0)
			end	
		end
	end
end

function add_door(_x,_y,_spr,_w,_h,_o1,_o2)
	local d={
		x=_x*8,
		y=_y*8,
		w=_w,
		h=_h,
		spt=_spr,
		o=0,
		closed=true,
		opening=false,
		closing=false
	}
	d.sensor={
		x=d.x+_o1,
		y=d.y+_o2,
		r=30
	}
	add(doors,d)
end

function upd_doors()
	for d in all(doors) do
		local isnear=false
		for i=1,4 do
			local p={x=p.px[i],y=p.py[i]}
			if(dist(p, d.sensor)<d.sensor.r) isnear=true
		end
		if isnear then
			if d.closed 
			and not d.opening 
			and not d.closing then
				d.opening=true
			end
		else 
			if not d.closed  
			and not d.closing then
				d.closing=true
		end
	end		
	if d.opening then
		if d.h>d.w then
			d.y-=1
		else
			d.x-=1
		end
		d.o+=1
		if d.o==16 then
			d.opening=false
			d.closed=false
			d.o=0
		end
	elseif d.closing then
		if d.h>d.w then
			d.y+=1
			else
				d.x+=1
			end		
			d.o+=1
			if d.o==16 then
				d.closing=false
				d.closed=true
				d.o=0
			end
		end
	end
end

function drw_doors()
	for d in all(doors) do
		spr(d.spt,d.x,d.y,d.w,d.h)
	end
end

function add_comp(_x,_y)
	local c={
		x=_x,
		y=_y
	}
	add(comps,c)
end

function drw_comps()
	for c in all(comps) do
		spr(7,c.x,c.y)
	end
end
-->8
--ui

function outline(txt,x,y)
	for i=1,#dirx do
		palt(0,false)
		print(txt,x+dirx[i],y+diry[i],0)
		palt()
	end
	print(txt,x,y,7)
end

function upd_msg()
	if btnp(❎)and not msg_wind.closing then
		msg_wind.closing=true 
	end
	if msg_wind.closing	then
		msg_wind.oy+=1
		if msg_wind.oy==msg_wind.h then	
			upd=upd_game
			msg_wind.on=false
			msg_wind.closing=false
			msg_wind.oy=0
		end
	end
end

function drw_msg()--28 char/line
	local x,y,w,h,oy=msg_wind.x,msg_wind.y,msg_wind.w,msg_wind.h,msg_wind.oy
	if msg_wind.on then
		rectfill(x,y,x+w-1,max(y+h-1-oy,y),0)
		rect(x+2,y+2,x+w-3,max(y+h-3-oy,y+2),7)
		if oy==0 then
			outline(msg_wind.txt,x+8,y+8)
			outline("❎",x+w-12,y+h-7-sin(t/30))
		end
	end
end


function upd_wind(cx,cy)
	msg_wind.x=cx
	msg_wind.y=cy+97
end

-->8
--enemies

function add_enemy(_x,_y,_dx,_dy)
	local e={
		x=_x,
		y=_y,
		r=4,
		px={0,0,0,0},
		py={0,0,0,0},
		pang={0,.25,.5,.75},
		poff={0,0,0,0},
		rot=0,
		hp=2,
		p=_p,
		dx=_dx,
		dy=_dy
	}
	
	add(enemies,e)
end

function upd_enemies()
	for e in all(enemies) do
		if e.hp<=0 then
			explode(e)
			del(enemies,e)
		end
		e.rot+=.01
		if(e.rot>=1)e.rot=0
		e=upd_trig(e)
		if check_walls(e.x,e.y) then
			e.dx*=-1
			e.dy*=-1
		end
		e.x+=e.dx
		e.y+=e.dy
	end
end

function drw_enemies()
	for e in all(enemies) do
		drw_poly(e,4)	
	end	
end

function check_enemies(o)
	for e in all(enemies) do
		if(dist(o,e)<e.r)return e
	end
	return false
end
-->8
--particles

function sparks(o,n)
	for i=1,n do
		local p={
			x=o.x,
			y=o.y,
			dx=rnd(2)-1,
			dy=rnd(2)-1,
			age=20+flr(rnd(10)),
			col=7
		}
		add(particles,p)
	end
end

function upd_part()

	for p in all(particles) do
		p.x+=p.dx
		p.y+=p.dy
		p.age-=1
		if p.age<=0 then
			p.dx-=.5
			p.dy-=.5
			if(p.dx<=0 and p.dy<=0)del(particles,p)
		end
	end
end

function drw_part()
	for p in all(particles) do
		pset(p.x,p.y,p.col)
	end
end

function add_shwave(o,_r,_tr)
		local s={
			x=o.x,
			y=o.y,
			r=_r,
			tr=_tr,
			col=7
		}
		add(shwaves,s)
end

function upd_shw()
	for s in all(shwaves) do
		local x=1
		if(s.tr==0)x*=-1
		s.r+=.5*x
		if(s.r==s.tr)del(shwaves,s)
	end
end

function drw_shw()
	for s in all(shwaves) do
		circ(s.x,s.y,s.r,7)
	end
end
__gfx__
00000000777777779555555995555559077777777777777000000000077777700006600000066000000000000000000000000000000000000000000000000000
00000000777777779555555995555559077777777777777077777777077070700060060000666600000000000000000000000000000000000000000000000000
00700700777777775955559595555559077777777777777077777777070707700600006006066060000000000000000000000000000000000000000000000000
00077000777777775955559595555559077777777777777077777777077070706666666660066006000000000000000000000000000000000000000000000000
00077000777777775595595599999999077777777777777077777777070707706666666660066006000000000000000000000000000000000000000000000000
00700700777777775595595595555559077777777777777077777777777777770600006006066060000000000000000000000000000000000000000000000000
00000000777777775559955595555559077777777777777077777777700000070060060000666600000000000000000000000000000000000000000000000000
00000000777777775559955595555559077777777777777077777777777777770006600000066000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010000010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000
__gff__
0003000001010105000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000009000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000202000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000800000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000070101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103000101010101010101010101010101030001010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103000101010101010101010101010101030001010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000800000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000008000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000080000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000800000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107000000000000000000000000000101000000000000000700000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010100000101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
