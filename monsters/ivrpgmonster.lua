local monsterOldInit = init
local monsterOldUpdate = update
local monsterOldUninit = uninit

  -- Listen to damage taken
  --[[self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        
        self.damaged = true
        self.board:setEntity("damageSource", notification.sourceEntityId)
      end
    end
  end)]]

function damage(args)
-- IVRPGMod
      --sb.logInfo("Damage Taken!!")
  self.id = args.sourceId
  self.damage = args.damage
  self.classType = world.entityCurrency(self.id, "classtype")
  self.dexterity = world.entityCurrency(self.id, "dexterity")
  if self.classType == 2 then
    if math.random(100) < 7 then
      status.addEphemeralEffect("electrified")
    end
    if math.random(100) < 7 then
      status.addEphemeralEffect("frostslow")
    end
    if math.random(100) < 7 then
      status.addEphemeralEffect("burning")
    end
  elseif self.classType == 4 then
    if math.random(10) < 3 then
      status.addEphemeralEffect("soldierstun")
      self.suppressDamageTimer = 1.5
    end
  elseif self.classType == 5 then
    if math.random(10) < 3 then
      status.addEphemeralEffect("weakpoison")
    end
  elseif self.classType == 3 then
    if nighttimeCheck() or undergroundCheck(self.id) then
      self.dexterity = self.dexterity + 20
    end
  end
  if math.random(100) <= self.dexterity then
    status.addEphemeralEffect("ivrpgweaken", (self.dexterity/50))
  end
  --End IVRPGMod
end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function undergroundCheck(position)
  return world.underground(position) 
end
