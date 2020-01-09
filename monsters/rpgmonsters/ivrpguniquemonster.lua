function rpg_initUniqueMonster()
  monster.setDamageBar("none")
  script.setUpdateDelta(1)
  self.rpg_boundBox = poly.boundBox(self.collisionPoly)
  self.rpg_size = config.getParameter("ivrpgSize", 1)
  self.rpg_respawn = config.getParameter("ivrpgRespawn", false)
  self.rpg_improvedStats = config.getParameter("ivrpgImprovedStats", {})
  self.rpg_shieldColors = root.assetJson("/monsters/rpgmonsters/shieldColors.config")
  self.animationCustom = root.assetJson("/monsters/rpgmonsters/animation.config")
  self.rpg_elementBreaks = {
    demonic = {holy = true},
    holy = {demonic = true},
    poison = {demonic = true, holy = true},
    fire = {nova = true, ice = true},
    electric = {nova = true},
    ice = {nova = true, fire = true}
  }

  if self.rpg_size ~= 1 and not status.statusProperty("ivrpg_monsterresized", false) then
  	animator.scaleTransformationGroup("body", {self.rpg_size, self.rpg_size})
  	status.setStatusProperty("ivrpg_monsterresized", true)
  end

  if config.getParameter("rpgOwnerUuid") then
  	world.sendEntityMessage(config.getParameter("rpgOwnerUuid"), "addToOwnedMonsters", self.rpg_ID)
  end

  message.setHandler("killedEnemy", function(_, _, enemyType, enemyLevel, position, facing, statusEffects, damageDealtForKill, damageKind)
  	if self.rpg_bloodStats then
  		self.rpg_bloodStats.current = self.rpg_bloodStats.current + 1
  		status.modifyResourcePercentage("health", 0.2)
  	end
  end)
end

function rpg_updateUniqueMonster(dt)
  for k,v in pairs(self.rpg_Actions) do
		if k == "debuff" then
		  local targetEntities = friendlyQuery(mcontroller.position(), v.range, {}, self.rpg_ID, true)
		  if targetEntities then
		    for _,id in ipairs(targetEntities) do
		      for _,effect in ipairs(v.statusEffects) do
		        world.sendEntityMessage(id, "addEphemeralEffect", effect, 1, self.rpg_ID)
		      end
		    end
		  end
		elseif k == "buff" then
		  local targetEntities = enemyQuery(mcontroller.position(), v.range, v.self and {} or {withoutEntityId = self.rpg_ID, includedTypes = {"creature"}}, self.rpg_ID, true)
		  if targetEntities then
		    for _,id in ipairs(targetEntities) do
		      for _,effect in ipairs(v.statusEffects) do
		        world.sendEntityMessage(id, "addEphemeralEffect", effect, 1, self.rpg_ID)
		      end
		    end
		  end
		elseif k == "tank" then
		  self.animationCustom.globalTagDefaults.armorType = v.type or "burst"
		  if self.rpg_armor then
		    rpg_stripArmor(self.rpg_armor.current == 0)
		  else
		    self.rpg_armor = {type = v.type, max = v.protection, current = v.protection, tag = 10, rechargeTime = v.rechargeTime, breakTime = v.breakTime, segments = v.segments or 10, elementType = v.elementType or "none"}
		  end
		  if self.rpg_armor.type == "shield" then
		  	animator.setGlobalTag("shieldDirectives", "?scalebilinear=0.5;1.0?setcolor=" .. self.rpg_shieldColors[self.rpg_armor.elementType])
		  end
		elseif k == "breed" then
		  self.animationCustom.globalTagDefaults.armorType = k
		  if not self.rpg_breedStats then
		    self.rpg_breedStats = {breedTypes = v.breedTypes, breedCount = v.breedCount, current = 10, breedTime = v.breedTime, refillTime = v.refillTime or v.breedTime, timer = 0, size = 1}
		  end
		elseif k == "blood" then
		  self.animationCustom.globalTagDefaults.armorType = k
		  if not self.rpg_bloodStats then
		  	self.rpg_bloodStats = {killsRequired = v.killsRequired, bloodMultiplier = v.bloodMultiplier or 2, growTime = 5, timer = 0, bloodStage = config.getParameter("ivrpgBloodStage", 1), sizeGrowth = v.sizeGrowth or 1, growthStats = v.growthStats or {}, current = 0, tag = "0"}
		  end
		  monster.setDamageTeam({team = 42, type = "enemy"})
		  local effectConfig = {}
		  for _,stat in ipairs(self.rpg_bloodStats.growthStats) do
		  	table.insert(effectConfig, {stat = stat, effectiveMultiplier = 1 + (self.rpg_bloodStats.bloodStage - 1) * self.rpg_bloodStats.bloodMultiplier / (self.rpg_bloodStats.timer == 0 and 1 or 2)})
		  end
		  status.setPersistentEffects("ivrpgBloodMonster", effectConfig)
		  rpg_checkForHostiles()
		end
  end

  if self.rpg_respawn then
  	rpg_grow(self.rpg_size)
    return
  end

  if self.rpg_size ~= 1 and not status.statusProperty("ivrpg_monsterresized", false) then
  	animator.scaleTransformationGroup("body", {self.rpg_size, self.rpg_size})
  	status.setStatusProperty("ivrpg_monsterresized", true)
  end

  status.setPersistentEffects("ivrpgUniqueMonster", self.rpg_improvedStats or {})

  if self.rpg_bloodStats then
  	local blood = math.min(math.ceil((self.rpg_bloodStats.current / self.rpg_bloodStats.killsRequired) * 10), 10)
  	animator.setGlobalTag("armor", tostring(blood))
  	animator.setGlobalTag("barFlipDirectives", mcontroller.facingDirection() == 1 and "" or "?flipx")
  	if self.rpg_bloodStats.timer > 0 then
  		animator.setGlobalTag("armor", "11")
  		local scale = (self.rpg_bloodStats.timer - self.rpg_bloodStats.growTime) / -self.rpg_bloodStats.growTime
  		animator.resetTransformationGroup("body")
  		animator.scaleTransformationGroup("body", {self.rpg_size + self.rpg_bloodStats.sizeGrowth * scale, self.rpg_size + self.rpg_bloodStats.sizeGrowth * scale})
  		self.rpg_bloodStats.timer = self.rpg_bloodStats.timer - dt
  		if self.rpg_bloodStats.timer <= 0 then
  			rpg_grow((self.rpg_size + self.rpg_bloodStats.sizeGrowth) / self.rpg_size, self.rpg_bloodStats.bloodStage + 1)
  		end
  	elseif self.rpg_bloodStats.current >= self.rpg_bloodStats.killsRequired then
  		self.rpg_bloodStats.timer = self.rpg_bloodStats.growTime
  		animator.playSound("grow")
  	end
  end

  if self.rpg_stripTimer and self.rpg_stripTimer > 0 then
    if self.rpg_breakTimer and self.rpg_breakTimer > 0 then
      self.rpg_breakTimer = self.rpg_breakTimer - dt
      animator.setGlobalTag("armor", self.rpg_armor.segments + 1)
    else
      local newArmor = math.floor((self.rpg_armor.rechargeTime - self.rpg_stripTimer) / self.rpg_armor.rechargeTime * self.rpg_armor.segments)
      if newArmor ~= self.rpg_armor.tag then
        self.rpg_armor.tag = newArmor
        if newArmor % (self.rpg_armor.segments / 10) == 0 and self.rpg_armor.type ~= "shield" then animator.playSound("fillTank2") end
      end
      animator.setGlobalTag("armor", tostring(newArmor))
      self.rpg_stripTimer = self.rpg_stripTimer - dt
      if self.rpg_stripTimer <= 0 then
        self.rpg_armor.current = self.rpg_armor.max
        animator.playSound("tankFull")
      end
    end
  elseif self.rpg_armor then
    animator.setGlobalTag("armor", tostring(math.ceil(self.rpg_armor.current / self.rpg_armor.max * self.rpg_armor.segments)))
  end

  if self.rpg_breedStats then
    animator.setGlobalTag("barFlipDirectives", mcontroller.facingDirection() == 1 and "" or "?flipx")
    if self.rpg_breakTimer and self.rpg_breakTimer > 0 then
      self.rpg_breakTimer = self.rpg_breakTimer - dt
      animator.setGlobalTag("armor", "11")
      rpg_weaken(true)
      if self.rpg_breakTimer <= 0 then
        self.rpg_breedStats.timer = self.rpg_breedStats.refillTime or self.rpg_breedStats.breedTime
        self.rpg_breedStats.refilling = true
      end
    elseif self.rpg_breedStats.timer == 0 then
      self.rpg_breedStats.timer = self.rpg_breedStats.breedTime
    elseif world.entityAggressive(self.rpg_ID) and not self.rpg_breedStats.refilling then
      local newArmor = math.ceil(self.rpg_breedStats.timer / self.rpg_breedStats.breedTime * 10)
      if newArmor ~= self.rpg_breedStats.current then
        self.rpg_breedStats.current = newArmor
        animator.playSound("fillTank")
      end
      rpg_weaken(false)
      animator.setGlobalTag("armor", tostring(newArmor))
      self.rpg_breedStats.timer = self.rpg_breedStats.timer - dt
      if self.rpg_breedStats.timer <= 0 then
      	rpg_breedActions(self.rpg_breedStats.breedCount)
        self.rpg_breakTimer = self.rpg_breedStats.breakTime or 0.5
        self.rpg_breedStats.current = 0
        animator.playSound("tankEmpty")
      end
    elseif self.rpg_breedStats.refilling then
      local newArmor = math.floor((self.rpg_breedStats.refillTime - self.rpg_breedStats.timer) / self.rpg_breedStats.refillTime * 10)
      animator.setGlobalTag("armor", tostring(newArmor))
      if newArmor ~= self.rpg_breedStats.current then
        self.rpg_breedStats.current = newArmor
        animator.playSound("fillTank2")
      end
      self.rpg_breedStats.timer = self.rpg_breedStats.timer - dt
      rpg_weaken(true)
      if self.rpg_breedStats.timer <= 0 then
        self.rpg_breedStats.refilling = false
        self.rpg_breedStats.current = 10
        self.rpg_breedStats.timer = self.rpg_breedStats.breedTime
        animator.playSound("tankFull")
      end
    end
  end

  monster.setDamageBar((self.rpg_armor and self.rpg_armor.current ~= 0) and "none" or "default")
  if status.resource("health") <= 0 and not self.rpg_spawnedTreaasure then
    self.rpg_spawnedTreaasure = true
  	world.spawnTreasure(mcontroller.position(), "experienceorbpoolminiboss", monster.level())
  end

  rpg_updateUniqueAI(dt)
end

function rpg_createAnimation(newAnimation)
	for k,v in pairs(newAnimation) do
		if self.animationCustom[k] then
			for x,y in pairs(v) do
				self.animationCustom[k][x] = y
			end
		else
			self.animationCustom[k] = v
		end
	end
	return self.animationCustom
end

function rpg_updateUniqueAI(dt)
	local pos = mcontroller.position()
	local xPos = pos[1]
	local yPos = pos[2] + 1
	local newXPos = xPos + mcontroller.facingDirection() * 2
	if world.polyCollision(self.collisionPoly, {newXPos, yPos + 1}, {"Block", "Slippery", "Dynamic"}) and not world.polyCollision(self.collisionPoly, {newXPos, yPos + 4}, {"Block", "Slippery", "Dynamic"}) then
		if mcontroller.groundMovement() then mcontroller.setVelocity({mcontroller.facingDirection()*30, 20}) end
	end 
end

function rpg_checkForHostiles()
	if self.rpg_bloodStats.target and world.entityExists(self.rpg_bloodStats.target) then
		monster.flyTo(world.entityPosition(self.rpg_bloodStats.target))
		return
	end
	local targetEntities = enemyQuery(mcontroller.position(), 10, {withoutEntityId = self.rpg_ID, includedTypes = {"creature"}}, self.rpg_ID)
	for _,id in ipairs(targetEntities) do
		self.rpg_bloodStats.target = id
		return
	end
end

function rpg_weaken(weaken)
	status.setPersistentEffects("ivrpgstripArmor", weaken and {
      	{stat="physicalResistance", amount=-0.5},
      	{stat="iceResistance", amount=-0.5},
      	{stat="fireResistance", amount=-0.5},
      	{stat="electricResistance", amount=-0.5},
      	{stat="poisonResistance", amount=-0.5},
      	{stat="novaResistance", amount=-0.5},
      	{stat="demonicResistance", amount=-0.5},
      	{stat="holyResistance", amount=-0.5},
      	{stat="shadowResistance", amount=-0.5},
      	{stat="cosmicResistance", amount=-0.5},
      	{stat="radioactiveResistance", amount=-0.5}
    } or {})
end

function rpg_damage(damage, sourceDamage, sourceKind, sourceId)
  if self.rpg_armor and self.rpg_armor.current ~= 0 then
    if self.rpg_armor.type == "burst" then
      local healthPercent = math.floor(sourceDamage / status.stat("maxHealth") * 100)
      self.rpg_armor.current = math.max(self.rpg_armor.current - math.max(healthPercent, 1), 0)
    elseif self.rpg_armor.type == "rapid" then
      self.rpg_armor.current = math.max(self.rpg_armor.current - 1, 0)
    elseif self.rpg_armor.type == "shield" then
    	local matchDamage = rpg_damageMatchesShield(sourceKind, self.rpg_armor.elementType)
    	if matchDamage > 0 then
      	self.rpg_armor.current = math.max(self.rpg_armor.current - sourceDamage * matchDamage, 0)
      end
    end
    status.modifyResource("health", damage)
    if self.rpg_armor.current == 0 then
    	if self.rpg_armor.type == "rapid" then
      	rpg_rapidSpark()
      end
      self.rpg_stripTimer = self.rpg_armor.rechargeTime
      self.rpg_breakTimer = self.rpg_armor.breakTime
      self.rpg_armor.tag = 0
      animator.playSound("tankEmpty")
      animator.setGlobalTag("armor", self.rpg_armor.segments + 1)
    end
  end
end

function rpg_damageMatchesShield(sourceKind, elementType)
	if string.find(sourceKind, elementType) then return 1 end
	if self.rpg_elementBreaks[elementType] then
		for element,_ in pairs(self.rpg_elementBreaks[elementType]) do
			if string.find(sourceKind, element) then return 0.5 end
		end
	end
	return 0
end

function rpg_rapidSpark()
	local damageClampRange = {1,1000}
	local healthDamageFactor = 1.0
	local boltPower = util.clamp(status.resourceMax("health") * healthDamageFactor * 2, damageClampRange[1], damageClampRange[2])

  local targetEntities = enemyQuery(mcontroller.position(), 30, {withoutEntityId = self.rpg_ID, includedTypes = {"creature"}}, self.rpg_ID, true)
  if targetEntities then
    for _,id in ipairs(targetEntities) do
    	if not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
	      local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
	      world.spawnProjectile(
		      "teslaboltsmall",
		      mcontroller.position(),
		      self.rpg_ID,
		      directionTo,
		      false,
		      {
		        power = boltPower,
		        damageTeam = {type = "friendly"}
		      }
		    )
	      animator.playSound("bolt")
	    end
    end
  end
end

function rpg_stripArmor(strip)
	local effectConfig = {
		{stat = "protection", effectiveMultiplier = strip and 0 or 1 },
    {stat = "protection", amount = strip and 0 or 100 },
    {stat = "statusImmunity", amount = strip and 0 or 1 },
    {stat = "grit", amount = (self.rpg_armor.type == "shield" and 0 or 1)}
  }
	if self.rpg_armor.type ~= "shield" then
  	monster.setDamageOnTouch(not strip)
  else
	  local elements = {"physical", "electric", "fire", "ice", "nova", "demonic", "holy", "poison", "shadow", "cosmic", "radioactive"}
	  for _,element in ipairs(elements) do
	    table.insert(effectConfig, {stat = element .. "StatusImmunity", amount = strip and 0 or 1})
	    if self.rpg_armor.elementType ~= element and not self.rpg_elementBreaks[self.rpg_armor.elementType][element] then
	      table.insert(effectConfig, {stat = element .. "Resistance", amount = strip and 0 or 3})
	    end
	  end
	end

  status.setPersistentEffects("ivrpgstripArmor", effectConfig)
  mcontroller.controlModifiers({
    speedModifier = (strip and self.rpg_armor.type ~= "shield") and 0 or 1
  })
end

function rpg_breedActions(count)
	local weight = 0
	local monsters = {}
	for k,v in pairs(self.rpg_breedStats.breedTypes) do
		weight = weight + v
		for i=1,v do
			table.insert(monsters, k)
		end
	end
	for i=1,count do
		world.spawnMonster(monsters[math.random(10)], vec2.add(mcontroller.position(), {math.random() * 4 - 2, math.random() * 4 - 2}), {ownerUuid = entity.uniqueId() or config.getParameter("ownerUuid"), rpgOwnerUuid = entity.id(), aggressive = true, level = monster.level(), damageTeam = entity.damageTeam().team, damageTeamType = entity.damageTeam().type, dropPools = {"experienceorbpoolsmall"}})
	end
end

function rpg_grow(size, bloodStage)
	local newPoly = poly.scale(self.collisionPoly, size)
  local movementSettings = config.getParameter("movementSettings", {})
  local touchDamage = config.getParameter("touchDamage", {})
  movementSettings.collisionPoly = newPoly
  touchDamage.poly = newPoly
  if bloodStage then
  	--local originalDamage = touchDamage.damage / (bloodStage - 1)
  	--touchDamage.damage = touchDamage.damage + originalDamage
  end
  world.spawnMonster(monster.type(), mcontroller.position(), {
    ivrpgSize = config.getParameter("ivrpgScaleViaJSON", false) and 1 or (bloodStage and (self.rpg_size + self.rpg_bloodStats.sizeGrowth) or size),
    ivrpgRespawn = false,
    movementSettings = movementSettings,
    touchDamage = touchDamage,
    metaBoundBox = poly.boundBox(newPoly),
    aggressive = config.getParameter("aggressive") or false,
    animationCustom = rpg_createAnimation(config.getParameter("animationCustom") or {}),
    level = monster.level(),
    scale = config.getParameter("ivrpgScaleViaJSON", false) and (bloodStage and (self.rpg_size + self.rpg_bloodStats.sizeGrowth) or size) or 1,
    damageTeam = entity.damageTeam().team,
    damageTeamType = entity.damageTeam().type,
    rpgOwnerUuid = config.getParameter("rpgOwnerUuid"),
    ivrpgBloodStage = bloodStage
  })
  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)
   if bloodStage then world.spawnProjectile("ivrpg_bloodexplosion", mcontroller.position(), self.rpg_ID, {0,0}, false, {}) end
  self.deathBehavior = nil
  self.shouldDie = true
  status.setPrimaryDirectives(string.format("?multiply=ffffff%02x", 0))
  status.setResource("health", 0)
  mcontroller.translate({0, -100000})
end