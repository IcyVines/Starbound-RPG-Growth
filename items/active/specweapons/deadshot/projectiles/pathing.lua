require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce", 1000)
  self.maxSpeed = config.getParameter("speed", 60)
  self.start = true
  self.pathLength = 0
  self.pathStep = 1
  self.path = nil
  script.setUpdateDelta(1)
  --[[mcontroller.applyParameters({
    collisionEnabled = false
  })]]
end

function update(dt)
  if self.start then
    self.direction = vec2.norm(mcontroller.velocity())
    self.nextPosition = vec2.add(mcontroller.position(), vec2.mul(self.direction, 20))
    self.start = false
  end
  
  if self.path then
    --sb.logInfo(sb.printJson(path))
    self.pathLength = #self.path
    if self.pathStep <= self.pathLength then
      mcontroller.setPosition(self.path[self.pathStep].target.position)
      self.pathStep = self.pathStep + 2
    else

    end
  else
    self.path = hasPath()
  end
end

function hasPath()
  local params = mcontroller.parameters()
  params["flySpeed"] = 100
  params["gravityEnabled"] = false
  params["minimumLiquidPercentage"] = 1.1 -- over 100% so never submerged
  local path = world.findPlatformerPath(mcontroller.position(), self.nextPosition, params)
  -- sb.logInfo("Path?: " .. sb.printJson(params, 1))
  -- sb.logInfo("Path?: " .. sb.printJson(path, 1))
  return path
end