pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--wobble function
--by treveron

function _init()
	--because we'll be using sspr
	--the sprite to draw needs:
	gue={
		sx=8,--x position on spr sheet
		sy=0,--y position on spr sheet
		sw=8,--spr width on spr sheet
		sh=8,--spr height on spr sheet
		x=40,--x position on screen
		y=40,--y position on screen
		w=56,--width on screen
		h=56,--height on screen
	}
	t=0--timer (could be an obj variable)
end

function _update()
	t+=1--increment timer
end

function _draw()
	cls()
	--use function wobble
	--instead of sspr
	wobble(gue.sx,gue.sy,gue.sw,gue.sh,gue.x,gue.y,gue.w,gue.h)
end

function wobble(sx,sy,sw,sh,x,y,w,h)
	local wob=sin(t/60)*w/6
	ox,oy=-wob/2,wob
	ow,oh=wob,-wob
	sspr(sx,sy,sw,sh,x+ox,y+oy,w+ow,h+oh)
end
__gfx__
000000000007a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007a22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070007aa22a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000a22aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000a22aa400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaa4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000