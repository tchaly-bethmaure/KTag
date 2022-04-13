fade(1)
txtr(0, "overlay.bmp")
txtr(1, "arena.bmp")
txtr(4, "knights.bmp")

mapMinSizeX = 5
mapMinSizeY = 0
mapsizeX = 20
mapsizeY = 18
mapsize = {mapsizeX, mapsizeY}
tilesize = 8

a = 0
b = 1
start = 2
select = 3
left = 4
right = 5
up = 6
down = 7
lbumper = 8
rbumper = 9

btnpressed = -1
secretHost = 0
secretJoin = 0

timespend = 0

opos = {}
pos = {}

collisions = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,1},
  {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,0,0,1},
  {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,0,0,1},
  {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,0,0,1},
  {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,0,0,1,1,1,0,0,1,1,0,0,0,1,1,0,0,1},
  {1,1,1,0,0,1,1,1,0,0,1,1,0,0,0,1,1,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,1,0,0,0,0,1,1,1,0,0,0,0,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

function playersCollide(poslocal, oposlocal)
  if(oposlocal[1] == poslocal[1] and oposlocal[2] == poslocal[2])
  then
    return true
  else
    return false
  end
end

function sendValueXY(poslocal)
  local i,j = poslocal[1], poslocal[2]
  --print("Value sent : {"..tostring(i)..","..tostring(j).."}", 0, 4)
  poke4(_IRAM, i)
  poke4(_IRAM + 4, j)
  send_iram(_IRAM)
end

function receiveValueXY()
  local i, j = -1, -1

  -- receiving values
  got_msg = recv_iram(_IRAM)
  while not got_msg
  do
    got_msg = recv_iram(_IRAM)
  end

  if got_msg
  then
    i = peek4(_IRAM + 1)
    j = peek4(_IRAM + 5)
    --print("Value received : {"..tostring(i)..","..tostring(j).."}", 0, 5)
  else
    print("No msg received",0,6)
  end

  return {i,j}
end

function syncPos(pos, host)
  local otherpos = nil
  if(host == 1)
  then
    sendValueXY(pos)
    otherpos = receiveValueXY()
  end

  if(host == 2)
  then
    otherpos = receiveValueXY()
    sendValueXY(pos)
  end

  if(host == 0)
  then
    print("BUG HOST == 0")
  end
  return otherpos
end

function mv(pos,d)
  -- or pos[1]+d[1] > mapsizeX or pos[2]+d[2] > mapsizeY or pos[1]+d[1] < 0 or pos[2]+d[2] < 0 or
  if(pos == nil or pos[1] == nil or pos[2] == nil or collisions[pos[2]+d[2]][pos[1]+d[1]] == 1)
  then
    return pos
  end

  return {pos[1]+d[1], pos[2]+d[2]}
end

function drawImg(x, y, w, h)
   local t = 0
   for yy = 0, h - 1
   do
      for xx = 0, w - 1
      do
        if(t == 0)
        then
          tile(1, (x+xx), (y+yy), 1)
        else
          tile(1, (x+xx), (y+yy), t)
        end
        t = t + 1
      end
   end
end

function drawMe(poslocal, host)
  if(host == 1)
  then
    spr(1, (poslocal[1]-2+mapMinSizeX)*tilesize, (mapMinSizeY+poslocal[2]-2)*tilesize)
  else
    spr(2, (poslocal[1]-2+mapMinSizeX)*tilesize, (mapMinSizeY+poslocal[2]-2)*tilesize)
  end
end

function drawOther(oposlocal, host)
  if(host == 1)
  then
    spr(2, (oposlocal[1]-2+mapMinSizeX)*tilesize, (mapMinSizeY+oposlocal[2]-2)*tilesize)
  else
    spr(1, (oposlocal[1]-2+mapMinSizeX)*tilesize, (mapMinSizeY+oposlocal[2]-2)*tilesize)
  end
end

function draw(poslocal, oposlocal, host)
  drawImg(mapMinSizeX, mapMinSizeY, mapsizeX, mapsizeY)
  if(cpt > 0)
  then
    drawMe(poslocal, host)
    drawOther(oposlocal, host)
  end
end

cpt = 0

while true do
  timespend = timespend + math.max(delta(), 0.2)
  if(timespend > 3600)
  then
    timespend = 0
  end

  if(cpt == 0)
  then
    print("Down to host, Up to join", 0,19)
  else
    if(cpt == 1)
    then
      fade(0)
      print("Game is being played !!! ", 0, 19)
    end
  end

  if(btn(down) and cpt == 0)
  then
    math.randomseed(math.ceil(timespend)+2468)
    --print("You are host",0,1)
    btnpressed = down
    host = 1

    --print("Connecting ....",0,0)
    if(connect(10))
    then
      pos = {math.random(mapsizeX), math.random(mapsizeY)}
      -- spawn on non collision cell
      while(collisions[pos[2]][pos[1]] == 1)
      do
        pos = {math.random(mapsizeX), math.random(mapsizeY)}
      end
      opos = syncPos(pos, host)
      cpt = 1
    else
      print("Connection failed (host)", 0,2)
    end
  end

  if(btn(up) and cpt == 0)
  then
    math.randomseed(math.ceil(timespend)+12345)
    --print("You join",0,1)
    btnpressed = up
    host = 2
    --print("Connecting ....",0,0)
    if(connect(10))
    then
      pos = {math.random(mapsizeX), math.random(mapsizeY)}
      -- spawn on non collision cell
      while(collisions[pos[2]][pos[1]] == 1)
      do
        pos = {math.random(mapsizeX), math.random(mapsizeY)}
      end
      opos = syncPos(pos, host)
      cpt = 1
    else
      --print("Connection failed (join)", 0,2)
    end
  end


  if(host == 1 and cpt > 0)
  then
    if(btn(up))
    then
      pos = mv(pos, {0,-1})
    end

    if(btn(down))
    then
      pos = mv(pos,{0,1})
    end

    if(btn(right))
    then
      pos = mv(pos,{1,0})
    end

    if(btn(left))
    then
      pos = mv(pos,{-1,0})
    end
    
    opos = syncPos(pos, host)
  end

  if(host == 2 and cpt > 0)
  then
    if(btn(up))
    then
      pos = mv(pos, {0,-1})
    end

    if(btn(down))
    then
      pos = mv(pos,{0,1})
    end

    if(btn(right))
    then
      pos = mv(pos,{1,0})
    end

    if(btn(left))
    then
      pos = mv(pos,{-1,0})
    end

    opos = syncPos(pos, host)
  end
  clear()
  draw(pos, opos, host)
  display()

  if(cpt >= 1 and playersCollide(pos, opos) == true)
  then
    print("Host catch Join !!! GAME OVER ", 0, 19)
    cpt = 2
    if(btn(start))
    then
      break
    end
  end
end