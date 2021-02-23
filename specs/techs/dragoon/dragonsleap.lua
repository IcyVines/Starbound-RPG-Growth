require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/tech/knighttech/knightslam/knightslam.lua"

local origInit = init
local origUpdate = update
local origUninit = uninit

function init()
  origInit()
  self.chargeTimer = 0
  self.leapActive = false
  self.slammedGroundTimer = 0
end

function uninit()
  tech.setParentDirectives()
  tech.setParentState()
  status.clearPersistentEffects("ivrpgdragonsleap")
  status.removeEphemeralEffect("ivrpgdragonscrash")
  origUninit()
end

function update(args)
  origUpdate(args)

   if mcontroller.falling() or mcontroller.onGround() or mcontroller.liquidMovement() then
    if not self.leapActive and self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
      status.clearPersistentEffects("ivrpgdragonsleap")
    end
    self.leapActive = false
  end


  if (not self.leapActive) and self.slammedGroundTimer == 0 and mcontroller.onGround() and args.moves["run"] == false and args.moves['jump'] and status.overConsumeResource("energy", args.dt * 20) then
    if self.chargeTimer < 2.5 then
      if self.chargeTimer == 0 then animator.playSound("charge") end
      local alpha = math.min(self.chargeTimer / 3, 0.85)
      tech.setParentDirectives("?fade=ff230f=" .. alpha)
      self.chargeTimer = math.min(self.chargeTimer + args.dt, 2.5)
      tech.setParentState("duck")
      status.setPersistentEffects("ivrpgdragonsleap", {
        { stat = "protection", amount = 10 * self.chargeTimer},
        { stat = "grit", amount = 1 }
      })
      mcontroller.controlModifiers({
        movementSuppressed = true
      })
    else
      leap(args)
    end
  elseif self.chargeTimer > 0 then
    leap(args)
  end

  if self.leapActive then
    mcontroller.controlModifiers({
      jumpingSuppressed = true
    })
  end

  if self.slammedGroundTimer > 0 then
    mcontroller.setVelocity({0,0})
    mcontroller.controlModifiers({
      movementSuppressed = true
    })
    self.slammedGroundTimer = math.max(self.slammedGroundTimer - args.dt, 0)
  end

  if (mcontroller.groundMovement() and mcontroller.onGround()) or self.liquidMovement then
    if self.slammedGroundTimer == 0 then
      status.removeEphemeralEffect("ivrpgdragonscrash")
    end
  end
end

function doSlam()
  if not self.downPressed and self.slamCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    local cPos = tech.aimPosition()
    local mPos = mcontroller.position()
    local distance = world.distance(cPos, mPos)
    local modifier = distance[1] < 0 and -1 or 1
    self.downPressed = true
    self.lastYPosition = mcontroller.yPosition()
    status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
    status.addEphemeralEffect("ivrpgdragonscrash", math.huge)
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(math.min(math.abs(distance[2]) * -20), -120)
    mcontroller.setXVelocity(modifier * math.min(math.abs(distance[1]) * 10, 75))
    animator.burstParticleEmitter("downParticles")
    animator.playSound("multiJumpSound")
  end
end

function spawnExplosions(x, y)
  self.slammedGroundTimer = 0.3
  self.strength = status.statusProperty("ivrpgstrength", 0)
  local damageFallOff = 1
  local bonusKnockback = 0
  if self.peakPerformance then
    damageFallOff = 0.8
    bonusKnockback = 40
  end

  local projectileParameters = {}
  projectileParameters.powerMultiplier = status.stat("powerMultiplier")
  projectileParameters.power = math.min(200*damageFallOff, (self.lastYPosition^2*self.strength/50+1)*damageFallOff)/5
  projectileParameters.knockback = 10 + bonusKnockback
  projectileParameters.actionOnTimeout = {
    {
      action = "projectile",
      inheritDamageFactor = 1,
      type = "firepillar",
      config = { }
    }
  }

  local pillarDuration = 1
  animator.playSound("slamSound")
  for j = -5, 5, 2.5 do
    local breakChain = false
    local chainStarted = false
    local projectileCount = 3 + (math.abs(j) == 2.5 and 2 or (j == 0 and 4 or 0))
    for i = 0, (projectileCount - 1) do
      projectileParameters.timeToLive = i * 0.02
      projectileParameters.actionOnTimeout[1].config.timeToLive = pillarDuration - (2 * projectileParameters.timeToLive)
      local yPosition = y - 3 + i
      local isEmpty = not world.pointTileCollision({x + j, yPosition}, {"Null", "Block", "Dynamic"})
      if isEmpty and not chainStarted and not world.pointTileCollision({x + j, yPosition - 1}, {"Null", "Block", "Dynamic"}) then
        breakChain = true
      end
      if isEmpty and not breakChain then
        world.spawnProjectile("pillarspawner", {x + j, yPosition}, entity.id(), {0, 0}, false, projectileParameters)
        chainStarted = true
      end
    end
  end
end

function leap(args)
  animator.stopAllSounds("charge")
  animator.playSound("leap")
  status.setPersistentEffects("ivrpgdragonsleap", {
    { stat = "invulnerable", amount = 1 },
    { stat = "grit", amount = 1 }
  })
  tech.setParentDirectives("?border=1;ff230faa")
  tech.setParentState()
  mcontroller.clearControls()
  self.leapActive = true
  local charge = (self.chargeTimer + 1)^0.75
  self.chargeTimer = 0
  self.jumpsLeft = 0
  local direction = args.moves["right"] and 1 or (args.moves["left"] and -1 or 0)
  mcontroller.controlApproachVelocity({direction * 200 * charge, 500 * charge}, 4000 * charge)
end
