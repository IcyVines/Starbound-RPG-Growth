
function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
  self.id = entity.id()
  self.strength = math.floor(world.entityCurrency(self.id, "strengthpoint")^1.1)
  self.agility = math.floor(world.entityCurrency(self.id,"agilitypoint")^1.1)
  self.vitality = math.floor(world.entityCurrency(self.id,"vitalitypoint"))
  self.vigor = math.floor(world.entityCurrency(self.id,"vigorpoint"))
  self.intelligence = math.floor(world.entityCurrency(self.id,"intelligencepoint")^1.1)
  self.endurance = math.floor(world.entityCurrency(self.id,"endurancepoint")^1.1)
  self.dexterity = math.floor(world.entityCurrency(self.id,"dexteritypoint")^1.1)
  self.classType = world.entityCurrency(self.id, "classtype")
  if self.strength > 0 then
    status.setPersistentEffects( "ivrpgstatboosts",
    {

  	-- Strength
      --Increases Shield Health, Damage with melee weapons, and physical resistance
  	{stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.02},
    {stat = "physicalResistance", amount = self.strength*.0025},
    --still needs melee weapon bonus damage

  	-- Intelligence
  	{stat = "energyRegenPercentageRate", amount = .05*self.intelligence},
  	{stat = "energyRegenBlockTime", amount = -.01*self.intelligence},
    --still needs magic bonus damage

  	-- Dexterity
    {stat = "fallDamageMultiplier", amount = -self.dexterity*.01},
    {stat = "critChance", amount = math.ceil(self.dexterity/1.46)},
    {stat = "cooldown", effectiveMultiplier = 1 - self.dexterity*.1},
    --still needs fire speed increase
    --still needs one-handed weapon bonus damage

  	-- Endurance
  	{stat = "physicalResistance", amount = self.endurance*.005},
    {stat = "poisonResistance", amount = self.endurance*.0025},
    {stat = "fireResistance", amount = self.endurance*.0025},
    {stat = "electricResistance", amount = self.endurance*.0025},
    {stat = "iceResistance", amount = self.endurance*.0025},
    {stat = "shadowResistance", amount = self.endurance*.0025},
    {stat = "cosmicResistance", amount = self.endurance*.0025},
    {stat = "radioactiveResistance", amount = self.endurance*.0025},
    {stat = "grit", amount = self.endurance*.01}, --not tested

    --Agility
    {stat = "fallDamageMultiplier", amount = -self.agility*.005},

  	-- Vitality
  	{stat = "maxHealth", amount = math.floor(self.vitality^1.1*3)},
    {stat = "foodDelta", amount = math.floor(self.vitality^1.1)*.02}, --not tested

  	-- Vigor
  	{stat = "maxEnergy", amount = math.floor(self.vigor^1.1*3)},
    {stat = "energyRegenPercentageRate", amount = .02*math.floor(self.vigor^1.1)}

    })
  end

  -- Agility
  mcontroller.controlModifiers({
    speedModifier = 1 + self.agility*.02,
    airJumpModifier = 1 + self.agility*.01
  })

  updateClassEffects(self.classType)

end

function updateClassEffects(classType)
  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  
  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("ninjaglow")
    status.removeEphemeralEffect("knightblock")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "grit", amount = .2},
    })

    self.notifications = status.damageTakenSince(5)
    if self.notifications then
      sb.logInfo("Damage Taken!!!")
      for _,notification in pairs(self.notifications) do
        if notification.hitType == "ShieldHit" then
          if status.resourcePositive("perfectBlock") then
            --increased damage after perfect blocks
            status.addEphemeralEffect("knightblock")
          end
        end
      end
    end
    if heldItem and root.itemHasTag(heldItem, "broadsword") then
      status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (root.itemHasTag(heldItem, "shortsword") and root.itemHasTag(heldItem2, "shield")) or (root.itemHasTag(heldItem, "shield") and root.itemHasTag(heldItem2, "shortsword")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
      end
    end
  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 3 then
    --Ninja
    --ThrowingStar, ThrowingKunai, SnowflakeShuriken, ThrowingKnife, ThrowingDagger
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "critChance", amount = 20},
      {stat = "critBonus", effectiveMultiplier = 1.2}
    })
    status.addEphemeralEffect("ninjaglow", math.huge)

    if holdingWeaponsCheck(heldItem, heldItem2, false) then
      if (heldItem and root.itemHasTag(heldItem, "ninja")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
      end
    elseif holdingWeaponsCheck(heldItem2, heldItem, false) then
      if (heldItem2 and root.itemHasTag(heldItem2, "ninja")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
      end
    end


  elseif classType == 4 then
    --Soldier
    --Molotov, Thorn Grenade, Bomb
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
    --Flare, Glow Bomb, GlowStick (green, blue, orange, yellow), 
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  end 
end

function holdingWeaponsCheck(heldItem, heldItem2, dualWield)
  if heldItem then
    --first item exists
    if heldItem2 then
      --second item exists
      if dualWield then
        --bonus from two weapons
        return true
      else
        --bonus should only apply to single weapon
        if root.itemHasTag(heldItem2, "weapon") then
          return false
        else
          return true
        end
      end
    else
      --second item does not exist
      if dualWield then
        --bonus applies with only two weapons
        return false
      else
        --only one item is equipped and we might get a bonus
        return true
      end
    end
  else
    --no item
    return false
  end
end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
  status.clearPersistentEffects("ivrpgclassboosts")
  status.removeEphemeralEffect("ninjaglow")
end
