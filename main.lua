function love.load()
  sprites = {}
  sprites.background = love.graphics.newImage("sprites/background.png")
  sprites.player = love.graphics.newImage("sprites/player.png")
  sprites.bullet = love.graphics.newImage("sprites/bullet.png")
  sprites.zombie = love.graphics.newImage("sprites/zombie.png")

  player = {}
  player.x = love.graphics.getWidth() / 2
  player.y = love.graphics.getHeight() / 2
  player.speed = 180

  zombies = {}

  bullets = {}

  gameStates = {}
  gameStates["Main Menu"] = 1
  gameStates["In Session"] = 2

  gameState = gameStates["Main Menu"]
  maxTime = 2
  timer = maxTime
  score = 0

  myFont = love.graphics.newFont(40)
end

function love.update(dt)
  --[[
  These cannot be merged into one if-elseif expression
  because then the latter conditions would not be triggered
  for multi-keys presses (e.g. moving diagonally)
  ]]

  if gameState == 2 then
    if love.keyboard.isDown("w") and player.y > 0 then
      player.y = player.y - (player.speed * dt)
    end

    if love.keyboard.isDown("a") and player.x > 0 then
      player.x = player.x - (player.speed * dt)
    end

    if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
      player.y = player.y + (player.speed * dt)
    end

    if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
      player.x = player.x + (player.speed * dt)
    end
  end

  for i,b in ipairs(bullets) do
    moveBullet(b, dt)
  end

  for i,z in ipairs(zombies) do
    moveZombie(z, dt)
    checkPlayerZombieCollision(z)
  end

  for i=#bullets, 1, -1 do
    removeHiddenBullet(i)
  end

  for i,z in ipairs(zombies) do
    for j,b in ipairs(bullets) do
      checkBulletZombieCollision(b, z)
    end
  end

  for i=#zombies, 1, -1 do
    local z = zombies[i]
    if z.dead == true then
      table.remove(zombies, i)
    end
  end

  for i=#bullets, 1, -1 do
    local b = bullets[i]
    if b.dead == true then
      table.remove(bullets, i)
    end
  end

  if gameState == 2 then
    timer = timer - dt
    if timer <= 0 then
      spawnZombie()
      maxTime = maxTime * 0.95
      timer = maxTime
    end
  end
end

function love.draw()
  love.graphics.draw(sprites.background, 0, 0)

  if gameState == 1 then
    love.graphics.setFont(myFont)
    love.graphics.printf("Click anywhere to start", 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(myFont)
  love.graphics.print("Score: " .. score, x, love.graphics.getHeight(), nil, nil, nil, nil, 40)

  love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth() / 2, sprites.player:getHeight() / 2)

  for i,z in ipairs(zombies) do
    love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth() / 2, sprites.zombie:getHeight() / 2)
  end

  for i,b in ipairs(bullets) do
    love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.25, 0.25, sprites.bullet:getWidth() / 2, sprites.bullet:getHeight() / 2)
  end
end

function playerMouseAngle()
  -- Calculate rotation for the player relative to the mouse
  -- Adding math.pi flips the character to face the mouse
  return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(zombieUnit)
  -- Calculate rotation for the zombie relative to the character
  return math.atan2(zombieUnit.y - player.y, zombieUnit.x - player.x) + math.pi
end

function moveZombie(z, dt)
  z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
  z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)
end

function moveBullet(b, dt)
  b.x = b.x + (math.cos(b.direction) * b.speed * dt)
  b.y = b.y + (math.sin(b.direction) * b.speed * dt)
end

function removeHiddenBullet(i)
  local b = bullets[i]
  if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
    table.remove(bullets, i)
  end
end

function checkPlayerZombieCollision(z)
  local distance = distanceBetween(player.x, player.y, z.x, z.y)
  if distance < 30 then
    for i,z in ipairs(zombies) do
      zombies[i] = nil
      gameState = gameStates["Main Menu"]
      player.x = love.graphics.getWidth() / 2
      player.y = love.graphics.getHeight() / 2
    end
  end
end

function checkBulletZombieCollision(b, z)
  local distance = distanceBetween(b.x, b.y, z.x, z.y)
  if distance < 20 then
    z.dead = true
    b.dead = true
    score = score + 1
  end
end

function spawnZombie()
  zombie = {}
  zombie.x = 0
  zombie.y = 0
  zombie.speed = 100
  zombie.dead = false

  local side = math.random(1, 4)

  if side == 1 then
    zombie.x = -30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 2 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = -30
  elseif side == 3 then
    zombie.x = love.graphics.getWidth() + 30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 4 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = love.graphics.getHeight() + 30
  end

  table.insert(zombies, zombie)
end

function spawnBullet()
  bullet = {}
  bullet.x = player.x
  bullet.y = player.y
  bullet.speed = 500
  bullet.direction = playerMouseAngle()
  bullet.dead = false

  table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
  return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function love.mousepressed(x, y, button)
  if gameState == 1 then
    gameState = gameStates["In Session"]
    maxTime = 2
    timer = maxTime
    score = 0
  end

  if button == 1 and gameState == 2 then
    spawnBullet()
  end
end

-- Test only
-- function love.keypressed(key, scancode, isrepeat)
--   if key == "space" then
--     spawnZombie()
--   end
-- end
