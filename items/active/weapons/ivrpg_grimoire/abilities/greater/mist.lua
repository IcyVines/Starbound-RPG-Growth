require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
  script.setUpdateDelta(30)
  --message.setHandler("kill", projectile.die)
  math.randomseed(os.time())
  self.owner = projectile.sourceEntity()
  if not self.owner then projectile.die() end 
  self.home = mcontroller.position()
end

function update()

  if not self.target then
    local targets = enemyQuery(mcontroller.position(), 15, {}, self.owner)
    if targets then
      for _,id in ipairs(targets) do
        if world.entityExists(id) then
          if self.target and math.random(0, 2) == 2 then
            self.target = id
            return
          else
            self.target = id
          end
        end
      end
    end
  end

  if self.target and world.entityExists(self.target) then
    local newPos = world.entityPosition(self.target)
    newPos = vec2.add(newPos, {math.random(-4, 4), math.random(-4,4)})
    self.home = newPos
  else
    self.target = nil
    self.home = mcontroller.position()
  end

  --self.home = world.entityPosition(self.owner)

  if math.random() < 0.33 then
    mcontroller.setVelocity({math.random() * 2 - 1, math.random() * 0.2 - 0.1})
  end

  if self.home then
    local distanceFrom = world.distance(self.home, mcontroller.position())
    if vec2.mag(distanceFrom) > 1 then
      mcontroller.setVelocity(distanceFrom)
    end
  end
end