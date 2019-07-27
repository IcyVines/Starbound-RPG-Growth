require "/scripts/ivrpgactivestealthintercept.lua"

function setHandlers()

  message.setHandler("addEphemeralEffect", function(_, _, name, duration, sourceId)
    status.addEphemeralEffect(name, duration, sourceId)
  end)

  message.setHandler("removeEphemeralEffect", function(_, _, name)
    status.removeEphemeralEffect(name)
  end)

  message.setHandler("setVelocity", function(_, _, velocity)
    mcontroller.setVelocity(velocity)
  end)

  message.setHandler("applySelfDamageRequest", function(_, _, damageType, damageSourceKind, damage, sourceId)
    status.applySelfDamageRequest({
      damageType = damageType,
      damageSourceKind = damageSourceKind,
      damage = math.floor(damage),
      sourceEntityId = sourceId
    })
  end)

  message.setHandler("modifyResource", function(_, _, type, amount)
    status.modifyResource(type, amount)
  end)

  message.setHandler("modifyResourcePercentage", function(_, _, type, amount)
    status.modifyResourcePercentage(type, amount)
  end)

  message.setHandler("ivrpgDevourState", function(_, _, player, position, direction)
    if self.devourState and self.devourState[3] ~= player then
      return
    end

    if self.devourState then
      self.devourState = false
    else
      self.devourState = {position, direction, player}
    end
  end)

  message.setHandler("hitByBloodAether", function(_, _)
    self.hitByBloodAether = true
  end)
end

function loadVariables(enemyType, level)
  self.id = entity.id()
  self.enemyType = enemyType
  self.level = level
  self.baseParameters = mcontroller.baseParameters()
  self.devourState = false
  self.devourTimer = 0
  performStealthFunctionOverrides()
end

function updateEffects(dt)
  if status.statPositive("ivrpgundead") then
    --status.modifyResourcePercentage("health", 1)
    if self.isMonster then monster.setDamageTeam({type = "friendly", team = 1})
    else npc.setDamageTeam({type = "friendly", team = 1}) end
  end

  if self.devourState then
    self.devourTimer = 0.3
    status.setPersistentEffects("ivrpgdevourstate", {
      {stat = "invulnerable", amount = 1}
    })
    mcontroller.controlModifiers({
      movementSuppressed = true,
      jumpingSuppressed = true
    })
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setXPosition(self.devourState[1][1] + self.devourState[2])
    local boundBox = mcontroller.boundBox()
    local yOffset = math.abs((boundBox[2] + boundBox[4] / 2))
    mcontroller.setYPosition(self.devourState[1][2] + 1 + yOffset)
  else
    status.clearPersistentEffects("ivrpgdevourstate")
  end

  if self.devourTimer > 0 then
    status.addEphemeralEffect("soldierstun", dt)
    self.devourTimer = math.max(self.devourTimer - dt, 0)
  end

  local shouldStealth = status.statPositive("invisible") or status.statPositive("ivrpgstealth")
  world.setProperty("entity["..tostring(self.id).."]Stealthed", shouldStealth)

  --[[ Movement Parameters!!!
    flySpeed : 8.0
    groundForce : 100.0
    gravityMultiplier : 1.5
    maxMovementPerStep : 0.80000001192093
    stickyForce : 0.0
    frictionEnabled : true
    airForce : 20.0
    bounceFactor : 0.0
    standingPoly : table: 0000024A0BC8E0C0
    maximumPlatformCorrection : 0.019999999552965
    airFriction : 0.0
    ambulatingGroundFriction : 1.0
    walkSpeed : 3.0
    slopeSlidingFactor : 0.0
    fallStatusSpeedMin : -4.0
    liquidImpedance : 0.5
    liquidFriction : 5.0
    normalGroundFriction : 14.0
    gravityEnabled : true
    fallThroughSustainFrames : 12
    maximumCorrection : 3.0
    groundMovementCheckDistance : 0.75
    groundMovementMaximumSustain : 0.25
    liquidForce : 30.0
    groundMovementMinimumSustain : 0.10000000149012
    physicsEffectCategories : table: 0000024A0BC8E580
    maximumPlatformCorrectionVelocityFactor : 0.029999999329448
    speedLimit : 200.0
    mass : 1.6000000238419
    runSpeed : 18.199998855591
    stickyCollision : false
    minimumLiquidPercentage : 0.5
    collisionEnabled : true
    liquidBuoyancy : 0.0
    crouchingPoly : table: 0000024A0BC8E340
    liquidJumpProfile : table: 0000024A0BC8E080
    airJumpProfile : table: 0000024A0BC8E040
  ]]

  local rallyLevel = 0
  local players = world.players()
  for _,id in ipairs(players) do
    local rally = world.getProperty("ivrpgRallyMode[" .. id .. "]", 0)
    rallyLevel = rallyLevel + rally
  end
  
  status.setPersistentEffects("ivrpgRallied", {
    {stat = "powerMultiplier", baseMultiplier = 1 + math.min(rallyLevel/50, 3)},
    {stat = "protection", amount = math.min(rallyLevel/5, 40)}
  })

  if rallyLevel > 0 then
    mcontroller.controlParameters({
      airFriction = self.baseParameters.airFriction * (1 - math.min(rallyLevel/150, 0.25))
    })
    mcontroller.controlModifiers({
      groundMovementModifier = 1 + math.min(rallyLevel/100, 1),
      liquidMovementModifier = 1 + math.min(rallyLevel/100, 1),
      speedModifier = 1 + math.min(rallyLevel/200, 1)
    })
    local targetIds = world.entityQuery(mcontroller.position(), 20, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for _,id in ipairs(targetIds) do
      if world.entityAggressive(id) then
        status.addPersistentEffect("ivrpgRallied", { 
          stat = "protection",
          effectiveMultiplier = 1 + math.min(rallyLevel/100, 1)
        })
        break
      end
    end
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

  if world.entityHealth(self.id)[1] and world.entityHealth(self.id)[1] <= 0 then
    enemyDeath(sourceId, damage, sourceKind, onKillList)
  end

  -- Bleed
  world.sendEntityMessage(sourceId, "bleedCheck", damage, sourceKind, self.id)

end

function enemyDeath(sourceId, damage, sourceKind, onKillList)
  -- Class + Spec + Affinity Effects
  local ignore = false
  for k,v in ipairs(onKillList) do
    ignore = false
    -- Only cause effect when target is killed by a specified source...
    if v.fromSourceKind then
      ignore = true
      for _,kind in ipairs(v.fromSourceKind) do
        if string.find(sourceKind, kind) then
          ignore = false
          break
        end
      end
    end

    -- Only cause effect when target type matches one of the specified enemy types...
    if v.targetList then
      ignore = true
      for x,y in ipairs(v.targetList) do
        if string.find(self.enemyType, y) then
          ignore = false
          break
        end
      end
    end

    -- Don't cause effect when gender is specified and target is either not an NPC or not gendered correctly...
    if v.gender and not (world.isNpc(self.id) and npc.gender() == v.gender) then
      ignore = true
    end

    local range = v.range and v.range or 10
    local focalId = v.searchFrom or sourceId

    if v.type then
      if (not ignore) and v.chance > math.random() then
        if v.type == "friendly" or v.type == "enemy" or v.type == "allyOnly" then
        -- Searches nearby entities centering from focalId's position, and not including the target monster.
          local targetIds = world.entityQuery(world.entityPosition(focalId), range, {
            includedTypes = {"creature"},
            withoutEntityId = self.id
          })
          -- Loops through found IDs. If we want to give to friendlies, we make sure we aren't giving to non-friendly PvP players. If we ant to give to enemies, we want to give to non-friendly PvP players.
          for _,id in ipairs(targetIds) do
            if ((v.type == "friendly" or v.type == "allyOnly") and (world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(sourceId, id))))
            or (v.type == "enemy" and (world.entityDamageTeam(id).type == "enemy" or (world.entityDamageTeam(id).type == "pvp" and world.entityCanDamage(sourceId, id)))) then
              -- If allyOnly was specified, we need to make sure we don't give the buff to ourself!
              if not (v.type == "allyOnly" and id == sourceId) then
                world.sendEntityMessage(id, v.effectType, v.effect, v.amount or v.length, sourceId)
              end
            end
          end
        elseif v.type == "target" then
          --sb.logInfo("Target chosen for special effect.")
          status[v.effectType](v.effect, v.amount or v.length, sourceId)
        elseif v.type == "self" then
          --sb.logInfo("Self chosen for special effect. " .. sourceKind)
          world.sendEntityMessage(sourceId, v.effectType, v.effect, v.amount or v.length, sourceId)
        elseif v.type == "drops" and v.dropList then
          for _,drop in ipairs(v.dropList) do
            if drop.item then
              local amount = drop.amount or 0
              local levelMultiplier = drop.levelMultiplier or 1
              if drop.levelCurve then
                amount = amount * (drop.levelCurve == "exponential" and (self.level^levelMultiplier or self.level*levelMultiplier))
              end
              if drop.randomFactor and #drop.randomFactor == 2 then
                amount = math.floor(amount * math.random(drop.randomFactor[1], drop.randomFactor[2]) / 100 + 0.5)
              end
              --sb.logInfo(drop.item .. ": " .. amount)
              world.spawnItem(drop.item, mcontroller.position(), amount, {}, vec2.mul(mcontroller.velocity(), 0.5))
            end
          end
        end
      end
    else
      sb.logInfo("RPG Growth Error: No 'type' in specified 'onKill' config.")
    end
  end
  sendDyingMessage(sourceId, damage, sourceKind)
end

function sendDyingMessage(sourceId, damage, sourceKind)
  world.sendEntityMessage(sourceId, "killedEnemy", self.enemyType, self.level, mcontroller.position(), status.activeUniqueStatusEffectSummary(), damage, sourceKind)
end

function hasEphemeralStat(statusEffects, stat)
  ephStats = util.map(statusEffects,
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    if v == stat then return true end
  end
  return false
end