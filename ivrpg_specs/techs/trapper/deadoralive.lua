require "/scripts/keybinds.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = entity.id()

  self.pet = status.statusProperty("ivrpg_trapperPet", nil)
  self.trapEnergyCost = config.getParameter("trapEnergyCost", 80)
  self.explodeEnergyCost = config.getParameter("explodeEnergyCost", 20)
  self.damageModifier = config.getParameter("damageModifier", 1)

  message.setHandler("beartrapCapture", function(_, _, pet, id)
    self.pet = pet
    status.setStatusProperty("ivrpg_trapperPet", self.pet)
    if self.pet and self.pet.config and self.pet.config.parameters and self.pet.config.parameters.level then
      world.spawnTreasure(mcontroller.position(), "money", self.pet.config.parameters.level)
      world.spawnTreasure(mcontroller.position(), "experienceorbpool", self.pet.config.parameters.level)
    end
  end)

  Bind.create("f", placeTrap)
end

function placeTrap()
  if self.shiftHeld and self.pet and self.pet.config and self.pet.config.type and not self.spawned then
    local params = self.pet.config.parameters or {}
    params.damageTeamType = "friendly"
    params.aggressive = true
    params.ownerUuid = entity.uniqueId()
    params.ownerId = self.id
    animator.playSound("spawnMonster")
    world.spawnMonster(self.pet.config.type, mcontroller.position(), params)
    animator.setAnimationState("captureStatus", "off")
    self.pet = nil
    status.setStatusProperty("ivrpg_trapperPet", nil)
  else
    if self.projectile and world.entityExists(self.projectile) and status.overConsumeResource("energy", self.explodeEnergyCost) then
      local power = status.statusProperty("ivrpgdexterity", 1) * self.damageModifier
      world.sendEntityMessage(self.projectile, "explode", power, status.stat("powerMultiplier"))
      self.projectile = nil
    elseif status.overConsumeResource("energy", self.trapEnergyCost) then
      animator.playSound("spawnTrap")
      self.projectile = world.spawnProjectile("ivrpg_beartrap", mcontroller.position(), self.id, {0,-5}, false, {timeToLive = 30, powerMultiplier = status.stat("powerMultiplier")})
    end
  end
end

function uninit()
  status.clearPersistentEffects("ivrpgdeadoralive")
  tech.setParentDirectives()
end

function update(args)
  self.shiftHeld = not args.moves["run"]

  if self.pet then
    animator.setAnimationState("captureStatus", "on")
  else
    animator.setAnimationState("captureStatus", "off")
  end

end