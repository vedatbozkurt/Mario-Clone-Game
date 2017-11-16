pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

level = 1
first_screen = true
target = false
score = 0
name_t = 0

background_song = flr(rnd(2))


if (background_song % 2 == 0) then
    music(0)
else
    music(7)
end

-- called at start
function _init()

 actor = {}
 glare = {}
 
 -- emerge player
 for y=0,63 do for x=0,127 do
   if (mget(x,y) == 48) then
   player = make_player(x,y+1,1)

   
   end
  end 
 end
 t = 0
 
 death_t = 0


 rain = {} --arkaplan yagmur
 for i=1,128 do
  add(rain,{
   rx=rnd(128), --rain x
   ry=rnd(128),
   rs=rnd(2)+1
  })
 end--rain end

end


function make_actor(k,x,y,d)
 local a = {}
 a.kind = k
 a.life = 1
 a.x=x a.y=y a.dx=0 a.dy=0
 a.ddy = 0.06 -- gravity
 a.w=0.3 a.h=0.5 -- half-width
 a.d=d a.jump=0.8
 a.sprite = 1  a.f0 = 0
 a.t=0
 a.standing = false
 add(actor, a)
 return a
end

function make_glare(x,y,sprite,col)
 local g = {}
 g.x=x
 g.y=y
 g.sprite=sprite
 g.col=col
 g.t=0 g.max_t = 8+rnd(4)
 g.dx = 0 g.dy = 0
 g.ddy = 0
 add(glare,g)
 return g
end

function make_player(x, y, d)
 pl = make_actor(1, x, y, d)
 pl.crush = 0
 pl.score  = 0
 pl.jump = 0
 pl.no     = 0 -- player 1
 pl.pal    = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
 
 return pl
end



-- clear_cel using neighbour val
-- prefer empty, then non-ground
-- then left neighbour
function clear_cel(x, y)
 val0 = mget(x-1,y)
 val1 = mget(x+1,y)
 if (val0 == 0 or val1 == 0) then
  mset(x,y,0)
 elseif (not fget(val1,1)) then
  mset(x,y,0)
 else
  mset(x,y,0)
 end
end


function move_emerges(x0, y0)

 -- emerge stuff close to x0,y0
 ----dusman ve itemlerin hangi surede ekranda gorunecegi
 for y=0,64 do
  for x=x0-10,x0+10 do
   val = mget(x,y)
   m = nil

   -- item
   if (fget(val, 5)) then    
    m = make_actor(2,x+0.5,y+1,1)
    m.f0 = val
    m.sprite = val
    if (fget(val,4)) then
     m.ddy = 0 -- zero gravity
    end
   end

   -- monster
   if (fget(val, 3)) then
    m = make_actor(3,x+0.5,y+1,-1)
    m.f0=val
    m.sprite=val
   end

   -- item
   if (fget(val, 6)) then    
    m = make_actor(4,x+0.5,y+1,1)
    m.f0 = val
    m.sprite = val
   end
   
   -- clear cel if emergeed something
   if (m ~= nil) then
    clear_cel(x,y)
   end
  end
 end

end

-- test if a point is solid
function solid (x, y)
 if (x < 0 or x >= 128 ) then
  return true end
    
 val = mget(x, y)
 return fget(val, 1)
end

function move_item(a)
 a.sprite = a.f0
-- if (flr((t/4) % 2) == 0) then
--  a.sprite = a.f0+1
-- end
end

function move_player(pl)

 local b = pl.no

 if (pl.life == 0) then
    death_t = 1
   for i=1,64 do
     g=make_glare(
      pl.x, pl.y-0.6, 96, 0)
     g.dx = cos(i/32)/2
     g.dy = rnd(2)-i/8
     g.max_t = 150 
     g.ddy = 0.01
     g.sprite=76+rnd(3)
     g.col = 9
    end
    
    del(actor,pl)
    
    sfx(50,3)
    --music(-1)
    --sfx(5)

  return
 end


 accel = 0.052
 
 if (not pl.standing) then
  accel = accel / 2
 end
  
 -- player control
 if (btn(0,b)) then 
   pl.dx = pl.dx - accel; pl.d=-1 end
 if (btn(1,b)) then 
  pl.dx = pl.dx + accel; pl.d=1 end

 if ((btn(4,b) or btn(2,b)) and 
--  solid(pl.x,pl.y)) then 
  pl.standing) then
  pl.dy = -0.7
  sfx(51,3)
 end

 -- sprite 

 if (pl.standing) then
  pl.f0 = (pl.f0+abs(pl.dx)*2+4) % 4
 else
  pl.f0 = (pl.f0+abs(pl.dx)/2+4) % 4 
 end
 
 if (abs(pl.dx) < 0.1) 
 then
  pl.sprite=48 pl.f0=0
 else
  pl.sprite = 49+flr(pl.f0)
 end

end

function move_monster(m)
 m.dx = m.dx + m.d * 0.02

 m.f0 = (m.f0+abs(m.dx)*3+4) % 4
 m.sprite = 116 + flr(m.f0)

 if (false and m.standing and rnd(100) < 1)
 then
  m.dy = -1
 end

end

function move_actor(pl)


 if (pl.kind == 1) then
  move_player(pl)
 end
 
 if (pl.kind == 2) then
  move_item(pl)
 end

 if (pl.kind == 3) then
  move_monster(pl)
 end

 pl.standing=false
 
 -- x movement 
 x1 = pl.x + pl.dx +
      sgn(pl.dx) * 0.3
      

 if(not solid(x1,pl.y-0.5)) then
  pl.x = pl.x + pl.dx  
 else -- hit wall

  -- search for contact point
  while (not solid(pl.x + sgn(pl.dx)*0.3, pl.y-0.5)) do
   pl.x = pl.x + sgn(pl.dx) * 0.1
  end

    val = mget(x1, pl.y-0.5,0)
    if(fget(val,7)) then
      if(target==false) then
        music(50)
      end
      target=true
    end


  if (pl.kind == 3) then
   pl.d = pl.d * -1
   pl.dx=0
  end

 end
 
 -- y movement

 if (pl.dy < 0) then
  -- going up
  
  if (solid(pl.x-0.2, pl.y+pl.dy-1) or
   solid(pl.x+0.2, pl.y+pl.dy-1))
  then
   pl.dy=0
   
   -- search up for collision point
   while ( not (
   solid(pl.x-0.2, pl.y-1) or
   solid(pl.x+0.2, pl.y-1)))
   do
    pl.y = pl.y - 0.01
   end

  else
   pl.y = pl.y + pl.dy
  end

 else

  -- going down
  if (solid(pl.x-0.2, pl.y+pl.dy) or
   solid(pl.x+0.2, pl.y+pl.dy)) then

   -- jumping
   if (pl.jump > 0 and 
       pl.dy > 0.2) 
   then
    pl.dy = pl.dy * -pl.jump
   else
 
    pl.standing=true
    pl.dy = 0
    
   end

   --fall down
   while (not (
     solid(pl.x-0.2,pl.y) or
     solid(pl.x+0.2,pl.y)
     ))
    do pl.y = pl.y + 0.05 end
  
   --pop up even if jumping
   while(solid(pl.x-0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
   while(solid(pl.x+0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
    
  else
   pl.y = pl.y + pl.dy  
  end

 end


 -- gravity and friction
 pl.dy = pl.dy + pl.ddy
 pl.dy = pl.dy * 0.95

 -- x friction
 if (pl.standing) then
  pl.dx = pl.dx * 0.78
 else
  pl.dx = pl.dx * 0.9
 end

 -- counters
 pl.t = pl.t + 1
end

function crash_case(a1, a2)
 if(a1.kind==1) then
  if(a2.kind==2) then

   -- 10 point
   if (a2.sprite==80) or (a2.sprite==81) then
    score = score + 10
    sfx(52,3)
   end

   -- 50 point
   if (a2.sprite==82) or (a2.sprite==83) then
    score = score + 50
    sfx(53,3)
   end


   -- 100 point
   if (a2.sprite==99) then
    score = score + 100
    sfx(54,3)
   end

   del(actor,a2)

  end


  -- crush or dupe monster
  
  if(a2.kind==3) then -- monster
   if(a1.crush > 0 or 
     (a1.y-a1.dy) < a2.y-0.7) then
    -- slow down player
    a1.dx = a1.dx * 0.7
    a1.dy = a1.dy * -0.7-- - 0.2
    
    -- explode ----------dusmani oldurdugunde
    for i=1,32 do
     g=make_glare(
      a2.x, a2.y-0.5, 77+rnd(3), 10)
     g.dx = g.dx + rnd(0.5)-0.1
     g.dy = g.dy + rnd(0.5)-0.1
     g.max_t = 15 
     g.ddy = 0.01
     
    end
    
    -- kill monster
    sfx(55,3)
    del(actor,a2)
    score=score+10
    
   else

    -- player death
    a1.life=0


   end
  end
   
 end
end

function move_glare(gl)
 if (gl.t > gl.max_t) then
  del(glare,gl)
 end
 
 gl.x = gl.x + gl.dx
 gl.y = gl.y + gl.dy
 gl.dy= gl.dy+ gl.ddy
 gl.t = gl.t + 1
end


function crash(a1, a2)
 if (a1==a2) then return end
 local dx = a1.x - a2.x
 local dy = a1.y - a2.y
 if (abs(dx) < a1.w+a2.w) then
  if (abs(dy) < a1.h+a2.h) then
   crash_case(a1, a2)
  end
 end
end

function collisions()

 for a1 in all(actor) do
  crash(player,a1)
 end

end

function endofgame()

 if (death_t > 0) then
  death_t = death_t + 1
  if (death_t > 30 and 
   btn(4) or btn(5))
  then 
    dpal={0,1,1, 2,1,13,6,
          4,4,9,3, 13,1,13,14}
    -- palette fade
    for i=0,40 do
     for j=1,15 do
      col = j
      for k=1,((i+(j%5))/4) do
       col=dpal[col]
      end
      pal(j,col,1)
     end
     flip()
    end
    
    -- restart cart
        run()

   end
 end
end


function draw_actor(pl)

 spr(pl.sprite, 
  pl.x*8-4, pl.y*8-8, 
  1, 1, pl.d < 0)
  
 pal()
end




function _update()
name_t += 1

--yagmur arkaplan hareketi
for rst in all(rain) do
  rst.ry += rst.rs
  if rst.ry >= 128 then
   rst.ry = 0
   rst.rx=rnd(128)
  end
 end

if level == 2 and nextlevel == true then
player.x = 5
player.y = 30
nextlevel = false
if (background_song % 2 == 0) then
    music(0)
else
    music(7)
end


elseif level == 3 and nextlevel == true then
player.x = 5
player.y = 45
nextlevel = false
if (background_song % 2 == 0) then
    music(0)
else
    music(7)
end

elseif level == 4 and nextlevel == true then
player.x = 5
player.y = 60
nextlevel = false
if (background_song % 2 == 0) then
    music(0)
else
    music(7)
end

end


 foreach(actor, move_actor)  
 foreach(glare, move_glare)
 collisions()
 move_emerges(player.x, player.y)

 endofgame()
 
 t=t+1


function draw_glare(g)
 
 if (g.col > 0) then
  for i=1,15 do
   pal(i,g.col)
  end
 end

 spr(g.sprite, g.x*8-4, g.y*8-4)

 pal()
end

end



function _draw()

 -- sky
 camera (0, 0)
 rectfill (0,0,127,127,13)

 
 -- map and actors
 cam_x = mid(0,player.x*8-64,1024-128)


 if level == 1 then
 cam_y = 0
   if player.y > 16 then
   death_t = death_t+1
   end
  sspr(80,40,16,16,player.x+40,24,25,25)

   
 elseif level == 2 then
 cam_y = 128
   if player.y > 31 then
   death_t = death_t+1

   for i=1,64 do
     g=make_glare(
      pl.x, pl.y-0.6, 96, 0)
     g.dx = cos(i/32)/2
     g.dy = rnd(2)-i/8
     g.max_t = 150 
     g.ddy = 0.01
     g.sprite=76+rnd(3)
     g.col = 9
    end
    
    del(actor,pl)
    sfx(50,3)
    player.y = 30 
   end
  sspr(80,40,16,16,player.x+40,24,25,25)


 elseif level == 3 then
 cam_y = 256
  -- yagmur goruntusu cizdir
 for rst in all(rain) do 
  pset(rst.rx,rst.ry,12)
 end 
   if player.y > 47 then
   death_t = death_t+1
   for i=1,64 do
     g=make_glare(
      pl.x, pl.y-0.6, 96, 0)
     g.dx = cos(i/32)/2
     g.dy = rnd(2)-i/8
     g.max_t = 150 
     g.ddy = 0.01
     g.sprite=76+rnd(3)
     g.col = 9
    end
    
    del(actor,pl)
    sfx(50,3)
   player.y = 46
   end



 elseif level == 4 then
 cam_y = 384
 -- kar goruntusu cizdir
 for rst in all(rain) do 
  pset(rst.rx,rst.ry,7)
 end 

    if player.y > 64 then
   death_t = death_t+1
   for i=1,64 do
     g=make_glare(
      pl.x, pl.y-0.6, 96, 0)
     g.dx = cos(i/32)/2
     g.dy = rnd(2)-i/8
     g.max_t = 150 
     g.ddy = 0.01
     g.sprite=76+rnd(3)
     g.col = 9
    end
    
    del(actor,pl)
    sfx(50,3)
    player.y = 63

   end
 end

 camera (cam_x,cam_y) --move screen
 pal(2,0) 
 mapdraw (0,0,0,0,256,128,1) 
 pal()
 foreach(glare, draw_glare)
 foreach(actor, draw_actor)
 

 -- player score
 camera(0,0)
 color(7)
 
 if (death_t > 30)  then --game over screen
    cls()
  rectfill(0,0,128,128,0)
  print("game over!!!", 40,18,9)

  print("your score: ", 20,28,7)
  print(score, 100, 28, 7) 

  sspr(64,32,8,8,40,44,48,48)


  print("press x to restart!", 27, 110, 9)
-----------------------------------
 if btn(4) or btn(5) then
 run() 
 end
 -------------------------
 end
 
 if (false) then
  cursor(0,2)
  print("actors:"..count(actor))
  print("score:"..player.score)
  print(stat(1))
 end

 if (target == true) and level ~= 4 then 
  cls()
  rectfill(0,0,128,128,0)
  print("you have finished current level!", 1,10,7)

  print("press x to next level", 27,20,7)
  sspr(16,24,8,8,40,44,48,48)


  print("your score: ", 18, 110, 7)
  print(score, 100, 110, 7) 
  if btn(5) then
    level = level+1
    target = false
    nextlevel = true
  end
  elseif  (target == true) and level == 4 then
  cls()
  rectfill(0,0,128,128,0)
  print("you win!", 47,10,7)

  print("press x to restart!", 27,20,8)
  sspr(64,40,16,16,38,44,48,48)


  print("total score: ", 18, 110, 7)
  print(score, 100, 110, 7) 
  if btn(5) then
    run()
  end
  end




  if (first_screen == true) then --first screen
 cls()
  
 for i=1,8 do
  for j0=0,7 do
  j = 7-j0
  col = 7+j
  t1 = name_t + i*4 - j*2
  x = cos(t0)*5
  y = 38 + j + cos(t1/50)*5
  pal(7,col)
  spr(119+i, 20+i*8 + x, y)
  end
 end

  print("welcome!,are you ready to enjoy", 2,16,7)
  print(" the beauty of four seasons?", 10,23,7)

    sspr(0,24,8,8,38,60,48,48)

    print("press x to start", 32,112,10)


  if btn(5) then
    first_screen=false
  end
  end




  if (first_screen == false) and (target == false) then 
  print("score: ",6,6,0)
  print(score,42,6,0)
  end

end








__gfx__
0000000000000000bbbbbbbb444444443ccc33cccccccccc9111111a77777777dccccccdcccccccc000000000000000000000000000000244400000022222222
0000000000000000bbbbbbbb22222222c3c3ccc3cc77777c1ffffff5779777979c9cdc9cdccddccc000000000000000000000000000000244400000044244424
0000000000700700bb3bbbbb33333333ccccccccc77777771f0ff0f57476976ac4cd9c9dcd6dc3cd000000000000000770000000000000244400000044442444
0000000000077000bbbbbbbbbbbbbbbbccccccccc78777871ffffff5469f79f94d9cd9c96bcbdcbb000000007700007777000000000000244400000044444444
0000000000077000bbbbbbbbbbbbbbbbccccccccc78878871ffffff54999999a4999999abbbbbbbb000000777770077777770000000000244400000044444444
0000000000700700bbbbb3bbbbbbb3bbccccccccc77777771ffffff54999999a4999999abbbbb3bb000007777777777777777000000000244400000044444444
0000000000000000bbbbbbbbbbbbbbbbcccccccccc77777c1f0ff0f54999999a4999999abb3bbbbb000007777777777777777000000004444440000044444444
0000000000000000bbbbbbbbbbbbbbbbcccccccccc7c7c7c555555554222222942222229bbbbbbbb000077777777777777777600000044444444000044444444
bbbbbbbb9999999955444555bbbbbbbb000000777700000044444444000000777700000000000000007777777777777777777760bbb3bbb3bb3bbb3b33833333
bbbbb3bb4554555545445545bbbbbbbb000077777770000022222222000077777777700000000000077777777777777777777770bbbbbbbbbbbbbbbb333333a3
bbbbbbbb4454445444544454bbb8bbb8007777777777700033333333007777777777777000000000777777777777777777777776bbbbbbbbbbbb3bbb3a333333
bb3bbbbb5545445455454454bbbbbbbb0077777777777700b7b7bbbb0777777777777770800000007777777777777777777777770bb3bbbbbbbbbbb333338333
bbbbebbb5445545554455455b8bbbbbb0777777777777600bb8bbbbb7777777777777777000000006777777777777777777777770bbbbbbbbbbbbb3033333333
bbbeaebb4455554544555545bbbbbbbb0677777777766000b7b7b3bb67777777777777700000000006777777777667777777777600bbbbbbbbbb330038333383
bbbbebbb5445555454455454bbbbbbbb00667777776000003bbbbbbb066777700677770000000000006667777660000066777660000bbb3bb3b300003333a333
bbbbbbb35544455555444555bbbb8bbb0000d66666000000bbbbbbb300066d0000666000000000000000066660000000006600000000bbbbbbb0000033333333
77777777777777777777777777777777777777770044999999940000000004899400000077740000000000000000000000000000000000000000000330000000
76b677b777b77b77b767b77b7b77b76b67b777b70049999999998400000049999990000077770000000000000000000000000000000000000000003333000000
b777b777b76737731b773676b6737b71b76b76670849999999999900000944999999000077777000000000000000000770000000000aa0000000033333300000
767b736b7b767b7b11b67b3777676b11767b7b7b849999999999994000844999999940007777700000000000770000711700000000a88a000000333333330000
b7b6bb73b6b7b3b6111bb7bbbb6bb111bbb7bbb69999999999999980094999999999940077777000000000771170071111770000033aa3300003333333333000
3333b3bb3b3b3b3b0011bb3bb3bb1100bbbbbbbb9999999999999990044999999999940077770000000007111111111111117000033333300033333333333300
bb3bbb3bb3b3bbbb00011bbbbbb11000bbbbbbbb0999999999999900099999999999990077700000000001111111111111111000333333330333333333333330
3bbb3bb33b3b3b3b00001bbbbbb10000b3bb3bb30009999999990000099999999999999077000000000071111111111111111600333333330d333333333333d0
0aaaaa000aaaa0000aaaa0000aaaa0000aaaa0000000033330000000004488770000000bb00000000071111111111111111111603bbb3bb3000bbbbbbbbbb000
0aaaaa00aaaaaa00aaaaaa00aaaaaa00aaaaaa00000033333300000000073370000000bbbb000000071111111111111111111110bbbbbbbb00bbbbbbbbbbbb00
aafffaa0aafffa00aafffa00aafffa00aafffa0000033777773000000077887700000bbbbbb00000111111111111111111111116b8bbbbbb0bbbbbbbbbbbbbb0
aacfcaa0aacfca00aacfca00aacfca00aacfca008333770707700000007777700000bbbbbbb00000111111111111111111111111bbbbb8bbbbbbbbbbbbbbbbbb
a0f8f0a0a0f8f000a0f8f000a0f8f000a0f8f0000000777977704000007777770000bbbbbbbb0000611111111111111111111111bbb8bbbbbbbbbbbbbbbbbbbb
0011100000111000001110000011100000111000004077797770440000077777000bbbbbbbbb0000061111111116611111111116bbbbbbbbbbbbbbbbbbbbbbbb
0011100000111800001118000811100008111000044038383800400000007777000bbbbbbbbbb000006661111660000066111660bb8bbb8bbbbbbbbbbbbbbbbb
0080800008000000080000000000080000008000004038383804400000000777000bbbbbbbbbb000000006666000000000660000bbbbbbbbbbbbbbbbbbbbbbbb
0000000000000000000000000000000000000aaaaaa0000000000000000000000000000000000000000000000000000000000000000900000090900000009000
000000000000000000000000000000000000aa4aa4aa000000000000000000000077777000000000000000000000000009990900009090000009000000900000
00000000000000000000000000000000000aa44aa44aa00000000000000000000777777700000000000000000000000009099990000000000000000000000000
0000000000000000000000000000000000aa444aa444aa0000000000000000000788788700000000000000000000000099990900000000000000000000000000
000000000000000000000000000000000aa4444aa4444aa000000000000000000777777700000000000000000000000009099900000000000000000000000000
00000000000000000000000000000000aa44444aa49444aa00000000000000000077777000000000000000000000000009990000000000000000000000000000
00000000000000000000000000000000aa44494aa49444aa00000000000000000070707000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000aa44494aa44444aa00000000000000000007070000000000000000000000000000000000000000000000000000000000
0000bbb0000000000000000000e8ee00aa44444aa44444aa00000000000000000099999999999900000000090000000000000333300000000000000000000000
008b800000000000044400000e8e8ee0aa4444aaaa4444aa00000000000000000009999999999000000000000000900000003333330000000000000000000000
088b8800388888834414400006e8e6e0aa444a0aa0a444aa00000000000000000009999999999000090000aaaa00000000033777773000000000000000000000
868888803888818344444400eee6eeeeaa444aaaaaa444aa0000000000000000099999999999999000000aaaaaa0000083337707077000000000000000000000
86688880381888834141440044ee4e44aa44494aa44444aa000000000000000090099999999990099000aaaaaaaa009000007779777040000000000000000000
88888880538818350044460004444440aa44494aa49444aa00000000000000009009999999999009000aaaaaaaaaa00000407779777044000000000000000000
08888800053883500000006604444440aa44444aa49444aa0000000000000000900999999999900900aaaaaaaaaaaa0004403838380040000000000000000000
00888000005335000000006000444400aa44444aa44444aa0000000000000000900999999999900900aaaaaaaaaaaa0900403838380440000000000000000000
0000000000000000000000000000044000000000000000000000000000000000090099999999009000aaaaaaaaaaaa0000448877777400000000000000000000
000000000000000000000000000001a100000000000000000000000000000000009999999999990000aaaaaaaaaaaa0000073370777700000000000000000000
00000000000000000000000000001aa1000000000000000000000000000000000000099999900000000aaaaaaaaaa00000078877777700000000000000000000
00000000000000000000000000011aa90000000000000000000000000000000000000099990000000000aaaaaaaa009000077770777700000000000000000000
0000000000000000000000000011aaa100000000000000000000000000000000000000099000000009000aaaaaa0000000007777777000000000000000000000
00000000000000000000000001aaa910000000000000000000000000000000000000000990000000000000aaaa00900000000777770000000000000000000000
0000000000000000000000001aa91100000000000000000000000000000000000000099999900000000900000000000000000000000000000000000000000000
00000000000000000000000001110000000000000000000000000000000000000000099999900000000000009000000000000000000000000000000000000000
09900099000000000000000000000000099000990880008809900099088000880000000000000000000000000000000000000000077770000000000000000000
00900090000000000000000000000000009000900080008000900090008000800700000700077000700000700007700007700000070077000007700000000000
00222220000000000000000000000000002222200022222000222220002222200770007700077000770007700077770007700000070007700007700000000000
002a2a20000000000000000000000000002a2a20002a2a20002a2a20002a2a200770007700077000770007700770077007700000070000700007700000000000
02222222000000000000000000000000022222220222222202222222022222220070007000077000070007000700007007700000070000700007700000000000
02002002000000000000000000000000020020020200200202002002020020020077077000077000077077000700007007777700077777000007700000000000
00011100000000000000000000000000000111100001110000111100000111000007770000077000007770000777777007777700077770000007700000000000
00010100000000000000000000000000000100000010010000000100000100100000000000000000000000000700007000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000a2b2c200000000000000000000000000000000000000000000000000
00000000000041510000a0b0c0000000000000000000000000a2b2c2000000000000000000000000000000000000000000000000a2b2c200000000a0b0c00000
0000000000004151000000a2b2c20000000000a0b0c00000000071810000a0b0c0000000a3b3c30000000000000000000041510000a0b0c07181000000000000
71810000000000000000a1b1c1000000415100000000000000a3b3c3000071810000415100a2b2c200a0b0c00000415100000000a3b3c300000000a1b1c10000
7181000000000000000000a3b3c30000000000a1b1c10000000000000000a1b1c10000000000415100000000000000000000a2b2c2a1b1c10000008000070005
00000005070000070000070005008000000000000000007181000000000000000000000000a3b3c300a1b1c10000000000007181000000415100000000004454
000080808000000000000000000000415100000000a2b2c20000000000000000000071810000000000000000000000000000a3b3c30000000000006080808080
808080808080808080808080808060000000000000000000415100000005000000a0b0c000000041510000000000000000000000000000000000000000004555
360000000000000000007181000000000000000000a3b3c300000000415100000000000000000000000000415100000000000000004151000000806060606060
606060606060606060606060606060000000a0b0c0000000000000000080800000a1b1c10000000000000071810000000000000000a0b0c00000000000808080
80000000000000008000000000a0b0c000000000000000000000000000000000000000000000000000000000a2b2c20000000000000000000000606060606060
606060606060606060606060606060000000a1b1c10000000000000000000000000000000000000000000000000000000000050000a1b1c10000000000000000
0000000000a2b2c20000000000a1b1c1007181000000000000000000000000000005000500000000a0b0c000a3b3c30071810000000000000080606060606060
60606060606060606060606060606000000000000000808080000000000000000000000000000000000000000000008080808080800000000080808000000000
0000000000a3b3c30041510080000000000000000000000071810000000021404040404040210000a1b1c1000000000000000000000000000000000000000000
00000000a0b0c0000000000000000000000000000000000000000000000000000000008080000000000500000000006060606060600000000000000000000005
00a0b0c0000000000000000000000005050000000000000000000000000021404040404040210000000000000000000000000000000000000000000000000071
81000000a1b1c100000000718100000000808000000000000000000000415100a2b2c20000000000008080000000006060606000000000000000000000808080
00a1b1c1000000000000000000000080800000000000000000000000000021404040404040210000000000000000000000808080808080808000000000000000
00000000000000000000000000000000000000000000000000a0b0c000000000a3b3c30000415100000000000000006060606000007181000000000000606060
00000000000000000000000000000000000000000000000000000000000021404040404040210000000000000000000000606060606060606000006000070000
15000700360000000500000700006000000000000080800000a1b1c1000000000000000000000000000000a0b0c0000000000000000000000000000000606060
00000000000000000000000000800000000080000000000072820000000080808080808080800000000072827282000000606060600000000000006060606060
60606060606060606060606060606000000000000000000000000000000000000000000000000000007282a1b1c1000000000000000000000000808080606060
00000000000000000000000000000000000000000000000052620000000060404040404040600000000052625262000000606060600000000000006060606060
60606060606060606060606060606000000000000000000000000000000000000000000000000000005262000000000000000000000000000080606060606060
000000000000000000008000000007001500070000800700d0e0360007e36040404040404060f3000007d0e0d0e0350700000007000000360000006060606060
6060606060606060606060606060600000050700070005008000000000000000000000360000000000d0e0000000008007250700360007003660606060606060
90909090909090904040909090909090909090909090909090909090909030303030303030309090909090909090909090909090909090909090909090909090
90909090909090909090909090909090909090909090909090404040909090404040909090404040909090904040409090909090909090909090909090909090
20202020202020205050202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020505050202020505050202020505050202020205050502020202020202020202020202020202020
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0b0c0000000004151000000000000000000000000000000000071810000415100000000000000000000415100000000000000007181000000a0b0c000000000
00000000a0b0c00000000071810000004151000000000000000000a0b0c000000000000000000000000000000000000000007181a0b0c0000000000000004454
a1b1c10000000000000000000000718100000000a0b0c000000000000000000000000000a0b0c0000000000000000000000041510000000000a1b1c100000000
00000000a1b1c10000000000000000000000000000000000000000a1b1c100000000000041510000000000000000000000000000a1b1c1000000000000004555
0000000000000000000000000000000000000000a1b1c100000005000005000000000000a1b1c171810000000000000000000000000000000000000071810000
000000000000000000000000000000a0b0c000000000000000718100000000000000000000000000a0b0c0000000000000000000000000000000000000707070
000000000000000000a0b0c000000000000000000000000000224242424232000000000000000000000000a0b0c0000000000000000000536300000000000000
000000000000000000050000000000a1b1c100000000000000000000000000007181000000000000a1b1c1000000000041510000000000000000000000d20000
000000000000000000a1b1c100000000000000000000000000000000000000000000000000000000000000a1b1c1000000000000000005739200000000000000
000000004151000070700000000000000000000000004151000000000000000000000000000000000000007181000000000000000000000000700000e2f1f200
00718100000000000000000000000000000041510000000070000000000000000000000000000000000000000000000000000000002242423200000000415100
000000000000000000000000000000000000000000000000000000150000000000000000055363000000000000000000000000000000000000000000e2f1f200
00000000000071810000000000000000000000000000000000000000000000000000000000004151000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000007392000000000000000000000000000035000000000000d0f0e000
00d200000000000000000000000000000000000000020007000035000700350700071200000000000000000000000070000000000000d200000000000000d200
000000707000000000a0b0c071810000000000000000000022424242423200000000224242424232000000000070700000000000707000000000000070707000
e2f1f20000000000000000000000000000000000002242424242424242424242424232000000000000000000000000000000000000e2f1f20000000000e2f1f2
000000000000000000a1b1c100000000000000000000000000000000000000000000000000000000000000000000000000007181000000004151000000000000
e2f1f20000000000000002000700250712000000000000000000000000000000000000000000000000000000000000000000700000e2f1f20000000000e2f1f2
00000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2f1f2000000000000002242424242423200000000000000000000000000a0b0c00000000000000236000712000000000000000000d0f0e03600000700d0f0e0
00000000000000000000000000000000000000000000000000000002050007000000360007000007251200000000000000000000000000000000000000000000
e2f1f2000000007070000000000000000000000070000000000000000000a1b1c100000000000022424242320000000000000000002242424242424242424232
00000000000000000000000000002500000000000000000000000022424242424242424242424242423200700000000000000000000000000000000000000000
d0f0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004200
00000000000000000000000022424232000000000000000000000000000000000000000000000000000000000000007000000036000000000000000036363600
70707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000007000000070707000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444cccccecc4f444444ccccdccc4f444444cccceccc4f444444cccccdcc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444cccceeec4f444444cccdddcc4f444444ccceeecc4f444444ccccdddc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccfff00ff00cc005000f000fffccdd5ddcffffff000c000eecffffffffcccdd5ddffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4404f404cc0e0e0e0404f440cdddddd14444f4440e0e0ee24444f444ccdddddd1444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc44000404c2050e004400f4441d5ddd1c4444f4000e0e0e2c4444f444c1d5ddd14444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc44440404cc0e0e0c0404f440c1ddd1cc4444f404c20e02cc4444f444cc1ddd1c4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccff00fff00c00e20c0f000fffcc1d1cccffffff000c000cccffffffffccc1d1ccffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444cccc2ccc4f444444ccc1cccc4f444444ccc2cccc4f444444cccc1ccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444444cccccccccccccccc9aaaaaa9cccccccccccccccccccccccccccc
cccc4f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444444cccccccccccccccc4999999acccccccccccccccccccccccccccc
ccccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccc4999999acccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccc4999999acccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccc4999999acccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccc4999999acccccccccccccccccccccccccccc
ccccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccc4999999acccccccccccccccccccccccccccc
cccc4f4444444f44444422222222222222222222222222222222222222224f4444444f444444cccccccccccccccc42222229cccccccccccccccccccccccccccc
cccc4f4444444f444444cccccccccccccccccccccccccccccccccccccccc4f4444444f444444cccccccccccccccccccccccccccccccccccccccc9aaaaaa9cccc
cccc4f4444444f444444cccccccccccccccccccccccccccccccccccccccc4f4444444f444444cccccccccccccccccccccccccccccccccccccccc4999999acccc
ccccffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4999999acccc
cccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4999999acccc
cccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4999999acccc
cccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4444f4444444f444cccccccccccccccccccccccccccccccccccccccc4999999acccc
ccccffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4999999acccc
cccc4f44444422222222cccccccccccccccccccccccccccccccccccccccc2222222222222222cccccccccccccccccccccccccccccccccccccccc42222229cccc
cccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccccccc
cccc4f444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777cccccccc
ccccffffffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777cccccc
cccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777ccccc
cccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6777777777776ccccc
cccc4444f444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66777777776cccccc
ccccffffffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666ccccccc
cccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9aaaaaa9cccccccccccccccccccc
cccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
ccccffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
cccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
cccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
cccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
ccccffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4999999acccccccccccccccccccc
cccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc42222229cccccccccccccccccccc
cccc4f444444cccc5555ccc5555ccccccccccccccccccc5555cccccccccccccccccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444cc5555555c555555ccccccccccccccccc555555ccccccccccccccccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccffffffffc5f57557555577555ccccccccccccccc555dd555ccccccccccccccccffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f444c5f55555555777755ccccccccccccccc55dddd55cccccccccccccccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f444ccf55775555777755ccccccccccccccc55dddd55cccccccccccccccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f444cc555555555577555ccccccccccccccc555dd555cccccccccccccccc4444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccffffffffccc111cc5c555555ccccccccccccccccc555555cccccccccccccccccffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f444444ccc1c1ccccc5555ccccccccccccccccccc5555cccccccccccccccccc4f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc4444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f4444444f444cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc222222222222222222222222222222222222222222222222222222222222222222222222cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44444444444444cccccccccccccccccccccccccccccccccccccc
ccccccbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbb22222222222222cccccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbb33bbbbbbb33bbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbb33bbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbb3b3bbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbb33bbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc44444444cccc
ccccbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc22222222cccc
ccccbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc33333333cccc
ccccbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbcccc
ccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbcccc
cccc33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33ccccccccccccccccccccccccbbbbb3bbcccc
ccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccbbbbbbbbcccc
cccccc333333333333333333333333333333333333333333333333333333333333333333333333333333333333ccccccccccccccccccccccccccbbbbbbbbcccc
cccccccccc2444ccccccccccccccccccccccccccccccccccccccccccccccc22222cccccccccccccccc2444ccccccccccccccccccccccccccccccbbbbbbbb4444
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccc2e22222ccccccccccccccc2444ccccccccccccccccccccccccccccccbbbbb7bb2222
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccc2fffff2ccccccccccccccc2444ccccccccccccccccccccccccccccccbb3b7a7b3333
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccc2f1ff12cccccccccccbcbc2444ccccccccccccccccccccccccccccccbbbbb7bbbbbb
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccccfffffccccccccccccc3cc2444ccccccccccccccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccccc333ccccccccccccccc4c2444ccccccccccccccccccccccccccccccbbbbb3bbbbbb
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccccc111cccccccccccccccc22444ccccccccccccccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444cccccccccccccccccccccccccccccccccccccccccccccccc1c1ccccccccccccccccc2444ccccccccccccccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444cccccc9aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa9cccccc2444cccccc5555ccccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444ccbccc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444ccccc555555cccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444c4c3cc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444cccc5555555cccccccccccccccccccbb3bbbbbbb3b
cccccccccc24442ccccc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444cccc5755755cccccccccccccccccccbbbbbbbbbbbb
cccccccccc2444cccccc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444cccc5555555cccccccccccccccccccbbebbbbbbbbb
cccccccccc2444cccccc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444cccc5577555cccccccccccccccccccbeaeb3bbbbbb
cccccccccc2444cccccc4999999a4999999a4999999a4999999a4999999a4999999a4999999acccccc2444cccc5555555cccccccccccccccccccbbebbbbbbbbb
cccccccccc2444cccccc42222229422222294222222942222229422222294222222942222229cccccc2444cccc5ccc5cccccccccccccccccccccbbbbbbbbbbbb
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbbbbbbbb
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222bbbbbbbbbbbb
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb3bbbbbbb3b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbb
bbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3b
bbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbeaeb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbeaeb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7a7bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3bbbbbbb3b
b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbb
b3bbbbbbb3bbbbbbb3bbbeaeb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbeaeb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbeaeb3bbbbbbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbb
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3b7a7bbb3bbbbbbb3bbbbbbb3b
bb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbb

__gff__
000003030101130303030101010101030303010101010301010101010103030103030303030101010103010101010101000000000013031301010303030301012000200083830000430000000000000020202020838300000000000000000000000000200000000000000000000000000a020202000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000000000000000000000000171800000000141500000000000000000000000000171800000000000000000000171800000000000000000000000000000000000000000000000000000a0b0c00000000000000171800000a0b0c0000000014150000000000000000000000000000000000
000000000000171800000000000000000014150000000000000000000000000000000000000a0b0c0000001415000000000000000000000000000000000000000000000014150000000000001718000000000000001718001a1b1c00141500000000000000001a1b1c0000000000000000000000000a0b0c0000000000444506
000000000000000000000014150000000000000a0b0c0000000000000000000000000000001a1b1c000000000000000000000000141500000000000000000000000000000000000a0b0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1b1c0000000000545506
000014150000000000000000000000000000001a1b1c0000000000000a0b0c000000000000000000000000000000000000000000000000000a0b0c0000005000000000000000001a1b1c000000000000000000000000000000000000000000000000000000141500000000000000500000000000000000000000000000060606
000000000000000000000000000000000000000000000000141500001a1b1c000000000000000000000000000000000000000000000000001a1b1c000000060600000000000000000000000000000000001415000000000000000000000000171800000000000000000000000006060600000006700000000070006300060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000001718000000000000000000000000000000000000000000000017180000001718000000000000000000000a0b0c000000000000000000000a0b0c00000000000000000000000000000006060606060606060606060606
00000a0b0c000000001415000000000000001718000000000000000000171800000000001415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1b1c000000000000000000001a1b1c00000000000000005000000000500006060606060606060606060606
00001a1b1c000000000000000000000000000000000000000000000000000000000000000000000000000000000050500000000000000000000000000600000000000000000000000000000000000000000000000000000000060050700006000000000000000000000000060606060606060006060606060606060606060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005100000000000000000000000000000000000000000000000000000000000006060606060606000000000000000000000000000000000000000000060606060606060606060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061111111111060000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000007000500000007051060606060606060606060606
0000000000000000381339640000500067000000000050000000000000000000000000000000000000000006060404040404060000000000381339000000000000000000000000000000000050000000000000000000000000000000003813390000000000060000060303030303030303030303060606060606060606060606
0000000000000000131313000006060606000000060606060600000000000000000000000000000000000606060404040404060000060000131313000000000000000000060606060000000606060606060000000606060600000000001313130606060600060606060202020202020202020202060606060606060606060606
00000000000000001d3d1e0000000000000006000000000000000000000000000000000000000000000606060604040404040600000000001d3d1e000000000000000000060600000000000000000000000000000000060000000000001d3d1e0000000000000000000202020202020202020202060606060606060606060606
00000030000000000d0f0e0000007053007006000000000000000000000070000063000070000000060606060604040404040650000000700d0f0e707052700053007000060650000070007000500000700000000050067000706300700d0f0e0000500070006300700202020202020202020202060606060606060606060606
1603160303161603160303161603160316030303160316030316030316040404040606040404040316030303031603160303030303160303160303031616030303031603030303160316030316030316030303031603030316031603031603031603030303160316030202020202020202020202060606060606060606060606
1002101010021002021002101002100202021002100210100202100210020210020202021002021010020202100202020202021002100202021010020202100202100202100210020202101010020202021002100210020210020202100202021010020210020210100202020202020202020202060606060606060606060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060606060606060606060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060600000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060600000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000060644450000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006300000000000000000000000000000606000000000000000000000000000000000000000000000000067000005000060654550000500050000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000060606000000000000000000000000000000000000060606060606060606060000000000000000000000060606060606060606060606060606000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000006000000000000060600000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606000000000000000000000000000000060600000000000000000000000000000000060000000000000000000000000000000000060600000000000000000006
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000060000000000000000060000000000000000000000000000000000060600000000000000000006
0000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000006060000000000000000000000000000060000000600000000000006060000060000000000000000060000060606060606060606000000000000060600000000067000005306
0000000000000000000000000000000000000000000000000000000000000000000000060600000000500000000000003813390000060600000000000000000000000000000000000000060050000600000000000000000000065000700063700063060000060606060606060606000000000000000000000000060606060606
0000000000000000000000000000060000000600000006000000060606000000000006060600000000060000000000001313130000000000000000000000000000000000003e3f000000000006000000000000000000000000060606060606060606060000060606060606060606007000000051007000000000007000007000
0000000000000000000000000000060000000000000006000000000000000000000606060600000000000000000000001d3d1e0000000000000000000000000000000000001d1e000000000006000000000000000000000006000000000000000000000000000000000000060606060606060606060606060606060606060606
0000000000000000000000000000060070510000507006005200700050007000060606060600007000000000007063000d0f0e0000000000000000000000000000000000000d0e000000000000000000000000000000060000000000000000700000000000000070000063060606060606060606060606060606060606060606
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110404111104040411110404041111040404111111040404111111111111111104040411111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212120505121205050512120505051212050505121212050505121212121212121205050512121212121212121212121212121212121212121212121212121212121212121212121212121212121212
__sfx__
01030000185001c5001f50024500185001c5001f50024500185001c5001f50024500185001c5001f500245001a5001d5001f500245001a5001d5001f500235001a5001d5001f5001a5001d500215002450023505
0110000024005242052407023000230700c005240002407026070240062400024070230703c505240701300528070240062400024070230703c505240002407026070240062400024070230703c5051f0701c005
0110000024000240002407023000230700c000240002407026070240002400024070230703c0002407013000280702400024000280702b0703c000240002d07028070240002400026070240703c000210701f000
01100000260701a00028070000002b070290702807018000260700000000000000002b0702907028070180002607032000280000000028070000000000024070300000000018000000003e000240000000000000
01100000260700c005180052807028000000050a005240002b0000a00524000000050a0050c00524070130052b0700c0050a0052807028000000050a0050c005240002400024070240002b070290702807028000
01100000260701a005280002800028070280001e00224070240002600724005200022b07029070280702800026070180021800218002280700000000000240702400000000000000000000000000000000000000
011000000c7730d0000c6751f0000c7731f0000c6751f0000c7730d0000c6751f0000c7731f0000c6751f0000c7730d0000c6751f0000c7731f0000c6751f0000c7730d0000c6751f0000c7731f0000c6750c675
011000000c7730d0000c675306750c7731f0000c675306050c7730d0000c675306750c7731f0000c675306050c7730d0000c675306750c7731f0000c675306050c7730d0000c675306750c7731f0000c67530605
011000000c1500c1510c1510c1510c1510c1510c1510c1510c1510c1510c1510c1511115111151111511115113151131511315113151131511315113151131511315113151131511315113151131511315113151
011000000e1500e1500e1500e1500e1500e1500e1500e150101501015010150101501015010150101501015011150111501115011150111501115011150111501115011150111501115011150111501115011150
011000000c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c1520c15215152151521515215152151521515215152151521515215152151521515215152151521515215152
011000001015210152101521015210152101521015210152111521115211152111521115211152111521115210152101521015210152101521015210152101521115211152111521115211152111521115211152
011000002b0702b0702b070290002807029070290702b0702b07024070240700000030070300702f0702f0702d0702d0702d0702b070290702807028070280702b0702b07024070240702807029070290702b070
011000002b0702b0702b070290002807029070290702b0702b07024070240700000030070300702f0702f0702d0702d0702d0702b070290702807028070280702b0702b07024070240702807029070290702b070
011000002b0702b0702b070240702d0702b07029070280702807028070280702807028070280702d0002b0002d0002b000290002d0002d0702b07029070290702807028070240702407024070240702407024070
011000002b0702b07029070290702807029070290702b0702b0702b0702b07029070280702807029070290702807028070290702907028070280702607026070240702407024070240702d0702b0702907029070
011000002807028070240702407024070240702407024070240702407024070240702900029000290702907028070280702607026070260702607026070260702607026070260702607026070260702607026070
0110000018070000000e000000001a0700000018070000001a07000000180700000000000000000c0000000018070000000e000000001a0700000018070000001a070000001c070000001a070000001807000000
011000001d070000000e000000001f070000001d070000001f070230001d0701c00015000110000f0000d0001d070000000e000000001a0700000018070000001a070000001c070000001a070000001807000000
011000001f070000000e0000000021070000001f0700000021070131001f07001100000000000000000000001d0700000000000000001f070000001d070000001f070290001d0700000029000000000000000000
0110000018070000000e000000001a0700000018070000001a0700000018070200021f0051b0071a0051b0051f07018002180021800221070000001f0700000021070000001f0701100000000000000000000000
01100000006051f005220052a00500675000050000500005006050000500005000050067500005000050000500605000050000500005006750000500005000050060500005000050000500675000050000500005
010100002b7602e7503a73033740377302e75033730337303372035710377103a710337103a7103c7100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100002257524575275652455527555275552b54524525225352252527525275252b5252e515305152e51500000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002137115371123710f3710a371063710337101351000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000190701e0702507031070370703e0700b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0000331533d14330123241231a113001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01060000365703b5703f5702550032500365002150024500315003950023500315003a50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000363713b3713f3710030100301003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301
01010000332722f2722c2722827224272202721b27216272102720c27209272082720527203272022720227203272022720020200202002020020200202002020020200202002020020200202002020020200202
000100000667007670096700d67011670146701d67028670006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011400002d1702d1702b1702b1702b1702b1702b1702b1702b1702b1702b1702b1702817028170281702817029170291702817028170261702617024170241702617026170241702417021170211701f1701f170
011400002117021170211702117021170211702117021170211702117021170211702110021100211002110000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400001d0701d0001d070000001d070000001d070000001a070000001a07000000180700000018070000001d070000001d070000001d070000001d070000001a070000001a0700000018070000001807000000
011400001a070000001a070000001a070000001a0700000015070000001507000000160700000016070000001a070000001a070000001a070000001a070000001507000000150700000016070000001607000000
010a00203543034430324303043035430344303243030430354303443032430304303543034430324303043035430344303243030430354303443032430304303543034430324303043035430344303243030430
01100000144762f406124760f406124760040612476004060d476004060d476004061047600406004060040600406004060040600406004060040600406004060040600406004060040600406004060040600406
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41420100
00 41420100
00 41020100
00 41020100
00 01020300
00 01020400
00 01020300
00 01020400
00 01060705
00 01060805
00 01060705
02 01060805
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

