require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
  self.damageUpdate = 1
  self.damageGivenUpdate = 1
  self.challengeDamageGivenUpdate = 1
  self.arcExplosion = true
  self.cryoExplosion = true
  self.lastMonster = {nil, nil, nil, nil, nil}
  self.level = -1
  self.id = entity.id()
  message.setHandler("addToChallengeCount", function(_, _, level)
  	addToChallengeCount(level)
  end)
end

function update(dt)
  
  self.xp = world.entityCurrency(self.id, "experienceorb")
  self.level = self.level == -1 and math.floor(math.sqrt(self.xp/100)) or self.level
  self.classType = world.entityCurrency(self.id, "classtype")

  self.strengthBonus = self.classType == 1 and 1.15 or 1
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.05 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.15 or 1))
  self.vigorBonus = self.classType == 4 and 1.15 or (self.classType == 2 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.05 or 1)))
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  self.strength = world.entityCurrency(self.id, "strengthpoint")^self.strengthBonus
  self.agility = world.entityCurrency(self.id,"agilitypoint")^self.agilityBonus
  self.vitality = world.entityCurrency(self.id,"vitalitypoint")^self.vitalityBonus
  self.vigor = world.entityCurrency(self.id,"vigorpoint")^self.vigorBonus
  self.intelligence = world.entityCurrency(self.id,"intelligencepoint")^self.intelligenceBonus
  self.endurance = world.entityCurrency(self.id,"endurancepoint")^self.enduranceBonus
  self.dexterity = world.entityCurrency(self.id,"dexteritypoint")^self.dexterityBonus

  status.setPersistentEffects( "ivrpgstatboosts",
  {

    -- Strength
    {stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.05},
    {stat = "physicalResistance", amount = self.strength*.0025},

    -- Intelligence
    {stat = "energyRegenPercentageRate", amount = .05*self.intelligence},
    {stat = "energyRegenBlockTime", amount = -.01*self.intelligence},

    -- Dexterity
    {stat = "fallDamageMultiplier", amount = -self.dexterity*.005},

    -- Endurance
    {stat = "physicalResistance", amount = self.endurance*.0075},
    {stat = "poisonResistance", amount = self.endurance*.005},
    {stat = "fireResistance", amount = self.endurance*.005},
    {stat = "electricResistance", amount = self.endurance*.005},
    {stat = "iceResistance", amount = self.endurance*.005},
    {stat = "shadowResistance", amount = self.endurance*.005},
    {stat = "cosmicResistance", amount = self.endurance*.005},
    {stat = "radioactiveResistance", amount = self.endurance*.005},
    {stat = "grit", amount = self.endurance*.01},

    --Agility
    {stat = "fallDamageMultiplier", amount = -self.agility*.01},

    -- Vitality
    {stat = "maxHealth", baseMultiplier = math.floor(100*(1 + self.vitality*.05))/100},
    {stat = "foodDelta", amount = self.vitality*.0002},

    -- Vigor
    {stat = "maxEnergy", baseMultiplier = math.floor(100*(1 + self.vigor*.05))/100},
    {stat = "energyRegenPercentageRate", amount = math.floor(.02*self.vigor)}

  })

  -- Agility
  if not status.statPositive("activeMovementAbilities") or mcontroller.canJump() or status.statPositive("ninjaVanishSphere") then
    mcontroller.controlModifiers({
      speedModifier = 1 + self.agility*.02,
      airJumpModifier = 1 + self.agility*.01
    })
  end

  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  self.itemConf = self.heldItem and root.itemConfig(self.heldItem).config
  self.twoHanded = self.itemConf and self.itemConf.twoHanded or false
  self.category = self.itemConf and self.itemConf.category or false
  self.isBrokenBroadsword = self.heldItem == "brokenprotectoratebroadsword" and true or false
  self.weapon1 = self.heldItem and root.itemHasTag(self.heldItem, "weapon") or false
  self.weapon2 = self.heldItem2 and root.itemHasTag(self.heldItem2, "weapon") or false
  self.isBow = self.weapon1 and root.itemHasTag(self.heldItem, "bow") or false

  --Weapon Stat Bonuses
  if self.heldItem == "magnorbs" or self.heldItem == "evileye" then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.01 + self.intelligence*0.01}
    })
  elseif self.heldItem == "remotegrenadelauncher" then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.015}
    })
  elseif self.heldItem == "erchiuseye" then
  	status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.015}
    })
  elseif self.heldItem == "energywhip" then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.02}
    })
  elseif self.heldItem then
  	if root.itemHasTag(self.heldItem, "broadsword") or root.itemHasTag(self.heldItem, "spear") or root.itemHasTag(self.heldItem, "hammer") then
  		status.addPersistentEffects("ivrpgstatboosts",
  		{
  		  {stat = "powerMultiplier", baseMultiplier = 1 + self.strength*0.02}
  		})
	 elseif root.itemHasTag(self.heldItem, "staff") then
  		status.addPersistentEffects("ivrpgstatboosts",
  		{
  		  {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.02}
  		})
  	elseif self.isBow or root.itemHasTag(self.heldItem, "rifle") or root.itemHasTag(self.heldItem, "sniperrifle") or root.itemHasTag(self.heldItem, "assaultrifle") or root.itemHasTag(self.heldItem, "shotgun") or root.itemHasTag(self.heldItem, "rocketlauncher") then
  		status.addPersistentEffects("ivrpgstatboosts",
  		{
  		  {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.015}
  		})
  	else
	    --Bonus for One-Handed Primary
	    if root.itemHasTag(self.heldItem,"wand") then
	      status.addPersistentEffects("ivrpgstatboosts",
	      {
	        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
	      })
	    elseif self.weapon1 or root.itemHasTag(self.heldItem,"ninja") then
	      status.addPersistentEffects("ivrpgstatboosts",
	      {
	        {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.0075}
	      })
	    end
	 end
  end
  --Extra Bonus with One-Handed Secondary
  if self.heldItem2 then
    if root.itemHasTag(self.heldItem2,"wand") then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
      })
    elseif self.weapon2 or root.itemHasTag(self.heldItem2,"ninja") then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.0075}
      })
    end
  end  

  updateClassEffects(self.classType)
  
  -- Affinity Effects
  
  self.affinity = world.entityCurrency(self.id, "affinitytype")
  
  if self.affinity == 0 then
    status.clearPersistentEffects("ivrpgaffinityeffects")
  else
      local frost = hasEphemeralStat("frostslow")
      local wet = hasEphemeralStat("wet")
      local isSuborWet = isInLiquid() | wet
      --sb.logInfo("FROST: "..frost)
      --sb.logInfo("WET: "..wet)
      --sb.logInfo("ISSUBORWET: "..isSuborWet)
      effs = {
        { -- Flame --
          {stat = "fireStatusImmunity", amount = 1},
          {stat = "biomeheatImmunity", amount = 1},
          {stat = "poisonResistance", amount = -0.25 * ((status.stat("ivrpguceternalflame")+1)%2)},
          {stat = "maxEnergy", effectiveMultiplier = 1 - 0.3*isInLiquid() * ((status.stat("ivrpguceternalflame")+1)%2)}
        },
        { -- Venom --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "biomeradiationImmunity", amount = 1},
          {stat = "electricResistance", amount = -0.25 * ((status.stat("ivrpgucincurable")+1)%2)},
          {stat = "maxHealth", effectiveMultiplier = 1 - 0.15 * ((status.stat("ivrpgucincurable")+1)%2)}
        },
        { -- Frost --
          {stat = "iceStatusImmunity", amount = 1},
          {stat = "wetImmunity", amount = 1},
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceslipImmunity", amount = 1},
          {stat = "biomecoldImmunity", amount = 1},
          {stat = "fireResistance", amount = -0.25 * ((status.stat("ivrpgucevergreen")+1)%2)}
        },
        { -- Shock --
          {stat = "electricStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "slimeImmunity", amount = 1},
          {stat = "fumudslowImmunity", amount = 1 },
          {stat = "jungleslowImmunity", amount = 1 },
          {stat = "spiderwebImmunity", amount = 1 },
          {stat = "sandstormImmunity", amount = 1 },
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceResistance", amount = -0.25 * ((status.stat("ivrpgucplasmacore")+1)%2)},
    	    {stat = "maxHealth", effectiveMultiplier = 1 - 0.3*isInLiquid() * ((status.stat("ivrpgucplasmacore")+1)%2)}
        },
        { -- Infernal --
          {stat = "fireStatusImmunity", amount = 1},
          {stat = "fireResistance", amount = 3},
          {stat = "biomeheatImmunity", amount = 1},

          {stat = "poisonResistance", amount = -0.25 * ((status.stat("ivrpguceternalflame")+1)%2)},
          {stat = "maxEnergy", effectiveMultiplier = 1 - 0.3*isInLiquid() * ((status.stat("ivrpguceternalflame")+1)%2)},

          {stat = "ffextremeheatImmunity", amount = 1},
          {stat = "lavaImmunity", amount = 1}
        },
        { -- Toxic --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonResistance", amount = 3},

          {stat = "electricResistance", amount = -0.25 * ((status.stat("ivrpgucincurable")+1)%2)},
          {stat = "maxHealth", effectiveMultiplier = 1 - 0.15  * ((status.stat("ivrpgucincurable")+1)%2)},

          {stat = "biomeradiationImmunity", amount = 1},
          {stat = "ffextremeradiationImmunity", amount = 1},
          {stat = "protoImmunity", amount = 1}
        },
        { -- Cryo --
          {stat = "iceStatusImmunity", amount = 1},
          {stat = "iceResistance", amount = 3},
          {stat = "breathProtection", amount = 1},
          {stat = "wetImmunity", amount = 1},
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceslipImmunity", amount = 1},
          {stat = "biomecoldImmunity", amount = 1},

          {stat = "fireResistance", amount = -0.25 * ((status.stat("ivrpgucevergreen")+1)%2)},

          {stat = "ffextremecoldImmunity", amount = 1},
        },
        { -- Arc --
          {stat = "electricStatusImmunity", amount = 1},
          {stat = "electricResistance", amount = 3},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "slimeImmunity", amount = 1},
          {stat = "fumudslowImmunity", amount = 1 },
          {stat = "jungleslowImmunity", amount = 1 },
          {stat = "spiderwebImmunity", amount = 1 },
          {stat = "sandstormImmunity", amount = 1 },
          {stat = "snowslowImmunity", amount = 1},

          {stat = "iceResistance", amount = -0.25 * ((status.stat("ivrpgucplasmacore")+1)%2)},
          {stat = "maxHealth", effectiveMultiplier = 1 - 0.3*isInLiquid() * ((status.stat("ivrpgucplasmacore")+1)%2)},

          {stat = "shadowResistance", amount = 3},
          {stat = "biomeradiationImmunity", amount = 1}
        }
      }
      status.setPersistentEffects("ivrpgaffinityeffects",effs[self.affinity])

      local aestheticType = {"fire", "poison", "ice", "electric"}
      if status.statPositive("ivrpgucmiasma") then aestheticType[2] = "miasma" end
      if self.affinity > 0 then
        local affinityMod = (self.affinity-1)%4
        if status.statPositive("ivrpgaesthetics") and (mcontroller.xVelocity() > 1 or mcontroller.xVelocity() < -1) and not status.statPositive("activeMovementAbilities") then
          world.spawnProjectile(aestheticType[affinityMod+1].."trailIVRPG", {mcontroller.xPosition(), mcontroller.yPosition()-2}, self.id, {0,0}, false, {power = 0, knockback = 0, timeToLive = 0.3, damageKind = "applystatus"})
        end

        if self.affinity == 8 and status.resource("energy") == 0 and self.arcExplosion then
          self.arcExplosion = false
          world.spawnProjectile("ivrpgarcexplosion", mcontroller.position(), self.id, {0,0}, false)
        end

        if isInLiquid() == 1 then
          if affinityMod == 0 then
            if not status.statPositive("ivrpguceternalflame") then status.overConsumeResource("health", dt) end
          elseif affinityMod == 3 then
            if not status.statPositive("ivrpgucplasmacore") then status.overConsumeResource("energy", dt) end
          end
        end

        if affinityMod == 2 then
          local noSpeedDebuff = false
          if not status.statPositive("ivrpgucevergreen") then
            mcontroller.controlModifiers({
              airJumpModifier = 0.85
            })
            if status.statPositive("ivrpgucicequeen") and world.entityGender(self.id) == "female" then
              if (self.weapon1 and root.itemHasTag(self.heldItem, "whip")) or (self.weapon2 and root.itemHasTag(self.heldItem2, "whip")) then
                noSpeedDebuff = true
              end
            end
            if not noSpeedDebuff then
              mcontroller.controlModifiers({
                speedModifier = 0.85
              })
            end
          end
          if status.statPositive("ivrpgucskadisblessing") then
            if self.isBow then
              status.addPersistentEffect("ivrpgaffinityeffects", {stat = "powerMultiplier", baseMultiplier = 1.5})
            end
          elseif status.statPositive("ivrpgucicequeen") and world.entityGender(self.id) == "female" then
            if (self.weapon1 and (root.itemHasTag(self.heldItem, "dagger") or root.itemHasTag(self.heldItem, "fist") or root.itemHasTag(self.heldItem, "whip"))) or (self.weapon2 and (root.itemHasTag(self.heldItem2, "dagger") or root.itemHasTag(self.heldItem2, "fist") or root.itemHasTag(self.heldItem2, "whip"))) then
              status.addPersistentEffect("ivrpgaffinityeffects", {stat = "powerMultiplier", baseMultiplier = 1.75})
            end
          end
        end

        if affinityMod == 3 then
          if (mcontroller.liquidPercentage() > 0 or wet == 1) and status.statPositive("ivrpgucdischarge") then
            shockNearbyTargets(dt)
          end
        end

        if self.affinity == 7 and status.resource("health")/status.stat("maxHealth") < 0.33 and self.cryoExplosion then
          self.cryoExplosion = false
          world.spawnProjectile("ivrpgcryoexplosionstatus", mcontroller.position(), self.id, {0,0}, false)
        end

      end
  end

  if self.arcExplosion == false and status.resource("energy") > 0 then
    self.arcExplosion = true
  end

  if self.cryoExplosion == false and status.resource("health")/status.stat("maxHealth") >= 0.33 then
    self.cryoExplosion = true
  end

  self.dnotifications, self.damageGivenUpdate = status.inflictedHitsSince(self.damageGivenUpdate)
  if self.dnotifications then
    --sb.logInfo("Damage Taken!!!")
    for _,notification in pairs(self.dnotifications) do
      --sb.logInfo("In damage given update")
      --Rogue Siphon
      if notification.damageSourceKind == "rogueelectricslash" then
        status.modifyResource("energy", 20)
        if status.statPositive("ivrpguccharger") then
          local playerIds = world.playerQuery(mcontroller.position(), 15, {
            withoutEntityId = self.id
          })
          for _,id in ipairs(playerIds) do
            world.sendEntityMessage(id, "modifyResource", "energy", 30)
          end
        end
      elseif notification.damageSourceKind == "roguepoisonslash" then status.modifyResource("health", 10)
      elseif notification.damageSourceKind == "rogueslash" then status.modifyResource("food", 3)
      end
    end
  end

  checkLevelUp()
  updateChallenges()
end

function shockNearbyTargets(dt)
  self.tickTimer = not self.tickTimer and 0.5 or self.tickTimer - dt
  local boltPower = status.stat("powerMultiplier")*5
  if self.tickTimer <= 0 then
    self.tickTimer = 0.5
    local targetIds = world.entityQuery(mcontroller.position(), 8, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      if world.entityCanDamage(self.id, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(self.id)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          self.id,
          directionTo,
          false,
          {
            power = boltPower,
            damageTeam = sourceDamageTeam,
            statusEffects = {"electrified"}
          }
        )
        return
      end
    end
  end
end

function checkLevelUp()
  local currXP = world.entityCurrency(self.id,"experienceorb")
  if currXP >= (self.level+1)^2*100 and self.level < 50 then
    self.level = self.level + 1
    if self.level == 1 then
      return
    end
    status.addEphemeralEffect("ivrpglevelup")
  elseif currXP < (self.level+1)^2*100 then
    self.level = math.floor(math.sqrt(currXP/100))
  end
end

function hasEphemeralStat(stat)
  ephStats = util.map(status.activeUniqueStatusEffectSummary(),
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    if v == stat then return 1 end
  end
  return 0
end

function isInLiquid()
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  local mouthful = world.liquidAt(mouthposition)
    if (world.liquidAt(mouthPosition)) and
	    ((mcontroller.liquidId()== 1) or 
	    (mcontroller.liquidId()== 5) or 
	    (mcontroller.liquidId()== 6) or 
	    (mcontroller.liquidId()== 12) or 
	    (mcontroller.liquidId()== 43) or 
	    (mcontroller.liquidId()== 55) or 
	    (mcontroller.liquidId()== 58) or
	    (mcontroller.liquidId()== 60) or 
	    (mcontroller.liquidId()== 69))
    then
      return 1
    end 
  return 0
end

function updateClassEffects(classType)
  local hardcore = status.statPositive("ivrpghardcore")
  local weaponsDisabled = false

  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("explorerglow")
    status.removeEphemeralEffect("knightblock")
    status.removeEphemeralEffect("ninjacrit")
    status.removeEphemeralEffect("wizardaffinity")
    status.removeEphemeralEffect("roguepoison")
    status.removeEphemeralEffect("soldierdiscipline")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "grit", amount = .2},
    })

    self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
    if self.notifications then
      --sb.logInfo("Damage Taken!!!")
      for _,notification in pairs(self.notifications) do
        if notification.hitType == "ShieldHit" then
          if status.resourcePositive("perfectBlock") then
            --increased damage after perfect blocks
            status.addEphemeralEffect("knightblock")
            --sb.logInfo("Perfect Block: " .. tostring(status.resource("perfectBlock")) .. ", " .. tostring(status.resource("prefectBlockLimit")))
          end
        end
      end
    end

    if self.heldItem and root.itemHasTag(self.heldItem, "broadsword") then
      status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
    elseif self.heldItem and self.heldItem2 and not self.twoHanded then
      if (root.itemHasTag(self.heldItem, "shortsword") and root.itemHasTag(self.heldItem2, "shield")) or (root.itemHasTag(self.heldItem, "shield") and root.itemHasTag(self.heldItem2, "shortsword")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2 + self.strength*.015}
          })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxEnergy", effectiveMultiplier = 0.75}
        })
      mcontroller.controlModifiers({
        speedModifier = 0.9,
        airJumpModifier = 0.7
      })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow then
        if self.twoHanded then
          if self.weapon1 and not root.itemHasTag(self.heldItem, "melee") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "melee") or self.weapon2 then
              weaponsDisabled = true
            end
          elseif self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "melee") then
              weaponsDisabled = true
            end
          end
        end
      end

    end

  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --purposefully left empty
    })
    --Arcane Chance Specified in monster.lua and npc.lua

    self.checkDualWield = true
    self.wizardaffinityAdded = false

    if self.heldItem and root.itemHasTag(self.heldItem, "staff") then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif (self.heldItem and root.itemHasTag(self.heldItem, "wand") and self.heldItem2 and root.itemHasTag(self.heldItem2,"wand")) then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) or (self.heldItem and root.itemHasTag(self.heldItem, "wand")) then
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end

    if holdingWeaponsCheck(self.heldItem, self.heldItem2, false) then
      if (self.heldItem and root.itemHasTag(self.heldItem, "wand")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end

    if holdingWeaponsCheck(self.heldItem2, self.heldItem, false) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end

    if not self.wizardaffinityAdded then
      status.removeEphemeralEffect("wizardaffinity")
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "physicalResistance", amount = -.2}
        })
      mcontroller.controlModifiers({
        speedModifier = 0.8,
        airJumpModifier = 0.8
      })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow and not (self.heldItem == "erchiuseye") and not (self.heldItem == "magnorbs") and not (self.heldItem == "evileye") then
        if self.twoHanded then
          if self.weapon1 and not root.itemHasTag(self.heldItem, "staff") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "wand") then
              weaponsDisabled = true
            end
          end
          if self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "wand") and not root.itemHasTag(self.heldItem2, "dagger") then
              weaponsDisabled = true
            end
          end
        end
      end

    end
  elseif classType == 3 then
    --Ninja
    --ThrowingStar, ThrowingKunai, SnowflakeShuriken, ThrowingKnife, ThrowingDagger
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "fallDamageMultiplier", amount = -.1}
    })
    nighttime = nighttimeCheck()
    underground = undergroundCheck()
    if nighttime or underground then
      status.addEphemeralEffect("ninjacrit", math.huge)
    else
      status.removeEphemeralEffect("ninjacrit")
    end
    self.checkDualWield = true
    --if self.heldItem and root.itemHasTag(self.heldItem, "bow") then
      --status.addPersistentEffects("ivrpgclassboosts",
      --{
        --{stat = "powerMultiplier", effectiveMultiplier = 1.1}
      --})
    --end
    if holdingWeaponsCheck(self.heldItem, self.heldItem2, false) then
      if (self.heldItem and root.itemHasTag(self.heldItem, "ninja")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end
    if holdingWeaponsCheck(self.heldItem2, self.heldItem, false) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "ninja")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end
    mcontroller.controlModifiers({
      speedModifier = 1.1,
      airJumpModifier = 1.1
    })

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxHealth", effectiveMultiplier = 0.5}
        })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow and not (self.heldItem == "adaptablecrossbow") and not (self.heldItem == "soluskatana") and not (self.heldItem == "energywhip") and not (self.heldItem and root.itemHasTag(self.heldItem, "katana")) then
        if self.twoHanded then
          if self.weapon1 then weaponsDisabled = true end
        else
          if self.weapon1 then
            if root.itemHasTag(self.heldItem, "ranged") or root.itemHasTag(self.heldItem, "wand") then
              weaponsDisabled = true
            end
          end
          if self.weapon2 then
            if root.itemHasTag(self.heldItem2, "ranged") or root.itemHasTag(self.heldItem2, "wand") then
              weaponsDisabled = true
            end
          end
        end
      end

    end
  elseif classType == 4 then
    --Soldier
    --Molotov, Thorn Grenade, Bomb
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --Purposefully Empty
    })
    self.energy = status.resource("energy")
    self.maxEnergy = status.stat("maxEnergy")
    if self.energy == self.maxEnergy then
      status.addEphemeralEffect("soldierdiscipline", math.huge)
    elseif self.energy < self.maxEnergy*3/4 then
      status.removeEphemeralEffect("soldierdiscipline")
    end
    if self.heldItem and (root.itemHasTag(self.heldItem, "shotgun") or root.itemHasTag(self.heldItem, "sniperrifle") or root.itemHasTag(self.heldItem, "assaultrifle")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
    elseif holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if (root.itemHasTag(self.heldItem,"soldier") and root.itemHasTag(self.heldItem2,"ranged")) or (root.itemHasTag(self.heldItem,"ranged") and root.itemHasTag(self.heldItem2,"soldier")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "poisonResistance", amount = -.2},
          {stat = "fireResistance", amount = -.2},
          {stat = "electricResistance", amount = -.2},
          {stat = "iceResistance", amount = -.2}
        })
      mcontroller.controlModifiers({
        airJumpModifier = 0.9
      })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow then
        if self.twoHanded then
          if self.weapon1 and (not root.itemHasTag(self.heldItem, "ranged") or self.heldItem == "erchiuseye") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "ranged") or self.weapon2 then
              weaponsDisabled = true
            end
          elseif self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "ranged") then
              weaponsDisabled = true
            end
          end
        end
      end

    end
  elseif classType == 5 then
    --Rogue
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --Purposefully empty
    })
    self.foodValue = status.resource("food")
    if self.foodValue >= 34 then
      status.addEphemeralEffect("roguepoison",math.huge)
    else
      status.removeEphemeralEffect("roguepoison")
    end
    --poison is finished in monster.lua
    if holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if self.weapon1 and self.weapon2 then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxHealth", effectiveMultiplier = 0.8},
          {stat = "foodDelta", amount = -0.002}
        })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow and not (self.heldItem == "energywhip") then
        if self.twoHanded and self.weapon1 then
          weaponsDisabled = true
        elseif (self.heldItem and root.itemHasTag(self.heldItem, "wand")) or (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) then
          weaponsDisabled = true
        end
      end
    end
  elseif classType == 6 then
    --Explorer
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "physicalResistance", amount = .1}
    })
    if (self.heldItem and root.itemHasTag(self.heldItem, "explorer")) or (self.heldItem2 and root.itemHasTag(self.heldItem2, "explorer")) then
      status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1},
          {stat = "physicalResistance", amount = .1},
          {stat = "poisonResistance", amount = .1},
          {stat = "fireResistance", amount = .1},
          {stat = "electricResistance", amount = .1},
          {stat = "iceResistance", amount = .1},
          {stat = "shadowResistance", amount = .1},
          {stat = "cosmicResistance", amount = .1},
          {stat = "radioactiveResistance", amount = .1}
        })
    end
    self.health = world.entityHealth(self.id)
    if self.health[1] ~= 0 and self.health[2] ~= 0 and self.health[1]/self.health[2]*100 >= 50 and not status.statPositive("ivrpgclassability") then
      status.addEphemeralEffect("explorerglow", math.huge)
    else
      status.removeEphemeralEffect("explorerglow")
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "powerMultiplier", effectiveMultiplier = 0.85}
        })
    end
  end

  if weaponsDisabled then
    status.setPersistentEffects("ivrpghardcoreweaponsdisabled", {
      {stat = "powerMultiplier", effectiveMultiplier = 0}
    })
  else
    status.clearPersistentEffects("ivrpghardcoreweaponsdisabled")
  end

end

function holdingWeaponsCheck(heldItem, heldItem2, dualWield)
  if heldItem then
    if heldItem2 then
      if dualWield then
        --Returning True only when two items are equipped and Dual-Wield is specified.
        return true
      else
        if root.itemHasTag(heldItem2, "weapon") then
          --Second Item is a weapon, and Dual-Wield is not specified, so we return False.
          return false
        else
        	--Second item is not a weapon, so we return True.
          return true
        end
      end
    else
      if dualWield then
        --Returning False because Dual-Wield is specified, but there is only one item equipped.
        return false
      else
        --Returning True because Dual-Wield is not specified, and only one item is equipped.
        return true
      end
    end
  else
    --Returning False because no items are equipped.
    return false
  end
end


function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function daytimeCheck()
  return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end

function updateChallenges()
  self.dnotifications, self.challengeDamageGivenUpdate = status.inflictedDamageSince(self.challengeDamageGivenUpdate)
  if self.dnotifications then
    --sb.logInfo("Damage Taken!!!")
    for _,notification in pairs(self.dnotifications) do
      --Challenges
      local challenge1 = status.stat("ivrpgchallenge1")
      local challenge2 = status.stat("ivrpgchallenge2")
      local challenge3 = status.stat("ivrpgchallenge3")

      if challenge1 then
        if challenge1 == 3 then
          if updateProgress(notification, "boss", 7, "kluexboss") then
            status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
          end
        end
      end

      if challenge2 then
		if challenge2 == 2 then
          if updateProgress(notification, "boss", 7, "dragonboss") then
            status.addPersistentEffect("ivrpgchallenge2progress", {stat = "ivrpgchallenge2progress", amount = 1})
          end
        end
      end

      if challenge3 then
		if challenge3 == 2 then
          if updateProgress(notification, "boss", 7, "vault") then
            status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
          end
        elseif challenge3 == 3 then
          if updateProgress(notification, "boss", 7, "eyeboss") then
            status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
          end
        end
      end

      if updateProgress(notification, "boss", 8, "eyeboss") then
      	world.spawnItem("experienceorb", mcontroller.position(), 1000)
      end

      if status.statPositive("ivrpgucskadisblessing") and (self.affinity-1)%4 == 2 and notification.damageSourceKind == "bow" then
        world.sendEntityMessage(notification.targetEntityId, "addEphemeralEffect", "ivrpgembrittle", 3, self.id)
      end

      if status.statPositive("ivrpgucbloodseeker") and notification.damageSourceKind == "bloodaether" then
        world.sendEntityMessage(notification.targetEntityId, "hitByBloodAether")
      end

    end
  end
end

function updateProgress(notification, challengeKind, threatTarget, bossKind)
  local targetEntityId = notification.targetEntityId
  local isMonster = world.isMonster(targetEntityId)
  if not isMonster then
  	return false
  end

  local isNpc = world.isNpc(targetEntityId)
  local monsterName = world.monsterType(targetEntityId)
  local health = world.entityHealth(targetEntityId)
  local healthLost = notification.healthLost
  local hitType = notification.hitType
  local damageTeam = world.entityDamageTeam(targetEntityId)
  local isEnemy = damageTeam and damageTeam.type == "enemy" or false
  local threat = world.threatLevel()
  local bosses = {"crystalboss", "apeboss", "cultistboss", "dragonboss", "eyeboss", "kluexboss", "penguinUfo", "spiderboss", "robotboss", "electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}
  local vaultGuardians = {"electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}
  local notKilled = (targetEntityId ~= self.lastMonster[threatTarget-3])

  if challengeKind == "boss" then
    if notKilled and ((not health) or (healthLost >= health[1])) then
      if bossKind == "vault" then
        for _,boss in pairs(vaultGuardians) do
          if boss == monsterName then
          	self.lastMonster[threatTarget-3] = targetEntityId
            return true
          end
        end
      else
        if bossKind == monsterName then
          self.lastMonster[threatTarget-3] = targetEntityId
          return true
        end
      end
    end
  elseif challengeKind == "bosses" then
    if notKilled and ((not health) or (healthLost >= health[1])) then
      for _,boss in pairs(bosses) do
        if boss == monsterName then
          self.lastMonster[threatTarget-3] = targetEntityId
          return true
        end
      end 
    end
  end
  return false
end

function addToChallengeCount(level)
	--sb.logInfo("Added to Challenge Count with Level: " .. level)
	local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

	if challenge1 == 1 and level >= 4 then
		status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
	elseif challenge1 == 2 and level >= 5 then
		status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
	end

	if challenge2 == 1 and level >= 6 then
		status.addPersistentEffect("ivrpgchallenge2progress", {stat = "ivrpgchallenge2progress", amount = 1})
	end

	if challenge3 == 1 and level >= 7 then
		status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
	end
end