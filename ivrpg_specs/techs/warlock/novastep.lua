require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"
require "/tech/wizardtech/wizardhover/wizardhover.lua"

oldInit = init
oldUpdate = update

function init()
  oldInit()

  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.cooldown = config.getParameter("cooldown", 2)
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CC33CCFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.cost = config.getParameter("cost", 30)

  Bind.create("Up", platform)
end

function update(args)
  oldUpdate(args)

  self.shiftHeld = not args.moves["run"]

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end
end

function platform()
  if self.shiftHeld and self.cooldownTimer == 0 and not mcontroller.groundMovement() and not mcontroller.liquidMovement() and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    mcontroller.setYVelocity(0)
    world.spawnVehicle("ivrpg_novastep", vec2.sub(mcontroller.position(),{0,3}))
    self.cooldownTimer = self.cooldown
  end
end

function uninit()

end