pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--die-fence, by treveron

--todo
--work on background
----randomize tiles
----fire particles behind the hill
--fix enemy sprites
--enemy lvl 2
--wave 2
--particles
----placing dice
----death particles
----dust under enemies
----lvl up
----roll ready
----wind?

function _init()
	start_game()
end

function _update()
	update_game()
end

function _draw()
	draw_game()
end

function start_game()
	mode="wave"
	has_horde=false
	p_rolls=5
	
	lives=3
	cellw=18
	cellh=16
	cellgap=2
	grid={}
	
	create_grid()
	
	s_ani=0
	roll_bar=10
	rb_cap=10
	rb_spd=0.1
	can_roll=false
	die_loaded=false
	ui_dice=6
	die_ani=0
	animate_die=false	
	dice={}

--right ui
	ruix=32
	ruiy_l1=108
	ruiy_l2=114
	ruiy_l3=120
	blinkt=1
	
	enemy_spawnx=134
	enemy_spawny={10,28,46,64,82}--rows y pos
	enemies={}
	spawn_timer=0	
	spawn_rate=150
	combat_info={}	
	att_ani={}
	arrows={}
	shwaves={}
	
	wave=1
	enemy_counter=10
	enemy_kills=0
	c_pause=cocreate(pause)
	c_horde=nil
	
	replacing=false
	upgrading=false
end

function update_game()
if(lives<=0)mode="over"
	manage_waves()
	if not replacing then
		if(btnp(0))select_cell(-1)
		if(btnp(1))select_cell(1)
		if(btnp(2))select_cell(-5)
		if(btnp(3))select_cell(5)
		recycle()
	if(upgrading)upgrade()
	end
	roll()
	if (animate_die)animate_roll()
	
	if replacing then 
		is_replacing()
		if(btnp(❎))replacing=false
		if(btnp(🅾️))replace()		
	else
		set_dice()
	end
	
	if(mode=="game")spawn_enemies()

	manage_enemies()
	manage_dice()
	manage_ci()
	manage_att_ani()
	manage_arrows()
	if get_die() then
		debug=get_die().upgraded
	else 
		debug=0
	end
end

function draw_game()
	cls()
	map()
--	draw_grid()
	draw_lives()
	draw_selector()
	left_ui()
	right_ui()
	draw_dice()
	draw_enemies()
	draw_ci()
	draw_att_ani()
	draw_arrows()
	draw_shwaves()
	die_hp()
	--print(debug,1,1,7)
end
-->8
--grid functions

function create_grid()
	local cellx=10
	local celly=10
	local id=1
	for i=0,4 do
		for j=0,4 do
			add(grid, {
				x=cellx,
				y=celly,
				id=id,
				die=nil,
				diex=cellx+2,
				diey=celly+1,
				selected=false,
				used=false})
			cellx+=(cellw+cellgap)
			id+=1
		end
		celly+=(cellh+cellgap)
		cellx=10
	end
	grid[1].selected=true
end

function draw_grid()
	for g in all(grid) do
		rectfill(g.x,g.y,g.x+cellw,g.y+cellh,11)
	end
end

function draw_selector()
	s_ani+=0.1
	if(s_ani>=2)s_ani=0
	for g in all(grid) do
		if g.selected then
			spr(41,g.x-s_ani,g.y-s_ani)
			spr(42,g.x+cellw-6+s_ani,g.y-s_ani)
			spr(57,g.x-s_ani,g.y+cellh-6+s_ani)
			spr(58,g.x+cellw-6+s_ani,g.y+cellh-6+s_ani)
		end
	end
end

function select_cell(s)
	local sel=0
	for i=1,count(grid) do
		if grid[i].selected then
			sel=i+s
			grid[i].selected=false
			if(sel<=0)sel+=count(grid)
			if(sel>count(grid))sel-=count(grid)
			grid[sel].selected=true
			return
		end
	end
end
-->8
--ui functions
function draw_lives()
	for i=1, 3 do
		spr(32,-8+i*9,1)
	end
	for i=1,lives do
		spr(16,-8+i*9,1)
	end
end
function left_ui()
	spr(63+ui_dice,5,112)

	rect(15,108,24,123,7)
	rectfill(17,121-roll_bar,22,121,10)
	fill_bar()
end

function fill_bar()
	if not can_roll then
		roll_bar+=rb_spd+0.02*count_d1s()
		if(roll_bar>rb_cap)can_roll=true
	end
end

function roll()
	if can_roll 
		and btnp(❎) 
		and not die_loaded then
			animate_die=true
	end
end

function animate_roll()
	die_ani+=1
	ui_dice+=1
	if(ui_dice>6)ui_dice=1 
	if die_ani>=30 then
--	local test={1,6}
--	ui_dice=rnd(test)
	ui_dice=flr(rnd(6))+1
	while #dice==0 and ui_dice==6 do
		ui_dice=flr(rnd(6))+1
	end 
		animate_die=false	
		die_ani=0
		if ui_dice==6 then
		 upgrading=true
		else
			die_loaded=true
		end
	end
end

function right_ui()
	local t1=""
	local t2=""
	local t3=""
	if mode=="wave" then
		t2="wave "..wave
		print(t2,ruix,ruiy_l2,blink())
	elseif mode=="horde" then
		t2="horde incoming!"
		print(t2,ruix,ruiy_l2,blink())	
	elseif mode=="win" then
		t2="congratulations!"
		print(t2,ruix,ruiy_l2,blink())	elseif mode=="win" then
	elseif mode=="over" then
		t2="game over..."
		print(t2,ruix,ruiy_l2,blink())	
	else
		if replacing then
			t1="replace dice?"
			t2="🅾️yes ❎no"
		elseif upgrading then
			t1="upgrade die!"
			t3="❎ for free reroll"
			local d=get_die()
			if d then
				if d.type==1 then 
					t1="lv up:citizen"
					t2="faster rb, ⬆️att"
				elseif d.type==2 then 
					t1="lv up:warrior"
					t2="⬆️att"	
				elseif d.type==3 then 
					t1="lv up:ranger"
					t2="more arrows"
				elseif d.type==4 then 
					t1="lv up:paladin"
					t2="att, ⬆️hp"
				elseif d.type==5 then 
					t1="lv up:cleric"
					t2="halo power ⬆️"
				end
			end
		else
			if(can_roll and not die_loaded)t2="press ❎ to roll!"
			if(die_loaded and (mode=="game" or mode=="post_horde"))t3="❎ to recycle(1/2 rbar)"
			if(die_loaded and mode=="prepare")t3=p_rolls.." rolls to start"
			if(die_loaded and ui_dice==1)t1="🅾️:place peasant" t2="(⬆️ roll bar spd)"
			if(die_loaded and ui_dice==2)t1="🅾️:place soldier" t2="(cq combat)"
			if(die_loaded and ui_dice==3)t1="🅾️:place archer" t2="(ranged combat)"
			if(die_loaded and ui_dice==4)t1="🅾️:place shield bearer" t2="(high hp)"
			if(die_loaded and ui_dice==5)t1="🅾️:place priest" t2="(healing halo)"
		end
		print(t1,ruix,ruiy_l1,7)
		print(t2,ruix,ruiy_l2,7)
		print(t3,ruix,ruiy_l3,7)
	end
end

function recycle()
	if die_loaded and btnp(❎) then
		die_loaded=false
		roll_bar=5
		can_roll=false
	end
	if upgrading and btnp(❎) then
		upgrading=false
		roll_bar=9.5
		can_roll=false
	end
end

function manage_ci()
	for ci in all(combat_info) do
		ci.y+=ci.dy
		ci.dy+=0.2
		ci.life-=1
		if(ci.life<=0)del(combat_info,ci)
	end	
end

function draw_ci()
	for ci in all(combat_info) do
		print(ci.value,ci.x,ci.y,ci.col)
	end		
end

function manage_att_ani()
	for a in all(att_ani) do
		a.life-=1
		if(a.life<=0)del(att_ani,a)
	end
end

function draw_att_ani()
	for a in all(att_ani) do
		local sprt=a.spr+2
		if(a.life>3)sprt-=1
		if(a.life>6)sprt-=1
		spr(sprt,a.x,a.y)
	end
end

function draw_shwaves()
		for sh in all(shwaves) do
		sh.r+=sh.spd
		circ(sh.x,sh.y,sh.r,sh.col)
		if sh.r>sh.tr then
			del(shwaves,sh)
		end
	end
end

function blink()
	blinkt+=1
	local blink_ani={5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5,5}
	if blinkt>#blink_ani then
		blinkt=1
	end
	return blink_ani[blinkt]
end
-->8
--dice functions

function set_dice()
	if btnp(🅾️) and die_loaded then
		for c in all(grid) do
			if c.selected and c.used==false then		
				add_die(c,ui_dice)		
				die_loaded=false
				can_roll=false
				c.used=true
				if mode=="prepare" then
					roll_bar=10
					p_rolls-=1
					if(p_rolls<=0)mode="start"
				else
					roll_bar=0
				end
				return
			elseif c.selected and c.used and not replacing then
				replacing=true
				return
			end
		end
	end
end

function replace()
	for c in all(grid)do
		for d in all(dice) do
			if d.cell==c.id and c.selected then
				del(dice,d)	
				add_die(c,ui_dice)	
				die_loaded=false
				can_roll=false
				replacing=false
				roll_bar=0
				return
			end
		end	
	end	
end

function is_replacing()
	for c in all(grid) do
		if(c.selected and c.used==false)replacing=false
	end
end

function upgrade()
	if btnp(🅾️) then
		local d=get_die()
		if d and not d.upgraded then
			d.upgraded=true
			d.maxhp*=1.5
			d.hp=d.maxhp
			
			if d.type==1 then
				d.att+=5
			elseif d.type==2 then
				d.att+=10
			elseif d.type==3 then
				d.att_t/=2
				d.rate/=2
			elseif d.type==4 then
				d.maxhp+=50
				d.hp=d.maxhp
			elseif d.type==5 then
				d.att+=5
				d.heal_v+=1
			end
			
			upgrading=false
			can_roll=false
			replacing=false
			roll_bar=0
		end
	end
end

function get_die()
	for d in all(dice) do
		if(grid[d.cell].selected)return d
	end
	return nil
end

function draw_dice()
	for d in all(dice) do
		if d.upgraded then
			pal(6,1)
			pal(8,10)
		end
		spr(d.spr,d.x,d.y,2,2)
		pal()
	end
end

function count_d1s()
	local d1s=0
	for d in all(dice) do
		if d.type==1 then
			if d.upgraded then
				d1s+=2
			else
				d1s+=1
			end
		end
	end
	return d1s
end

function manage_dice()
	for d in all(dice) do
	 if(d.hp<=0)kill(dice,d,"ally")
		if(d.type==2 or d.type==1)manage_cqc(d)
		if(d.type==3)manage_3s(d)
		if(d.type==5)manage_5s(d)
	end
end

function manage_cqc(d2)			
	local d=ally_hitbox_detection(d2)
	if d!=nil then
		attack(d2,d,"ally")
	end
end

function manage_3s(d3)			
	d3.att_t-=1
	if(d3.att_t<=0)then
		local arrow={
			x=d3.x,
			y=d3.y+5,
			att=5,
			att_t=0,
			rate=0
		}
		arrow.spr=13
		add(arrows,arrow)
		d3.att_t=d3.rate
	end
end

function manage_5s(d5)
	d5.att_t-=1
	if d5.att_t<=0 then
		priest_hitbox_detection(d5)
		d5.att_t=d5.rate
		local sh={
			x=d5.x+8,
			y=d5.y+8,
			r=2,
			tr=20,
			col=12,
			spd=2
		}
		add(shwaves,sh)	
		d5.att_t=d5.rate
	end
end

function priest_hitbox_detection(p)
	local hb={
		x1=p.x-8,
		y1=p.y-8,
		x2=p.x+23,
		y2=p.y+23,
	}
	for e in all(enemies)do
		local ehb={
			x1=e.x,
			y1=e.y,
			x2=e.x+15,
			y2=e.y+15
		}
		if(col(hb,ehb)) halo_attack(p,e)
	end
	for d in all(dice)do
		local dhb={
			x1=d.x,
			y1=d.y,
			x2=d.x+15,
			y2=d.y+15
		}
		if col(hb,dhb) then
			heal(p,d)
		end
	end
end

function die_hp()
	local d=get_die()
	if d then
		rectfill(d.x,d.y-3,d.x+15,d.y,8)
		local myhp=d.hp*15/d.maxhp
		rectfill(d.x,d.y-3,d.x+myhp,d.y,12)
	end
end

function add_die(cell,no)
	local d={
		x=cell.diex,
		y=cell.diey,
		cell=cell.id,
		maxhp=50,
		hp=50,
		upgraded=false,
		ani=1,
		att=5,
		att_t=30,
		rate=30
	}
	d.type=no
	if d.type==1 then
		d.spr=1
	elseif d.type==2 then
		d.spr=33
		d.att=10
	elseif d.type==3 then
		d.spr=5
	elseif d.type==4 then
		d.spr=37
		d.maxhp=100
		d.hp=100
	elseif d.type==5 then
		d.spr=9
		d.heal_v=1
	end
	add(dice,d)
end
-->8
--enemy functions

function spawn_enemies()
	spawn_timer=spawn_timer+1+count(dice)*0.05
	if spawn_timer>=spawn_rate
	and enemy_counter>0 then 
		add_enemy()
--todo: spawn more types
		spawn_timer=0
		enemy_counter-=1
	end
end

function spawn_horde()
	for i=1,#enemy_spawny do
		local myen=add_enemy(true)
		myen.y=enemy_spawny[i]
		add(enemies,myen)
	end
	for j=1,90 do
		yield()
	end
	for i=1,#enemy_spawny do
		local myen=add_enemy(true)
		myen.y=enemy_spawny[i]
		add(enemies,myen)
	end
	c_horde=nil
end

function add_enemy(is_horde)
	local myen={
		x=enemy_spawnx,
		y=rnd(enemy_spawny),
		ani=0,
		wait=false,
		rate=30,
		att_t=30,
		combat=false
	}
	myen=spawnd4(myen)
	if is_horde then return myen
	else	add(enemies,myen)
	end
end
function spawnd4(d4)
	d4.type=4
	d4.spr1=100
	d4.spr2=102
	d4.hp=50
	d4.spd=0.3
	d4.att=5
	return d4
end

function manage_enemies()
	for e in all(enemies) do
		if(e.hp<=0)kill(enemies,e,"enemy")
		e.ani+=1
		if(e.ani>20)e.ani=0
		wait(e)
		if(not e.combat and not e.wait)	e.x-=e.spd
		if e.x<=-16 then
			del(enemies,e)
			enemy_kills+=1
			lives-=1
		end
		if(e.type==4)manage_d4s(e)
	end
end

function draw_enemies()
	for e in all(enemies) do
		local myspr=0
		if e.ani<=10 then
			myspr=e.spr1
		else
			myspr=e.spr2
		end
		spr(myspr,e.x,e.y,2,2)
	end
end

function manage_d4s(d4)			
	local d=enemy_hitbox_detection(d4,dice)
	if not d then
		d4.combat=false
	else
		d4.combat=true
		if(attack(d4,d,"enemy")) kill(dice,d,"ally")
	end
end

function wait(e)
		if not enemy_hitbox_detection(e,enemies) then
			e.wait=false
		else e.wait=true
		end
end
-->8
--combat functions

function enemy_hitbox_detection(ch,table)
	local obj=nil
	local hitbox={
	x1=ch.x,
	y1=ch.y+8,
	x2=ch.x+8,
	y2=ch.y+10
	}
	for d in all(table) do
		local d_hitbox={
			x1=d.x+18,
			y1=d.y+6,
			x2=d.x+20,
			y2=d.y+12
		}
		if (col(hitbox,d_hitbox))obj=d
	end
	return obj
end

function ally_hitbox_detection(ch,is_long)
	local obj=nil
	local long=0
	if(is_long)long=100
	local hitbox={
		x1=ch.x+20,
		y1=ch.y+6,
		x2=ch.x+22,
		y2=ch.y+12
	}
	for d in all(enemies) do
		local d_hitbox={
			x1=d.x,
			y1=d.y+8,
			x2=d.x+8,
			y2=d.y+10
		}
		if (col(hitbox,d_hitbox))obj=d
	end
	return obj
end

function arrow_hitbox_detection(a)
	local obj=nil
	local hitbox={
		x1=a.x,
		y1=a.y+4,
		x2=a.x+7,
		y2=a.y+6
	}
	for d in all(enemies) do
		local d_hitbox={
			x1=d.x,
			y1=d.y,
			x2=d.x+15,
			y2=d.y+15
		}
		if (col(hitbox,d_hitbox))obj=d
	end
	return obj
end

function attack(d,r,source)
	d.att_t-=1
	if d.att_t<=0 then
		d.att_t=d.rate
		r.hp-=d.att
		local ci={
			value=d.att,
			col=8,
			life=10,
			x=r.x+5,
			y=r.y,
			dy=-1
		}
		add(combat_info,ci)
		local ani={
			x=r.x+5,
			y=r.y+5,
			life=10
			}
		if (source=="enemy")ani.spr=70
		if (source=="ally")ani.spr=73
		if (source=="arrow")ani.spr=76
		add(att_ani,ani)
	end
end

function manage_arrows()
	for a in all(arrows) do
		a.x+=2
		if(a.x>128)del(arrows,a)
		local d=arrow_hitbox_detection(a)
		if d then
			attack(a,d,"arrow")
			del(arrows,a)
		end
	end
end

function draw_arrows()
	for a in all(arrows) do
		spr(a.spr,a.x,a.y)
	end
end

function kill(t,i,side)
	--todo death particles
	if(side=="ally")grid[i.cell].used=false
	if(side=="enemy")enemy_kills+=1
	del(t,i)
end

function col(a,b)
	local a_left=a.x1
	local b_left=b.x1
	local a_top=a.y1
	local b_top=b.y1
	local a_right=a.x2
	local b_right=b.x2
	local a_bottom=a.y2
	local b_bottom=b.y2
	
	if a_top>b_bottom then return false end
	if b_top>a_bottom then return false end
	if a_right<b_left then return false end
	if b_right<a_left then return false end
	
	return true
end

function heal(p,d)
	if p.cell!=d.cell then
		d.hp+=p.heal_v
		if(d.hp>d.maxhp)d.hp=d.maxhp
		local ci={
			value=p.heal_v,
			col=12,
			life=10,
			x=d.x+5,
			y=d.y,
			dy=-1
		}
		add(combat_info,ci)
	end
end

function halo_attack(p,e)
	e.hp-=p.att
	local ci={
		value=p.att,
		col=8,
		life=10,
		x=e.x+5,
		y=e.y,
		dy=-1
	}
	add(combat_info,ci)
end
-->8
--wave logic

function manage_waves()
	if mode=="wave" then
	 if c_pause and costatus(c_pause)!="dead"then
			coresume(c_pause)
		else
			mode="game"
			c_pause=nil
		end
	elseif mode=="horde" then
		if c_pause and costatus(c_pause)!="dead"then
			coresume(c_pause)			
		elseif c_horde and costatus(c_horde)!="dead"then
			coresume(c_horde)
		else
			mode="game"
			has_horde=true
			c_pause=nil
			c_horde=nil
		end
	end
	if enemy_kills==10 then
		if not has_horde then
			mode="horde"
			enemy_kills=0
			c_pause=cocreate(pause)
			c_horde=cocreate(spawn_horde)
		else
			enemy_kills=0
			has_horde=false
			mode="win"
			
			
		end	
	end
end

function pause()
	for i=0,90 do
		yield()
	end
end
__gfx__
00000000555000000000000000000000000000000000000bbb000000000000000000000000000077770000000000000000000000000000000006600000000000
0000000055550000000000000000000000000000000000bbbbb04400000000000000000000000775577000000000000000000000000000000006600000000000
007007005555009999000000000000000000000000000bbbbbbb440000000000000000007a907755557700000000000000000000000000000006600000000000
00077000555009999990000000000000000000000700bbbbbbbb74400000000000000000aa977555555770000000000000000000dd0000700006600000000000
00077000040999999999900000006666666600007770666666667440000066666666000099876666666670000000666666660000044444770006600000000000
00700700040066666666000000006666666600000400688666667044000066666666000004006886688600000000666666660000dd0000700006600000000000
000000000400666666660000000066666666000004ff688666667044000066666666000004ff68866886ff000000666666660000000000000006600000000000
0000000004ff66688666ff00000066666666000004f0666886667f44000066666666000004f0666886660ff00000666666660000000000000006600000000000
0880088004f0666886660ff00000666666660000040066688666704f000066666666000004006668866600ff0000666666660000760000000000006700000000
88888888f4006666666600ff00006666666600000f0066666886704f00006666666600000f006886688600ff0000666666660000760000000000006700000000
88888888f4006666666600ff0000666666660000040066666886744000006666666600000f006886688600000000666666660000760000000000006700000000
8888888804006666666600000000666666660000d4d0666666667440000066666666000004006666666600000000666666660000760000000000006700000000
0888888044000f0000f000000000000000000000d0d00f00000f4400000000000000000004007777777700000000000000000000760000000000006700000000
088888800400ff0000ff000000000000000000000000ff00000f4400000000000000000004077777777770000000000000000000760000000000006700000000
00888800040fff0000fff0000000000000000000000fff00000fff00000000000000000004777777777777000000000000000000760000000000006700000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000760000000000006700000000
088008800000000dd000000000000000000000000000000dd00000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
81188118000000dddd0000070000000000000000000000dddd0000000000000000000000a99990000009999a7766666666666666667777666666667700000000
8111111800000dddddd00077000000000000000000000dddddd000000000000000000000a90000000000009a7660000000000000006666000000066700000000
811111180000dddddddd007700000000000000000000dddddddd00000000000000000000a90000000000009a7600000000000000000660000000006700000000
08111180000dddddddddd0770000666666660000000d66666666d0000000666666660000a90000000000009a7600000000000000000660000000006700000000
08111180000d688dd666d0770000666666660000000d6886644444440000666666660000a00000000000000a7600000000000000000660000000006700000000
008118000000688dd666007700006666666600000000688664474744000066666666000000000000000000007600000000000000000660000000006700000000
0008800000dd66666666dd77000066666666000000dd666666444440000066666666000000000000000000007600000000000000000660000000006700000000
000000000dd0666666660d7700006666666600000dd0666666444440000066666666000000000000000000007600000000000000000660000000006700000000
00000000dd006666688600440000666666660000dd00688668474740000066666666000000000000000000007600000000000000000660000000006700000000
00000000dd0066666886004d0000666666660000dd006886688444000000666666660000a00000000000000a7600000000000000000660000000006700000000
000000000000666666660040000066666666000000006666666444000000666666660000a90000000000009a7600000000000000000660000000006700000000
0000000000000d0000d00000000000000000000000000d0000d040000000000000000000a90000000000009a7600000000000000000660000000006700000000
000000000000dd0000dd000000000000000000000000dd0000dd00000000000000000000a90000000000009a7660000000000000006666000000066700000000
00000000000ddd0000ddd0000000000000000000000ddd0000ddd0000000000000000000a99990000009999a7766666666666666667777666666667700000000
000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
6666666666666666666666666666666666666666688668860990000000000000000000000077770000666600006666000000d000000000000000000000000000
6666666666666886666668866886688668866886688668869aa90000000000900000000000007770000066600000666000000d00000000000000000000000000
66666666666668866666688668866886688668866666666609900000000009a90000000000000770000006660000066600d04000000000000000000000000000
6668866666666666666886666666666666688666688668860000000000009aa909900000000000000000077700000666000d0400000d044400dd000000000000
6668866666666666666886666666666666688666688668860000000000009aa99aa990090000000000000777000006660000004400d040000004444400000000
66666666688666666886666668866886688668866666666600000000000009909aaaa9900000000000000070000006660000000000000d0000dd000000000000
66666666688666666886666668866886688668866886688600000000000000009aaa9900000000000000000000007770000000000000d0000000000000000000
66666666666666666666666666666666666666666886688600000000000000000999900000000000000000000077770000000000000000000000000000000000
00000000000000003333333333333333333333333333333300000000000000000000000037373333333333339999999900000000000000000000000000000000
0000000000000000333333333b333333333333333333344300000000007070000000000033a33333337373339999999900000000000000000000000000000000
95499954999900003333333333b3333333333333333344430000000b000a00000000000b37373333333a33339999999900000000000000000000000000000000
95444954444959003333333333b333b33333333333344433000b000b007b7000b00b000bb3333333337b73339999999900000000000000000000000000000000
45244454244454003333333333b33b333333366333444333000bb00b000b0000bb0b00bbbb333a33333b33339999999900000000000000000000000000000000
55555555555555003333333333333b33333366533ff433330333b0bb003b33000b3b33b0b333b333333bb3339999999933400099000000000000000000000000
99954999954999003333333333333b33333355633ff3333333333333333333333b3333b333333b33333b33339999999933499999000000000000000000000000
44954444954449003333333333333333333333333333333333333333333333333333333333333b33333333339999999934999999000000000000000000000000
44452444452444333333449933334499000000000000000000000008800000000000000000000000000000000000000000000000000000000000000000000000
55555555555555333333449933334499000000088000000000000008800000000000000000000000000000000000000000000000000000000000000000000000
95499954999549333334499933334499000000088000000000000082880000000000000000000000000000000000000000000000000000000000000000000000
95444954449549333334499933334499000000828800000000000822828000000000000000000000000000000000000000000000000000000000000000000000
45244452444524333334499933344999000008228280000000008212812800000000000000000000000000000000000000000000000000000000000000000000
55555555555555333334999933349999000082128128000000082122821280000000000000000000000000000000000000000000000000000000000000000000
99954999954999333334499933344999000821228212800000822222822228000000000000000000000000000000000000000000000000000000000000000000
44954444954449333333449933334499008222228222280008212222812222800000000000000000000000000000000000000000000000000000000000000000
00000000000000003333449933334499082122228122228082211221811221280000000000000000000000000000000000000000000000000000000000000000
00000000000000003334449933334999822112218112212888888222822288880000000000000000000000000000000000000000000000000000000000000000
00000000000000003334499933334499888882228222888800008882888800000000000000000000000000000000000000000000000000000000000000000000
00000000000000003333499933333499000088828888000000800808808008000000000000000000000000000000000000000000000000000000000000000000
00000000000000003333499933333499000008088080000000888000000888000000000000000000000000000000000000000000000000000000000000000000
00000000000000003333499933334499000080000088000000800000000008000000000000000000000000000000000000000000000000000000000000000000
00000000000000003334449933344999000080000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000003333449933334499000888800088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000008800000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000082880000000000082282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008212812800000008221181128000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00822222822228000821222282222180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82212211811221288888222188228888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008882888800000000088880800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000008800000088800000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088880008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6156575856585857585756585857565c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152545252535252525252525253635b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525552525a52525252735b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525552525252525252535952725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525353525252525254625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61525a5952525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525255635b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
615252525252525352525a525252725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6154525352525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2c2c2d2c2c2c2c2c2c2c2c2c2c2c2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d00000e00000000000000000000001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3c3c3d3c3c3c3c3c3c3c3c3c3c3c3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
