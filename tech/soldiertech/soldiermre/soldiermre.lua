require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.cooldownTimer = 0
  self.grenadeCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.foodGain = config.getParameter("foodGain")
  self.cooldown = config.getParameter("cooldown")

  self.id = entity.id()
  self.validGrenades = config.getParameter("validGrenades", {})
  self.grenadeConfig = config.getParameter("grenadeConfig", {})

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=B7862CFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("f", eat)
end

function eat()
  if (not self.shiftHeld) then
    if self.grenadeCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then lobGrenade() end
    return
  end
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then
      self.cooldownTimer = self.cooldown
      status.addEphemeralEffect("soldiermre", self.cooldown)
      animator.playSound("eat")
      status.modifyResourcePercentage("food", self.foodGain/100)
      status.modifyResourcePercentage("energy", 1)
  end
end

function lobGrenade()
  local handItem = world.entityHandItem(self.id, "alt")
  if handItem then
    local grenade = self.validGrenades[handItem]
    if grenade and status.overConsumeResource("energy", 20) then
      self.grenadeConfig.power = grenade.power / 2 or 0
      self.grenadeConfig.speed = grenade.speed or 0
      world.spawnProjectile(grenade.name or handItem, mcontroller.position(), self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, self.grenadeConfig)
      self.grenadeCooldownTimer = 2
    end
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("soldiermre", self.cooldown)
end

function update(args)
  self.shiftHeld = not args.moves["run"]

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
      --self.rechargeEffectTimer = self.rechargeEffectTime
      --tech.setParentDirectives(self.rechargeDirectives)
      --animator.playSound("recharge")
    end
  end

  if self.grenadeCooldownTimer > 0 then
    self.grenadeCooldownTimer = math.max(0, self.grenadeCooldownTimer - args.dt)
    if self.grenadeCooldownTimer == 0 then
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
