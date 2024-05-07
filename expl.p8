pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--explosion tool

function _init()
	expl={}
	spd=1
end

function _update()
	if(btnp(❎))add_expl(63,63)
	upd_expl()
	upd_sparks()
	if btnp(⬆️)then
		spd+=1
	elseif btnp(⬇️) then
		spd-=1	
	end
end

function _draw()
	cls()
	drw_expl()
	drw_sparks()
end
-->8
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
-->8
--expl

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
-->8
--sparks
sparks={}
function lerp(from,to,weight)
	local dist=to-from
	if(abs(dist)<.2)return to
	return to-dist*weight
end

function range(low,high)
	return rnd(high-low+1)+low
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
