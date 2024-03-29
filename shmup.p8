pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--shmup: tutorial by lazydevs

--last commit: 2/3/23

--todo
----------------
--game over screen (timer after
		-- death, press any key)
--wave logic
--improve music
--flexible collision detection
--enemy bullets
--enemy behaviour

function _init()
	cls()
	k_left=0
	k_right=1
	k_up=2
	k_down=3
	k_o=4
	k_x=5

	mode="start"
	blinkt=1
	
	btnreleased=false
end

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="wavetext" then
		draw_wavetext()
	elseif mode=="over" then
		draw_over()
	elseif mode=="win" then
		draw_win()
	end	
end

function _update()
	blinkt+=1
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="wavetext" then
		update_wavetext()
	elseif mode=="over" then
		update_over()
	elseif mode=="win" then
		update_win()
	end
end

function start_game()
	
	music(0)
	
	wave=0
	nextwave()
	
	player={}
	player.x=63
	player.y=63
	player.speed=2
	player.sprite=2
	player.transspr=10
	player.is_transforming=false
	player.transformed=false
	player.muzzlespr=0
	player.is_turning=false
	player.rbtspr=19
	player.rbtturningspr=15
	player.lives=4
	player.lives_remaining=4

	prop={}
	prop.sprite=4
	prop.x=player.x
	prop.y=player.y+8

	ani_timer=0
	transani_timer=0
	ani_rate=3
	
	score=0

	stars={}
	for i=1, 100 do
		local 	newstar={
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		} 
		add(stars,newstar)
	end
	
	bullets={}
	bulspd=4
	bultimer=0
	bulpwr=4
			
	enemies={}
	spawnrate=60 --every 2 seconds
	spawntimer=60 --frame 1 spawn
	
	explosions={}
	
	particles={}
	
	shwaves={}
	
	invul=0
	t=0
end
-->8
--tools

function starfield()

	for i=1,#stars do
		local mystar=stars[i]
		local scol=6
		
		if mystar.spd<1 then
			scol=13
		elseif mystar.spd<1.5 then
			scol=1
		end
		
		if mystar.spd>1.5 then
			spr(30,mystar.x,mystar.y)
		else
			pset(mystar.x,mystar.y,scol)		
		end
	end
end

function animate_stars()
	for i=1, #stars do
		local mystar=stars[i]
		mystar.y=mystar.y+mystar.spd
		if mystar.y>128 then
			mystar.y-=128
		end
	end
end

function manage_bullets()
	for bul in all(bullets) do
		bul.y=bul.y-bulspd
		if bul.y<-8 then
			del(bullets,bul)
		end
		for myen in all(enemies) do
			if col(bul,myen) then
				sparks(bul.x,bul.y,3)
				enemy_damage(myen,bul)
			end
		end
	end
end

function draw_bullets()
	for i=1, #bullets do
		local bul=bullets[i]
		bul.spr=63
		draw_spr(bul)
	end
end

function blink()
	local blink_ani={5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5,5}
	if blinkt>#blink_ani then
		blinkt=1
	end
	return blink_ani[blinkt]
end

function draw_spr(myspr)
	spr(myspr.spr,myspr.x,myspr.y)
end

function col(a,b)
	local a_left=a.x+1
	local b_left=b.x+1
	local a_top=a.y+1
	local b_top=b.y+1
	local a_right=a.x+6
	local b_right=b.x+6
	local a_bottom=a.y+6
	local b_bottom=b.y+6

	if a_top>b_bottom then return false end
	if b_top>a_bottom then return false end
	if a_right<b_left then return false end
	if b_right<a_left then return false end
	
	return true
end

function explode(exx,exy,isblue)

--big explosion	
	local myp={}
	myp.x=exx
	myp.y=exy
	myp.sx=0
	myp.sy=0
	myp.age=0
	myp.maxage=20
	myp.size=10
	myp.blue=isblue
	add(particles,myp)

--small explosions
	for i=1, 15 do
		local myp={}
		myp.x=exx
		myp.y=exy
		myp.sx=rnd()*5-2.5
		myp.sy=rnd()*5-2.5
		myp.age=rnd(2)
		myp.maxage=10+rnd(10)
		myp.size=2+rnd(5)
		myp.blue=isblue
		add(particles,myp)
	end
	sparks(exx,exy,20)
end

function red_explosion(p_age)
	local col=7
	if p_age>20 then
		col=6
	elseif p_age>16 then
		col=8
	elseif p_age>12 then
	 col=9 
	elseif p_age>8 then
	 col=10
	elseif p_age>4 then
	 col=7  	
	end
	return col
end

function blue_explosion(p_age)
	local col=7
	if p_age>20 then
		col=5
	elseif p_age>16 then
		col=1
	elseif p_age>12 then
	 col=13 
	elseif p_age>8 then
	 col=12
	elseif p_age>4 then
	 col=7  	
	end
	return col
end

function enemy_damage(enmy,mybul)
	enmy.hp-=bulpwr
	del(bullets,mybul)
	enmy.flash=2
	if enmy.hp<=0 then
		explode(enmy.x,enmy.y,false)
		big_shwave(enmy.x,enmy.y)
		del(enemies,enmy)
		score+=100
	end
end

function sparks(spx,spy,qty)
	for i=1, qty do
		local myp={}
		myp.x=spx
		myp.y=spy
		myp.sx=(rnd()-0.5)*6
		myp.sy=(rnd()-0.5)*6
		myp.age=rnd(2)
		myp.maxage=10+rnd(10)
		myp.size=2+rnd(5)
		myp.spark=true
		add(particles,myp)
	end
end

function big_shwave(shx,shy)
	local sh={}
	sh.x=shx+4
	sh.y=shy+4
	sh.r=8
	sh.tr=20
	sh.spd=2
	sh.col=7
	add(shwaves,sh)
end

function check_btnreleased()
	if not btn(k_o)
	and not btn(k_x)
	then
		btnreleased=true
	else
		btnreleased=false
	end
end
-->8
--debug call

function debug()
print("javis es el mejor",0,119,7)
end



-->8
--update


function update_game()

--increase timer
	t+=1	
--idle ship
	if(player.is_transforming==false) then
		player.sprite=2
	end

--controls

	if btn(k_up) and player.transformed==false then
	 player.y-=player.speed
	end

	if btn(k_down)  and player.transformed==false then
	 player.y+=player.speed
	end

	if btn(k_right) and player.is_transforming==false then
	 player.x+=player.speed
		player.sprite=3
		player.is_turning=true
	end
	
	if btn(k_left) and player.is_transforming==false then
	 player.x-=player.speed
		player.sprite=1
		player.is_turning=true
	end
	
	--robot moving animatiom
	if not btn(k_left)
	and not btn(k_right)
	then
	
		player.is_turning=false
		player.rbtturningspr=15
		if player.transformed then
		
	--robot idle animation
			if ani_timer<ani_rate then
				ani_timer+=1
			else
		  player.rbtspr+=1
		  if(player.rbtspr>22) then
		  	player.rbtspr=19
		  end
				ani_timer=0
			end
		end
	end
	
	if player.is_turning then
	
		if ani_timer<ani_rate then
			ani_timer+=1
		else
			
			player.rbtturningspr+=1
			
			if player.rbtturningspr>18 then
				player.rbtturningspr=15
			end	
			ani_timer=0
		end
	end
	
	--keep fire on player
	
	prop.x=player.x
	prop.y=player.y+8
	
	--animate flame
	prop.sprite+=1
	if (prop.sprite==9) then
		prop.sprite=4
	end
	
	--shooting
	
	if btn(k_x) and player.transformed==false then
		if bultimer<=0 then
			local bul={
				x=player.x,
				y=player.y-5,
				spd=bulspd
			}
			add(bullets,bul)
			player.muzzlespr=22
			sfx(0)
			bultimer=8
		end	
	end
	bultimer-=1
		
	if player.muzzlespr ~= 0 then
		player.muzzlespr+=1
	end

	if player.muzzlespr>27 then
		player.muzzlespr=0
	end
	
	--transforming player
	if btnp(k_o) and player.is_turning==false then
		player.is_transforming=true
	end

	--ship to robot	
	if (player.is_transforming 
	and player.transformed==false) then
	
		if transani_timer<ani_rate then
			transani_timer+=1
		else
			
			player.transspr+=1
			if(player.transspr==14) then
				player.is_transforming=false
				player.transformed=true
			end	
			transani_timer=0
		end
				
	--robot to ship
	elseif (player.is_transforming 
	and player.transformed) then
	
			if transani_timer<ani_rate then
				transani_timer+=1
			else
			player.transspr-=1
			if(player.transspr==10) then
				player.is_transforming=false
				player.transformed=false
			end	
			transani_timer=0
		end
			
	end
	
	--keeping player on screen
	
	if (player.x<0) then
		player.x=120
	end
	
	if (player.x>120) then
		player.x=0
	end
	
	if (player.y<0) then
		player.y=0
	end
	
	if (player.y>120) then
		player.y=120
	end
	
	manage_bullets()
	animate_stars()
	manage_enemies()

	if mode=="game" then
		spawn_enemies()
	end
end

function update_start()
if btnp(k_o) or btnp(k_x) then
	start_game()
end

end

function update_over()
	check_btnreleased()
	if btnreleased and btnp(k_o) or btnp(k_x) then
		start_game()
	end
end

function update_wavetext()
	update_game()
	wavetime-=1
	if wavetime==0 then
		mode="game"
	end
end

function update_win()
	check_btnreleased()
	if btnreleased and (btnp(k_o) or btnp(k_x)) then
		start_game()
	end
end
-->8
--draw game

function draw_game()
	cls()
	
	debug()

	--draw stars
	starfield()

	--draw ship
	if (player.transformed==false and player.is_transforming==false) then
		if player.lives_remaining>0 then
			if invul>=60 then
				spr(player.sprite,player.x,player.y)
				spr(prop.sprite,prop.x,prop.y)
			else
				if sin(t/6)<0.3 then --blink ship when invul
					spr(player.sprite,player.x,player.y)
					spr(prop.sprite,prop.x,prop.y)
				end
			end
		end
		--draw muzzle flash
		if player.muzzlespr>=22 then		
			spr(player.muzzlespr,player.x,player.y-4)
		end

	--draw shwaves
	
	for sh in all(shwaves) do
		sh.r+=sh.spd
		circ(sh.x,sh.y,sh.r,sh.col)
		if sh.r>sh.tr then
			del(shwaves,sh)
		end
	end
	
	--draw explosions
	for myp in all(particles) do
		
		local pc=7
		if myp.blue then
			pc=blue_explosion(myp.age)
		else
			pc=red_explosion(myp.age)
		end
		
		if myp.spark then
			pset(myp.x,myp.y,7)
		else		
			circfill(myp.x,myp.y,myp.size,pc)
		end
		
		myp.x+=myp.sx
		myp.y+=myp.sy
		
		myp.sx*=0.9
		myp.sy*=0.9
		
		myp.age+=1
		
		if myp.age>=myp.maxage then
			myp.size-=0.8
			if myp.size<=0 then
				del(particles,myp)
			end
		end
	end
			
	--draw transformation
	elseif (player.is_transforming) then
		spr(player.transspr,player.x,player.y)

	--draw robot
	elseif(player.transformed) then
		if player.is_turning==false then
			spr(player.rbtspr,player.x,player.y)
		else
			spr(player.rbtturningspr,player.x,player.y)
		end
	end

	draw_bullets()

	draw_enemies()
	
	print("score:"..score,48,1,12)	
	
	--draw lives
	for i=1,player.lives do	
		if player.lives_remaining>=i then
			spr(29,i*9,1)
		else 
			spr(28,i*9,1)
		end
	end
end

function draw_start()

cls(1)
print("space: the game", 32,40,12)
print("press any key", 36,60,blink())

end

function draw_over()
	draw_game()
	print("game over", 48,40,2)
	print("press any key", 36,60,blink())
end

function draw_wavetext()
	draw_game()
	print("wave "..wave, 54,40,blink())
end

function draw_win()
	cls(11)
	print("congrats!", 48,40,2)
	print("press any key", 36,60,blink())
end
-->8
--waves and enemies

function spawn_enemies()
	spawntimer+=1
	if spawntimer>=spawnrate then
		local myen=new_enemy()
		myen.y=-8
		myen.x=flr(rnd(120)+1)
		myen.flash=0
		add(enemies,myen)
		spawntimer=0
	end
end

function new_enemy()
	local myen={}
	local entypes={1,2,3,4}
	myen.type=rnd(entypes)
	if(myen.type==1)myen.spr=31 myen.hp=8
	if(myen.type==2)myen.spr=33 myen.hp=12
	if(myen.type==3)myen.spr=45 myen.hp=16
	if(myen.type==4)myen.spr=47 myen.hp=20
	myen.ani=0
	return myen
end

function manage_enemies()
	for myen in all(enemies) do
		myen.y+=1
		myen.ani+=0.1--animation speed
		if (myen.ani>=2)myen.ani=0
		if myen.y>128 then
			del(enemies,myen)
		end
		if invul>=60 then
			if col(player,myen) then
				player.lives_remaining-=1
				sfx(1)
				explode(myen.x,myen.y,true)
				invul=0
			end
		else
			invul+=1
		end
		if player.lives_remaining<=0 then
			mode="over"
		end
	end
end

function draw_enemies()
	for myen in all(enemies) do
		if myen.flash>0 then
			myen.flash-=1
			for i=1, 15 do
				pal(i,7)
			end
		end
		spr(myen.spr+myen.ani,myen.x,myen.y)
		pal()
	end
end

function nextwave()
	wave+=1
	wavetime=80
	mode="wavetext"
end
__gfx__
00000000000a9000000a9000000a9000000000000000000000000000000000000000000000000000000a9000000a900000a9990000a9990000a9990000a99900
00000000000a9000000a900000099000000770000007700000077000000770000007700000077000000a900000a9990000a999000a97c9900a97c9900a97c990
0070070000aa990000a9990000a99800007777000007700000077000000770000077770000c77c0000a9990000a999000a97c990099cd980099cd980099cd980
0007700000aa990000a999000099980000c77c0000077000000770000007700000c77c0000cccc0000a999000a97c990099cd980a099980aa099980aa099980a
000770000a7c99900a97c9900a997c80000cc000000770000007700000077000000cc000000000000a97c990099cd980a099980a900980099009800990098009
0070070009cd9990099cd9800999cd8000000000000cc00000077000000cc0000000000000000000099cd980a099980a90098009000a900000a0090000a00900
000000000a9999a0a099980a0a9988a00000000000000000000cc000000000000000000000000000a099980a90098009000a9000000a900000a0090000a00900
00000000090a8090900980090909809000000000000000000000000000000000000000000000000090098009000a9000000a900000a999000a9009a00a9009a0
00a9990000a9990000a9990000a99900000000000000000000a9990000000000000000007770077777700777ccc00ccc08800880088008800000000000000000
0a97c9900a97c9900a97c9900a97c99000a9990000a999000a97c9900000000007700770777007777cc00cc7c000000c80088008878888880000000000aaab00
099cd98a099cd980a99cd980099cd9800a97c990aa97c99aa99cd98a007007000770077077c00c777c0000c7c000000c80000008878888880000100000bbbb00
a0999809a099980a9099980aa099980aa99cd98a999cd98990999809000000000000000000000000000000000000000080000008888888820000d0000a371330
90a980009009800900098909900980099099980900999800000980000000000000000000000000000000000000000000080000800888882000006000abb113bb
00a0090000a0090000a0090000a0090000a9890000a9890000a009000000000000000000000000000000000000000000008008000088820000007000bbb3333b
0a90090000a0090000a009a000a0090000a0090000a0090000a009000000000000000000000000000000000000000000000880000008200000000000b00b3003
000009a00a9009a00a9000000a9009a00a9009a00a9009a00a9009a0000000000000000000000000000000000000000000000000000000000000000000000000
00aaab000006c0000006c0000000000aa00000000000a911119a0000000000000000000000000000000000000000000000000000000e8000000e8000f00ff000
00bbbb0000678c0000678c000000000990000000000aa11cc11aa000000000000000000000000000000000000000000000000000000e80000007b0000ff00f00
000b300006c88cc006c88cc0000000a99a000000000a1177cc11a00000000000000000000000000000000000000000000000000000e7be0000ebbe00000000f0
000b300006c556c006c556c0000050a99a050000000a1c77ccc1a0000000000000000000000000000000000000000000000000000eebbe800eeeee8000ff000f
0aa71b3006c006c00c0000c0000559a99a95500000a91ccc11719a000000000000000000000000000000000000000000000000008eeeee888ee00e880f67f00f
abb11bb30cc006c0cc0000cc000559a99a9550000aa911c117119aa000000000000000000000000000000000000000000000000000700700070000700f1690f0
abbb3bb300c00c00cc0000cc0000a911119a00009aaa91177119aaa900000000000000000000000000000000000000000000000000000000000000000fff9f00
0ab0033000c77c00c770077c000aa11cc11aa0009a00a911119a00a9000000000000000000000000000000000000000000000000000000000000000000f90000
0ff0ff000000000000000000000a1177cc11a000a00000a99a00000a000000000000000000000000000000000000000000000000000000000000000000000000
f00f00f00000000000000000000a1c77ccc1a000a00000a00a00000a000000000000000000000000000000000000000000000000000000000000000000088000
f0000f00000000000000000000a91ccc11719a00000000a00a000000000000000000000000000000000000000000000000000000000000000000000000899800
00ff00f000000000000000000aa911c117119aa000000090090000000000000000000000000000000000000000000000000000000000000000000000089aa980
0f67f00f00000000000000009aaa91177119aaa900000a9009a000000000000000000000000000000000000000000000000000000000000000000000089aa980
0f1690f000000000000000009a00a911119a00a900050a9009a05000000000000000000000000000000000000000000000000000000000000000000000899800
0fff9f000000000000000000a00000a99a00000a00559a9009a95500000000000000000000000000000000000000000000000000000000000000000000088000
00f900000000000000000000a000000aa000000a00559a9009a95500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000002bbbb200000000002bbbb200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b77aaabb00000000bb33331b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b777aaabbb000000bbbb33333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a777aabbb3200002babbbbb333200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaabbbb330000bbaaabbbb33b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002baabbbbb33200002baaaaaabbb200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000babbbbb313000000bbaa77aabb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbbb333300000000bb9aa9bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000062b793260000000062a77a260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000760aa990660000076009779006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060009800060000060000aa0000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00760000000076000760000000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00760000000076000760000000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00760760076076007660000000000766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00766600006666007660000000000766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000300502b05024050210501d0501905017050130500f0500c0500a050070500005000050010500605003000020000200001000010000100003000030000200004000070000b00000000040000100000000
0109000031620276201f62017620116200e6200b6200962006620046200361002610026000260002600000000000000000000000000000000000000000000000000003e000000000000000000000000000000000
011000000c0430000000000000003c6150000000000000000c0430000000000000003c6150000000000000000c0430000000000000003c6150000000000000000c0430000000000000003c615000000000000000
011000001915419154191541915419154191541915419154191541915419154161541615416154151541515416154161541615416154161541615416154161541615416154161541415414154141541215412154
011000000f1540f1540f1540f1540f1540f1540f1540f1540f1540f1540f15411154111541115414154141540f1540f1540f1540f1540f1540f1540f1540f1540f1540f1540f1541215412154121541415414154
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 04434344
02 03424344

