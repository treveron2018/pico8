pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	ax=0
	ay=0
	az=0
	camx=0
	camy=0
	camz=-4
	pts={}
--[[	for x=-1,1 do
		for y=-1,1 do
			for z=-1,1 do
				add(pts,{x=x,y=y,z=z})
			end
		end
	end]]
	for i=1, 10 do
		add(pts,{x=rnd(6)-3,y=rnd(6)-3,z=rnd(6)-3})		
	end
end

function _update60()
	if btn(🅾️) then
		if(btn(⬇️))camz-=.1
		if(btn(⬆️))camz+=.1
		if(btn(⬅️))camx-=.1
		if(btn(➡️))camx+=.1		
	else
		if(btn(⬇️))ax-=.01
		if(btn(⬆️))ax+=.01
		if(btn(⬅️))ay-=.01
		if(btn(➡️))ay+=.01				
	end
end

function _draw()
	cls()
	for p in all(pts) do
		local rx,ry,rz=rotx(p.x,p.y,p.z,ax)
		rx,ry,rz=roty(rx,ry,rz,ay)
		local x,y=project(rx-camx,ry-camy,rz-camz)	
		circfill(x,y,1,7)
		print(p.z-camz,x+2,y+2,8)
	end
	print(camz,0,0,7)
end
-->8
--3d

function project(x,y,z)
  return 63.5+63.5*(x/z), 63.5+63.5*(y/z)
end

function rotx(x,y,z,a) return x, y*cos(a)-z*sin(a), y*sin(a)+z*cos(a) end

function roty(x,y,z,a) return z*sin(a)+x*cos(a), y, z*cos(a)-x*sin(a) end

function rotz(x,y,z,a) return x*cos(a)-y*sin(a), x*sin(a)+y*cos(a), z end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
