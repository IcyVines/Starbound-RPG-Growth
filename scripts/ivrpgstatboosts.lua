
function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
  self.id = entity.id()
  self.strength = world.entityCurrency(self.id, "strengthpoint")^1.1
  self.agility = world.entityCurrency(self.id,"agilitypoint")^1.1
  self.vitality = world.entityCurrency(self.id,"vitalitypoint")^1.1
  self.vigor = world.entityCurrency(self.id,"vigorpoint")^1.1
  self.intelligence = world.entityCurrency(self.id,"intelligencepoint")^1.1
  self.endurance = world.entityCurrency(self.id,"endurancepoint")^1.1
  self.dexterity = world.entityCurrency(self.id,"dexteritypoint")^1.1
  status.setPersistentEffects( "ivrpgstatboosts",
  {

	-- Strength
    --Increases Shield Health, Damage with melee weapons, and physical resistance
	{stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.01},
  {stat = "physicalResistance", effectiveMultiplier = 1 + self.strength*.005},


	-- Intelligence
	{stat = "energyRegenPercentageRate", effectiveMultiplier = 1+.1*self.intelligence},
	{stat = "energyRegenBlockTime", effectiveMultiplier = 1-.015*self.intelligence},

	-- Dexterity

	-- Endurance
	{stat = "physicalResistance", effectiveMultiplier = 1 + self.endurance*.01},

	-- Vitality
	{stat = "maxHealth", effectiveMultiplier = 1 + self.vitality*.02},
  {stat = "foodDelta", effectiveMultiplier = 1 - self.vitality*.02},

	-- Vigor
	{stat = "maxEnergy", effectiveMultiplier = 1 + self.vigor*.02}
  {stat = "energyRegenPercentageRate", effectiveMultiplier = 1+.1*self.vigor},

  })

  -- Agility
  mcontroller.controlModifiers({
	     speedModifier = 1 + self.agility*.02,
    	airJumpModifier = 1 + self.agility*.02
  })

end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
end
