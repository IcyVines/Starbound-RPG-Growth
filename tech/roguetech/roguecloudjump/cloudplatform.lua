require "/scripts/rails.lua"

function init()
  mcontroller.setRotation(0)
  vehicle.setInteractive(false)
  self.timer = config.getParameter("liveTime", 5)
end

function update(dt)
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    return
  end

  if self.timer > 0 then
    self.timer = math.max(0, self.timer - dt)
    if self.timer == 0 then
      vehicle.destroy() 
    end
  end
end
