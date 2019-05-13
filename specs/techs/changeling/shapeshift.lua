require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/specs/techs/changeling/shapeshiftHelper.lua"

function init()
  self.id = entity.id()
  initCommonParameters()
  status.setStatusProperty("ivrpgshapeshift", true)
  Bind.create("f", shapeshift)
  Bind.create("g", action1)
  Bind.create("h", action2)
  Bind.create("primaryFire", primaryFire)
  Bind.create("altFire", altFire)
end

function shapeshift()
  self.oldCreature = self.creature
  if self.shiftHeld and self.downHeld then
    return
  elseif self.downHeld then
    self.creature = "orbide"
  elseif self.shiftHeld then
    self.creature = "poptop"
  else
    self.creature = "wisper"
  end
  attemptActivation(self.oldCreature == self.creature)
end

function action1()

end

function action2()
  if self.creature == "poptop" then
    self.oldCreature = self.creature
    self.creature = "adultpoptop"
    attemptActivation(false)
  end
end

function primaryFire()

end

function altFire()

end

function uninit()
  tech.setParentDirectives()
  self.oldPoly = false
  storePosition()
  deactivate()
  status.setStatusProperty("ivrpgshapeshift", false)
end

function update(args)
  meltyBlood()
  restoreStoredPosition()
  self.shiftHeld = not args.moves["run"]
  self.downHeld = args.moves["down"]
  self.hDirection = (args.moves["left"] == args.moves["right"]) and 0 or (args.moves["right"] and 1 or -1)
  self.vDirection = (args.moves["up"] == self.downHeld) and 0 or (self.downHeld and -1 or 1)

  self.directives = ""
  if self.active then
    if status.statPositive("ivrpgmeltyblood") then
      self.directives = "?scalenearest=0.5"
    else
       self.basePoly = mcontroller.baseParameters().standingPoly
    end
    self.directives = self.directives .. "?hueshift=" .. self.hueShift
  else
    self.basePoly = mcontroller.collisionPoly()
  end

  --[[if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]]

  if not args.moves["special1"] then
    self.forceTimer = nil
  end  

  if self.active then
    local collisionPoly = config.getParameter(self.creature .. (status.statPositive("ivrpgmeltyblood") and "MeltyCollisionPoly" or  "CollisionPoly"))
    self.transformedMovementParameters.collisionPoly = collisionPoly
    mcontroller.controlParameters(self.transformedMovementParameters)
    updateFrame(args.dt)
    checkForceDeactivate(args.dt)
    calculatePassives()
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function calculatePassives()

end

function meltyBlood()
  if status.statPositive("ivrpgmeltyblood") then
    tech.setToolUsageSuppressed(true)
  elseif not self.active then
    tech.setToolUsageSuppressed(false)
  end
end