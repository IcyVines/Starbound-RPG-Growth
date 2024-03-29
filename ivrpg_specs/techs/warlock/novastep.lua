require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"
require "/tech/wizardtech/wizardhover/wizardhover.lua"

oldInit = init

function init()
  oldInit()

  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  _,self.damageUpdate = status.damageTakenSince()
  self.cooldown = config.getParameter("cooldown", 2)
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CC33CCFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.cost = config.getParameter("cost", 30)

  Bind.create("specialThree", platform)
end

function update(args)
  local action = input(args)
  local energyUsagePerSecond = config.getParameter("energyUsagePerSecond")
  local hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  local vDirection = args.moves["down"] and -1 or (args.moves["up"] and 1 or 0)
  local energyOff = (vDirection == -1 and hDirection == 0) and 4 or (vDirection == -1 and 3 or ((hDirection == 0 and vDirection == 0) and 1.5 or (vDirection == 1 and 0.5 or 1)))

  if action == "wizardhover" and (not status.statPositive("activeMovementAbilities")) and status.overConsumeResource("energy", energyUsagePerSecond * args.dt / energyOff)  then
    local agility = status.statusProperty("ivrpgagility", 0)
    local intelligence = status.statusProperty("ivrpgintelligence", 0)
    local maxSpeed = math.min(agility^0.7 + intelligence^0.9 + 10, 50)
    local angle = (hDirection ~= 0 or vDirection ~= 0) and vec2.angle({hDirection, vDirection}) or false
    local velocity = angle and vec2.withAngle(angle, maxSpeed) or {0,0}
    mcontroller.controlApproachVelocity(velocity, self.hoverControlForce)
    if vDirection == 0 then mcontroller.controlApproachYVelocity(0, self.hoverControlForce) end

    if not self.active then
      animator.playSound("activate")
      animator.setAnimationState("hover", "toggleOn")
    end
    self.active = true
  else
    if self.active then
      mcontroller.controlApproachVelocity({0,0}, self.hoverControlForce * 10)
      animator.setAnimationState("hover", "toggleOff")
    end
    self.active = false
  end

  self.shiftHeld = not args.moves["run"]

  if self.active then
    status.setPersistentEffects("ivrpg_novastep", {
      {stat = "physicalResistance", amount = 0.2},
      {stat = "iceStatusImmunity", amount = 1},
      {stat = "fireStatusImmunity", amount = 1},
      {stat = "electricStatusImmunity", amount = 1}
    })
  else
    status.clearPersistentEffects("ivrpg_novastep")
  end

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

  updateDamageTaken()
end

function platform()
  if self.cooldownTimer == 0 and not mcontroller.groundMovement() and not mcontroller.liquidMovement() and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    mcontroller.setYVelocity(0)
    animator.playSound("activateStep")
    world.spawnVehicle("ivrpg_novastep", vec2.sub(mcontroller.position(),{0,3.5}))
    world.spawnProjectile("ivrpg_novastepstorm", vec2.sub(mcontroller.position(),{0,3.5}), entity.id(), {0, 0}, false, {timeToLive = 5})
    self.cooldownTimer = self.cooldown
  end
end

function uninit()
  status.clearPersistentEffects("ivrpg_novastep")
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.active and notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        if notification.sourceEntityId and world.entityExists(notification.sourceEntityId) then
          local targetPos = world.entityPosition(notification.sourceEntityId)
          local direction = world.distance(targetPos, mcontroller.position())
          world.spawnProjectile("ivrpg_novawave", mcontroller.position(), entity.id(), direction, false, {power = status.statusProperty("ivrpgintelligence") / 25})
        end
      end
    end
  end
end