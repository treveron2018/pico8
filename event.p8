pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main
--todo
--design rest of the panel
function _init()

	x=63
	y=63
	
	radar_pos={
		{pos="topleft",x=54,y=97},
		{pos="topcenter",x=66,y=93},
		{pos="topright",x=77,y=97},
		{pos="centerleft",x=55,y=103},
		{pos="centercenter",x=68,y=102},
		{pos="centerright",x=78,y=103},
		{pos="bottomleft",x=54,y=117},
		{pos="bottomcenter",x=67,y=119},
		{pos="bottomright",x=77,y=117}
	}
	
	rotx=0
	roty=0
	rnddirs={3,-3,4,-4}
	dirx=rnd(rnddirs)
	diry=rnd(rnddirs)	
end

function _update()
	
end

function _draw()
	cls()
	reference()
	draw_panel()
end
-->8
--draw functions

function draw_panel()

--panel
	rectfill(0,87,127,127,12)
	rectfill(0,84,127,86,7)
--radar
	circfill(63,107,20,3)
	oval(58,87,68,127,10)
	oval(43,102,83,112,10)
	oval(48,92,55,122,10)
	oval(71,92,78,122,10)
	
	spr(1,60,103)
	
	local pos=getpos()
	draw_pos(pos)
end

function getpos()

	local pos=""
	if(roty>diry)pos=pos.."bottom"
	if(roty<diry)pos=pos.."top"
	if(roty==diry)pos=pos.."center"
	if(rotx>dirx)pos=pos.."left"
	if(rotx<dirx)pos=pos.."right"
	if(rotx==dirx)pos=pos.."center"
	
	return pos
	
end

function draw_pos(pos)
	local mypos={}
	for p in all(radar_pos) do
		if pos==p.pos then 
			mypos.x=p.x
			mypos.y=p.y
		end
	end

	circfill(mypos.x,mypos.y,2,11)
end

function reference()

	if(btnp(0))rotx-=1
	if(btnp(1))rotx+=1
	if(btnp(2))roty-=1
	if(btnp(3))roty+=1
	
	print("x: "..rotx,7)
	print("y: "..roty,7)
	
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
