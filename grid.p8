pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--grid
--by treveron

--todo
--improve ui (cards desc on 
	--the top of the screen?)
--(p)ower and (m)ov in the cards
--flip cards when clicked

function _init()
	poke(0x5f2d,1)
	cur={
		x=stat(32),
		y=stat(33),
		sp=3,
		bt=stat(34),
		rel=false
	}
	
	deck={}
	hand={}
	handx=4
	handy=118
	cardw=26
	cardh=26
	
	for i=1,5 do
		add_card(1)
	end
	
	offx={1,-1,0,0}
	offy={0,0,1,-1}
	tiles={}
	create_tiles(6,6,17,10)
	p={
		sp=19,
		tile=tiles[15],
		mov=2
	}
	p.x=p.tile.posx+4
	p.y=p.tile.posy+3
end

function _update()
	upd_cur()	
	upd_tiles()
	upd_player()
	upd_cards()
end

function _draw()
	cls(3)
	drw_tiles()
	drw_player()
	drw_cards()
	drw_cur()
	
	print(deck[2].w,0,0,7)
end

-->8
--grid

function create_tiles(rows,cols,x,y)
	local _x,_y=0,0
	for i=1, rows do
		for j=1, cols do
			local t={
				x=i,
				y=j,
				posx=x+_x,
				posy=y+_y,
				h=2,
				w=2,
				sp=4
			}
			add(tiles,t)
			_x+=16
		end
		y+=16
		_x=0
		_y=0
	end
end

function upd_tiles()
	for t in all(tiles)do
		t.hl=false
				
		--tile_mov(p,p.mov)
	end
	cur_tile()
end

function drw_tiles()
	for t in all(tiles) do
		if t.hl then
			pal(11,8)
		elseif t.sel then
			pal(11,10)
		end
		spr(t.sp,t.posx,t.posy,t.w,t.h)
		pal()
	end
end

function tile_mov(o,mov)
	for t in all(tiles)do
		if abs(o.tile.x-t.x)+abs(o.tile.y-t.y)<=mov then
			t.hl=true
		else t.hl=false
		end
	end
end

function cur_tile()
	for t in all(tiles)do 
		if cur_butt(t.posx,t.posy,t.posx+15,t.posy+15)then
			t.sel=true
		else t.sel=false
		end
	end
end

function get_tile()
	for t in all(tiles)do
		if cur_butt(t.posx,t.posy,t.posx+15,t.posy+15)then
			return t
		end
	end
	return false
end
-->8
--tools

function outline(sp,x,y)
	for i=1,15 do
		pal(i,1)
	end
	for i=1,#offy do
		spr(sp,x+offx[i],y+offy[i])
	end
	pal()
	spr(sp,x,y)
end

function lerp(from, to, weight)
 local dist = to - from
 if (abs(dist) < 0.2) then
  return to
 end
 return from + (dist * weight)
end
-->8
--player

function drw_player()
	outline(p.sp,p.x,p.y)
end

function upd_player()
	p.tx=p.tile.posx+4
	p.ty=p.tile.posy+3
	p.x=lerp(p.x,p.tx,0.2)
	p.y=lerp(p.y,p.ty,0.2)
	
	local tile=get_tile()
	if click() and tile and tile.hl then
		p.tile=tile
	end
end	
-->8
--cursor

function upd_cur()	
	cur.x=stat(32)
	cur.y=stat(33)
	if cur.bt==1 then
		cur.rel=false
	else 
		cur.rel=true
	end
	cur.bt=stat(34)	
end

function drw_cur()
	outline(cur.sp,cur.x,cur.y)
end

function click()
	if(cur.bt==1 and cur.rel)return true
	return false
end

function cur_butt(x1,y1,x2,y2)
	if cur.x<=x1
	or cur.x>=x2
	or cur.y<=y1
	or cur.y>=y2
	then return false
	else	return true
	end
end
-->8
--iu



-->8
--cards

cardnames={"shoot", "high speed"}
cardspt={7,23}
carddesc={{"normal","shoot"},{"xtra","mvmnt"}}

function add_card(n)
	local c={
		name=cardnames[n],
		sp=cardspt[n],
		desc=carddesc[n],
		ty=handy,
		y=handy,
		w=cardw
	}
	add(deck,c)
end

function drw_cards()
	for c in all(deck)do
		local x,y=c.x,c.y
		local w,h=c.w,y+cardh
	
		clip(c.x,y,w-3,h)
		rectfill(c.x,c.y,x+c.w-4,h,0)
		rect(c.x,c.y,x+c.w-4,h,7)
		local cx,cy=c.x+3,c.y+12		
		spr(c.sp,cx,c.y+2,2,1)
		for t in all(c.desc) do
			print(t,cx,cy,7)
			cy+=6
		end
		clip()
		print(c.x,c.x,c.y,8)
	end
end

function upd_cards()
	local ox,flpspd=0,1
	for c in all(deck)do
		c.x=handx+ox
		if c.isflipping and c.w>2 then
			c.w-=flpspd
			c.x+=flpspd/2
			if c.w<=2  then
				c.isflipping=false
			end
		elseif not c.isflipping and c.w<cardw then
				--show back of the card
			c.w+=flpspd
			c.x-=flpspd/2
		end
		
		ox+=25
		if cur_butt(c.x,c.y,c.x+c.w,c.y+cardh) or c.w!=cardw then
			c.ty=100
			if click() and c.y==100 and not c.isflipping then
				c.isflipping=true
			end
		else c.ty=118
		end		
		c.y=lerp(c.y,c.ty,.2)
	end
end


__gfx__
0000000000000000000000007a00000000bbbbbbbbbbbb0000000000800000000000000080000000000000000000000000000000000000000000000000000000
0000000000000000000000007aaa9000000000000000000000005550888560000000000088856000000080000000000000000000000000000000000000000000
0070070000000000000000000acaa900b00000000000000b00055555089900000000000008990000000a87700000000000000000000000000000000000000000
00077000000000000000000007a7aaa9b00000000000000b55555c55897c880115566700897c8801299a87770000000000000000000000000000000000000000
000770000000000bb000000000aa5600b00000000000000baaa557c5089900000000000008990000000a87700000000000000000000000000000000000000000
00700700000000b00bb00000007a6600b00000000000000b55555c55888560000000000088856000000080000000000000000000000000000000000000000000
000000000000bb00000bb000000a0000b00000000000000b00055555800000000000000080000000000000000000000000000000000000000000000000000000
0000000000bb000000000bb0000a0000b00000000000000b00005550000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb0000000000000b00000000b00000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb0000000000bb009800000b00000000000000b00000000001102209800000000b009800000b0000000000000000000000000000000000000000000
00000000000bb000000bb00000888560b00000000000000b0000000000010020088856000b00008885600b000000000000000000000000000000000000000000
0000000000000bb00bb0000080089900b00000000000000b0000000001002008008990000b00800899000b000000000000000000000000000000000000000000
000000000000000bb000000098897c88b00000000000000b00000000011122298897c8800b0098897c880b000000000000000000000000000000000000000000
00000000000000000000000080089900b00000000000000b0000000001002008008990000b00800899000b000000000000000000000000000000000000000000
0000000000000000000000000088856000000000000000000000000000010020088856000b00008885600b000000000000000000000000000000000000000000
0000000000000000000000000980000000bbbbbbbbbbbb0000000000001102209800000000b009800000b0000000000000000000000000000000000000000000
