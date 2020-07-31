require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce", 1000)
  self.maxSpeed = config.getParameter("speed", 60)
  self.start = true
  self.path = nil
  script.setUpdateDelta(1)
end

function update(dt)
  if self.start then
    self.direction = vec2.norm(mcontroller.velocity())
    mcontroller.setVelocity({0,0})
    self.start = false
  end

  if world.magnitude(world.entityPosition(self.playerId), mcontroller.position()) > 50 then
    mcontroller.setVelocity(vec2.mul(self.direction, 150))
    mcontroller.applyParameters({
        collisionEnabled = true
      })
    return
  end

  if self.path then
    mcontroller.applyParameters({
        collisionEnabled = false
      })
    -- sb.logInfo(sb.printJson(path))
    if self.pathStep <= #self.path then
      local rotation = vec2.angle(world.distance(self.path[self.pathStep].target.position, self.path[self.pathStep].source.position))
      mcontroller.setPosition(self.path[self.pathStep].target.position)
      mcontroller.setRotation(rotation)
      self.pathStep = self.pathStep + 1
    else
      self.nextPosition = vec2.add(mcontroller.position(), vec2.mul(self.direction, 20))
      self.path = path()
      if self.path then
        self.pathStep = 1
      else
        mcontroller.setVelocity(vec2.mul(self.direction, 150))
        mcontroller.applyParameters({
          collisionEnabled = true
        })
      end
    end
  else

    self.nextPosition = vec2.add(mcontroller.position(), vec2.mul(self.direction, 20))
    local collisions = world.lineTileCollision(mcontroller.position(), self.nextPosition, {"Block", "Slippery", "Dynamic"})
    if not collisions then
      mcontroller.setVelocity(vec2.mul(self.direction, 150))
      mcontroller.applyParameters({
        collisionEnabled = true
      })
      return
    end
    self.path = path()
    if self.path then
      self.pathStep = 1
    else
      mcontroller.setVelocity(vec2.mul(self.direction, 150))
      mcontroller.applyParameters({
        collisionEnabled = true
      })
    end
  end
end

function path()
  local params = mcontroller.parameters()
  params["flySpeed"] = self.maxSpeed
  params["gravityEnabled"] = false
  params["minimumLiquidPercentage"] = 1.1 -- over 100% so never submerged
  local path = world.findPlatformerPath(mcontroller.position(), self.nextPosition, params)
  -- sb.logInfo("Path?: " .. sb.printJson(params, 1))
  --sb.logInfo("Path?: " .. sb.printJson(path))
  return path
end
