pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--die-fence
--by treveron

--todo
--optimize particle code
--use arrays to optimize upgrades

function _init()
	version="2.0"
	t=0
	mode="title"
	is_easy=false
	blinkt=0
	blinkb=0
	diff_pos={
		{x=72,y=88, diff="normal"},
		{x=72,y=98, diff="easy"},
		{x=72,y=108, diff="tutorial"},		
	}
	current_dpos=1
	title_dice={}	
	flames={}
	
	tut_dice={
		{1,
		[[peasant: low attack,
increases roll bar speed]]
		},
		{33,
		[[soldier: high attack]]
		},
		{5,
		[[archer: low attack,
high range]]
		},
		{37,
		[[shield bearer: very high hp
but does not attack]]
		},
		{9,
		[[priest:attack enemies and
heal allies around them]]
		}
	}
page=1
end

function _update()
	if mode=="title" then
		update_title()
	elseif mode=="tutorial" then
		update_tutorial()
	else
		update_game()
	end
end

function _draw()
	if mode=="title" then
		draw_title()
	elseif mode=="tutorial" then
		draw_tutorial()
	else
		draw_game()
	end
end

function update_title()
	if btnp(❎)or btnp(🅾️) then
	 if(current_dpos==1 or current_dpos==2)start_game()
	 if(current_dpos==3)mode="tutorial"
	end
	diff_select()	
	add_title_dice()
	update_title_dice()
	manage_fire()
	if(t%3==0)fire()
end

function draw_title()
	cls(0)
	map(16)
	draw_title_dice()
	draw_fire()
	for opt in all(diff_pos) do
		print(opt.diff,opt.x+8,opt.y+1,9)
	end 
	spr(48,diff_pos[current_dpos].x,diff_pos[current_dpos].y)
	print("v "..version,1,1,7)
	print("by @trevvieaamb",65,120,7)
end

function update_tutorial()
	if btnp(❎)or btnp(🅾️) then 
		page+=1
		if page>2 then
			mode="title"
			page=1
		end
	end
end

function draw_tutorial()
	cls()
	if page==1 then
		print([[
		roll the dice 
		and defend the wall!
		]],2,2,7)
		for i=1,5 do
			spr(tut_dice[i][1],3,18*i,2,2)
			print(tut_dice[i][2],20,18*i+2,7)
		end
		print("🅾️ or ❎ next page",1,120,blink())
	elseif page==2 then
		print(		[[roll a 6 and select a die
to upgrade it! upgrading 
makes them more powerful and
heals them! selecting an
already upgraded die 
just heals them!
press 🅾️ if you
don't need an upgrade
for a free reroll!

recycle! if you don't need
the die you just rolled
press 🅾️ to try again
with 50% of the roll bar!

replace! you can put a die
on top of another to
replace it!]],2,2,7)
		print("🅾️ or ❎ to go back to title",1,120,blink())	
	end
end

function start_game()
	music(0,0,7)
	is_easy=false
	if(diff_pos[current_dpos].diff=="easy")is_easy=true
	rnd_tiles()
	mode="wave"
	p_rolls=0
	if is_easy then 
		mode="easy"
		p_rolls=5
	else
		sfx(20,0,4)
	end
	has_horde=false
	shake=0
	flames={}
	
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
	ui_dicey=115
	die_ani=0
	animate_die=false	
	dice={}

	ruix=32
	ruiy_l1=108
	ruiy_l2=114
	ruiy_l3=120
	blinkt=1
	
	enemy_spawnx=134
	enemy_spawny={10,28,46,64,82}
	wave_enemies={
		{4,4,4,4,4,4,4,4,4,4},
		{4,4,4,4,4,4,4,8,8,8,8,8,8,8,8},
		{4,4,4,4,4,4,4,12,12,8,8,8,8,8,8,8,8},
		{4,4,4,4,4,8,8,12,12,12,12,8,8,8,8,8,8,8,8}
	}
	
	enemies={}
	d12s={}
	m_missiles={}
	spawn_timer=0	
	spawn_rate=150
	combat_info={}	
	att_ani={}
	arrows={}
	shwaves={}
	row_cleaners={}
	
	wave=1
	loop=false
	enemy_counter=10
	c_pause=cocreate(pause)
	c_horde=nil
	replacing=false
	upgrading=false	
	particles={}
	fire()
	init_boss()
end

function update_game()
	t+=1
	we=wave_enemies[wave]
	if(t%3==0)fire()
	manage_waves()
	if mode!="over" and mode!="win" then
		if not replacing then
			if(btnp(0))select_cell(-1)
			if(btnp(1))select_cell(1)
			if(btnp(2))select_cell(-5)
			if(btnp(3))select_cell(5)
			if(p_rolls==0)recycle()
			if(upgrading)upgrade()
		end
		roll()
		if (animate_die)animate_roll()
	end	
	if replacing then 
		is_replacing()
		if(btnp(🅾️))replacing=false
		if(btnp(❎))replace()		
	else
		set_dice()
	end
	
	if(mode=="game")spawn_enemies()

	if(loop and (btnp(🅾️) or btnp(❎)))mode="title"
	
	manage_enemies()
	manage_d12s()
	manage_missiles()
	manage_dice()
	manage_ci()
	manage_att_ani()
	manage_arrows()
	manage_particles()
	manage_fire()
	manage_row_cleaners()
	manage_fireball()
	manage_orbs()
	camera_shake()
	if mode=="boss" then
		manage_boss()
	end
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
	draw_d12s()
	if mode=="boss" then
		draw_boss()
		boss_hp()
		if(boss.beaming)draw_beam()
	end
	draw_particles()
	draw_missiles()
	if(not boss.isdead) draw_orbs()
	draw_att_ani()
	draw_arrows()
	draw_shwaves()
	die_hp()
	draw_row_cleaners()
	draw_fireball()
	draw_ci()
	if(die_loaded)preview()
	if(upgrading)show_upg()
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
	for i=1, 3 do
		spr(136,-1+i*4,107)
	end
	for i=1,lives do
		spr(135,-1+i*4,107)
	end
end
function left_ui()
	spr(63+ui_dice,ui_dicex,ui_dicey)
	if not animate_die
	and not die_loaded 
	and not upgrading	
	then
		spr(15,ui_dicex,ui_dicey)
	end
	local col=8
	if(can_roll and not die_loaded)col=blink(true)
	rect(16,108,24,123,7)
	rectfill(18,121-roll_bar,22,121,col)
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
		and not die_loaded
		and not upgrading then
			animate_die=true
	end
end

function animate_roll()
	sfx(18)
	die_ani+=1
	ui_dice+=1
	if(ui_dice>6)ui_dice=1 
	if die_ani>=30 then
		sfx(19)
		ui_dice=flr(rnd(6))+1
		small_explosion(ui_dicex+4,ui_dicey+4)
		while (#dice==0 or p_rolls>0) 
		and ui_dice==6 do
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
	if loop then
		t3="🅾️/❎ to restart"
		print(t3,ruix,ruiy_l3,7)	
	end
	if mode=="wave" then
		t2="wave "..wave
		print(t2,ruix,ruiy_l2,blink())
	elseif mode=="horde" then
		t2="horde incoming!"
		print(t2,ruix,ruiy_l2,blink())	
	elseif mode=="boss_w" then
		t2="true evil approaching!"
		print(t2,ruix,ruiy_l2,blink())		
	elseif mode=="win" then
		t1=[[evil has been
defeated!]]
		print(t1,ruix,ruiy_l1,blink())
	elseif mode=="over" then
		t1="game over..."
		print(t1,ruix,ruiy_l1,blink())	
	else
		if replacing then
			t1="replace dice?"
			t2="❎yes 🅾️no"
		elseif upgrading then
			t1="upgrade die!"
			t3="🅾️ for free reroll"
			local d=get_die()
			if d and not d.evil then
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
			if(mode=="easy")t1="5 free dice!"
			if(can_roll and not die_loaded)t2="press ❎ to roll!"
			if(die_loaded and (mode=="game" or mode=="post_horde"))t3="🅾️ to recycle(1/2 rbar)"
			if(die_loaded and mode=="easy")t3=p_rolls.." dice to start"
			if(die_loaded and ui_dice==1)t1="❎:place peasant" t2="(⬆️ roll bar spd)"
			if(die_loaded and ui_dice==2)t1="❎:place soldier" t2="(cq combat)"
			if(die_loaded and ui_dice==3)t1="❎:place archer" t2="(ranged combat)"
			if(die_loaded and ui_dice==4)t1="❎:place shield bearer" t2="(high hp)"
			if(die_loaded and ui_dice==5)t1="❎:place priest" t2="(healing halo)"
		end
		print(t1,ruix,ruiy_l1,7)
		print(t2,ruix,ruiy_l2,7)
		print(t3,ruix,ruiy_l3,7)
	end
end

function recycle()
	if die_loaded and btnp(🅾️) then
		die_loaded=false
		roll_bar=5
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
		print(ci.value,ci.x-1,ci.y,1)
		print(ci.value,ci.x+1,ci.y,1)
		print(ci.value,ci.x,ci.y-1,1)
		print(ci.value,ci.x,ci.y+1,1)
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
		if	sh.tr>sh.r then
			sh.r+=sh.spd
		else 
			sh.r-=sh.spd
		end
			circ(sh.x,sh.y,sh.r,sh.col)
			if sh.r==sh.tr then
				del(shwaves,sh)
			end
	end
end

function blink(bar)
	local blink_ani={5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5,5}
	local b=1
	if bar then
		blink_ani={8,8,8,8,8,8,8,8,8,8,9,9,10,10,9,9,8,8}
		blinkb+=1
		b=blinkb
	else
		blinkt+=1
		b=blinkt
	end
	if b>=#blink_ani then
		if bar then
			blinkb=0
		else
			blinkt=0
		end
	end
	return blink_ani[b]
end

function camera_shake()
	local shakey=shake
	local shakex=shake
	if flr(rnd(2))==0 then
		shakex*=-1
	end
		if flr(rnd(2))==0 then
		shakey*=-1
	end
	camera(shakex,shakey)
	if(shake>0)shake-=1
end

function diff_select()
	if btnp(⬆️) then
		current_dpos-=1
		if(current_dpos<1)current_dpos=3
	end
	if btnp(⬇️) then
		current_dpos+=1
		if(current_dpos>3)current_dpos=1
	end
end

function preview()
	local sprites={1,33,5,37,9}
	local even=true
	for g in all(grid) do
		if g.selected then
			spr(sprites[ui_dice],g.diex,g.diey,2,2)
			if(g.used)pal(1,8)
			spr(15,g.diex,g.diey)
			spr(15,g.diex+8,g.diey)
			spr(15,g.diex,g.diey+8)
			spr(15,g.diex+8,g.diey+8)
			pal()
		end
	end
end

function add_title_dice()
	t+=1
	if t%10==0 then
		local d={
			sp=64+flr(rnd(6)),
			x=flr(rnd(120)),
			y=-8,
			dy=0,
			acc=0.1
		}
		add(title_dice,d)
	end
end

function update_title_dice()
	for d in all(title_dice) do
		d.dy+=d.acc
		d.y+=d.dy
		if(d.y>=128)del(title_dice,d)
	end
end

function draw_title_dice()
	for d in all(title_dice) do
		spr(d.sp,d.x,d.y)
	end
end
-->8
--dice functions

function set_dice()
	if btnp(❎) and die_loaded then
		for c in all(grid) do
			if c.selected and c.used==false then		
				add_die(c,ui_dice)		
				die_loaded=false
				can_roll=false
				c.used=true
				sfx(13)
				if mode=="easy" then
					roll_bar=10
					p_rolls-=1
					if(p_rolls<=0)mode="wave" roll_bar=0 sfx(20,0,4)
				else
					roll_bar=0
				end
				return
			elseif c.selected and c.used and not replacing then
				local d=get_die()
				if(not d)return --sfx
				if(not d.evil)replacing=true
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
	if btnp(❎) then
		local d=get_die()
		if d and not d.upgraded and not d.evil then
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
			sfx(12)
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
			sfx(12)
		end
	elseif btnp(🅾️) then
		upgrading=false
		animate_die=true
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
		local flp=false
		if d.upgraded then
			pal(6,1)
			pal(8,10)
		elseif d.evil then
			pal(8,2)
			pal(6,8)		
			flp=true
		end
		local myspr=0
		if d.ani<=10 then
			myspr=d.spr1
		else
			myspr=d.spr2
		end
		spr(myspr,d.x,d.y,2,2,flp)
		pal()
	end
end

function count_d1s()
	local d1s=0
	for d in all(dice) do
		if d.type==1 and not d.evil then
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
	local d=nil
	if not d2.evil then
		d=ally_hitbox_detection(d2)
	else
		d=enemy_hitbox_detection(d2,dice)	
	end
	if d!=nil then
		attack(d2,d,"ally")
	end
end

function manage_3s(d3)			
	d3.att_t-=1
	if(d3.att_t<=0)then
		local arrow={
			x=d3.x+14,
			y=d3.y+4,
			att=5,
			att_t=0,
			rate=0
		}
		arrow.spr=13
		if d3.evil then 
			arrow.evil=true
			arrow.x=d3.x-6
		end
		add(arrows,arrow)
		d3.att_t=d3.rate
		sfx(15)
	end
end

function manage_5s(d5)
	d5.att_t-=1
	if d5.att_t<=0 then
		priest_hitbox_detection(d5)
		d5.att_t=d5.rate
		local mycol=11
		if(d5.evil)mycol=8
		local sh={
			x=d5.x+8,
			y=d5.y+8,
			r=2,
			tr=20,
			col=mycol,
			spd=2
		}
		add(shwaves,sh)	
		d5.att_t=d5.rate
		sfx(11)
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
		local ehb=set_hitbox_2(e)
		if(col(hb,ehb)and not p.evil) halo_attack(p,e)
	end
	for e in all(d12s)do
		local ehb=set_hitbox_2(e)
		if(col(hb,ehb)and not p.evil) halo_attack(p,e)
	end
	for d in all(dice)do
		local dhb=set_hitbox_2(d)
		if col(hb,dhb)then
			if(not p.evil and not d.evil)then
				heal(p,d)
			else
			 if(p.cell!=d.cell)halo_attack(p,d)
			end
		end
	end
	if boss.isin then
		local bhb=set_hitbox_2(boss)
		if(col(hb,bhb) and not p.evil)halo_attack(p,boss)
	end
end

function die_hp()
	local d=get_die()
	if d then
		rectfill(d.x-1,d.y-4,d.x+16,d.y+1,1)
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
		b_mhp=50,
		hp=50,
		upgraded=false,
		ani=1,
		b_att=5,
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
		d.b_att=10
	elseif d.type==3 then
		d.spr1=5
		d.spr2=7
	elseif d.type==4 then
		d.spr1=37
		d.spr2=39
		d.b_mhp=100
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

function show_upg()
	for d in all(dice) do
		if not d.evil then
			if d.upgraded then
				spr(133,d.x+10,d.y-2)
			else
				spr(134,d.x+10,d.y-2)
			end
		end
	end
end
-->8
--enemy functions

function spawn_enemies()
	spawn_timer=spawn_timer+1+count(dice)*0.05
	if spawn_timer>=spawn_rate
	and #we>0 
	and not has_horde then 
		local e=rnd(we)
		add_enemy(e)
		del(we,e)
		spawn_timer=0
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
		local d=4
		if(wave==2 or wave==3)d=8
		local myen=add_enemy(d,true)
		myen.y=enemy_spawny[i]
		add(enemies,myen)
	end
	if wave==3 then
		for j=1,90 do
			yield()
		end
		for i=1,2 do
			local myen=add_enemy(12,true)
			add(d12s,myen)
		end	
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
	if(d==12)myen=spawnd12(myen)
	if is_horde then return myen
	elseif d==12 then
		add(d12s,myen)
	else
		add(enemies,myen)
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

function spawnd12(d12)
	d12.type=12
	d12.spr1=108
	d12.spr2=110
	d12.hp=50
	d12.spd=0.3
	d12.att=10
	d12.phase=1
	d12.charge=0
	d12.fullcharge=150
	return d12
end

function manage_enemies()
	for e in all(enemies) do
		if(e.hp<=0)kill(enemies,e,"enemy")
		e.ani+=1
		if(e.ani==10 or e.ani==20)dust(e)
		if(e.type==8 and (e.ani==5 or  e.ani==15))dust(e)
		if(e.ani>20)e.ani=0
		wait(e)
		if(not e.combat and not e.wait)	e.x-=e.spd
		if e.x<=-6 then
			lives-=1
			explode(e,3)
			shake=4
			sfx(16)
			local r={
				x=e.x,
				y=e.y+3,
				r=5,
				col=7,
			}
			add(row_cleaners,r)
			del(enemies,e)
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
	if not d or d4.wait or d.evil then
		d4.combat=false
	else
		d4.combat=true
		if(attack(d4,d,"enemy")) kill(dice,d,"ally")
	end
end

function manage_d12s()
	for d in all(d12s) do
		if(d.hp<=0) then
			check_missiles(d)
			kill(d12s,d,"enemy")
		end
		if d.phase==1 then			
			wait(d)
			d.ani+=1
			if(d.ani>=20)d.ani=0
			if(d.ani==10 or d.ani==20)dust(d)
			if(not d.wait)	d.x-=d.spd
			if(d.x<=108)d.phase=2
		elseif d.phase==2 then
			if (t%3==0) dust(d)
			if(d.charge<d.fullcharge)	d.charge+=1
			if d.charge%15==0 and d.charge<d.fullcharge then --shwave
				local sh={
					x=d.x+2,
					y=d.y+3,
					r=20,
					tr=2,
					col=12,
					spd=1
				}
				add(shwaves,sh)	
				sfx(23,0,4)
			end
			if d.charge>=d.fullcharge and #dice>0 then
				d.charge=0
				d.phase=3			
				sfx(22,0,4)
				local m={
					x=d.x+2,
					y=d.y+3,
					y_limit=d.y-100,
					r=5,
					col=7,
					phase=1,
					obj=rnd(dice),
					spd1=5,
					spd2=1,
					att=50,
					owner=d
				}
				add(m_missiles,m)
			end			
		end	
	end
end

function draw_d12s()
	for d in all(d12s) do
		if d.phase==1 then
			local myspr=0
			if d.ani<=10 then
				myspr=d.spr1
			else
				myspr=d.spr2
			end
			spr(myspr,d.x,d.y,2,2)
		elseif d.phase==2 then
			spr(d.spr1,d.x,d.y,2,2)
			circfill(d.x+2,d.y+3,d.charge/30+1,12)
			circfill(d.x+2,d.y+3,d.charge/30,7)
		elseif d.phase==3 then
			spr(d.spr1,d.x,d.y,2,2)
		end
	end
end

function manage_missiles()
	for m in all(m_missiles) do
		if t%10==0 then
		local sh={
			x=m.obj.x+8,
			y=m.obj.y+8,
			r=2,
			tr=20,
			col=12,
			spd=2
		}
		add(shwaves,sh)
		sfx(24,0,4)
		end
		if m.phase==1 then
			m.y-=m.spd1
			if m.y<=m.y_limit then
				m.phase=2
				m.x=m.obj.x+8
			end
		else
			m.y+=m.spd2
			if m.y==m.obj.y+8 then
				explode(m.obj,4)
				missile_hitbox_detection(m)
				m.owner.phase=2
				del(m_missiles,m)
				shake=4
			end
		end
		if t%3==0 then
			local myp={
				x=m.x,
				y=m.y,
				sx=0,
				sy=0,
				age=5,
				size=7,
				col=12,
				trace=true
			}
			add(particles,myp)
		end	
	end
end

function missile_hitbox_detection(p)
	local hb={
		x1=p.x-16,
		y1=p.y-16,
		x2=p.x+16,
		y2=p.y+16,
	}
	for e in all(dice)do
		local ehb={
			x1=e.x,
			y1=e.y,
			x2=e.x+15,
			y2=e.y+15
		}
		if(col(hb,ehb)) halo_attack(p,e)
	end
	for e in all(enemies)do
		local ehb={
			x1=e.x,
			y1=e.y,
			x2=e.x+15,
			y2=e.y+15
		}
		if(col(hb,ehb)) halo_attack(p,e)
	end
end

function draw_missiles()
	for m in all(m_missiles) do
		circfill(m.x,m.y,m.r,m.col)
	end
end

function wait(e)
		if not enemy_hitbox_detection(e,enemies)
		and not enemy_hitbox_detection(e,d12s)
	 then
			e.wait=false
		elseif enemy_hitbox_detection(e,dice)	then
		 local obj=enemy_hitbox_detection(e,dice)
		 if(obj.evil)e.wait=true
		else
		 e.wait=true
		end
end

function  check_missiles(d)
	for m in all(m_missiles) do
		if(m.owner==d)del(m_missiles,m)
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
		local d_hitbox=set_hitbox(d)
		if (col(hitbox,d_hitbox))obj=d
	end
	for d in all(d12s) do
		local d_hitbox=set_hitbox(d)
		if (col(hitbox,d_hitbox))obj=d
	end
	for d in all(dice) do
		local d_hitbox=set_hitbox(d)
		if col(hitbox,d_hitbox)then
			obj=d
			if(not obj.evil)obj=nil
		end
	end
	if boss.isin then
		local bhb=set_hitbox(boss)
		if (col(hitbox,bhb))obj=boss
	end
	return obj
end

function set_hitbox(d)
	local hitbox={
		x1=d.x,
		y1=d.y+8,
		x2=d.x+8,
		y2=d.y+10
	}
	return hitbox
end

function set_hitbox_2(d)
	local hitbox={
		x1=d.x,
		y1=d.y,
		x2=d.x+15,
		y2=d.y+15
	}
	return hitbox
end

function arrow_hitbox_detection(a)
	local obj=nil
	local hitbox={
		x1=a.x,
		y1=a.y+4,
		x2=a.x+7,
		y2=a.y+6
	}
	if a.evil then
		for d in all(dice) do
			local d_hitbox=set_hitbox_2(d)
			if (col(hitbox,d_hitbox))obj=d
		end	
	else
		for d in all(dice) do
			local d_hitbox=set_hitbox_2(d)
			if (d.evil and col(hitbox,d_hitbox))obj=d
		end
		for d in all(enemies) do
			local d_hitbox=set_hitbox_2(d)
			if (col(hitbox,d_hitbox))obj=d
		end
		for d in all(d12s) do
			local d_hitbox=set_hitbox_2(d)
			if (col(hitbox,d_hitbox))obj=d
		end
		if boss.isin then
		local bhb=set_hitbox_2(boss)
		if (col(hitbox,bhb))obj=boss
	end
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
			if (source=="enemy")ani.spr=70 sfx(10)
			if (source=="ally")ani.spr=73 sfx(17)
			add(att_ani,ani)
		end
		att_particles(r,source)
	end
end

function manage_arrows()
	for a in all(arrows) do
		if a.evil then
			a.x-=2
		else
			a.x+=2
		end
		if(a.x>128 or a.x<=-8)del(arrows,a)
		local d=arrow_hitbox_detection(a)
		if d then
			attack(a,d,"arrow")
			del(arrows,a)
			sfx(10)
		end
	end
end

function manage_row_cleaners()
	for a in all(row_cleaners) do
		a.x+=4
		if t%2==0 then
			local myp={
				x=a.x,
				y=a.y,
				sx=0,
				sy=0,
				age=5,
				size=7,
				col=9,
				trace=true
			}
			add(particles,myp)
		end
		if(a.x>128)del(row_cleaners,a)
		local d=arrow_hitbox_detection(a)
		if d and not d.isboss then
			kill(enemies,d)
		elseif d and d.evil then
			kill(dice,d,"ally")
		end
	end
end

function draw_arrows()
	for a in all(arrows) do
		local flp=a.evil
		spr(a.spr,a.x,a.y,1,1,flp)
	end
end

function draw_row_cleaners()
	for m in all(row_cleaners) do
		circfill(m.x,m.y,m.r,m.col)
	end
end


function kill(t,i,side)
	if(side=="ally")grid[i.cell].used=false
	explode(i,3)
	del(t,i)
	sfx(14)
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
			col=11,
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
	if lives<=0 and mode!="over" then 
		mode="over"
		c_pause=cocreate(pause)
		music(-1,1000)
	end
	if mode=="wave" then
	 if c_pause and costatus(c_pause)!="dead"then
			coresume(c_pause)
		else
			mode="game"
			c_pause=nil
		end
	elseif (mode=="over" or mode=="win") and not loop then
		if c_pause and costatus(c_pause)!="dead"then
			coresume(c_pause)		
		else
			loop=true
		end
	elseif mode=="horde" or mode=="boss_w" then
		if c_pause and costatus(c_pause)!="dead"then
			coresume(c_pause)			
		elseif c_horde and costatus(c_horde)!="dead"then
			coresume(c_horde)
		else
			if mode=="horde"then
				mode="game"
			else
				mode="boss"
			end
			c_pause=nil
			c_horde=nil
			has_horde=true
		end
	else
		if (mode!="over" and mode!="win")	check_wave()
	end
end

function check_wave()
	if #we==0 
	and #enemies==0
	and #d12s==0
	and mode!="boss" then
		if wave==4 then
			mode="boss_w"
			c_pause=cocreate(pause)
			music(-1,1000)
			sfx(21,0,4)
		elseif not has_horde then
			mode="horde"
			sfx(21,0,4)
			c_pause=cocreate(pause)
			c_horde=cocreate(spawn_horde)
		else
			has_horde=false
			wave+=1
			c_pause=cocreate(pause)
			mode="wave"
			sfx(20,0,4)
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
		{8,14,2},
		{2,7,12},
		{0,1,2}
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
		if case==4 then
			local myp={
				x=d.x+8,
				y=d.y+8,
				sx=0,
				sy=0,
				age=10+rnd(10),
				size=10,
				col=7
			}
			add(particles,myp)	
			local sh={
				x=d.x+8,
				y=d.y+8,
				r=2,
				tr=20,
				col=7,
				spd=2
			}
			add(shwaves,sh)	
		end
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
			if(p.age<=0 and not p.trace)p.size-=1
			if(p.age<=0 and p.trace)p.size-=.5
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
	local ly=12
	if(mode=="title")ly=128

	for x=0,128,2 do
		local n=rnd()
		if n<=.5 then
			local fl={
				x=x+rnd()*2-2,
				y=rnd()*5+ly,
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
	for i=1, 4 do
		local myp={
			x=d.x+12,
			y=d.y+16,
			sx=rnd()*2,
			sy=rnd()*-.5,
			age=3+rnd(2),
			size=1+rnd(2),
			col=flr(rnd(2))+6
		}
		add(particles,myp)
	end	
end
-->8
--boss
function init_boss()
	boss={
		x=108,
		y=46,
		hp=1000, --test
		phase=1,
		sp=78,
		timer=0,
		beaming=false,
		isin=false,
		isatt=false,
		target=nil,
		intro=true,
		charge=false,
		isboss=true
	}
	beam={
		x1=boss.x+8,
		y1=0,
		x2=boss.x+8,
		y2=boss.y+16
	}
	fireball={
		r=5,
		x=boss.x,
		y=boss.y+8,
		att=50,
		active=false,
		spd=3
	}
	
	c_beam=nil
	orbs={}
end

function manage_boss()
	if boss.hp<=0 and not boss.isdead then
		boss.isdead=true
		boss.timer=0
		boss.isin=false
		music(-1,1000)
		kill_all()
	end
	if boss.isdead then
		boss.timer+=1
		if boss.timer%15==0 and boss.timer<=120 then
			shake=2
			local myorb={
				d=1,
				angle=rnd(),
				r=rnd(2)+1,
				col=2,
				dir=-1
			}
			add(orbs,myorb)
			sfx(14,0,4)
		end
		if boss.timer==120 then
			explode(boss,5)
			local sh={
				x=boss.x+7,
				y=boss.y+7,
				r=2,
				tr=40,
				col=2,
				spd=1
			}
			add(shwaves,sh)	
			boss.x=129
			shake=6
			c_pause=nil
			c_pause=cocreate(pause)
			
			sfx(50,0,4)
		elseif boss.timer>=180 then
			music(30,0,7)
			mode="win"
		end
	elseif not boss.isatt then
		boss.beaming=true
		if(c_beam==nil)c_beam=cocreate(update_beam)
		if(c_pause==nil)c_pause=cocreate(pause)	 
	 if c_beam and costatus(c_beam)!="dead"then
			coresume(c_beam)
		else
			boss.beaming=false
			if c_pause and costatus(c_pause)!="dead"then
				coresume(c_pause)
			else
				c_pause=nil
				c_beam=nil
				boss.timer=0
				if boss.isin then
					boss.isatt=true
					if(boss.phase==1)music(14,0,7)
					boss.phase+=1
					boss.sp=76
					if(boss.phase>4 and boss.hp>0)boss.phase=2
				end
			end
		end
	elseif boss.phase==2 then
		if(c_beam==nil)c_beam=cocreate(update_beam)
		if(c_pause==nil)c_pause=cocreate(pause)	 
		boss.timer+=1
		if #dice==0 then
			boss.isatt=false
			boss.sp=78
		elseif  not boss.target then
			boss.target=rnd(dice)
			boss.timer=0
		else
			if boss.timer%5==0 then
				local sh={
						x=boss.x+7,
						y=boss.y+7,
						r=2,
						tr=20,
						col=2,
						spd=1
				}
				add(shwaves,sh)	
				local sh2={
						x=boss.target.x+7,
						y=boss.target.y+7,
						r=20,
						tr=2,
						col=2,
						spd=1
				}
				add(shwaves,sh2)	
				sfx(48)				
			end
			if boss.timer>=150 then
				boss.timer=0
				if boss.target.evil then
					boss.target.att=boss.target.hp
					missile_hitbox_detection(boss.target)
					kill(dice,boss.target,"ally")
					shake=6
				else
					turn_evil(boss.target)
					boss.target=nil
				end
				boss.beaming=true
				boss.isatt=false	
				boss.sp=78
			end
		end
	elseif boss.phase==3 then
		boss.timer+=1
		boss.charge=true
		if boss.timer%10==0 and not fireball.active then
			local myorb={
				d=20,
				angle=rnd(),
				r=rnd(2)+1,
				col=2,
				dir=1
			}
			add(orbs,myorb)
			sfx(46)
		end
		if boss.timer>=151 then
			sfx(45)
			fireball.active=true
			fireball.x=boss.x+8
			fireball.y=boss.y+8
			boss.timer=0
			boss.charge=false
			boss.sp=78
		end			
	elseif boss.phase==4 then
		boss.timer+=1
		if boss.timer==1 then
			sfx(47)
			local sh={
			x=boss.x+7,
			y=boss.y+7,
			r=2,
			tr=128,
			col=2,
			spd=1
		}
		add(shwaves,sh)
		for i=1,#enemy_spawny do
			local myen=add_enemy(4,true)
			myen.y=enemy_spawny[i]
			add(enemies,myen)
		end
		elseif boss.timer>=90 then
			boss.timer=0
			boss.sp=78
			boss.isatt=false
		end
	end
end

function draw_boss()
	if(boss.isin or boss.isdead)spr(boss.sp,boss.x,boss.y,2,2)
	if boss.charge and not boss.isdead then		
			circfill(boss.x,boss.y,boss.timer/30+2,1)
			circfill(boss.x,boss.y,boss.timer/30,2)
	end
end

function update_beam()
	sfx(44)
	for i=1, 4 do
		beam.x1-=i
		beam.x2+=i
		yield()
	end
	boss.isin=not boss.isin
	boss.intro=false
	for i=1, 4 do
		beam.x1+=i
		beam.x2-=i
		yield()
	end
	boss.beaming=false
	if (not boss.isin)boss_location()
	beam.x1=boss.x+8
	beam.x2=boss.x+8
	beam.y2=boss.y+16
end

function draw_beam()
	rectfill(beam.x1-2,beam.y1,beam.x2+2,beam.y2,3)
	rectfill(beam.x1,beam.y1,beam.x2,beam.y2,2)
end

function boss_location()
	local loc={
		{diex=108,diey=10},
		{diex=108,diey=28},
		{diex=108,diey=46},
		{diex=108,diey=64},
		{diex=108,diey=82}
	}
	for c in all(grid) do
		if(not c.used and c.x>10)add(loc,c)
		if(c.diex==boss.x and c.diey==boss.y)c.used=false
	end
	
	local newloc=rnd(loc)
	boss.x=newloc.diex
	boss.y=newloc.diey
	if(newloc.id)newloc.used=true
end

function manage_orbs()
 for o in all(orbs) do
 	o.d-=1*o.dir
 	if(o.d<=0 or o.d>20)del(orbs,o)

		local offset=0
		if(o.dir==-1)offset=8
		o.x=sin(o.angle)*o.d+boss.x+offset
 	o.y=cos(o.angle)*o.d+boss.y+offset
 	if t%3==0 then
			local myp={
				x=o.x,
				y=o.y,
				sx=0,
				sy=0,
				age=5,
				size=o.r+1,
				col=1,
				trace=true
			}
			add(particles,myp)
		end
 end
end

function draw_orbs()
	for o in all(orbs) do
		circfill(o.x,o.y,o.r,o.col)
 end	
end

function manage_fireball()
	if fireball.active then
		if t%3==0 then
			local myp={
				x=fireball.x,
				y=fireball.y,
				sx=0,
				sy=0,
				age=5,
				size=fireball.r+1,
				col=1,
				trace=true
			}
			add(particles,myp)
		end
		fireball.x-=fireball.spd
		local hb={
			x1=fireball.x-4,
			y1=fireball.y-4,
			x2=fireball.x+4,
			y2=fireball.y+4
		}
		for d in all(dice) do
			local d_hitbox=set_hitbox_2(d)
			if col(hb,d_hitbox) then d.hp-=fireball.att
				local ci={
					value=fireball.att,
					col=10,
					life=10,
					x=d.x+5,
					y=d.y,
					dy=-1
				}
				add(combat_info,ci)
				fireball.active=false	
				boss.isatt=false
				shake+=3
				explode(d,5)
				boss.charge=false
				return
			end
		end
		if fireball.x<=0 then
			lives-=1
			fireball.active=false	
			boss.isatt=false		
			shake+=3
			explode(fireball,5)
			boss.charge=false
		end
	end
end

function draw_fireball()
	if fireball.active then
		circfill(fireball.x,fireball.y,fireball.r+1,1)
		circfill(fireball.x,fireball.y,fireball.r,2)
	end
end

function kill_all()
	for d in all(enemies) do
		explode(d,3)
		del(enemies,d)
	end
end

function turn_evil(d)
	if d then
		d.upgraded=false
		d.evil=true
		d.upgrade=false
		d.att=d.b_att
		d.maxhp=d.b_mhp
		d.hp=d.maxhp
	end
end

function boss_hp()
	rect(1,1,127,6,7)
	rectfill(3,3,125,4,8)
	local myhp=boss.hp/1000
	myhp*=124
	rectfill(3,3,2+myhp,4,1)
	spr(16,1,1)
end
__gfx__
00000000001100000000000000110000000000000000000000000000000000000000000000000000000000000011000000000000000000000006600010101010
000000000155100000000000015510000000000000000001100000000000000110000000001100011000000001bb100110000000000000000006600001010101
00700700015551000000000001555111111000000000001bb10011000001001bb1000000017b1117710000001b77b11771000000000000000006600010101010
0007700001551011110000000155119999110000000101bbbb114410001711bbbb1011001bbb3177771000001b77b17777100000dd0000700006600001010101
000770000141119999110000014199999999100000171bbbbbb1744101777bbbbbb144101b3337777771000001bb177777710000044444770006600010101010
00700700014199999999100001411666666100000177788666617141001418866661744101327786687710000144778668771000dd0000700006600001010101
000000000141166666611000014116666661100000141886666f7f41001418866661714101557886688710000144788668871000000000000006600010101010
00000000014ff666666ff100014ff668866ff10000141668866171f10014f668866f7f4101447668866710000144766886671000000000000006600001010101
001111001f4f16688661ff101f4f16688661ff100014f66886617141001f1668866171f101447668866710000144766886671000760000000000006700000000
016677101e4f16688661ef101e4f16666661ef10001f166668817141001416666881714101447886688710000144788668871000760000000000006700000000
16666771014116666661110001411666666111000014166668817441001416666881714101447786687771000144778668777100760000000000006700000000
166161710141066666610000014101f11f100000001411f11f11441001d4d1f11f11744101441177771ef10001441177771ef100760000000000006700000000
15661671014101f11f100000014101f11f10000001d4d1f11f10110001d1d1f11f11441001441177771110000144117777111000760000000000006700000000
0156761001411ff11ff1000001411ff11ff1000001d1dff11ff1000000101ff11ff1110001441777777100000144177777710000760000000000006700000000
00171710001001100110000000100110011000000010111001100000000001100110000001447777777710000011777777771000760000000000006700000000
00010100000000000000000000000000000000000000000000000000000000000000000000111111111100000000111111110000760000000000006700000000
000000000000000000000010000000000000001000000000000000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
000000000000001111000171000000000000017100000001100000000000000110000000a99990000009999a7766666666666666667777666666667700000000
00000000000001ddd710177100000011110017710000001d710000000000001d71000000a90000000000009a7660000000000000006666000000066700000000
0000000000001ddddd711771000001ddd7101771000001ddd7100000000001ddd7100000a90000000000009a7600000000000000000660000000006700000000
000000000001ddddddd7177100001ddddd71177100001ddddd71110000001ddddd711110a90000000000009a7600000000000000000660000000006700000000
000000000001d88dd66d17710001ddddddd717710001d886644444100001d88668444441a00000000000000a7600000000000000000660000000006700000000
000000000001d88dd66d17710001d88dd66d17710001d886647474100001d8866847474100000000000000007600000000000000000660000000006700000000
0000000000011666666117710001d88dd66d17710001166664444410000116666644444100000000000000007600000000000000000660000000006700000000
00000000001dd666666dd771001116666661d7710001d66664747410001dd6666647474100000000000000007600000000000000000660000000006700000000
00a00000016d166668811441016dd666666d14410017d88668474100017d18866884741000000000000000007600000000000000000660000000006700000000
00aaa00001d51666688114d101d51666688114d1001d58866844410001d5188668844410a00000000000000a7600000000000000000660000000006700000000
00aaaa00001101d11d1014100011166668811410000111d11d474100001101d11d147410a90000000000009a7600000000000000000660000000006700000000
00aaa000000001d11d100100000001d11d100100000001d11d141000000001d11d114100a90000000000009a7600000000000000000660000000006700000000
00a0000000001dd11dd1000000001dd11dd1000000001dd11dd1000000001dd11dd11000a90000000000009a7660000000000000006666000000066700000000
000000000000011001100000000001100110000000000110011000000000011001100000a99990000009999a7766666666666666667777666666667700000000
000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0000aaaaaa0777777777777777777007777777777000000000
66666666666666666666666666666666666666666886688609900000000000000000000000777700006666000066660000000001110000100000000111000000
6666666666666886666668866886688668866886688668869aa90000000000900000000000007770000066600000666000000012221001f10000001222100000
66666666666668866666688668866886688668866666666609900000000009a90000000000000770000006660000066600000122822101210000012282210000
6668866666666666666886666666666666688666688668860000000000009aa90990000000000000000007770000066601001228882211210000122888221000
6668866666666666666886666666666666688666688668860000000000009aa99aa990090000000000000777000006661f1122ff8ff22121000122ff8ff22100
66666666688666666886666668866886688668866666666600000000000009909aaaa99000000000000000700000066612122888f888221000122888f8882210
66666666688666666886666668866886688668866886688600000000000000009aaa99000000000000000000000077701212f88f8f88f2100012f88f8f88f210
6666666666666666666666666666666666666666688668860000000000000000099990000000000000000000007777000122f8f888f8f2100012f8f888f8f210
0000000000000000333333333333333333333333333331130000000000101000001000003313133333131333999999990012fffffffff2100012fffffffff210
1111111111110000333333333b3333333333333333331441000000010171710001b10100317171333171713399999999001228f888f82210001228f888f82210
95499954999911003333333333b3333333333333333144410001001b001a10001bb11b10331a1333331a13339999999900012f8f8f8f210001212f8f8f8f2121
95444954444959103333333333b333b33333311333144433001b101b017b71001b111bb131717133317b713399999999000122f8f8f22100121122f8f8f22121
45244454244454103333333333b33b333333166131444333011bb11b001b11001b1bb1b11b131313331b1333999999990000122f8f2210001210122f8f221121
55555555555555103333333333333b33333166511ff433331333b1bb113b33111b3b33b11bb131a1331bb1339999999900012222f222210017112222f22221f1
99954999954999103333333333333b33333155611ff3333333333333333333333b3333b31b131b13331b13339999999900122222222222100112222222222210
449544449544491033333333333333333333333333333333333333333333333333333333333331b1333333339999999900011111111111000001111111111100
44452444452444133331449933314499000000000000000000000001000000000000000010000000000000000000000000100001111100000000000111110000
555555555555551333314499333144990000000010000000000000181000000000000001a100000000000000100000000121001eeeee10000010001eeeee1000
95499954999549133314499933314499000000018100000000000188810000000000001aa100000000000001a100000012c211eddedde100012101eddedde100
9544495444954913331449993331449900000018881000000000018881000000000001a33a1000000000001aa100000012d21eddededde1012c21eddededde10
452444524445241333144999331449990000001888100000000018282810000000001a9939a10000000001aa9a1000000121edeedddeede112d2edeedddeede1
55555555555555133314999933149999000001828281000000018f28f28100000001a999399a100000001a9a33a100000141eedd2d2ddee10121eedd2d2ddee1
99954999954999133314499933144999000018f28f28100000018f28f2810000001a99999999a1000001a39a939a1000014eeedd2dd2dee10141eedd2dd2dee1
44954444954449133331449933314499000018f28f281000001822282228100001aaaaaaaaaaaa10001a933a9999a1000141eded2d2dede1014eeded2d2dede1
0000000000000000333144993331449900018222822281000182222822228100001a99939999a10001aa999a9999aa101ee1eded2d22ede10141eded2d22ede1
000000000000000033144499333149990018222282222810018f2228f22281000001a993999a10000019aa9a99aa91000141eddedddedde11ee1eddedddedde1
000000000000000033144999333144990018f2228f222810188ff2f8ff2f881000001a9339a10000000199aa9a99100001411edeeeeede1001411edeeeeede10
000000000000000033314999333314990188ff2f8ff2f8810118882828881100000001a99a1000000000193aa9310000014101eddddde100014101eddddde100
00000000111000113331499933331499001188828288811001818188818110000000001aa100000000000199a9100000014101eeeeee10000141001eeeeee100
0000000031411199333149993331449900001818881810000188111111188100000000011000000000000019a1000000014101e1111e10000141001e1111e100
00000000314999993314449933144999000188111118810000110000000181000000000000000000000000011000000000101ee1001ee100014101ee1001ee10
00000000149999993331449933314499000011000001100000000000000010000000000000000000000000000000000000000110000110000010001100001100
77777777777700000000777700000000777777770001100000011000010100000101000000000000000000000000000000000000000000000000000000000000
7777777777770000000077770000000077777777001bb10000188100181810001212100000000000000000000000000000000000000000000000000000000000
7777777777770000000077770000000077777777011bb11001888810188810001222100000000000000000000000000000000000000000000000000000000000
77777777777700000000777700000000777777771bbbbbb118888881018100000121000000000000000000000000000000000000000000000000000000000000
77777777777700000000777777777777000000001bbbbbb101188110001000000010000000000000000000000000000000000000000000000000000000000000
7777777777770000000077777777777700000000011bb11000188100000000000000000000000000000000000000000000000000000000000000000000000000
7777777777770000000077777777777700000000001bb10000188100000000000000000000000000000000000000000000000000000000000000000000000000
77777777777700000000777777777777000000000001100000011000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070000077700000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070000000700000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666000000000
07070000077700000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666000000000
07770000070000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666000000000
00700000077700700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066688666000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066688666000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000066666666000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000066666666000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777666666660000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777688668860000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777688668860000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777666666660000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777666666660000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777688668860000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777688668860000000000077777777777777770000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777666666660000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777770000000077777777000000000000000077777777000000000000000077777777000000000000000000000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777777777770000000077777777777777777777777700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777776886688607777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777776886688607777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777776666666607777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777776886688607777777700000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000077777776886688607777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777776666666607777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777776886688607777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777776886688607777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777777777700007777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777777700007777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777777700007777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777777700007777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777777700007777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000077777777000077777777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777777777770000000077777777000000007777777700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000a00000990009909990999099909000000000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000aaa000909090909090999090969666660000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000aaaa00909090909900909099989668860000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000aaa000909090909090909090989668860000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000a00000909099009090909090969996660000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000000000000000000000000000666886660000000000000000000000
00000000777777777777777777777777000000007777777777777777777777770000000000000000000000000000000000688668860000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000000000000000000000000000000688668860000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000000000000000000000000000000666666660000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000007777777700000000000000000000000000000000999099900990909000000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777000000000000000000000000900090909000909000000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777000000000000000000000000990099909990999000000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777000000000000000000000000900090900090009000000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777000000000000000000000000999090909900999000000000000000000000000000000000
00000000777777770000000000000500000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770500000000000000000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00005000775777770000000000000000000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000050000050000000000007777777700000000000000000000000000000000500000000000000000000005000000000000000000000000
00000000777777770000000000000500000000007777777700000050000000000000000000000000999090909990099099909990999090000000000000000000
00000000777777775000000000000000000005007777757705000000000000000000000500000000090095900900909090900900909090000000000000000000
00000000777777770005005000000000000000007577777700000000000000000000000000500000090090900900909099000900999090000000000000000000
05000000777777777777777777777777000000007777777777757777777777770005000000000000090090900900909090900900909090000000000000050000
55500050557777777777777777777777000000007777777777555777777777770000000550000000090009900900990090909990909599900000000000000000
05500005555777777777775777777777000000007777777775757777777777770000005550050000050000000050000000000000500500000000000000000000
00050000555777577777575777577777000000007777777755577777757777770000000500000000000000000000000000000000000000000000000000000000
00000000777777777775557775777777500000007777777775777777555777770000000000005000000000000000000505000500200050000500000050000005
00000000577777777777577777777755550000007777777777772757757777770050000000000000000500000000005555505552220500005550050555005000
00000000777727777777777777777777585000005777777777722277755777770000000500050000000000000000000505000500255550000500000050555505
50000000777222777277775577777777888500007777777757772777777777770000085550555000500000000000000000052000000500000000000000005000
00000000000020002220005550000000585000000000050555000000000005008777878700050070077707770777070707072777077707770777077707770000
00050000000000000205000505000000000050000000005050000999000000088787070702000707007027072720070707072070070007070707077707570005
00555000005050050000000000000000000000005000000000009999900000088778077722200707007227722779970707070070077007770777570707700005
50055005025200005000000005000000500000000580000000009999900000088727882722000700007027072799977707770070070007070707070707070055
00055509992220055520000058550509998500005888000000029999999922288777877788000077807007070777997008780777077707070787875707779995
00005599999200888999000089800088888850000880888000228999999992888888888888800008880000009299999088228888892000500008555888099999
000005999aaa088899999000999528888880000088888888aaaaaa059999928888888888888000258000000999299900822288889990055500005aaa88899999
20000299aaaaa888999990000952aaa8889000000858888aaaaaaaa599998988888888aaa8888222000005809000222582228888890022520000aaaaa8899999

__map__
5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6156575856585857585756565857567100808000008080800080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00800080000080000080830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252635b00800080000080000080840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252735b00808000008080800080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00808080008080800080008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00808300008083000080818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00808400008084000080828000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00800000008080800080008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252635b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252725b00808080008080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6152525252525252525252525252625b00800000008083000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2c2c2d2c2c2c2c2c2c2c2c2c2c2c2e00800000008084000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d00000e00000000000000000000001e00808080008080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3c3c3d3c3c3c3c3c3c3c3c3c3c3c3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011200000213002130021200211002110000000000000000021300212000000041300412000000051200000004130041300412004110041100000000000000000413004120000000513005120000000413000000
011200000213002130021200211002110000000000000000021300212000000041300412000000051200000004130041300412004110041100000000000000000413004120000000213002120000000012000000
011200000c02300000000000c02300000000000c023000003c61500000000000c02300000000000c023000000c02300000000000c02300000000000c023000003c61500000000000c023000003c6003c6153c615
011200001513015130000001313013130000001513000000101301013010130000000e1300e130000000c13010130101301013000000111301113000000131300e1300e1300e1300e1300e130000000000000000
0112000015130151301513000000131301313000000151301013010130000000e1300e130000000c1300000010130101301013000000111301113000000131300e1300e130000000c1300c130000000e1300c130
011200000713009130091300913009130091300912009110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000e1300c130071300913009130091300912009110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000c02300000000000c02300000000000c023000003c61500000000000c02300000000000c023000000c02300000000000c02300000000000c023000003c61500000000000c02300000000000c02300000
011200000b1300b130000000c1300c130000000e130000000c1300c1300c130000000e1300e130000001013010130101301013000000111301113000000131300e1300e1300e1300e1300e130000000000000000
011000000913009130091300913009130091300912009110091100911009110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000320000000000000000000000000000000500b070000700205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000031200412006120091200e12013110191201f1102a1103411000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
300200001333013320123301333014330173301d33023330283202d32034320343200030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
310100003c63036620336202e62029620256201f6201a61017610126100e610096100161000610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000396203962039610396103861037610346102f6102961023610146100b6100061000610006100161002610016100061000610006100061000610006100161000610006100060000600006000060000600
00020000262102b2102f210242101c210132100a2100421000210102000c200092000520001200002001a2001a2001a2001b20027200282000020000200002000020000200002000020000200002000020000200
180300003263635636366363663635626356263461632616306162c6162861622616196160e616016160260603616026160161601616016160261602616026160161601616016160161601606016060160601606
00020000111201312015120181201c11020110231102511028110291102c1102d1102c11025110151100011000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100001c010340003f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003f02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c10200001c6501c6501c65018650196501865018650196001a6001c6001d6001d6001d6501c6501b6501b6501c6501c6501c650186501c65018650006001d6001c6001b6001b6000000000000000000000000000
b10600002a7502d7503075032750367503775023700267002a7502d7503075032750367503775020700237002a7502d750307503275036750377501d700237002a7502d750307503275036750377500000000000
91020000186501e65022650266502b7502f7502f7502e7502c75028750247501a7500f75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000000500005202d520235201e5201c5201a5101952019520195201a5201d52023520295202f5203551038510005000050000500005000050000500005000050000500005000050000500005000050000500
000200002c75027750217501c75017750127500e7500a750067500275000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c02300000000000c023000003c6003c6153c615
010600000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f1400000011140000001114000000111400000014140000001414000000
010600001914000000191400000019140000001914000000191400000019140000001914000000191400000019140000001914000000191400000016140000001614000000161400000015140000001514000000
010600001614000000161400000016140000001614000000161400000016140000001614000000161400000016140000001614000000161400000015140000001514000000151400000015140000001514000000
010600001614000000161400000016140000001614000000161400000016140000001614000000161400000016140000001614000000161400000014140000001414000000141400000012140000001214000000
010600000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f140000000f1400000014140000001414000000141400000012140000001214000000
010600001614000000161400000016140000001614000000161400000016140000001614000000161400000015140000001514000000151400000015140000001514000000151400000015140000001514000000
010600001614000000161400000016140000001614000000161400000016140000001614000000161400000015140000001514000000151400000016140000001614000000161400000015140000001514000000
010600001914000000191400000019140000001914000000191300000019130000001913000000191300000019120000001912000000191200000019120000001911000000191100000019110000001911000000
010600000000000000000000000000000000000000000000000000000000000000001014000000101400000010140000001014000000111400000011140000001314000000131400000010140000001014000000
010600001614000000161400000016140000001614000000161400000016140000001614000000161400000014140000001414000000141400000014140000001214000000121400000012140000001214000000
010600000c043000000c00000000000003c0000c04300000000000000000000000000c0430000000000000003c6150000000000000000c0430000000000000000c0430000000000000003c615000003c61500000
010600000c043000000c00000000000003c0000c04300000000000000000000000000c0430000000000000003c6150000000000000000c0430000000000000003c6150000000000000003c615000003c61500000
010600000214002130021200211002110021100211002110021100211002110021100211002110021100211000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000214002130021200211002110021100211002110000000000000000000000414004130041200411004110041100411004110000000000000000000000514005130051200000007140071300914009130
010600000a1400a1300a1200a1100a1100a1100a1100a1100a1100a1100a1100a1100a1100a1100a1100a11000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000a1400a1300a1200a1100a1100a1100a1100a1100a1100a1100a110000000914009130091200911009110091100911009110091100911009110000000514005130051200000004140041300412000000
010600001614000000161400000016140000001614000000161300000016130000001613000000161300000016120000001612000000161200000016120000001611000000161100000016110000001611000000
010600000a1400a1300a1200a1100a110000000a1400a1300a1200a1100a110000000a1400a1300a1200a11009140091300912009110091100000009140091300912009110091100000009140091300912009110
000200003c05006050070500c0501a05021050390503f050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3103000039750367503475032750307502a750247501c750157500e75001750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91040000047500475005750077500b75010750177501f7503a7503675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18070000376103061025610076100761008610096100a6100a6100a6100a6100a6100b6100b6100c6100d6100f6101061011610136101561017610196101b6101d61020610226102561027610296102b6102e610
3102000004010090100e0101101015010190101b0101d0101f010210102201022010230202302022020210201f0201c0201902015020120200d02006020000101c6001d600006000060000600006000060000600
010e00000e1500e150000001115011150000000e15000000101501015010150000001115011150000001315015150151501515015150151501515000000000000000000000000000000000000000000000000000
300200003562035610356103661037620376203761037610376203562034620316102f6102c6202a61026620226201c61017610136100f6100c61008610056100361000610006100061000610006100060000600
010e0000111301113011130111301113000000000000000010130101301013010130101300000000000000000e1300e1300e1300e1300e1300e13000000000000000000000000000000000000000000000000000
010e0000111331113300000111331113300003000000000010133101331013310133101330000300000000000e1330e1330e1330e1330e1330000300000000000000000000000000000000000000000000000000
__music__
01 00074344
00 01024444
00 00070344
00 01020444
00 00070544
00 01024344
00 00070344
00 00020444
00 00070644
00 01024344
00 00070844
00 01020344
00 00470944
02 01194344
01 1a242644
00 1a242744
00 1b242844
00 1d252944
00 1e242644
00 1a242744
00 1b242844
00 1f252b44
00 1b242644
00 20242744
00 1e242844
00 1a252944
00 21242644
00 22242744
00 2a242844
02 23252b44
00 31333444

