
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
  self.classType = world.entityCurrency(self.id, "classtype")
  status.setPersistentEffects( "ivrpgstatboosts",
  {

	-- Strength
    --Increases Shield Health, Damage with melee weapons, and physical resistance
	{stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.01},
  {stat = "physicalResistance", effectiveMultiplier = 1 + self.strength*.005},
  --still needs melee weapon bonus damage

	-- Intelligence
	{stat = "energyRegenPercentageRate", effectiveMultiplier = 1+.05*self.intelligence},
	{stat = "energyRegenBlockTime", effectiveMultiplier = 1-.015*self.intelligence},
  --still needs magic bonus damage

	-- Dexterity
  {stat = "fallDamageMultiplier", effectiveMultiplier = 1 - self.dexterity*.01},
  --{stat = "critChance", effectiveMultiplier = 1 + self.dexterity*.005},
  --{stat = "fireTime", effectiveMultiplier = 1 + self.dexterity*.005},
  --still needs one-handed weapon bonus damage

	-- Endurance
	{stat = "physicalResistance", effectiveMultiplier = 1 + self.endurance*.01},
  {stat = "poisonResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "fireResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "electricResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "iceResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "shadowResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "cosmicResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "radioactiveResistance", effectiveMultiplier = 1 + self.endurance*.005},
  {stat = "grit", effectiveMultiplier = 1 + self.endurance*.01}, --not tested

  --Agility
  {stat = "fallDamageMultiplier", effectiveMultiplier = 1 + self.agility*.005},

	-- Vitality
	{stat = "maxHealth", effectiveMultiplier = 1 + self.vitality*.02},
  {stat = "foodDelta", effectiveMultiplier = 1 - self.vitality*.02}, --not tested

	-- Vigor
	{stat = "maxEnergy", effectiveMultiplier = 1 + self.vigor*.02},
  {stat = "energyRegenPercentageRate", effectiveMultiplier = 1+.1*self.vigor}

  })

  -- Agility
  mcontroller.controlModifiers({
    speedModifier = 1 + self.agility*.02,
    airJumpModifier = 1 + self.agility*.005
  })

  updateClassEffects(self.classType)

end

function updateClassEffects(classType)
  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 3 then
    --Ninja
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 4 then
    --Soldier
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 5 then
    --Rogue
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 6 then
    --Explorer
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  end 
end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
  status.clearPersistentEffects("ivrpgclassboosts")
end
