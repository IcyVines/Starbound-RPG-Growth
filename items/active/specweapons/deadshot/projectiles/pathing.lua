require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  -- self.controlForce = config.getParameter("controlForce", 1000)
  self.maxSpeed = config.getParameter("speed", 150) or 150
  self.start = true
  self.path = nil
  self.timer = 0
  script.setUpdateDelta(1)
  -- self.magicDist = 128
  self.resolution = 16
  self.iters = 8 -- even number please
  self.maxNodes = 2048
  self.direction = vec2.norm(mcontroller.velocity())
  -- sb.logInfo("Direction: " .. sb.printJson(self.direction))

  -- probably overkill bullshit but it works well so just keep it
  self.magic = {}
  local a = A153154(self.iters)
  -- sb.logInfo(sb.printJson(a))
  for i = 1, self.iters do
    self.magic[i] = 2*halton(a[i],1,2)-1
  end
  -- sb.logInfo(sb.printJson(self.magic))

end

function setSmart(mag)
  if mag then
    mcontroller.setVelocity({0,0})
  else
    mcontroller.setVelocity(vec2.mul(self.direction, self.maxSpeed/2))
  end
  mcontroller.applyParameters({
      collisionEnabled = not mag
    })
end

function update(dt)
  if self.timer < 0.05 then
    setSmart(false)
    self.timer = self.timer + dt
    return
  end

  if self.path then
    setSmart(true)
    -- sb.logInfo(sb.printJson(path))
    if self.pathStep <= #self.path then
      local rotation = vec2.angle(world.distance(self.path[self.pathStep].target.position, self.path[self.pathStep].source.position))
      mcontroller.setPosition(self.path[self.pathStep].target.position)
      mcontroller.setRotation(rotation)
      self.pathStep = self.pathStep + 1
      return
    end
  end

  if not findNextPos(vec2.mul(self.direction, self.resolution), self.maxNodes) then
    setSmart(false)
  end
end

function findNextPos(suggestDisp, maxNodes)
  local suggestion = vec2.add(mcontroller.position(), suggestDisp)
  local direction = vec2.norm(suggestDisp)
  for i = 1,self.iters do
    testPos = vec2.add(suggestion, vec2.mul(direction, self.resolution*self.magic[i]))
    if not world.pointTileCollision(testPos, {"Block", "Slippery", "Dynamic"}) then
      if not world.lineTileCollision(mcontroller.position(), testPos, {"Block", "Slippery", "Dynamic"}) then
        setSmart(false)
        return true
      else
        self.path = findPath(testPos, maxNodes)
        if self.path then
          self.pathStep = 1
          return true
        end
      end
    end
  end
  return false
end

function findPath(target, maxNodes)
  local params = mcontroller.parameters()
  params["flySpeed"] = self.maxSpeed
  params["gravityEnabled"] = false
  params["minimumLiquidPercentage"] = 1.1 -- over 100% so never submerged
  pathfinder = world.platformerPathStart(mcontroller.position(), target, params)
  if pathfinder:explore(maxNodes) then
    return pathfinder:result()
  else
    return nil
  end
end

function halton(i,f,b)
  local r = 0
  while(i > 0) do
    f = f/b
    r = r+f*(i % b)
    i = math.floor(i/b)
  end
  return r
end

function A153154(size)
  -- please make size even
  a = {1,3,2}
  for n = 2, size/2 do
    a[2*n] = 2*a[n] + 1
    if n%2==0 then
      a[2*n+1] = 2*a[n+1]
    else
      a[2*n+1] = 2*a[n-1]
    end
  end
  return a
end
