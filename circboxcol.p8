pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
function _init()
c={
	x=63,
	y=63,
	r=10,
	col=8
}

s={
	x1=20,
	x2=40,
	y1=20,
	y2=40,
	col=3
}
cx=c.x
cy=c.y

end

function _update()
	if(btn(⬆️))c.y-=1
	if(btn(⬇️))c.y+=1
	if(btn(⬅️))c.x-=1
	if(btn(➡️))c.x+=1
	cx=c.x
	cy=c.y
end

function _draw()
 cls()
 if cb_col(c,s) then
	 circfill(c.x,c.y,c.r,c.col) 
	 rectfill(s.x1,s.y1,s.x2,s.y2,s.col)
	else
	 rect(s.x1,s.y1,s.x2,s.y2,s.col)
 	circ(c.x,c.y,c.r,c.col)
 end
 circ(cx,cy,2,7)
end

function cb_col(c,s)
	if(cx<s.x1)cx=s.x1
	if(cx>s.x2)cx=s.x2
	if(cy<s.y1)cy=s.y1
	if(cy>s.y2)cy=s.y2

	local dx=cx-c.x
	local dy=cy-c.y
	local dist=sqrt(dx^2+dy^2)

if(dist<c.r)return true
return false
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
