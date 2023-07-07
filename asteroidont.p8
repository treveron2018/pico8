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
		tay=0}
		asteroids={}
		ships={}
		shwaves={}
		sparks={}
		
		_upd=upd_game
		_drw=drw_game
		
		spawn_ast(0,0)
		spawn_ship(84,84)
		spawn_ship(44,44)
end

function _update60()
	upd_cursor()
	_upd()
end

function upd_game()
	upd_ast()
	ast_select()
	upd_ships()
	upd_shwaves()
	upd_sparks()
end

function upd_dir()
	if cur.bt==1 then
		stir(get_ast())
	else
		_upd=upd_game
		_drw=drw_game
	end
end

function drw_game()
	drw_ast()
	drw_ships()
	drw_shwaves()
	drw_sparks()
end

function drw_dir()
	drw_ast()
	drw_ships()
	line(cur.x,cur.y,cur.tax,cur.tay,7)
end

function _draw()
	cls()
	drw_cursor()
	_drw()
	--print(#sparks,0,0,7)
end
-->8
--cursor

function upd_cursor()
	cur.x=stat(32)
	cur.y=stat(33)
	cur.bt=stat(34)
	ast_clic()
end

function drw_cursor()
	spr(cur.spt, cur.x, cur.y)
end

function ast_select()
	for a in all(asteroids)do
		if dist(cur.x,cur.y,a.x,a.y)<a.r then
			a.sel=true
		else
			a.sel=false
		end
	end 
end

function ast_clic()
	for a in all(asteroids)do
		if cur.bt==1 and a.sel then
			cur.tax,cur.tay=a.x,a.y
			_upd=upd_dir
			_drw=drw_dir
		end
	end
end
-->8
--tools

function dist(p1x,p1y,p2x,p2y)
	return sqrt(((p1x-p2x)/10)^2+((p1y-p2y)/10)^2)*10
end

function checkastpos(o)
	if(o.x<-o.r)o.x=o.r+128
	if(o.x>o.r+128)o.x=-o.r
	if(o.y<-o.r)o.y=o.r+128
	if(o.y>o.r+128)o.y=-o.r
end

function get_angle(p1x,p1y,p2x,p2y)
	return atan2(p1y-p2y,p1x-p2x)
end
-->8
--asteroids

function spawn_ast(_x,_y)
	local a={
		x=_x,
		y=_y,
		r=9
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
		circ(a.x,a.y,a.r,7)
		if(a.sel)circ(a.x,a.y,a.r+1,7)
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
	ast.dx=sin(ang)/2
	ast.dy=cos(ang)/2
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
		poff={0,0,1,0}
	}
	add(ships,sh)
end

function upd_ships()
	for s in all(ships)do
		s.rot=aim(s)
		for i=1,#s.pang do
			s.px[i]=sin(s.rot+s.pang[i])*(s.r-s.poff[i])+s.x
			s.py[i]=cos(s.rot+s.pang[i])*(s.r-s.poff[i])+s.y
			if(ship_col(s.px[i],s.py[i]))explode(s)
		end
	end
end

function drw_ships()
	for s in all(ships)do
		for i=1,#s.pang do
			local off=1
			if(i==#s.pang)off=-3
			line(s.px[i],s.py[i],s.px[i+off],s.py[i+off])
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
		if(dist(x,y,a.x,a.y)<a.r)return true
	end
	return false
end

function explode(s)
	add_shwave(s.x,s.y,0,20)
	add_sparks(s.x,s.y,40)
	del(ships,s)
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
			s.r+=.75
		else
			s.r-=.75
		end
		if(s.r>=s.tr)then
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

__gfx__
00000000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
