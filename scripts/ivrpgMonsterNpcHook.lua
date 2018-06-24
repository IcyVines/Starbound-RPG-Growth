function setHandlers()
  message.setHandler("addEphemeralEffect", function(_, _, name, duration, sourceId)
    status.addEphemeralEffect(name, duration, sourceId)
  end)

  message.setHandler("applySelfDamageRequest", function(_, _, damageType, damageSourceKind, damage, sourceId)
    status.applySelfDamageRequest({
      damageType = damageType,
      damageSourceKind = damageSourceKind,
      damage = math.floor(damage/2),
      sourceEntityId = sourceId
    })
  end)

  message.setHandler("modifyResource", function(_, _, type, amount)
    status.modifyResource(type, amount)
  end)

  message.setHandler("modifyResourcePercentage", function(_, _, type, amount)
    status.modifyResourcePercentage(type, amount)
  end)

  message.setHandler("hitByBloodAether", function(_, _)
    self.hitByBloodAether = true
  end)
end

function loadVariables(enemyType, level)
  self.id = entity.id()
  self.enemyType = enemyType
  self.level = level
end

function updateEffects(dt)
  if status.statPositive("ivrpgundead") then
    --status.modifyResourcePercentage("health", 1)
    if self.isMonster then monster.setDamageTeam({type = "friendly", team = 1})
    else npc.setDamageTeam({type = "friendly", team = 1}) end
  end
end

function loadConfigs()
  self.classList = root.assetJson("/classList.config")
  self.affinityList = root.assetJson("/affinityList.config")
  self.specList = root.assetJson("/specList.config")
end

function loadInfo(class, affinity, spec)
  self.classInfo = (class and class > 0) and root.assetJson("/classes/" .. self.classList[class] .. ".config") or nil
  self.affinityInfo = (affinity and affinity > 0) and root.assetJson("/affinities/" .. self.affinityList[affinity] .. ".config") or nil
  self.specInfo = ((class and class > 0) and (spec and spec > 0)) and root.assetJson("/specs/" .. self.specList[class][spec].name .. ".config") or nil
end

function updateDamageTaken(notification)
  local damage = notification.damage
  local sourceKind = notification.sourceKind
  local sourceId = notification.sourceId

  if world.isMonster(sourceId) or world.isNpc(sourceId) then return end

  local class = world.entityCurrency(sourceId, "classtype")
  local affinity = world.entityCurrency(sourceId, "affinitytype")
  local spec = world.entityCurrency(sourceId, "spectype")
  loadInfo(class, affinity, spec)

  -- Class + Affinity Effects
  local onHitList = {}
  local onKillList = {}

  if self.classInfo then
    for k,v in ipairs(self.classInfo.passive) do
      if v.type == "onHit" then
        for x,y in ipairs(v.apply) do
          table.insert(onHitList, y)
        end
      elseif v.type == "onKill" then
        for x,y in ipairs(v.apply) do
          table.insert(onKillList, y)
        end
      end
    end
  end

  if self.specInfo then
    for k,v in ipairs(self.specInfo.ability.apply) do
      if v.type == "onHit" then
        for x,y in ipairs(v.apply) do
          table.insert(onHitList, y)
        end
      elseif v.type == "onKill" then
        for x,y in ipairs(v.apply) do
          table.insert(onKillList, y)
        end
      end
    end
  end

  if self.affinityInfo then
    for k,v in ipairs(self.affinityInfo.passive) do
      if v.type == "onHit" then
        for x,y in ipairs(v.apply) do
          table.insert(onHitList, y)
        end
      elseif v.type == "onKill" then
        for x,y in ipairs(v.apply) do
          table.insert(onKillList, y)
        end
      end
    end
  end

  -- Class + Affinity Effects
  for k,v in ipairs(onHitList) do
    if v.chance > math.random() then
      local lengthModifier = v.basedOnDamagePercent and (1.0*damage/world.entityHealth(self.id)[2]) or 1
      lengthModifier = lengthModifier < 0.04 and 0.04 or lengthModifier
      status.addEphemeralEffect(v.effect, v.length * lengthModifier, sourceId)
    end
  end

  if world.entityHealth(self.id)[1] <= 0 then
    enemyDeath(sourceId, damage, sourceKind, onKillList)
  end

  -- Bleed
  world.sendEntityMessage(sourceId, "bleedCheck", damage, sourceKind, self.id)

end

function enemyDeath(sourceId, damage, sourceKind, onKillList)
  -- Class + Spec + Affinity Effects
  local ignore = false
  for k,v in ipairs(onKillList) do
    
    -- Only cause effect when killed by...
    if v.fromSourceKind then
      for _,kind in ipairs(v.fromSourceKind) do
        if string.find(sourceKind, kind) then
          ignore = false
          break
        end
        ignore = true
      end
    end

    if v.type and v.type == "friendly" then
      local correctEnemy = true
      if v.npcs then
        for x,y in ipairs(v.npcs) do
          if string.find(self.enemyType, y) then
            correctEnemy = true
            break
          end
          correctEnemy = false
        end
      end
      if correctEnemy and v.effectType and v.effectType == "modifyResourcePercentage" then
        local targetIds = world.entityQuery(world.entityPosition(sourceId), 15, {
          includedTypes = {"creature"},
          withoutEntityId = self.id
        })
        for _,id in ipairs(targetIds) do
          if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
            world.sendEntityMessage(id, "modifyResourcePercentage", v.effect, v.amount)
          end
        end
      end
    elseif (not ignore) and v.chance > math.random() then
      status.addEphemeralEffect(v.effect, v.length, sourceId)
    end
  end
  sendDyingMessage(sourceId, damage, sourceKind)
end

function sendDyingMessage(sourceId, damage, sourceKind)
  world.sendEntityMessage(sourceId, "killedEnemy", self.enemyType, self.level, mcontroller.position(), status.activeUniqueStatusEffectSummary(), damage, sourceKind)
end