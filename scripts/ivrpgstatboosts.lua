require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(15)

  -- General Variables
  self.damageUpdate = 1
  self.damageGivenUpdate = 1
  self.hitsInflictedUpdate = 5
  self.challengeDamageGivenUpdate = 1
  self.arcExplosion = true
  self.cryoExplosion = true
  self.lastMonster = {nil, nil, nil, nil, nil}
  self.level = -1
  self.rpgPlayerID = entity.id()
  self.affinity = 0
  self.class = 0
  self.profession = 0

  message.setHandler("bleedCheck", function(_, _, damage, sourceKind, sourceId)
    local bleedChance = status.stat("ivrpgBleedChance")
    local bleedLength = status.stat("ivrpgBleedLength")
    local guaranteed = string.find(sourceKind, "bleed") or string.find(sourceKind, "scythe")
    local noBleed = string.find(sourceKind, "bluntforce") or string.find(sourceKind, "hammer")
    if (bleedChance > math.random() or guaranteed) and not noBleed then
      bleedLength = (guaranteed and bleedLength < 1) and 1 or bleedLength
      world.sendEntityMessage(sourceId, "applySelfDamageRequest", "IgnoresDef", "bleed", damage/2, self.rpgPlayerID, sourceKind)
      world.sendEntityMessage(sourceId, "addEphemeralEffect", "ivrpgweaken", bleedLength, self.rpgPlayerID)
    end
  end)

  -- Configs
  self.specList = root.assetJson("/ivrpgSpecList.config")
  self.classList = root.assetJson("/ivrpgClassList.config")
  self.affinityList = root.assetJson("/ivrpgAffinityList.config")
  self.profList = root.assetJson("/ivrpgProfessionList.config")
  self.statList = root.assetJson("/ivrpgStats.config")
  self.weaponScaling = root.assetJson("/ivrpgWeaponScaling.config")
  self.skillList = root.assetJson("/ivrpgSkillList.config")
end

function updateHeldItems()
  self.heldItem = world.entityHandItem(self.rpgPlayerID, "primary")
  self.heldItem2 = world.entityHandItem(self.rpgPlayerID, "alt")
  if self.heldItem == "sapling" then self.heldItem = nil end
  if self.heldItem2 == "sapling" then self.heldItem2 = nil end
  self.itemConf = self.heldItem and root.itemConfig(self.heldItem).config
  self.twoHanded = self.itemConf and self.itemConf.twoHanded or false
  self.category = self.itemConf and self.itemConf.category or false
  self.isBrokenBroadsword = self.heldItem == "brokenprotectoratebroadsword" and true or false
  self.weapon1 = self.heldItem and root.itemHasTag(self.heldItem, "weapon") or false
  self.weapon2 = self.heldItem2 and root.itemHasTag(self.heldItem2, "weapon") or false
  self.isBow = self.weapon1 and root.itemHasTag(self.heldItem, "bow") or false
end

function update(dt)
  self.xp = math.min(world.entityCurrency(self.rpgPlayerID, "experienceorb"), 500000)
  self.level = self.level == -1 and math.floor(math.sqrt(self.xp/100)) or self.level
  self.classicMode = status.statPositive("ivrpghardcore")

  updateStats()
  updateStealth()
  local pStatus, pMessage = pcall(updateHeldItems)
  if not pStatus then sb.logInfo(pMessage or "There was an error attempting to generate an item config") end

  --Weapon Stat Bonuses
  
  --[[
  Based on String Finds, removed for optimization reasons
  local stringFind = false
  local stringFind2 = false
  if self.heldItem or self.heldItem2 then
    for name,t in pairs(self.weaponScaling.finds) do
      if self.heldItem and string.find(self.heldItem, name) then
        local statAmount = 1
        for k,v in pairs(t) do
          statAmount = statAmount + self.stats[k]*v
        end
        status.addPersistentEffects("ivrpgstatboosts", {
          {stat = "powerMultiplier", baseMultiplier = statAmount}
        })
        stringFind = true
      end
      if self.heldItem2 and string.find(self.heldItem2, name) then
        local statAmount = 1
        for k,v in pairs(t) do
          statAmount = statAmount + self.stats[k]*v
        end
        status.addPersistentEffects("ivrpgstatboosts", {
          {stat = "powerMultiplier", baseMultiplier = statAmount}
        })
        stringFind2 = true
      end
    end
  end
  ]]

  if self.heldItem and self.weaponScaling.items[self.heldItem] then
    local statAmount = 1
    for k,v in pairs(self.weaponScaling.items[self.heldItem]) do
      statAmount = statAmount + self.stats[k]*v
    end
    status.addPersistentEffects("ivrpgstatboosts", {
      {stat = "powerMultiplier", baseMultiplier = statAmount}
    })
  elseif self.heldItem then
     --Bonus for One-Handed Primary
    for k,v in pairs(root.itemTags(self.heldItem)) do
      tagInfo = self.weaponScaling.tags[v]
      if tagInfo and tagInfo.conflictingTags then
        for _,tag in ipairs(tagInfo.conflictingTags) do
          if root.itemHasTag(self.heldItem, tag) then
            tagInfo = false
          end
        end
      end
      if tagInfo then
        local statAmount = -1
        local amount = 0
        for x,y in pairs(self.twoHanded and tagInfo.twoHanded or tagInfo.oneHanded) do
          if self.stats[x] > statAmount then
            statAmount = self.stats[x]
            amount = y
          end
        end
        status.addPersistentEffects("ivrpgstatboosts", {
          {stat = "powerMultiplier", baseMultiplier = 1 + statAmount*amount}
        })
        break
      end
    end
  end
  --Extra Bonus with One-Handed Secondary
  if self.heldItem2 and not self.twoHanded then
    for k,v in pairs(root.itemTags(self.heldItem2)) do
      tagInfo = self.weaponScaling.tags[v]
      if tagInfo and tagInfo.conflictingTags then
        for _,tag in ipairs(tagInfo.conflictingTags) do
          if root.itemHasTag(self.heldItem2, tag) then
            tagInfo = false
          end
        end
      end
      if tagInfo then
        local statAmount = -1
        local amount = 0
        for x,y in pairs(tagInfo.oneHanded) do
          if self.stats[x] > statAmount then
            statAmount = self.stats[x]
            amount = y
          end
        end
        status.addPersistentEffects("ivrpgstatboosts", {
          {stat = "powerMultiplier", baseMultiplier = 1 + statAmount*amount}
        })
        break
      end
    end
  end  

  updateProfessionEffects(dt)
  updateClassEffects(dt)
  updateAffinityEffects(dt)
  if not self.classicMode then
    status.clearPersistentEffects("ivrpghardcoreweaponsdisabled")
  end

  checkLevelUp()
  updateDamageGiven()
  updateDamageTaken()
  updateChallenges()
  updateSkills()
end

function updateStealth()
  local shouldStealth = status.statPositive("invisible") or status.statPositive("ivrpgstealth")
  world.setProperty("entity["..tostring(self.rpgPlayerID).."]Stealthed", shouldStealth)
end

function updateStats()
  self.stats = {
    strength = world.entityCurrency(self.rpgPlayerID, "strengthpoint"),
    agility = world.entityCurrency(self.rpgPlayerID, "agilitypoint"),
    vitality = world.entityCurrency(self.rpgPlayerID, "vitalitypoint"),
    vigor = world.entityCurrency(self.rpgPlayerID, "vigorpoint"),
    intelligence = world.entityCurrency(self.rpgPlayerID, "intelligencepoint"),
    endurance = world.entityCurrency(self.rpgPlayerID, "endurancepoint"),
    dexterity = world.entityCurrency(self.rpgPlayerID, "dexteritypoint")
  }
  self.statBonuses = {
    strength = 1 + status.stat("ivrpgstrengthscaling"),
    agility = 1 + status.stat("ivrpgagilityscaling"),
    vitality = 1 + status.stat("ivrpgvitalityscaling"),
    vigor = 1 + status.stat("ivrpgvigorscaling"),
    intelligence = 1 + status.stat("ivrpgintelligencescaling"),
    endurance = 1 + status.stat("ivrpgendurancescaling"),
    dexterity = 1 + status.stat("ivrpgdexterityscaling")
  }
  self.classicBonuses = {
    strength = 0,
    agility = 0,
    vitality = 0,
    vigor = 0,
    intelligence = 0,
    endurance = 0,
    dexterity = 0,
    default = 0
  }

  --Stat Linearity Change + Scaling
  for k,v in pairs(self.stats) do
    if v >= 20 then
      self.classicBonuses[k] = 1
      if v < 30 then
        v = (v + 30)/2.0
      end
    end
    self.stats[k] = math.floor(v^self.statBonuses[k])
  end

  for stat,amount in pairs(self.stats) do
    status.setStatusProperty("ivrpg" .. stat, amount)
  end

  local statConfig = {}
  local movementConfig = {}
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      for x,y in ipairs(v) do
        if y.type == "stat" then
          for i,j in ipairs(y.apply) do
            local currentConfig = {}
            local extra = 1
            if j.type == "status" then
              currentConfig.stat = j.stat
              if j.amountType == "amount" then extra = 0 end
              currentConfig[j.amountType] = (extra + (j.amount*self.stats[k]*(j.negative and -1 or 1)))
              table.insert(statConfig, currentConfig)
            elseif j.type == "movement" then
              if j.stat ~= "airJumpModifier" or not mcontroller.walking() then
                movementConfig[j.stat] = (extra + (j.amount*self.stats[k]))
              end
            end
          end
        end
      end
    end
  end

  status.setPersistentEffects("ivrpgstatboosts", statConfig)
  if (not status.statPositive("activeMovementAbilities")) or mcontroller.canJump() or status.statPositive("ninjaVanishSphere") or status.statPositive("ivrpgshapeshifting") then
    mcontroller.controlModifiers(movementConfig)
  end
end

function checkLevelUp()
  local currXP = world.entityCurrency(self.rpgPlayerID,"experienceorb")
  if currXP >= (self.level+1)^2*100 and self.level < 50 then
    local oldLevel = self.level
    self.level = math.min(math.floor(math.sqrt(currXP/100)), 50)
    if self.level == 1 then
      return
    end
    status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) + (self.level - oldLevel))
    status.addEphemeralEffect("ivrpglevelup")
  elseif currXP < (self.level+1)^2*100 then
    self.level = math.floor(math.sqrt(currXP/100))
  end
end

-- Profession Effects
function updateProfessionInfo()
  self.profInfo = root.assetJson("/professions/" .. self.profList[self.profession] .. ".config")
end

function updateProfessionEffects(dt)

  local profession = self.profession
  self.profession = world.entityCurrency(self.rpgPlayerID, "proftype")
  if self.profession == 0 then
    status.clearPersistentEffects("ivrpgprofessioneffects")
    if profession ~= 0 then
      local profInfo = root.assetJson("/professions/" .. self.profList[profession] .. ".config")
      status.removeEphemeralEffect(profInfo.ability.name)
    end
    self.profInfo = false
    return
  end

  updateProfessionInfo()
  local classicMode = self.classicMode

  -- Ability
  status.addEphemeralEffect(self.profInfo.ability.name, math.huge)

  -- Stat Bonuses
  local statDictionary = {}
  local effectsConfig = {}
  local movementConfig = {}
  for k,v in ipairs(self.profInfo.scaling) do
    table.insert(statDictionary, v)
  end
  for k,v in ipairs(self.profInfo.effects) do
    table.insert(statDictionary, v)
  end
  if classicMode then
    for k,v in ipairs(self.profInfo.classic) do
      table.insert(statDictionary, v)
    end
  end

  for k,v in ipairs(statDictionary) do
    if v.type == "status" or v.type == "movement" then
      for x,y in pairs(v.apply) do
        local classic = y.halvingStat and y.halvingAmount * self.classicBonuses[y.halvingStat] or 0
        if v.type == "status" then
          effectConfig = {}
          effectConfig[y.type] = y.amount * (y.negative and -1 or 1) + classic
          effectConfig.stat = y.stat
          table.insert(effectsConfig, effectConfig)
        elseif v.type == "movement" then
          movementConfig = {}
          movementConfig[y.stat] = y.amount + classic
          mcontroller.controlModifiers(movementConfig)
        end
      end
    end
  end

  status.setPersistentEffects("ivrpgprofessioneffects", effectsConfig)

end

-- Class Effects
function updateClassInfo()
  self.classInfo = root.assetJson("/classes/" .. self.classList[self.class] .. ".config")
end

function updateClassEffects(dt)

  if self.class ~= world.entityCurrency(self.rpgPlayerID, "classtype") then
    self.class = world.entityCurrency(self.rpgPlayerID, "classtype")
  end
  
  if self.class == 0 then
    self.classInfo = false
    status.clearPersistentEffects("ivrpgclassboosts")
    status.clearPersistentEffects("ivrpgclasseffects")
    status.clearPersistentEffects("ivrpgspecstatusbonus")
    return
  end

  updateClassInfo()
  local classicMode = self.classicMode

  -- Ability
  status.addEphemeralEffect(self.classInfo.ability.name, math.huge)

  -- Stat Bonuses
  local statDictionary = {}
  local effectsConfig = {}
  local movementConfig = {}
  for k,v in ipairs(self.classInfo.scaling) do
    table.insert(statDictionary, v)
  end
  for k,v in ipairs(self.classInfo.passive) do
    table.insert(statDictionary, v)
  end
  if classicMode then
    for k,v in ipairs(self.classInfo.classic) do
      table.insert(statDictionary, v)
    end
  end

  for k,v in ipairs(statDictionary) do
    if v.type == "status" or v.type == "movement" then
      for x,y in pairs(v.apply) do
        local classic = y.halvingStat and y.halvingAmount * self.classicBonuses[y.halvingStat] or 0
        if v.type == "status" then
          effectConfig = {}
          effectConfig[y.type] = y.amount * (y.negative and -1 or 1) + classic
          effectConfig.stat = y.stat
          table.insert(effectsConfig, effectConfig)
        elseif v.type == "movement" then
          movementConfig = {}
          movementConfig[y.stat] = y.amount + classic
          mcontroller.controlModifiers(movementConfig)
        end
      end
    end
  end

  status.setPersistentEffects("ivrpgclasseffects", effectsConfig)

  -- Weapon Bonuses
  status.clearPersistentEffects("ivrpgweaponbonus")
  local weaponDictionary = getDictionaryFromType(self.classInfo.weaponBonuses, "weapon")
  updateWeaponBonuses(weaponDictionary)

  -- Specialization Bonuses
  updateSpecialization()

  -- Classic Mode Weapon Penalties
  if classicMode then
    updateClassicMode()
  end
end

-- Specialization Effects
function updateSpecInfo()
  self.specInfo = root.assetJson("/specs/" .. self.specList[self.class][self.spec].name .. ".config")
end

function updateSpecialization()
  if self.spec ~= world.entityCurrency(self.rpgPlayerID, "spectype") then
    self.spec = world.entityCurrency(self.rpgPlayerID, "spectype")
  end

  if self.spec == 0 then
    status.clearPersistentEffects("ivrpgspecstatusbonus")
    self.specInfo = false
    return
  end

  updateSpecInfo()

  local specInfo = self.specInfo
  local specEffects = specInfo.effects
  
  -- Ability
  status.addEphemeralEffect(specInfo.ability.name, math.huge)

  -- Status
  local statuses = getArrayFromType(specEffects, "status")
  local statusConfig = {}
  for k,v in ipairs(statuses) do
    local classic = v.halvingStat and v.halvingAmount * self.classicBonuses[v.halvingStat] or 0
    local modifier = {}
    local statModifier = v.statModifier and status.statusProperty("ivrpg" .. v.statModifier, 1) or 1
    modifier["stat"] = v.stat
    modifier[v.type] = v.amount * (v.negative and -1 or 1) * statModifier + (classic * (v.halvingInverse and -1 or 1))
    table.insert(statusConfig, modifier)
  end
  status.setPersistentEffects("ivrpgspecstatusbonus", statusConfig)

  -- Movement
  local movement = getArrayFromType(specEffects, "movement")
  movementConfig = {}
  for k,v in ipairs(movement) do
    local classic = v.halvingStat and v.halvingAmount * self.classicBonuses[v.halvingStat] or 0
    movementConfig[v.type] = v.amount + classic
  end
  mcontroller.controlModifiers(movementConfig)

  -- Weapon Bonus
  local weaponDictionary = getDictionaryFromType(specEffects, "weapon")
  updateWeaponBonuses(weaponDictionary)
end

function updateWeaponBonuses(weaponDictionary)
  if not weaponDictionary then return end
  local effectsConfig = {}
  local effectConfig = false
  local scalingBonus = 0
  -- Primary Hand
  if self.heldItem then
    for k,v in ipairs(root.itemTags(self.heldItem)) do
      local info = weaponDictionary[v]
      if info then
        if self.twoHanded then
          if info.twoHanded or info.anyHand then
            scalingBonus = getScaleBonus(info.scaling, 2)
            effectConfig = {stat = "powerMultiplier", baseMultiplier = info.amount + scalingBonus}
          end
        else
          if (not info.twoHanded) or info.anyHand then
            if info.with and self.heldItem2 then
              for x,y in ipairs(info.with) do
                if root.itemHasTag(self.heldItem2, y) then
                  scalingBonus = getScaleBonus(info.scaling, 1)
                  effectConfig = {stat = "powerMultiplier", baseMultiplier = info.amount + scalingBonus}
                  break
                end
              end
            elseif not info.with then
              scalingBonus = getScaleBonus(info.scaling, 1)
              effectConfig = {stat = "powerMultiplier", baseMultiplier = info.amount + scalingBonus}
              if info.without and self.heldItem2 then
                for x,y in ipairs(info.without) do
                  if root.itemHasTag(self.heldItem2, y) then
                    effectConfig = false
                    break
                  end
                end
              end
            end
          end
        end
      end
      if effectConfig then
        table.insert(effectsConfig, effectConfig)
        if info.allowSecond then
          effectConfig = false
        end
        break
      end
    end
  end

  -- Secondary Hand: Should not include Two-Handed Weapons 
  if (not effectConfig) and (not self.twoHanded) and self.heldItem2 then
    for k,v in ipairs(root.itemTags(self.heldItem2)) do
      local info = weaponDictionary[v]
      if info then
        if (not info.twoHanded) or info.anyHand then
          if info.with and self.heldItem then
            for x,y in ipairs(info.with) do
              if root.itemHasTag(self.heldItem, y) then
                scalingBonus = getScaleBonus(info.scaling, 2)
                effectConfig = {stat = "powerMultiplier", baseMultiplier = info.amount + scalingBonus}
                break
              end
            end
          elseif not info.with then
            scalingBonus = getScaleBonus(info.scaling, 1)
            effectConfig = {stat = "powerMultiplier", baseMultiplier = info.amount + scalingBonus}
            if info.without and self.heldItem then
              for x,y in ipairs(info.without) do
                if root.itemHasTag(self.heldItem, y) then
                  effectConfig = false
                  break
                end
              end
            end
          end
        end
      end
      if effectConfig then
        table.insert(effectsConfig, effectConfig)
        break
      end
    end
  end

  status.addPersistentEffects("ivrpgweaponbonus", effectsConfig)

end

function updateClassicMode()
  -- Classic Mode
  weaponDictionary = {}
  weaponsDisabled = false
  for k,v in ipairs(self.classInfo.classic) do
    if v.type == "disable" then
      for x,y in pairs(v.apply) do
        weaponDictionary[x] = y
      end
    end
  end

  if self.specInfo then
    for k,v in ipairs(self.specInfo.classic) do
      for x,y in pairs(v.apply) do
        if v.type == "disable" then
          weaponDictionary[x] = y
        end
      end
    end
  end

  -- Disabling Certain Weapon Combinations
  if (self.heldItem and weaponDictionary[self.heldItem] and weaponDictionary[self.heldItem].named) then
    weaponsDisabled = true
  end
  if self.heldItem then
    for x,y in ipairs(root.itemTags(self.heldItem)) do
      local info = weaponDictionary[y]
      if info then
        if info.all or (info.twoHanded and self.twoHanded) then
          weaponsDisabled = true
        elseif info.with and self.heldItem2 then
          for r,tag in ipairs(info.with) do
            if root.itemHasTag(self.heldItem2, tag) then
              weaponsDisabled = true
              break
            end
          end
        end
        if weaponsDisabled then break end
      end
    end
  end

  if (not weaponsDisabled) and (not self.twoHanded) and self.heldItem2 then
    for x,y in ipairs(root.itemTags(self.heldItem2)) do
      local info = weaponDictionary[y]
      if info then
        if info.all then
          weaponsDisabled = true
        elseif info.with and self.heldItem then
          for r,tag in ipairs(info.with) do
            if root.itemHasTag(self.heldItem, tag) then
              weaponsDisabled = true
              break
            end
          end
        end
        if weaponsDisabled then break end
      end
    end
  end

  -- Enabling Disabled Weapon Combinations
  if weaponsDisabled then
    local enablesSpec = self.specInfo and getDictionaryFromType(self.specInfo.classic, "enable")
    local enablesClass = getDictionaryFromType(self.classInfo.classic, "enable")
    local enablesProf = self.profInfo and getDictionaryFromType(self.profInfo.classic, "enable")
    local enables = joinMaps(joinMaps(enablesClass, enablesProf), enablesSpec)
    local loopBreak = false
    if enables then
      if self.heldItem then
        for k,v in ipairs(root.itemTags(self.heldItem)) do
          local info = enables[v]
          if info then
            if info.without then
              if self.heldItem2 then
                for x,y in ipairs(info.without) do
                  if root.itemHasTag(self.heldItem2, y) then
                    loopBreak = true
                    break
                  end
                end
                if loopBreak then break end
              end
              weaponsDisabled = false
              break
            elseif info.with then
              local allowAlone = info.allowAlone
              if self.heldItem2 then
                for x,y in ipairs(info.with) do
                  if root.itemHasTag(self.heldItem2, y) or (allowAlone and not root.itemHasTag(self.heldItem2, "weapon"))  then
                    weaponsDisabled = false
                    loopBreak = true
                    break
                  end
                end
                if loopBreak then break end
              elseif allowAlone then
                weaponsDisabled = false
              end
            elseif info.onlyWithCorrectWeapons then
              if self.heldItem2 then
                for x,y in ipairs(root.itemTags(self.heldItem2)) do
                  if y ~= v and weaponDictionary[y] and weaponDictionary[y].all then
                    weaponsDisabled = true
                    break
                  end
                  weaponsDisabled = false
                end
              else
                weaponsDisabled = false
              end
              break
            elseif info.anyHand then
              weaponsDisabled = false
              break
            elseif info.twoHanded and self.twoHanded then
              weaponsDisabled = false
              break
            elseif not info.twoHanded and not self.twoHanded then
              weaponsDisabled = false
              break
            end
          end
        end
      end
      if weaponsDisabled and self.heldItem2 then
        for k,v in ipairs(root.itemTags(self.heldItem2)) do
          local info = enables[v]
          if info then
            if info.without then
              if self.heldItem then
                for x,y in ipairs(info.without) do
                  if root.itemHasTag(self.heldItem, y) then
                    loopBreak = true
                    break
                  end
                end
                if loopBreak then break end
              end
              weaponsDisabled = false
              break
            elseif info.with then
              local allowAlone = info.allowAlone
              if self.heldItem then
                for x,y in ipairs(info.with) do
                  if root.itemHasTag(self.heldItem, y) or (allowAlone and not root.itemHasTag(self.heldItem, "weapon")) then
                    weaponsDisabled = false
                    loopBreak = true
                    break
                  end
                end
                if loopBreak then break end
              elseif allowAlone then
                weaponsDisabled = false
              end
            elseif info.onlyWithCorrectWeapons then
              if self.heldItem then
                for x,y in ipairs(root.itemTags(self.heldItem)) do
                  if y ~= v and weaponDictionary[y] and weaponDictionary[y].all then
                    weaponsDisabled = true
                    break
                  end
                  weaponsDisabled = false
                end
              else
                weaponsDisabled = false
              end
              break
            elseif info.anyHand then
              weaponsDisabled = false
              break
            elseif not info.twoHanded and not self.twoHanded then
              weaponsDisabled = false
              break
            end
          end
        end
      end
      if weaponsDisabled and (self.heldItem and enables[self.heldItem] and enables[self.heldItem].named) then
        weaponsDisabled = false
      end
      --[[
      String Find stuff disabled for optimization reasons
      if weaponsDisabled then
        local enablesFind = getDictionaryFromType(self.classInfo.classic, "enable_find")
        for name,t in pairs(enablesFind) do
          if (self.heldItem and string.find(self.heldItem, name)) or (self.heldItem2 and string.find(self.heldItem2, name)) then
            weaponsDisabled = false
          end
        end
      end
      ]]
    end
  end

  -- Removing Full Penalty Based On Stats
  if weaponsDisabled then
    local multiplier = 0
    local classicType = "default"
    local both = "default"
    if self.weapon1 then
      if self.twoHanded then
        if root.itemHasTag(self.heldItem, "melee") then
          classicType = "strength"
          multiplier = 0.5
        elseif root.itemHasTag(self.heldItem, "staff") then
          classicType = "intelligence"
          multiplier = 0.5
        elseif root.itemHasTag(self.heldItem, "ranged") then
          classicType = "dexterity"
          multiplier = 0.5
        end
      else
        if self.weapon2 then
          if (root.itemHasTag(self.heldItem, "melee") or root.itemHasTag(self.heldItem, "ranged")) and (root.itemHasTag(self.heldItem2, "melee") or root.itemHasTag(self.heldItem2, "ranged")) then
            classicType = "dexterity"
            multiplier = 0.5
          end
        else
          if root.itemHasTag(self.heldItem, "wand") then
            classicType = "intelligence"
            multiplier = 0.75
          elseif root.itemHasTag(self.heldItem, "ranged") then
            classicType = "dexterity"
            multiplier = 0.75
          elseif root.itemHasTag(self.heldItem, "melee") then
            classicType = "strength"
            both = "dexterity"
            multiplier = 0.75
          end
        end
      end
    elseif self.weapon2 then
      if root.itemHasTag(self.heldItem2, "wand") then
        classicType = "intelligence"
        multiplier = 0.75
      elseif root.itemHasTag(self.heldItem2, "ranged") then
        classicType = "dexterity"
        multiplier = 0.75
      elseif root.itemHasTag(self.heldItem2, "melee") then
        classicType = "strength"
        both = "dexterity"
        multiplier = 0.75
      end
    end
    status.setPersistentEffects("ivrpghardcoreweaponsdisabled", {
      {stat = "powerMultiplier", effectiveMultiplier = (self.classicBonuses[classicType] | self.classicBonuses[both]) * multiplier}
    })
  else
    -- If not disabled, remove disable status and add potential requirement penalty
    status.clearPersistentEffects("ivrpghardcoreweaponsdisabled")
    if not self.specInfo then return end
    local requires = getDictionaryFromType(self.specInfo.classic, "require")
    if not requires then return end
    for k,v in pairs(requires) do
      if (not self.heldItem or (self.heldItem and not root.itemHasTag(self.heldItem, k))) and (not self.heldItem2 or (self.heldItem2 and not root.itemHasTag(self.heldItem2, k))) or (v.twoHanded and not self.twoHanded) then
        status.addPersistentEffect("ivrpgweaponbonus", {stat = "powerMultiplier", baseMultiplier = v.amount}) 
      end
    end
  end
end

-- Affinity Effects
function updateAffinityInfo()
  self.affinityInfo = root.assetJson("/affinities/" .. self.affinityList[self.affinity] .. ".config")
end

function updateAffinityEffects(dt)

  if self.affinity ~= world.entityCurrency(self.rpgPlayerID, "affinitytype") then
    self.affinity = world.entityCurrency(self.rpgPlayerID, "affinitytype")
  end
  
  if self.affinity == 0 then
    status.clearPersistentEffects("ivrpgaffinityeffects")
    return
  end

  updateAffinityInfo()

  local affinityMod = (self.affinity - 1) % 4
  local effectsConfig = {}
  local movementConfig = {}
  for k,v in ipairs(self.affinityInfo.immunity) do
    for x,y in ipairs(v.apply) do
      table.insert(effectsConfig, {stat = y.stat, amount = y.amount})
    end
  end
  for k,v in ipairs(self.affinityInfo.weakness) do
    if v.type ~= "ability" then
      for x,y in ipairs(v.apply) do
        local remove = y.removingStat and status.statPositive(y.removingStat)
        if not remove then
          if v.type == "status" then
            local effectConfig = {}
            effectConfig["stat"] = y.stat
            effectConfig[y.type] = (y.type == "amount" and 0 or 1) + (y.amount * (y.negative and -1 or 1))
            table.insert(effectsConfig, effectConfig)
          elseif v.type == "movement" then
            movementConfig[y.stat] = 1 - y.amount
          end
        end
      end
    end
  end

  -- Bonus Effects (Too complicated or specific for configs)
  local wet = hasEphemeralStat(status.activeUniqueStatusEffectSummary(), "wet") and 1 or 0
  local hardcodedAesthetic = false

  if affinityMod == 0 then
    -- Flame & Infernal --

    -- Health loss in Water
    if isInLiquid() and not status.statPositive("ivrpguceternalflame") then table.insert(effectsConfig, {stat = "maxEnergy", effectiveMultiplier = 0.7}) end
    if isInLiquid() and not status.statPositive("ivrpguceternalflame") then status.overConsumeResource("health", dt) end

  elseif affinityMod == 1 then
    -- Venom & Toxic --

    -- Upgrade Chips
    if status.statPositive("ivrpgucmiasma") and self.affinity then hardcodedAesthetic = "ivrpgmiasmatrail" end

  elseif affinityMod == 2 then
    -- Frost & Cryo --

    -- Upgrade Chips
    if status.statPositive("ivrpgucicequeen") and world.entityGender(self.rpgPlayerID) == "female" then
      if (self.weapon1 and root.itemHasTag(self.heldItem, "whip")) or (self.weapon2 and root.itemHasTag(self.heldItem2, "whip")) then
        movementConfig.speedModifier = 1
      end
      if (self.weapon1 and (root.itemHasTag(self.heldItem, "dagger") or root.itemHasTag(self.heldItem, "fist") or root.itemHasTag(self.heldItem, "whip"))) or (self.weapon2 and (root.itemHasTag(self.heldItem2, "dagger") or root.itemHasTag(self.heldItem2, "fist") or root.itemHasTag(self.heldItem2, "whip"))) then
        table.insert(effectsConfig, {stat = "powerMultiplier", baseMultiplier = 1.75})
      end
    elseif status.statPositive("ivrpgucskadisblessing") then
      if self.isBow then
        table.insert(effectsConfig, {stat = "powerMultiplier", baseMultiplier = 1.5})
      end
    end

    -- Cryo Explosion
    if self.affinity == 7 and status.resource("health")/status.stat("maxHealth") < 0.33 and self.cryoExplosion then
      self.cryoExplosion = false
      world.spawnProjectile("ivrpgcryoexplosionstatus", mcontroller.position(), self.rpgPlayerID, {0,0}, false)
    end

  elseif affinityMod == 3 then
    -- Shock & Arc --

    -- Upgrade Chips
    if status.statPositive("ivrpgucdischarge") and (mcontroller.liquidPercentage() > 0 or wet == 1) then
      shockNearbyTargets(dt)
    end

    -- Energy loss in water
    if isInLiquid() and not status.statPositive("ivrpgucplasmacore") then table.insert(effectsConfig, {stat = "maxHealth", effectiveMultiplier = 0.7}) end
    if isInLiquid() and not status.statPositive("ivrpgucplasmacore") then status.overConsumeResource("energy", dt) end

    --Arc Explosion
    if self.affinity == 8 and status.resource("energy") == 0 and self.arcExplosion then
      self.arcExplosion = false
      world.spawnProjectile("ivrpgarcexplosion", mcontroller.position(), self.rpgPlayerID, {0,0}, false)
    end

  end

  status.setPersistentEffects("ivrpgaffinityeffects", effectsConfig)
  mcontroller.controlModifiers(movementConfig)

  --Aesthetic Trails
  if status.statPositive("ivrpgaesthetics") and (mcontroller.xVelocity() > 1 or mcontroller.xVelocity() < -1) and not status.statPositive("activeMovementAbilities") then
    world.spawnProjectile(hardcodedAesthetic or self.affinityInfo.aesthetic, {mcontroller.xPosition(), mcontroller.yPosition()-2}, self.rpgPlayerID, {0,0}, false, {power = 0, knockback = 0, timeToLive = 0.3, damageKind = "applystatus"})
  end

  --Reset Arc Explosion and Cryo Explosion variables regardless of Affinity
  if self.arcExplosion == false and status.resource("energy") > 0 then
    self.arcExplosion = true
  end
  if self.cryoExplosion == false and status.resource("health")/status.stat("maxHealth") >= 0.33 then
    self.cryoExplosion = true
  end
end

function shockNearbyTargets(dt)
  self.tickTimer = not self.tickTimer and 0.5 or self.tickTimer - dt
  local boltPower = status.stat("powerMultiplier")*5
  if self.tickTimer <= 0 then
    self.tickTimer = 0.5
    local targetIds = world.entityQuery(mcontroller.position(), 8, {
      withoutEntityId = self.rpgPlayerID,
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      if world.entityCanDamage(self.rpgPlayerID, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(self.rpgPlayerID)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          self.rpgPlayerID,
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

function updateSkills()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  local skillEffects = {}
  local movementConfig = {}
  for k,v in pairs(activeSkills) do
    local skill = self.skillList[k]
    if skill then
      local allow = true
      if skill.when then
        local count = 1
        for _,w in ipairs(skill.when) do
          local amount = skill.whenTiers[count][v]
          if allow and w.type == "status" and not operate(w.operator2, operate(w.operator, status[w.stat1[1]](w.stat1[2]), status[w.stat2[1]](w.stat2[2])), amount) then
            allow = false
          elseif allow and w.type == "world" and not operate(w.operator, world[w.func](), amount) then
            allow = false
          end
          count = count + 1
        end
      end
      if (allow or skill.withoutWhen) and skill.persistentEffects then
        for i=1,#skill.persistentEffects do
          local effectConfig = {}
          effectConfig.stat = skill.persistentEffects[i]
          effectConfig[skill.effectTypes[i]] = skill.effectTiers[i][v]
          if allow or (skill.withoutWhen and skill.withoutWhen[i]) then
            table.insert(skillEffects, effectConfig)
          end
        end
      end
      if allow and skill.movementEffects then
        for i=1,#skill.movementEffects do
          movementConfig[skill.movementEffects[i]] = (movementConfig[skill.movementEffects[i]] or 1) + skill.movementTiers[i][v]
        end
      end
    end
  end
  status.setPersistentEffects("ivrpgskilleffects", skillEffects)
  if (not status.statPositive("activeMovementAbilities")) or status.statPositive("ninjaVanishSphere") or status.statPositive("ivrpgshapeshifting") then
    mcontroller.controlModifiers(movementConfig)
  end
end

function getScaleBonus(scalingList, hands)
  local scalingDamage = 0
  if scalingList then
    for stat,amount in pairs(scalingList) do
      scalingDamage = scalingDamage + (self.stats[stat] * (amount * (hands / 2)))
    end
  end
  return scalingDamage
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

-- Challenges
function updateChallenges()
  local notifications = nil
  notifications, self.challengeDamageGivenUpdate = status.inflictedDamageSince(self.challengeDamageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      -- Challenges
      local challenge1 = status.stat("ivrpgchallenge1")
      local challenge2 = status.stat("ivrpgchallenge2")
      local challenge3 = status.stat("ivrpgchallenge3")

      if challenge1 then
        if challenge1 == 3 then
          if updateProgress(notification, "boss", 7, "kluexboss") then
            status.setStatusProperty("ivrpgchallenge1progress", status.statusProperty("ivrpgchallenge1progress", 0) + 1)
            updateChallengeNearbyPlayers("ivrpgchallenge1progress", "ivrpgchallenge1", challenge1)
          end
        end
      end

      if challenge2 then
        if challenge2 == 2 then
          if updateProgress(notification, "boss", 7, "dragonboss") then
            status.setStatusProperty("ivrpgchallenge2progress", status.statusProperty("ivrpgchallenge2progress", 0) + 1)
            updateChallengeNearbyPlayers("ivrpgchallenge2progress", "ivrpgchallenge2", challenge2)
          end
        end
      end

      if challenge3 then
        if challenge3 == 2 then
          if updateProgress(notification, "boss", 7, "vault") then
            status.setStatusProperty("ivrpgchallenge3progress", status.statusProperty("ivrpgchallenge3progress", 0) + 1)
            updateChallengeNearbyPlayers("ivrpgchallenge3progress", "ivrpgchallenge3", challenge3)
          end
        elseif challenge3 == 3 then
          if updateProgress(notification, "boss", 7, "eyeboss") then
            status.setStatusProperty("ivrpgchallenge3progress", status.statusProperty("ivrpgchallenge3progress", 0) + 1)
            updateChallengeNearbyPlayers("ivrpgchallenge3progress", "ivrpgchallenge3", challenge3)
          end
        end
      end

      if updateProgress(notification, "boss", 8, "eyeboss") then
        giveNearbyPlayers("experienceorb", 2000)
      end
      if status.statPositive("ivrpgucskadisblessing") and (self.affinity-1)%4 == 2 and notification.damageSourceKind == "bow" then
        world.sendEntityMessage(notification.targetEntityId, "applyStatusEffect", "ivrpgembrittle", 3, self.rpgPlayerID)
      end
      if status.statPositive("ivrpgucbloodseeker") and notification.damageSourceKind == "bloodaether" then
        world.sendEntityMessage(notification.targetEntityId, "hitByBloodAether")
      end

    end
  end
end

function giveNearbyPlayers(item, amount)
  local players = world.playerQuery(mcontroller.position(), 100, {}) or {}
  for _,id in ipairs(players) do
    world.sendEntityMessage(id, "giveItem", item, amount)
  end
end

function updateChallengeNearbyPlayers(challengeType, challengeNumber, bossNumber)
  local players = world.playerQuery(mcontroller.position(), 100, {withoutEntityId = self.rpgPlayerID}) or {}
  for _,id in ipairs(players) do
    world.sendEntityMessage(id, "challengeStatusProperty", challengeType, challengeNumber, bossNumber)
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
  local damageDealt = notification.damageDealt
  local hitType = notification.hitType
  local damageTeam = world.entityDamageTeam(targetEntityId)
  local isEnemy = damageTeam and damageTeam.type == "enemy" or false
  local threat = world.threatLevel()
  local bosses = {"crystalboss", "apeboss", "cultistboss", "dragonboss", "eyeboss", "kluexboss", "penguinUfo", "spiderboss", "robotboss", "electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}
  local vaultGuardians = {"electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}
  --local notKilled = (targetEntityId ~= self.lastMonster[threatTarget-3])

  if challengeKind == "boss" then
    --if notKilled and ((not health) or (healthLost >= health[1])) then
    if healthLost > 0 and damageDealt > healthLost then
      if bossKind == "vault" then
        for _,boss in pairs(vaultGuardians) do
          if boss == monsterName then
            --self.lastMonster[threatTarget-3] = targetEntityId
            return true
          end
        end
      else
        if bossKind == monsterName then
          --self.lastMonster[threatTarget-3] = targetEntityId
          return true
        end
      end
    end
  elseif challengeKind == "bosses" then
    if healthLost > 0 and damageDealt > healthLost then
    --if notKilled and ((not health) or (healthLost >= health[1])) then
      for _,boss in pairs(bosses) do
        if boss == monsterName then
          --self.lastMonster[threatTarget-3] = targetEntityId
          return true
        end
      end 
    end
  end
  return false
end

function updateDamageTaken()
end

function updateDamageGiven()
  --[[self.dnotifications, self.damageGivenUpdate = status.inflictedHitsSince(self.damageGivenUpdate)
  if self.dnotifications then
    for _,notification in pairs(self.dnotifications) do
      sb.logInfo("damage")
    end
  end]]
end

--[[
  Damage Taken Notification
    targetMaterialKind
    healthLost
    position
    targetEntityId
    sourceEntityId
    damageSourceKind
    damageDealt
    hitType

  Damage Given Notification
    damageDealt
    healthLost
    position
    hitType
    damageSourceKind
    targetMaterialKind
    sourceEntityId
    targetEntityId
]]