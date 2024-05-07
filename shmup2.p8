pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--shmup2
--by treveron

--todo
	--bomb mode
	--touch pad buttons

function _init()
	t=0
	p={
		x=64,
		y=64,
		sp=2,
		bn=0,
		maxbn=10,	
		isdead=false,
		rt=0,
		ifr=0
	}
	orbitals={}
	orb_mode=1
	o_dx=split("-.5,.5,-.5,.5")
	mode_desc=split("disperse,focused,barrier")
	obr=4
	pbul={}
	ebul={}
	trails={}
	trail_c=split("8,9,10")
	shwaves={}
	prop={}
	expl={}
	sparks={}
	
	enemies={}
	
	--tests
	add_orbital()
	add_orbital()
	add_orbital()
	add_orbital()
	spawn(56,-8,1)

end

function _update60()
	t+=1
	--
	if t%180==0 then
		spawn(rnd(40)+60,-8,1)
			
	end
	
	--
	if p.isdead then
		respawn()
	else
		upd_player()
	end
	upd_trails()
	upd_pbul()
	upd_shwaves()
	upd_prop()
	upd_orbital()
	upd_enemies()
	upd_ebul()
	upd_sparks()
	upd_expl()
end

function _draw()
	cls()
	drw_expl()
	drw_sparks()
	drw_prop()
	drw_orbital()
	drw_shwaves()
	if not p.isdead 
	or p.isrespawning then
		drw_player()
	end
	drw_trails()
	drw_pbul()
	drw_enemies()
	drw_ebul()
	print(mode_desc[orb_mode],0,0,7)

end
-->8
--player

function upd_player()
	if(p.ifr>0)p.ifr-=1	
	if btn(⬆️)then
		p.y-=1
	elseif btn(⬇️)then
		p.y+=1
	end
	if btn(⬅️)then
		p.x-=1
		banking(-1)
	elseif btn(➡️)then
		p.x+=1
		banking(1)
	else banking(0)
	end
	if(p.x<0)p.x=0
	if(p.x>113)p.x=113
	if(p.y<0)p.y=0
	if(p.y>115)p.y=115
	if btnp(❎)then
		local offx=3
		for i=1,2 do
			shoot(p.x+offx,p.y,2,0)
			offx+=8
		end
	end
	--★
	if btnp(🅾️)then
		orb_mode+=1
		if(orb_mode>3)orb_mode=1
	end
--/★
	upd_phb()
	propel(p.x+8,p.y+11,3)
end

function drw_player()
local sps={6,4,2,8,10}	
	if p.ifr==0 or sin(t/10)<.5 then
		spr(sps[flr(p.bn/5)+3],p.x,p.y,2,2)
	end
end

function upd_phb()
	p.hb={
		x=p.x+7,
		y=p.y+7,
		r=3
	}
end

function shoot(_x,_y,_r,_dx)
	local b={
		x=_x,
		y=_y,
		dx=_dx,
		dy=-5,
		r=_r
	}
	add(pbul,b)
	add_shwave(b.x,b.y,0,3)
end

function upd_pbul()
	for b in all(pbul)do
		b.x+=b.dx
		b.y+=b.dy
		local t={
			x=b.x,
			y=b.y,
			r=b.r+1,
			a=6
		}
		add(trails,t)
		local e=check_hit(b)
		--★
		if e then
			hit(b,e)
			if e.hp<=0 then
				del(enemies,e)
				add_expl(e.x+e.w/2,e.y+e.h/2)
			end
			del(pbul,b)
		end
		if b.y<0-b.r then
			del(pbul,b)
		end
	end
end

function drw_pbul()
	for b in all(pbul)do
		circfill(b.x,b.y,b.r,7)
	end
end

function banking(b)
	if b!=0 then
		p.bn+=b
		if(p.bn<=-p.maxbn)p.bn=-p.maxbn
		if(p.bn>=p.maxbn)p.bn=p.maxbn
	else
		if p.bn<0 then
			p.bn+=1
		elseif p.bn>0 then
			p.bn-=1
		end	
	end
end

function check_hit(b)
	for e in all(enemies) do
		if(circbox_col(b,e))return e
	end
	return false
end

function hit(b,e)
	e.hp-=b.r
	e.hf=6
end

function kill_p()
	p.isdead=true
	p.rt=120
	add_expl(p.x+7,p.y+6)
end

function respawn()
	if p.rt>0 then
		p.rt-=1
	elseif not p.isrespawning then
		p.x=56
		p.y=144
		p.isrespawning=true
	else
		p.y=lerp(p.y,100,.7)
		if p.y==100 then
			p.isdead=false
			p.isrespawning=false
			p.ifr=120
		end
	end
	
end
-->8
--particles

function add_shwave(_x,_y,_r,_tr)
	local s={
		x=_x,
		y=_y,
		r=_r,
		tr=_tr
	}
	add(shwaves,s)
end

function upd_shwaves()
 for s in all(shwaves)do
 	local off=s.r<s.r and 1 or -1
 	s.r+=.5
 	if(s.r==s.tr)del(shwaves,s)
 end
end

function drw_shwaves()
 for s in all(shwaves)do
		circ(s.x,s.y,s.r,7)
 end
end

function propel(_x,_y,_r)
	local offr=0
	if btn(⬇️) then 
		offr=-1
	elseif btn(⬆️) then
		offr=1
	end
	local p={
		x=_x,
		y=_y,
		r=_r+offr,
		c=12,
		dx=rnd()-.5,
		dy=rnd()
	}
	add(prop,p)
end

function upd_prop()
	for p in all(prop)do
		p.r-=.2
		if(p.r<=0)del(prop,p)
		p.x+=p.dx
		p.y+=p.dy
	end
end

function drw_prop()
	for p in all(prop)do
		circfill(p.x,p.y,p.r,p.c)	
	end
end

function upd_trails()
	for t in all(trails)do
		t.r-=.5
		if(t.r<=0)del(trails,t)
	end
end

function drw_trails()
	for t in all(trails)do
		circfill(t.x,t.y,t.r,trail_c[flr(t.r)])
	end
end

-->8
--tools

function lerp(from,to,weight)
	local dist=to-from
	if(abs(dist)<.2)return to
	return to-dist*weight
end

function getframe(o)
	return o.ani[flr(o.t/15)%#o.ani+1]
end

function dist(p1,p2)
	return sqrt((p1.x-p2.x)^2+(p1.y-p2.y)^2)
end

function circbox_col(c,b)
	local p={x=c.x,y=c.y}
	if(c.x<b.x)p.x=b.x
	if(c.x>b.x+b.w-1)p.x=b.x+b.w-1
	
	if(c.y<b.y)p.y=b.y
	if(c.y>b.y+b.h-1)p.y=b.y+b.h-1
	
	return dist(c,p)<c.r
end

function range(low,high)
	return rnd(high-low+1)+low
end

-->8
--orbitals

function add_orbital()
	local o={
		sp=1,
		x=p.x+8,
		y=p.y+5,
		o=#orbitals+1,
		b=true,
		bt=0
	}
	add(orbitals,o)
	orb_rot()
end

function upd_orbital()
	local px,py=p.x,p.y
	for o in all(orbitals)do
		if p.isdead then
			o.y=lerp(o.y,136,.95)		
		else
			if o.bt>0 then
				o.bt-=1
			else 
				o.b=true
			end
			if orb_mode==3 then
				o.rot+=.01
				if(o.rot>1)o.rot=0
				o.x=lerp(o.x,sin(o.rot)*15+p.x+5,.9)
				o.y=lerp(o.y,cos(o.rot)*15+p.y+5,.9)
			else
				orb_pos={
					{
						{px-7,py+7},
						{px+15,py+7},
						{px-14,py+7},
						{px+22,py+7},
					},
					{
						{px+1,py-6},
						{px+7,py-6},
						{px+1,py-12},
						{px+7,py-12},
					}
				}
				o.x=lerp(o.x,orb_pos[orb_mode][o.o][1],.9)
				o.y=lerp(o.y,orb_pos[orb_mode][o.o][2],.9)
				local dx=orb_mode==1 and o_dx[o.o] or 0
				if(btnp(❎) and not p.isdead and not p.isrespawning)shoot(o.x+3,o.y,1,dx)	
			end
		end
		propel(o.x+3,o.y+6,2)
	end
end

function drw_orbital()
	for o in all(orbitals)do
		spr(o.sp,o.x,o.y)
		if orb_mode==3 then
			local cols={7,12}
			local col=cols[flr(t/5)%2+1]
			if(not o.b)col=5
			circ(o.x+3,o.y+3,obr,col)
		end
	end
end

function orb_rot()
	for o in all(orbitals)do
		o.rot=(1/#orbitals)*o.o
	end
end
-->8
--enemies
animations={
	{12,13}
}
hp={
	20
}
w={
	8
}
h={
	8
}
function spawn(_x,_y,ty)
	local e={
		x=_x,
		y=_y,
		typ=ty,
		ani=animations[ty],
		hp=hp[ty],
		w=w[ty],
		h=h[ty],
		t=0,
		hf=0
	}
	add(enemies,e)
end

function upd_enemies()
	for e in all(enemies)do
		
		e.t+=1
		if (e.hf>0)e.hf-=1
		--type 1
			e.y+=.5
			e.x+=sin(e.t/150)*.5
			if(e.t%60==0)e_shoot(e)
		--
		if e.y>=128 then
			del(enemies,e)
		end
	end
end

function drw_enemies()
	for e in all(enemies)do
		if e.hf>0 then
			for i=2,15 do
				pal(i,7)
			end
		end
		spr(getframe(e),e.x,e.y)
		pal()
	end
end

function e_shoot(e)
	local ex,ey=e.x+e.w/2,e.y+e.h/2
	_ang=atan2(p.y+7-ey,p.x+7-ex)

	local b={
		x=ex,
		y=ey,
		ang=_ang,
		r=2,
		spd=2
	}
	add(ebul,b)
end

function upd_ebul()
	for b in all(ebul) do
		b.dx=sin(b.ang)/b.spd
		b.dy=cos(b.ang)/b.spd
		b.x+=b.dx
		b.y+=b.dy
		
		if b.x<0-b.r 
		or b.x>128+b.r
		or b.y<0-b.r 
		or b.y>128+b.r
		then
			del(ebul,b)
		end
		for o in all(orbitals)do
			if dist(b,{x=o.x+3,y=o.y+3})<b.r+obr 
			and o.b
			and orb_mode==3 then
				del(ebul,b)
				o.bt=120
				o.b=false
			end
		end
		if dist(b,p.hb)<b.r+p.hb.r and not p.isdead and p.ifr==0 then
			kill_p()
		end
	end
end

function drw_ebul()
	for b in all(ebul) do
		circfill(b.x,b.y,b.r,10)
	end
end
-->8
--explotions

--blob

function blob(b,c)
	local thk={
		5,
		3,
		1,
		0
	}
	
	local p={
		0b1111111111111111,
		0b1010011010101111,
		0b101000001010000,
		0
	}
	if b.r==b.tr then
		thc={
		5,
		3,
		0
	}
	p={		
		0b1010011010101111,
		0b101000001010000,
		0}
	elseif b.r==b.tr+1 then
		thk={5,3}
		p={
		0b1010011010101111,
		0b101000001010000}
	elseif b.r==b.tr+2 then
		thk={3}
		p={▒}
	elseif b.r==b.tr+3 then
		thk={3}
		p={░}
	end
		
	for i=1,#thk do
		fillp(p[i])
		circfill(b.x,b.y+thk[i],b.r+thk[i],c)
	end
	fillp()
end

function add_expl(_x,_y)
	local e={
		x=_x,
		y=_y,
		r=-2,
		tr=8,
	}
	add(expl,e)
	add_sparks(10,_x,_y)
end

function upd_expl()
	for e in all(expl) do
			e.r+=1
		if(e.r>=e.tr+4)del(expl,e)
	end
end

function drw_expl()
	for e in all(expl)do
		local r,tr,c=e.r,e.tr,167
		if r>=tr then
			c=93
		elseif r>tr-3 then
			c=137
		elseif r>tr-6 then
			c=154
		end
		blob(e,c)
	end
end

function add_sparks(n,_x,_y)
	local ang=rnd()
	for i=1,n do
		local ang2=range(ang,.5)
		local s={
			x=_x,
			y=_y,
			ang2=range(ang,.3),
			r=range(1,3),
			a=flr(range(5,10))
		}
		add(sparks,s)
	end
end

function upd_sparks()
	for s in all(sparks)do
		s.a-=1
		if(s.a==0)del(sparks,s)
		s.px=s.x
		s.py=s.y
		s.x=sin(s.ang2)*s.r+s.x
		s.y=cos(s.ang2)*s.r+s.y
	end
end

function drw_sparks()
	for s in all(sparks)do
		local col=10
		if(s.a<3)col=9
		line(s.x,s.y,s.px,s.py,col)
	end
end


__gfx__
00000000000100000000000000000000000000000000000000000000001000000000000000000000000001000000000000222200008888000000000000000000
00000000001b1000000100010001000000000001000100000000000101510000000010001000000000001510100000000288882008aaaa800000000000000000
0070070001acb1000015101a101510000010001a101510000010001a1551000000015101a100010000001551a100010028a1aa8228a1aa820000000000000000
000770001abb3310001551bbb1551000015101abb1551000015101abb55100000001551bbb1015100000155bbb1015102a111aa22a111aa20000000000000000
000770000115110000155bb7b355100001551bb7b355100001551bb7b3510000000155bb73315510000015bb733155102a111aa22a111aa20000000000000000
00700700000100000015bbc7c33510000155bbc7c33510000155bbc7c333100000015bbc7c3355100001bbbc7c33551028a1aa8228a1aa820000000000000000
000000000000000001bbbccccc333100015bbcc7cc333100015bbccbb323b100001bbbcc7cc33510001ab2bbbcc335100288882008aaaa800000000000000000
00000000000000001ab2bbbab3323b1001bbccbab3323b1001bbccbab338b10001ab2bbba3cc3310001a8bbba3cc331000222200008888000000000000000000
00000000000000001a8bbbb5b3338b101a2bbba5b3338b101a2bbba51332b10001a8bbbb5b333231001a2bb15b33323100000000000000000000000000000000
00000000000000001a2bb1d5d13323101abbbb55d13323101abbbb5d1553b10001a2bb1d55333331001ab5515533333100000000000000000000000000000000
00000000000000001ab5511d115533101a2b1d5d115533101a2b1d5d1d11b10001ab5511d5d13231001a11d1d5d1323100000000000000000000000000000000
00000000000000001a11d10101d11b101a5511d101d11b101a5511d00100100001a11d101d115531000100100d11553100000000000000000000000000000000
000000000000000001001000001001001a1d1010001001001a1d101000000000001001000101d131000000000101d13100000000000000000000000000000000
00000000000000000000000000000000010100000000000001010000000000000000000000001010000000000000101000000000000000000000000000000000
