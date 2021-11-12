require "/scripts/keybinds.lua"

function init()
  self.cost = config.getParameter("cost")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.controlForce = config.getParameter("controlForce")
  
  self.soundActive = false

  self.hDirection = 0
  self.vDirection = 0
  self.shift = 1
  
end

function phase()
  local diagonal = math.abs(self.hDirection*self.vDirection) * math.sqrt(2)
  local agility = status.statusProperty("ivrpgagility", 1)
  local speed = self.dashSpeed + (agility / 10)
  diagonal = diagonal == 0 and 1 or diagonal

  mcontroller.controlApproachVelocity({speed * self.hDirection / diagonal, speed * self.vDirection / diagonal}, self.controlForce)
  
  if self.shift == 1 then
    mcontroller.controlParameters({
      collisionEnabled = false
    })
    tech.setParentDirectives("?multiply=666666CC")
    status.setPersistentEffects("ivrpgdarkphase", {
      {stat = "invulnerable", amount = 1}
    })
  else
    tech.setParentDirectives()
    status.clearPersistentEffects("ivrpgdarkphase")
  end

  if not self.soundActive then
    animator.playSound("ghostly", -1)
    self.soundActive = true
  end
  
end

function uninit()
  reset()
end

function reset()
  tech.setParentDirectives()
  status.clearPersistentEffects("ivrpgdarkphase")
  animator.stopAllSounds("ghostly")
  self.soundActive = false
end

function update(args)
  -- Find Directional Input
  directionalInput(args)

  if self.jumping and (not status.statPositive("activeMovementAbilities")) and status.overConsumeResource("energy", self.cost * args.dt / self.shift) then
    phase()
  else
    reset()
  end

  mcontroller.controlModifiers({jumpingSuppressed = true})
end


function directionalInput(args)
  self.hDirection = 0
  self.vDirection = 0
  if args.moves["left"] and not args.moves["right"] then
    self.hDirection = -1
  elseif args.moves["right"] and not args.moves["left"] then
    self.hDirection = 1
  end
  if args.moves["up"] and not args.moves["down"] then
    self.vDirection = 1
  elseif args.moves["down"] and not args.moves["up"] then
    self.vDirection = -1
  end
  if args.moves["run"] then self.shift = 1 else self.shift = 2 end
  if args.moves["jump"] then self.jumping = true else self.jumping = false end
end