_DEBUG_ = false

#magic numbers
ENEMIES_PROPABILITY = 0.05
NUMBER_OF_ENEMIES = 100

MIN_ENEMY_SPEED = 0.5
MAX_ENEMY_SPEED = 1

PLAYER_START_SIZE = 20

DEFAULT_USER_ACCELERATION = 0.1
MAX_USER_SPEED = 4

#DEFAULT_LINE_WIDTH = 2
#DEFAULT_POSITIVE_CIRCLE_JOIN_RATE = 0.5
DEFAULT_NEGATIVE_CIRCLE_JOIN_RATE = 0.5
RATIO_PREVAILANCE_WITH_MERGE = 0.8

MINIMAL_VIABLE_RADIUS = 1
MAX_RADIUS = 500

MAX_ENEMY_RADIUS = 450
MIN_ENEMY_RADIUS = 1
PROPORTION_MAX_NEW_ENEMY_SIZE = 12.0

BULLET_SHOOTER_RATIO = 0.2
SHOOTER_SHOOT_LOSS = 0.01

DRAW_BIGGER_RADIUS_FACTOR = 1.8

_NODE_WEBKIT_CONTEXT_ = false

if require? 
  _NODE_WEBKIT_CONTEXT_ = true


dlog = (msg) ->
  console.log(msg) if _DEBUG_
  return msg

delay = (ms, func) -> setTimeout(func, ms)

randomInt = (from,to) ->
  Math.floor(Math.random()*to)+from

randomIntDefault = (from, to, default_value) ->
  if default_value? then pareseInt(default_value)
  randomInt(from,to)

randomNumber = (from, to) ->
  (Math.random()*to)+from

randomPlusOrMinusOne = () -> 
  if Math.random() < 0.5
    return -1
  else
    return 1

clamp = (v, min, max) -> Math.min(Math.max(v, min), max)

clampRgb = (v) -> 
  parseInt(clamp(v,0,255))

zeroTo255 = (n) ->
  until n? then return randomInt(0,255)
  if n <0 or n>255 then return randomInt(0,255)
  return parseInt(n)



randomColor = (r,g,b) ->
  return [zeroTo255(r),zeroTo255(g),zeroTo255(b)]

randomColorHsl = (h,s,l) ->
  return [randomIntDefault(0,360,h), randomIntDefault(0,100,l), randomIntDefault(0,100,l)]

randomPrettyHslColor = (h) ->
  randomeColor(h, 100, 50)

makeColorString = (color_rgb_array, opacity = 1) ->
  [r,g,b] = color_rgb_array
  return "rgba(#{r},#{g},#{b}, #{opacity})"

makeHslColorString = (color_hsl_array) ->
  [h,s,l] = color_hsl_array
  return "hsl(#{h},#{s}%,#{l}%)"

c = circle = (x,y,r) ->
  [x,y,r]

rc = reverse_circle = (a) ->
  [x,y,r] = a

calcCircleBox = (circle) ->
  [x,y,r] = rc(circe)
  return [x-r,y-r,r*2]

isCircleRadiusViable = (radius, minradius = MINIMAL_VIABLE_RADIUS) ->
  if radius < minradius
    return false
  return true

maxEnemySize = (player) ->
  return Math.floor(Math.sqrt(player.circle[2]) * PROPORTION_MAX_NEW_ENEMY_SIZE)

maxEnemyVelocity = (player) ->
  Math.max.apply(Math,[player.vx,player.vy])

#higher abstractions
moveBubble = (bubble) ->
  bubble.circle[0] = bubble.circle[0] + bubble.vx
  bubble.circle[1] = bubble.circle[1] + bubble.vy
  return bubble

limitPlayerVelocity = (v) ->
  if Math.abs(v) > MAX_USER_SPEED
    return MAX_USER_SPEED *(v/Math.abs(v))
  else
    return v



moveBubbleWithinBounds = (w,h,bubble) ->
  [x,y,r] = bubble.circle
  if y < (r * -1)
    bubble.circle[1] = h+r
    return moveBubble(bubble)
  else if y > (h + r)
    bubble.circle[1] = r * -1
    return moveBubble(bubble)
  else if x < (r * -1)
    bubble.circle[0] = w + r
    return moveBubble(bubble)
  else if x > w+r
    bubble.circle[0] = r * -1
    return moveBubble(bubble)
  else
    return moveBubble(bubble)

makeBubble = (x = 100, y = 100, r = 100, vx = 0, vy = 0, rgb) ->
  b = {}
  b.circle = c(x,y,r)
  b.fillColor = rgb ? randomColor()
  b.opacity = 1
  b.strokeColor = [0,0,255]
  b.alive = true
  b.explode = false
  b.vx = vx
  b.vy = vy
  return b

makeEnemy = (x, y, r, vx, vy, rgb) ->
  if r > MAX_ENEMY_RADIUS then r = MAX_ENEMY_RADIUS
  makeBubble(x, y, r, vx, vy, rgb)

makePlayer = (x,y,r) ->
  makeBubble(x,y,r,0,0,[255,255,0])

spawnPlayer = (w,h) ->
  makePlayer(Math.floor(w/2), Math.floor(h/2), PLAYER_START_SIZE)

makeBullet = (x,y,r,vx,vy,rgb) ->
  makeBubble(x, y, r, vx, vy, rgb)

spawnEnemy = (world_width, world_height, min_r = 15, max_r = 75, min_v = MIN_ENEMY_SPEED, max_v = MAX_ENEMY_SPEED) ->
  r = randomInt(min_r, max_r)
  vx = randomNumber(min_v, max_v)
  vy = randomNumber(min_v, max_v)
  where = Math.random()
  switch
    when (where < 0.25)
      #top
      x = Math.random()*world_width
      y = r * -1
      #vy = vy
      vx = vx * randomPlusOrMinusOne() 
    when (where < 0.5)
      #bottom
      x = Math.random()*world_width
      y = world_height+r
      vy = vy * -1
      vx = vx * randomPlusOrMinusOne()
    when (where < 0.75)
      #left
      x = r * -1
      y = Math.random()*world_height
      vy = vy * randomPlusOrMinusOne()
      vx = vx 
    else 
      #right
      x = world.width + r
      y = Math.random()*world_height
      vy = vy * randomPlusOrMinusOne()
      vx = vx * -1
  makeEnemy(x, y, r, vx, vy)

#collison detection
rectangleCollision = (a,b) -> 
  [a_x, a_y, a_width] = a
  [b_x, b_y, b_width] = b
  a_x < b_x + b_width &&
  a_x + a_width > b_x &&
  a_y < b_y + b_width &&
  a_y + a_width > b_y

circleCollision = (c1, c2) ->
  [c1_x, c1_y, c1_r] = rc(c1)
  [c2_x, c2_y, c2_r] = rc(c2)
  a = c2_x - c1_x
  b = c2_y - c1_y
  d = Math.sqrt(a*a + b*b)
  if (d - c1_r - c2_r) < 0
    return true
  return false

bubbleCollision = (b1, b2) ->
  [c1_x, c1_y, c1_r] = rc(b1.circle)
  [c2_x, c2_y, c2_r] = rc(b2.circle)
  if rectangleCollision([c1_x-(c1_r/2),c1_y-(c1_y/2), c1_r*2],[c2_x-(c2_r/2),c2_y-(c2_y/2), c2_r*2])
    #b1.strokeColor=[255,128,0]
    #b2.strokeColor=[255,128,0]
    return circleCollision(b1.circle,b2.circle)
  return false

getA = (circle) ->
  return circle[2]*circle[2]*Math.PI

getADifference = (c1, c2) ->
  return Math.abs(getA(c1)-getA(c2))

getRadiusByArea = (a) ->
  return Math.sqrt(a/Math.PI)

getADifferenceMinusRadius = (circle, minus) ->
  c2 = [circle[0], circle[1], circle[2]-minus]
  getADifference(circle, c2)

colorMixHsl = (hsl1, hsl2, ratio) ->
    [h1, s1, l1] = hsl1
    [h2, s2, l2] = hsl2

    return [(h1+(parseInt(h2*ratio)))%360, (s1+s2)/2, (l1+l2)/2]

colorMix = (rgb1, rgb2, percentage) ->
    [r1, g1, b1] = rgb1
    [r2, g2, b2] = rgb2

    if r1+g1+b1 > 255
      r_faktor = 1; if r1 < r2 then r_faktor = r_faktor*-1
      g_faktor = 1; if g1 < g2 then g_faktor = g_faktor*-1 
      b_faktor = 1; if b1 < b2 then b_faktor = b_faktor*-1
    else
      #return [255,255,255]
      r_faktor = g_faktor = b_faktor = 1


    r_diff = Math.abs(r1-r2)
    g_diff = Math.abs(g1-g2)
    b_diff = Math.abs(b1-b2)

    r_n = clampRgb(r1+(r_diff*percentage*r_faktor))
    g_n = clampRgb(g1+(g_diff*percentage*g_faktor))
    b_n = clampRgb(b1+(b_diff*percentage*b_faktor))
    #R' = R1 + f * (R2 - R1)
    #G' = G1 + f * (G2 - G1)
    #B' = B1 + f * (B2 - B1)
    return [r_n, g_n, b_n]




getRidOfTheDeadAndReturnTheLiving = (bubbles) ->
  temp = []
  for b in bubbles
      if b.alive isnt false
        temp.push(b)
  return temp 

event2Command = (event) ->
  if event.keyCode is 40 then return 'down'
  if event.keyCode is 38 then return 'up'
  if event.keyCode is 37 then return 'left'
  if event.keyCode is 39 then return 'right'
  if event.keyCode is 32 then return 'fire'
  dlog(event.keyCode)
  return false


#drawFunctions
drawCircleBox = (circle, ctx) ->


drawCircle = (ctx, circle, fill = randomColor(), border = [0,0,255], opacity = 1) ->
  [x,y,r]=rc(circle)
  if r <= 0 then return false
  ctx.globalCompositeOperation = "lighter"
  ctx.lineWidth = 2
  #ctx.fillStyle = makeColorString(fill)
  gradient = ctx.createRadialGradient(x, y, 0, x, y, r*DRAW_BIGGER_RADIUS_FACTOR)
  #gradient.addColorStop(0, "white")
  #gradient.addColorStop(0.4, "white")
  gradient.addColorStop(0.4, makeColorString(fill, opacity))
  gradient.addColorStop(1, "black")
  ctx.fillStyle = gradient
  #ctx.strokeStyle = makeColorString(border)
  #ctx.strokeStyle = makeColorString(border)
  ctx.beginPath()
  #ctx.arc(x,y,r,0,2*Math.PI)
  ctx.arc(((0.5 + x) | 0),((0.5 + y) | 0),((0.5 + r*DRAW_BIGGER_RADIUS_FACTOR) | 0), 0,2*Math.PI)
  #ctx.arc((~~(0.5 + x)),(~~(0.5 + y)),(~~(0.5 + r)), 0,2*Math.PI)
  #.arc((Math.round(x)),(Math.round(y)),(Math.round(r)), 0,2*Math.PI)
  ctx.fill()
  #ctx.stroke()

drawCircleExplosion = (circle, options, board_cxt) ->


init = (w = document.getElementById('world'), full_screen = true) ->
  dlog('in init')
  dom_window = window
  loop_id = undefined

  if _NODE_WEBKIT_CONTEXT_ is true
    ngui = require('nw.gui')
    nwin = ngui.Window.get()
    nwin.show()
    dom_window = nwin.window
    if full_screen 
      nwin.maximize()
      w.width = nwin.width-nwin.x
      w.height = nwin.height-nwin.y
    else
      w.width = dom_window.innerWidth
      w.height = dom_window.innerHeight
  else
    w.width = dom_window.innerWidth
    w.height = dom_window.innerHeight
  
  world_width = w.width  
  world_height = w.height


  document.addEventListener('keydown', (event) ->
    event.preventDefault()
    command = event2Command(event)
    if command then setActiveCommand(command)
    )

  document.addEventListener('keyup', (event) ->
    event.preventDefault()
    command = event2Command(event)
    if command then removeActiveCommand(command)
    )

  currently_active_commands = []

  window.onresize = () ->
    #alert('resize')
    window.cancelAnimationFrame(loop_id)
    init(w, false)
  


  getActiveCommands = () ->
    return currently_active_commands

  setActiveCommand = (command) ->
    if currently_active_commands.indexOf(command) is -1
      currently_active_commands.push(command)
    dlog(currently_active_commands)

  removeActiveCommand = (command) ->
    temp = []
    for co in currently_active_commands
      do (co) ->
        if co isnt command
          temp.push(co)
    currently_active_commands = temp
    dlog(currently_active_commands)
  


  game = (w, max_nr_of_enemies, chance_of_new_enemy, min_enemy_speed, max_enemy_speed, number_of_active_players = 1) ->
    wctx = w.getContext('2d')
    cache_canvas = document.createElement('canvas')
    cache_canvas.width = world_width
    cache_canvas.height = world_height
    cctx = cache_canvas.getContext('2d')
    dlog('in game')
    #cctx = wctx
    enemies = []
    players = []
    explosions = []
    bullets = []
    _JUST_FIRED_A_BULLET_ = false

    explodeBubble = (b) ->
      console.log(b)
      [x,y,r] = rc(b.circle)
      explosions.push(makeBullet(x,y,r,0,0,b.fillColor))
      b.alive = false

    joinBubbles = (b1, b2) ->
      [c1_x, c1_y, c1_r] = rc(b1.circle)
      [c2_x, c2_y, c2_r] = rc(b2.circle)
      if c1_r > c2_r
        winner = b1
        looser = b2
      else if c1_r < c2_r
        winner = b2
        looser = b1
      else
        if Math.random() <= 0.5
          explodeBubble(b1)
        else
          explodeBubble(b2)
        return true
      winner.strokeColor = [0,255,0]
      looser.strokeColor = [255,0,0]
      if (winner and looser)
        looser_area_difference = getADifferenceMinusRadius(looser.circle, DEFAULT_NEGATIVE_CIRCLE_JOIN_RATE)
        looser.circle[2] = looser.circle[2] - DEFAULT_NEGATIVE_CIRCLE_JOIN_RATE
        winner_area = getA(winner.circle)
        percentage_of_area = looser_area_difference / winner_area
        winner.fillColor = colorMix(winner.fillColor, looser.fillColor, percentage_of_area)
        winner.circle[2] = getRadiusByArea(winner_area+(looser_area_difference*RATIO_PREVAILANCE_WITH_MERGE))
    
        if looser.circle[2] < MINIMAL_VIABLE_RADIUS
          looser.alive = false
      return [b1, b2]

    movePlayer = (active_commands, w, h, p) ->
      for command in active_commands
        do (command) ->
          if command is 'up'
            p.vy = p.vy - DEFAULT_USER_ACCELERATION
            p.vy = limitPlayerVelocity(p.vy)
          else if command is 'down'
            p.vy = p.vy + DEFAULT_USER_ACCELERATION
            p.vy = limitPlayerVelocity(p.vy)
          else if command is 'left'
            p.vx = p.vx - DEFAULT_USER_ACCELERATION
            p.vx = limitPlayerVelocity(p.vx)
          else if command is 'right'
            p.vx = p.vx + DEFAULT_USER_ACCELERATION
            p.vx = limitPlayerVelocity(p.vx)
          else if command is 'fire'
            fireBulletBy(p)
          else
            dlog('unkown command: '+c)
      moveBubbleWithinBounds(w,h,p)

    fireBulletBy = (p) ->
      if _JUST_FIRED_A_BULLET_ is true then dlog("can't fire");return false
      _JUST_FIRED_A_BULLET_ = true
      delay(500, (()->_JUST_FIRED_A_BULLET_ = false))
      [x,y,r] = p.circle

      bullet_r = r*0.3
      bullet_area = getA([0,0,bullet_r])
      p_area = getA(p.circle)
      p.circle[2]=getRadiusByArea(p_area - bullet_area)
      #console.log('fire '+bullet_r)
      #p.circle[2] = r - bullet_r 
      if p.circle[2] < MINIMAL_VIABLE_RADIUS then p.alive = false
      bullets.push(makeBullet(x,y,bullet_r,p.vx*1.8,p.vy*1.8,p.fillColor))

    update = () ->
      continue_game = true
      
      if players.length < number_of_active_players
        players.push(spawnPlayer(world_width, world_height))

      if enemies.length < max_nr_of_enemies and Math.random() < chance_of_new_enemy
        enemies.push(spawnEnemy(world_width, world_height, MIN_ENEMY_RADIUS, maxEnemySize(players[0]), MIN_ENEMY_SPEED, maxEnemyVelocity(players[0])))


      #move
      for e in enemies
        do (e) ->
          moveBubbleWithinBounds(world_width, world_height, e)

      for p in players
        do (p) ->
          #dlog(p)
          #debugger;
          movePlayer(getActiveCommands(), world_width, world_height, p)
          if p.circle[2] > MAX_RADIUS 
            continue_game = false

      for bullet in bullets
        do (bullet) ->
          moveBubbleWithinBounds(world_width, world_height, bullet)

      for e in explosions
        do (e) ->
          e.circle[2] = e.circle[2] + 50  
          e.opacity = Math.round((e.opacity - 0.1)*100)/100
          if e.opacity <= 0
            e.alive = false  

      #dlog(enemies)
      #debugger;

      ##check if enemies colide with eachother
      for e, i in enemies 
        for e2 in enemies[i+1..]
          if circleCollision(e.circle, e2.circle)
            joinBubbles(e,e2)

      for bullet, i in bullets
        for e in enemies
          if circleCollision(e.circle, bullet.circle)
            explodeBubble(e)
            bullet.alive = false

      ##check if the player(s) collide with the enemies
      for p in players
        for e in enemies
          if circleCollision(p.circle, e.circle)
            joinBubbles(p,e)

      #get rid of not dead enemies
      enemies = getRidOfTheDeadAndReturnTheLiving(enemies)
      bullets = getRidOfTheDeadAndReturnTheLiving(bullets)
      explosions = getRidOfTheDeadAndReturnTheLiving(explosions)

      
      #get rid of dead players, if player number is 0, then game over
      players = getRidOfTheDeadAndReturnTheLiving(players)

      if players.length is 0
        continue_game = false



      ##players_and_enemies = temp

      #now we split them back into players and enemies

      ##players = players_and_enemies.slice(0,players.length)
      ##enemies = players_and_enemies.slice(players.length)

      
      

      all_bubbles = players.concat(enemies, bullets, explosions) #players_and_enemies
      #return players
      #return enemies
      #dlog(all_bubbles)
      #debugger
      return [continue_game, all_bubbles]

    draw = (bubbles) ->
      #wctx.clearRect(0, 0, world_width, world_height)
      cctx.clearRect(0, 0, world_width, world_height)
      #cctx.globalCompositeOperation = "source-over"
      cctx.fillStyle = "rgba(0, 0, 0, 0.3)"
      cctx.fillRect(0, 0, world_width, world_height)
      #debugger;
      #cctx.beginPath()

      for b in bubbles 
        drawCircle(cctx, b.circle, b.fillColor, b.strokeColor, b.opacity)


      #final step, draw the cache over to the world
      wctx.drawImage(cache_canvas,0,0)

    run = () ->
      window.stats.begin()
      loop_id = window.requestAnimationFrame(run)
      [continue_game, bubbles] = update()
      
      #look if our player is still alive
      if continue_game is false
        window.cancelAnimationFrame(loop_id)
        loop_id = undefined
        #alert('ende')
        #start again
        game(w, NUMBER_OF_ENEMIES, ENEMIES_PROPABILITY)

      draw(bubbles)
      window.stats.end()
    run()

  game(w, NUMBER_OF_ENEMIES, ENEMIES_PROPABILITY)

init()
