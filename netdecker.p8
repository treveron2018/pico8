pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--netdecker

--by treveron

function _init()
	t=0
	dirx={-8,8,0,0,8,8,-8,-8}
	diry={0,0,-8,8,-8,8,8,-8}
	mob_ani={48,64}
	mob_att={1,1}
	mob_hp={5,2}
	wind={}
	dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}
	buttbuff=-1
	talkwind=nil
	start_game()
end

function _update60()
	t+=1
	_upd()
end

function _draw()
	cls()
	_drw()
	drawind()
	checkfade()
end

function start_game()
	fadeperc=1
	mob={}
	dmob={}
	float={}
	p=add_mob(1,8,96)
	--test mob
	for x=0,15 do
		for y=0, 15 do
			if mget(x,y)==19 then
				add_mob(2,x*8,y*8)
			end
		end
	end
	_upd=update_game
	_drw=draw_game
end

function update_game()
	if talkwind then
		if getbutt()==5 then
			talkwind.dur=0
			talkwind=nil
		end
	else
		if(buttbuff==-1)buttbuff=getbutt()
		dobutt(buttbuff)
	end
	upd_float()
end

function update_over()
--	if btnp(4) then
--		debug="works"
--	end
end

function draw_over()
	cls(2)
	if btnp(4) or btnp(5) then
		fadeout()
		start_game()	
	end
	print("u ded",50,50,7)
end

function draw_game()
	map()
	draw_mob()
	drw_float()
	--oprint8(mob[2].t,0,0,8)
end
-->8
--player functions

function move_player(d)
	local dx,dy=dirx[d+1],diry[d+1]
	local destx,desty=(p.x+dx)/8,(p.y+dy)/8
	local tle=mget(destx,desty)
	if not iswalkable(destx,desty,tle,"checkmobs") then
		mobbump(p,dx,dy)
		local m=getmob(destx*8,desty*8)
		if not m then
			if(fget(tle,1))trig_bump(tle,destx,desty)
		else
			hitmob(p,m)
		end
	else
		mobwalk(p,dx,dy)
	end
	_upd=update_pturn
end

-->8
--tools

function get_frame(ani)
	return flr(t/8)%#ani+1
end

function draw_spr(_spr,_x,_y,_c,_flip)
	palt(0,false)
	pal(6,_c)
	spr(_spr,_x,_y,1,1,_flip)
	pal()
	palt()
end

function getbutt()
	for i=0,5 do
		if(btnp(i))return i
	end
	return -1
end

function dobutt(butt)
	if(butt<0)return
	if butt<4 then
		move_player(butt)
	end
	buttbuff=-1
end

function oprint8(t,x,y,c,c2)
	for i=1,8 do
		print(t,x+dirx[i]/8,y+diry[i]/8,c2)
	end
	print(t,x,y,c)
end

function dist(fx,fy,tx,ty)
	return sqrt((fx-tx)^2+(fy-ty)^2)
end

function fadein()
	local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
	for j=1,15 do
		col=j
		kmax=flr(p+(j*1.46))/22
		for k=1, kmax do
			col=dpal[col]
		end
		pal(j,col,1)
	end
end

function fadeout(spd,_wait)
	if(not spd)spd=.04
	if(not _wait)_wait=0
	repeat
		fadeperc=min(fadeperc+spd,1)
		fadein()
		flip()
	until fadeperc==1
	wait(_wait)
end

function checkfade()
	if fadeperc>0 then
		fadeperc=max(fadeperc-.04,0)
		fadein()
	end
end

function wait(_wait)
	repeat
		_wait-=1
		flip()
	until _wait<0
end
-->8
--ui

function addwind(_x,_y,_w,_h,_txt,_dur)
	local w={
	x=_x,
	y=_y,
	w=_w,
	h=_h,
	txt=_txt,
	dur=_dur}
	add(wind,w)
	return w
end

function rectfill2(_x,_y,_w,_h,_c)
	rectfill(_x,_y,max(_x+_w-1,0),max(_y+_h-1,0),_c)
end

function drawind()
	for w in all(wind) do
		local wx,wy,ww,wh=w.x,w.y,w.w,w.h
		rectfill2(wx,wy,ww,wh+6,0)
		rect(wx+1,wy+1,wx+ww-2,wy+wh+4,7)
		wx+=4
		wy+=4
		clip(wx,wy,ww,wh)
		for i=1,#w.txt do
			local txt=w.txt[i]
			print(txt,wx,wy,6)
			wy+=7
		end
		clip()
		if w.dur then
			w.dur-=1
			if w.dur<=0 then 
				local diff=wh/8
				w.h-=diff
				if(w.h<3)del(wind,w)
			end
		else
			if w.butt then
				oprint8("❎",wx+ww-15,w.y+wh+2+sin(time()),7,0)
			end
		end
	end
end

function show_msg(txt,dur)
	local wid=(#txt+2)*4+7
	local w=addwind(63-wid/2,50,wid,7,{" "..txt},dur)
end

function show_lmsg(txt)
	talkwind=addwind(16,50,94,#txt*7,txt)
	talkwind.butt=true
end

function addfloat(_x,_y,_txt,_c)
	local f={
		x=_x,
		y=_y,
		txt=_txt,
		c=_c,
		ty=_y-10,
		t=0
	}
	add(float,f)
end

function upd_float()
	for f in all(float) do
		f.y+=(f.ty-f.y)/10
		f.t+=1
		if(f.t>=10)del(float, f)
	end
end

function drw_float()
	for f in all(float) do
		oprint8(f.txt, f.x, f.y, f.c, 0)
	end 
end
-->8
--mob

function add_mob(typ,mx,my)
	local m={
		x=mx,
		y=my,
		att=mob_att[typ],
		hp=mob_hp[typ],
		maxhp=mob_hp[typ],
		ox=0,
		oy=0,
		sox=0,
		soy=0,
		_flip=false,
		mov=nil,
		t=0,
		flash=0,
		ani={}
	}
	for i=0,5 do
		add(m.ani,mob_ani[typ]+i)
	end
	add(mob,m)
	return m
end

function draw_mob()
	for m in all(mob) do
		drawmob(m)
	end	
	for m in all(dmob) do
		m.dur-=1
		if(m.dur<0)del(dmob,m)
		if(sin(time()*8)>0)drawmob(m)
	end
end

function drawmob(m)
	local col=10
	if m.flash>0 then
		m.flash-=1
		col=7
	end
	draw_spr(m.ani[get_frame(m.ani)],m.x+m.ox,m.y+m.oy,col,m._flip)
end

function getmob(x,y)
	for m in all(mob) do
		if(m.x==x and m.y==y)return m
	end
	return false
end

function inbounds(x,y)
	return not (x<0 or y<0 or x>15 or y>15)
end

function iswalkable(x,y,tle,mode)
	if(mode==nil)mode=""
	if inbounds(x,y) then
		if not fget(tle,0) then
			if mode=="checkmobs" then
				return getmob(x*8,y*8)==false
			end
		end
		return false
	end
	return false
end

function mobwalk(m,dx,dy)
	mobflip(m,dx,dy)
	m.x+=dx
	m.y+=dy
	m.ox+=-dx
	m.oy+=-dy
	m.sox,m.soy=-dx,-dy
	m.mov=mov_walk	
	m.t=0
end

function mobbump(m,dx,dy)
	mobflip(m,dx)
	m.sox,m.soy,m.ox,m.oy=dx,dy,0,0				
	m.mov=mov_bump
	m.t=0
end

function mobflip(m,dx)
	if dx<0 then
		m._flip=true
	elseif dx>0 then
		m._flip=false
	end
end

function mov_walk(m)
		m.ox,m.oy=m.sox*(1-m.t),m.soy*(1-m.t)
end

function mov_bump(m)
	local tme=m.t
	if(tme>0.5)tme=1-m.t
	m.ox=m.sox*tme
	m.oy=m.soy*tme
end

function hitmob(attm,defm)
	defm.hp-=attm.att
	defm.flash=5
	addfloat(defm.x, defm.y, "-"..attm.att, 9)
	if defm.hp<=0 then
		checkend()
		add(dmob,defm)
		defm.dur=15
		del(mob,defm)
	end
end

function do_ai()
	for m in all(mob) do
		if m!=p then
			m.mov=nil
			if dist(m.x,m.y,p.x,p.y)==8then
				local dx,dy=p.x-m.x,p.y-m.y
				mobbump(m,dx,dy)
				hitmob(m,p)
				_upd=update_aiturn	
			else
				local bdst,bx,by=999,0,0
				for i=1,4 do
					local dx,dy=dirx[i],diry[i]
					local tx,ty=m.x+dx,m.y+dy
					local tle=mget(tx/8,ty/8)
					if iswalkable(tx/8,ty/8,tle,"checkmobs")	then
						local d=dist(tx,ty,p.x,p.y)
						if (d<bdst) bdst,bx,by=d,dx,dy
					end
				end
				mobwalk(m,bx,by)
				_upd=update_aiturn		
			end 
		end
	end
end
-->8
--gameplay

function update_pturn()
	if(buttbuff==-1)buttbuff=getbutt()
	p.t=min(p.t+0.125,1)
	p.mov(p)
	if p.t==1 then
		_upd=update_game
		if(checkend())do_ai()
	end
end

function update_aiturn()
	dobutt(buttbuff)
	for m in all(mob) do
		if m!=p and m.mov then
			m.t=min(m.t+.125,1)
			m.mov(m)
			if(m.t==1)_upd=update_game
		end
	end
end

function trig_bump(tle,destx,desty)
	if tle==11 or tle==12 then
		mset(destx,desty,3)
	elseif tle==6 or tle==8 then
		mset(destx,desty,tle+1)
	elseif tle==10 then
		mset(destx,desty,3)	
	elseif tle==13 then
		if(destx==6 and desty==9)show_msg("it begins...",120)
		if(destx==11 and desty==1)show_lmsg({"invasion is afoot.","","gather datacards."})
	end
end

function checkend()
	if p.hp<=0 then
		_upd=update_over
		_drw=draw_over
		fadeout()
		return false
	end
	return true
end

__gfx__
00000000666666606666666000000000aaaaaaa05555555000aaa0000055500000000000000000000aaaaaa00aaa00000aa0aa00aaaaaaa00000000000000000
000000000606060066666000000000000a000a00055555000a000a000500050000aaa00000555000a000000000aa000000a0a000a00000a00000000000000000
007007006066606066660660000000000a000a0005000500a0aaa0a0505050500aaaaa0005555500a00000a000aa000000a0a000a0aaaaa00000000000000000
000770006066606066000660000000000a000a0005000500a00000a0505050500aa0aa0005050500aa0000000a0a000000a0a000a00000a00000000000000000
000770006066606066066660000500000a000a0005000500a0aaa0a0505050500a000a0005505500a00000a0a000a0000a000a0000a0aa000000000000000000
007007000606060000666660000000000aaaaa0005000500aa000aa0550005500aa0aa0005050500a0000000a000a000a00000a0a00000a00000000000000000
00000000666666606666666000000000aaaaaaa055555550aaaaaaa0555555500aaaaa00055555000aaaaaa00aaa0000aaaaaaa0aaaaaaa00000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000066666000066600000666000006660000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600006660000600060006000600060006000660060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000060006000600060006000600060006000660060000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000600060006006666666066666660666666606666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000600666666606066606060666060606660606066606000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660606660600066600000666000006060000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666060006660000666660006606600066066000660660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000006660000000000000666000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600600066006000066600006600600066006000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600600666006000660060006600600066006600660060000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660666666606660066066666660666666606660066000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666060006660606666666060666060606660006666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00606000006066000066600000606000066060000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606600066000000660660006606600000066000660660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000000000000000000000660000006600000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00660000006660000066600006666600066666000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600006600000066000006606000666060600666660000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606060066666000666660006666600666666606660606000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660666060600660600006666600066666006666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600066666000666660000666000006660000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000000303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02060303030303020c0b0b0d0203040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020b03030303030a0c0b0c0b0203030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020c0303030303020303030302020a0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020203030303020c030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020c0303130b0c0203030303020c030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030c0203030303020c030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303030303030203030303020b030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020a02020203030202020b030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0208030303030d02030302030303030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303030303030a03030a030303030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030302030302030303030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205030303030302030302030303080200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030302030302030303030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020c0303030c0b02030c02030303030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
