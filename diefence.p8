pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--die-fence
--by treveron

--todo
--wave 2
--particles
----dust under enemies
--wall explosion/camera shake

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
	t=0
	rnd_tiles()
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
	ui_dicex=5
	ui_dicey=112
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
	enemy_types={4}
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
	
	particles={}
	flames={}
	fire()
end

function update_game()
t+=1
if(t%3==0)fire()
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
	manage_particles()
	manage_fire()
	debug=#att_ani
end

function draw_game()
	cls()
	draw_fire()
	map()
	draw_lives()
	draw_selector()
	left_ui()
	right_ui()
	draw_dice()
	draw_enemies()
	draw_att_ani()
	draw_arrows()
	draw_shwaves()
	die_hp()
	draw_ci()
	draw_particles()
	print(debug,1,1,7)
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

function rnd_tiles()
	local tiles={83,84,85,90}
	for x=1,13 do
		for y=2,12 do
			local n=rnd()
				if(n<=.2)mset(x,y,rnd(tiles))
		end
	end
end

-->8
--ui functions
function draw_lives()
	pal(8,8+128)
	for i=1, 3 do
		spr(32,-8+i*9,1)
	end
	for i=1,lives do
		spr(16,-8+i*9,1)
	end
	pal()
end
function left_ui()
	spr(63+ui_dice,ui_dicex,ui_dicey)
	local col=8
	if(can_roll and not die_loaded	and mode!="wave")col=blink(true)
	rect(15,108,24,123,7)
	rectfill(17,121-roll_bar,22,121,col)
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
	small_explosion(ui_dicex+4,ui_dicey+4)
	while #dice==0 and ui_dice==6 do
		ui_dice=flr(rnd(6))+1
		small_explosion(ui_dicex+4,ui_dicey+4)
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
				if d.upgraded then
					t1="full health!"
				elseif d.type==1 then 
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

function blink(bar)
	blinkt+=1
	local blink_ani={5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5,5}
	if(bar)blink_ani={8,8,8,8,8,8,8,8,8,8,9,9,10,10,9,9,8,8}
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
			explode(d,2)
			upgrading=false
			can_roll=false
			replacing=false
			roll_bar=0
		elseif d and d.upgraded then
			d.hp=d.maxhp
			local ci={
			value="full hp!",
			col=7,
			life=10,
			x=d.x-3,
			y=d.y,
			dy=-1
			}
			add(combat_info,ci)
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
		local myspr=0
		if d.ani<=10 then
			myspr=d.spr1
		else
			myspr=d.spr2
		end
		spr(myspr,d.x,d.y,2,2)
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
		d.ani+=1
		if(d.ani>20)d.ani=0
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
		d.spr1=1
		d.spr2=3
	elseif d.type==2 then
		d.spr1=33
		d.spr2=35
		d.att=10
	elseif d.type==3 then
		d.spr=5
	elseif d.type==4 then
		d.spr1=37
		d.spr2=39
		d.maxhp=100
		d.hp=100
	elseif d.type==5 then
		d.spr1=9
		d.spr2=11
		d.heal_v=1
	end
	add(dice,d)
	explode(d,1)
end
-->8
--enemy functions

function spawn_enemies()
	spawn_timer=spawn_timer+1+count(dice)*0.05
	if spawn_timer>=spawn_rate
	and enemy_counter>0 then 
		add_enemy(4)
--todo: spawn more types
		spawn_timer=0
		enemy_counter-=1
	end
end

function spawn_horde()
	for i=1,#enemy_spawny do
		local myen=add_enemy(4,true)
		myen.y=enemy_spawny[i]
		add(enemies,myen)
	end
	for j=1,90 do
		yield()
	end
	for i=1,#enemy_spawny do
		local myen=add_enemy(8,true)
		myen.y=enemy_spawny[i]
		add(enemies,myen)
	end
	c_horde=nil
end

function add_enemy(d,is_horde)
	local myen={
		x=enemy_spawnx,
		y=rnd(enemy_spawny),
		ani=0,
		wait=false,
		rate=30,
		att_t=30,
		combat=false
	}
	if(d==4)myen=spawnd4(myen)
	if(d==8)myen=spawnd8(myen)
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

function spawnd8(d8)
	d8.type=8
	d8.spr1=104
	d8.spr2=106
	d8.hp=100
	d8.spd=0.3
	d8.att=10
	return d8
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
		if(e.type==4 or e.type==8)manage_d4s(e)
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
			col=10,
			life=10,
			x=r.x+5,
			y=r.y,
			dy=-1
		}
		add(combat_info,ci)
		if source=="enemy" or source=="ally" then
			local ani={
				x=r.x+5,
				y=r.y+5,
				life=10
				}
			if (source=="enemy")ani.spr=70
			if (source=="ally")ani.spr=73
			add(att_ani,ani)
		end
		att_particles(r,source)
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
	if(side=="ally")grid[i.cell].used=false
	if(side=="enemy")enemy_kills+=1
	explode(i,3)
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
		col=10,
		life=10,
		x=e.x+5,
		y=e.y,
		dy=-1
	}
	add(combat_info,ci)
	att_particles(p,"ally")
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
-->8
--particles

function explode(d,case)
	local colors={
		{5,6,7},
		{3,10,11},
		{8,14,2}
	}
	for i=1, 15 do
		local myp={
			x=d.x+8,
			y=d.y+8,
			sx=rnd()*5-2.5,
			sy=rnd()*5-2.5,
			age=10+rnd(10),
			size=2+rnd(5),
			col=rnd(colors[case])
		}
		add(particles,myp)
	end
end

function small_explosion(x,y)
	local colors={5,6,7,8}
	for i=1, 20 do
		local myp={
			x=x,
			y=y,
			sx=rnd()*5-2.5,
			sy=rnd()*5-2.5,
			age=10+rnd(10),
			isp=true,
			col=rnd(colors)
		}
		add(particles,myp)
	end
end

function att_particles(r,source)
	local colors={7,8,9,10}
	for i=1, 15 do
		local myp={
			x=r.x+5,
			y=r.y+5,
			sx=rnd()*5,
			sy=rnd()*-2.5,
			age=10+rnd(10),
			isp=true,
			col=rnd(colors)
		}
		if(source=="enemy")myp.sx*=-1
		add(particles,myp)
	end
	
end

function manage_particles()
	for p in all(particles) do
		p.x+=p.sx
		p.y+=p.sy
		p.age-=1
		if p.isp then
			if(p.age<=0)del(particles,p)
		else
			if(p.age<=0)p.size-=1
			if(p.size<=0)del(particles,p)
		end
	end
end

function draw_particles()
		for p in all(particles) do
			if p.isp then
				pset(p.x,p.y,p.col)
			else
				circfill(p.x,p.y,p.size,p.col)
			end
		end
end

function fire()
	for x=0,128,2 do
		local n=rnd()
		if n<=.5 then
			local fl={
				x=x+rnd()*2-2,
				y=rnd()*5+12,
				sy=rnd()+.1,
				age=10+rnd(10),
				size=2+rnd(),
				col=10		
			}
			add(flames,fl)
		end
	end
end

function manage_fire()
	for fl in all(flames) do
		fl.y-=fl.sy
		fl.age-=1
		if fl.age>16 then
			fl.col=10
		elseif fl.age>12 then
			fl.col=9
		elseif fl.age>8 then
			fl.col=8
		elseif fl.age>4 then
			fl.col=2
		elseif fl.age>0 then
			fl.col=5
		end
		--if(fl.age<=0)fl.size-=1
		fl.size-=.1
		if(fl.size<=0)del(flames,fl)
	end
end

function draw_fire()
	for fl in all(flames) do
		circfill(fl.x,fl.y,fl.size,fl.col)
	end
end

function upgrade_particles(d)
	local colors={3,7,10,11}
	for x=d.x, d.x+16 do
		local n=rnd()
		if n>=.25 then
			local myp={
				x=x,
				y=d.y+7,
				size=2+rnd(5),
				col=rnd(colors),
				sx=0,
				sy=-1-rnd(3),
				age=10+rnd(5)				
			}
			add(particles,myp)
		end
	end
end

function dust(d)
		for i=1, 15 do
		local myp={
			x=d.x+8,
			y=d.y+16,
			sx=rnd()*2.5,
			sy=rnd()*2.5,
			age=5+rnd(5),
			size=2+rnd(5),
			col=rnd(colors[case])
		}
		add(particles,myp)
	end	
end
__gfx__
00000000001100000000000000110000000000000000000000000000000000000000000000000000000000000011000000000000000000000006600000000000
000000000155100000000000015510000000000000000001100000000000000110000000001100011000000001aa100110000000000000000006600000000000
00700700015551000000000001555111111000000000001bb10011000001001bb1000000017a1117710000001a77a11771000000000000000006600000000000
0007700001551011110000000155119999110000000101bbbb114410001711bbbb1011001aaa9177771000001a77a17777100000dd0000700006600000000000
000770000141119999110000014199999999100000171bbbbbb1744101777bbbbbb144101a9997777771000001aa177777710000044444770006600000000000
00700700014199999999100001411666666100000177788666617141001418866661744101987786687710000144778668771000dd0000700006600000000000
000000000141166666611000014116666661100000141886666f7f41001418866661714101557886688710000144788668871000000000000006600000000000
00000000014ff666666ff100014ff668866ff10000141668866171f10014f668866f7f4101447668866710000144766886671000000000000006600000000000
088008801f4f16688661ff101f4f16688661ff100014f66886617141001f1668866171f101447668866710000144766886671000760000000000006700000000
888888881e4f16688661ef101e4f16666661ef10001f166668817141001416666881714101447886688710000144788668871000760000000000006700000000
88888888014116666661110001411666666111000014166668817441001416666881714101447786687771000144778668777100760000000000006700000000
888888880141066666610000014101f11f100000001411f11f11441001d4d1f11f11744101441177771ef10001441177771ef100760000000000006700000000
08888880014101f11f100000014101f11f10000001d4d1f11f10110001d1d1f11f11441001441177771110000144117777111000760000000000006700000000
0888888001411ff11ff1000001411ff11ff1000001d1dff11ff1000000101ff11ff1110001441777777100000144177777710000760000000000006700000000
00888800001001100110000000100110011000000010111001100000000001100110000001447777777710000011777777771000760000000000006700000000
00088000000000000000000000000000000000000000000000000000000000000000000000111111111100000000111111110000760000000000006700000000
088008800000000000000010000000000000001000000000000000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
811881180000001111000171000000000000017100000001100000000000000110000000a99990000009999a7766666666666666667777666666667700000000
81111118000001ddd610177100000011110017710000001d610000000000001d61000000a90000000000009a7660000000000000006666000000066700000000
8111111800001ddddd611771000001ddd6101771000001ddd6100000000001ddd6100000a90000000000009a7600000000000000000660000000006700000000
081111800001ddddddd6177100001ddddd61177100001ddddd61110000001ddddd611110a90000000000009a7600000000000000000660000000006700000000
081111800001d88dd66d17710001ddddddd617710001d886644444100001d88668444441a00000000000000a7600000000000000000660000000006700000000
008118000001d88dd66d17710001d88dd66d17710001d886647474100001d8866847474100000000000000007600000000000000000660000000006700000000
0008800000011666666117710001d88dd66d17710001166664444410000116666644444100000000000000007600000000000000000660000000006700000000
00000000001dd666666dd771001116666661d7710001d66664747410001dd6666647474100000000000000007600000000000000000660000000006700000000
00000000016d166668811441016dd666666d14410016d88668474100016d18866884741000000000000000007600000000000000000660000000006700000000
0000000001d51666688114d101d51666688114d1001d58866844410001d5188668844410a00000000000000a7600000000000000000660000000006700000000
00000000001101d11d1014100011166668811410000111d11d474100001101d11d147410a90000000000009a7600000000000000000660000000006700000000
00000000000001d11d100100000001d11d100100000001d11d141000000001d11d114100a90000000000009a7600000000000000000660000000006700000000
0000000000001dd11dd1000000001dd11dd1000000001dd11dd1000000001dd11dd11000a90000000000009a7660000000000000006666000000066700000000
000000000000011001100000000001100110000000000110011000000000011001100000a99990000009999a7766666666666666667777666666667700000000
000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
66666666666666666666666666666666666666666886688609900000000000000000000000777700006666000066660000000000000000000000000000000000
6666666666666886666668866886688668866886688668869aa90000000000900000000000007770000066600000666000000000000000000000000000000000
66666666666668866666688668866886688668866666666609900000000009a90000000000000770000006660000066600000000000000000000000000000000
6668866666666666666886666666666666688666688668860000000000009aa90990000000000000000007770000066600000000000000000000000000000000
6668866666666666666886666666666666688666688668860000000000009aa99aa9900900000000000007770000066600000000000000000000000000000000
66666666688666666886666668866886688668866666666600000000000009909aaaa99000000000000000700000066600000000000000000000000000000000
66666666688666666886666668866886688668866886688600000000000000009aaa990000000000000000000000777000000000000000000000000000000000
66666666666666666666666666666666666666666886688600000000000000000999900000000000000000000077770000000000000000000000000000000000
00000000000000003333333333333333333333333333311300000000001010000010000033131333331313339999999900000000000000000000000000000000
1111111111110000333333333b3333333333333333331441000000010171710001b1010031717133317171339999999900000000000000000000000000000000
95499954999911003333333333b3333333333333333144410001001b001a10001bb11b10331a1333331a13339999999900000000000000000000000000000000
95444954444959103333333333b333b33333311333144433001b101b017b71001b111bb131717133317b71339999999900000000000000000000000000000000
45244454244454103333333333b33b333333166131444333011bb11b001b11001b1bb1b11b131313331b13339999999911100011000000000000000000000000
55555555555555103333333333333b33333166511ff433331333b1bb113b33111b3b33b11bb131a1331bb1339999999931411199000000000000000000000000
99954999954999103333333333333b33333155611ff3333333333333333333333b3333b31b131b13331b13339999999931499999000000000000000000000000
449544449544491033333333333333333333333333333333333333333333333333333333333331b1333333339999999914999999000000000000000000000000
44452444452444133331449933314499000000000000000000000001000000000000000010000000000000000000000000000000000000000000000000000000
555555555555551333314499333144990000000010000000000000181000000000000001a1000000000000001000000000000000000000000000000000000000
95499954999549133314499933314499000000018100000000000188810000000000001aa100000000000001a100000000000000000000000000000000000000
9544495444954913331449993331449900000018881000000000018881000000000001a33a1000000000001aa100000000000000000000000000000000000000
452444524445241333144999331449990000001888100000000018282810000000001a9939a10000000001aa9a10000000000000000000000000000000000000
55555555555555133314999933149999000001828281000000018f28f28100000001a999399a100000001a9a33a1000000000000000000000000000000000000
99954999954999133314499933144999000018f28f28100000018f28f2810000001a99999999a1000001a39a939a100000000000000000000000000000000000
44954444954449133331449933314499000018f28f281000001822282228100001aaaaaaaaaaaa10001a933a9999a10000000000000000000000000000000000
0000000000000000333144993331449900018222822281000182222822228100001a99939999a10001aa999a9999aa1000000000000000000000000000000000
000000000000000033144499333149990018222282222810018f2228f22281000001a993999a10000019aa9a99aa910000000000000000000000000000000000
000000000000000033144999333144990018f2228f222810188ff2f8ff2f881000001a9339a10000000199aa9a99100000000000000000000000000000000000
000000000000000033314999333314990188ff2f8ff2f8810118882828881100000001a99a1000000000193aa931000000000000000000000000000000000000
00000000000000003331499933331499001188828288811001818188818110000000001aa100000000000199a910000000000000000000000000000000000000
0000000000000000333149993331449900001818881810000188111111188100000000011000000000000019a100000000000000000000000000000000000000
00000000000000003314449933144999000188111118810000110000000181000000000000000000000000011000000000000000000000000000000000000000
00000000000000003331449933314499000011000001100000000000000010000000000000000000000000000000000000000000000000000000000000000000
__map__
5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6156575856585857585756585857565c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252635b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252735b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252635b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2c2c2d2c2c2c2c2c2c2c2c2c2c2c2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d00000e00000000000000000000001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3c3c3d3c3c3c3c3c3c3c3c3c3c3c3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
