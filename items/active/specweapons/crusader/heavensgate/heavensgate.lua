require "/scripts/poly.lua"

PortalSword = WeaponAbility:new()

function PortalSword:init()
	self:reset()
	
	self.ownerId = activeItem.ownerEntityId()
	self.beamDamageCfg.baseDamage = self.beamDamageCfg.baseDamage * self.beamDamageCfg.timeout
	self.impactSoundTimer = 0
	
	self.lightningArcs = {}
	self.arcCfg.maxEndAngle = self.arcCfg.maxEndAngle * math.pi / 180
end

function PortalSword:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
	
	self.impactSoundTimer = math.max(0, self.impactSoundTimer - self.dt)
	
	if self.fireMode == "alt"
	and not self.weapon.currentAbility
	and not status.resourceLocked("energy") then
		self:setState(self.charge)
	end
	
	if animator.animationState("blade") ~= "inactive" then
		self:updateLightningArcs()
	else
		activeItem.setScriptedAnimationParameter("lightning", nil)
	end
end

function PortalSword:charge()
  self.weapon:setStance(self.stances.charge)
  activeItem.setCursor(self.cursors.charge)
  animator.playSound("charge")
  animator.setAnimationState("charge", "charge")
  animator.setParticleEmitterActive("charge", true)
	
	local chargeTimer = self.stances.charge.duration
	while self.fireMode == "alt" do
		if chargeTimer > 0 then
			chargeTimer = chargeTimer - self.dt
			
			if chargeTimer <= 0 then
				self.weapon:setStance(self.stances.charged)
				activeItem.setCursor(self.cursors.ready)
				animator.stopAllSounds("charge")
				animator.playSound("fullcharge")
				animator.playSound("chargedloop", -1)
			end
		else
			activeItem.setCursor(self.cursors[self:canFire() and "ready" or "invalid"])
		end
		
		mcontroller.controlModifiers(self.chargeModifiers)
		status.setResourcePercentage("energyRegenBlock", 0.5)
		
    coroutine.yield()
	end

  animator.stopAllSounds("charge")

  if chargeTimer <= 0 and self:canFire() then
    self:setState(self.discharge)
  else
		animator.stopAllSounds("chargedloop")
    animator.playSound("discharge")
    self:setState(self.cooldown)
  end
end

function PortalSword:discharge()
  self.weapon:setStance(self.stances.discharge)
  activeItem.setCursor(self.cursors.ready)
	animator.playSound("activate")
	
	local timer = self.rocketSpawnTimer
	local beam = false
	local beamAngle
	
	self.portalId = world.spawnProjectile(self.projectiles.portal, activeItem.ownerAimPosition(), self.ownerId)
	
	while	self.portalId and world.entityExists(self.portalId) do
		if not beam and (self.fireMode == "alt" or status.resourceLocked("energy")) then
			status.overConsumeResource("energy", math.huge)
			beam = true
			timer = self.beamDuration
			animator.setAnimationState("charge", "spark")
			animator.playSound("activate")
			animator.playSound("beamStart")
			animator.playSound("beamLoop", -1)
			world.sendEntityMessage(self.portalId, "timeToLive", self.beamDuration)
		end
		
		local pos = world.entityPosition(self.portalId)
		local aimPos = activeItem.ownerAimPosition()
		
		timer = timer - self.dt
		
		--rockets
		if not beam then
			if timer <= 0 and status.overConsumeResource("energy", self.rocketEnergyUsage) then
				timer = self.rocketSpawnTimer
				self:fireRocket(pos, aimPos)
			end
		--beam
		else
			local newAngle = vec2.angle(world.distance(aimPos, pos))
			if beamAngle then
				newAngle = beamAngle + util.angleDiff(beamAngle, newAngle)
				beamAngle = beamAngle + ((newAngle - beamAngle) * self.beamRotationRate)
			else
				beamAngle = newAngle
			end
			
			local endPos = vec2.add(pos, vec2.withAngle(beamAngle, self.beamLength))
			self:fireBeam(pos, endPos)
			
			if timer <= 0 then
				break
			end
		end
		
		mcontroller.controlModifiers(self.chargeModifiers)
		status.setResourcePercentage("energyRegenBlock", 0.5)
		
		coroutine.yield()
	end
	
	if beam then
		animator.playSound("beamEnd")
	end
	
	animator.playSound("discharge")
  animator.stopAllSounds("beamLoop")
  animator.stopAllSounds("chargedloop")
  activeItem.setScriptedAnimationParameter("chains", nil)
	self:setState(self.cooldown)
end

function PortalSword:fireRocket(pos, aimPos)
	local angle
	if vec2.eq(pos, aimPos) then
		angle = self:randomVector()
	else
		angle = vec2.norm(world.distance(aimPos, pos))
		angle = vec2.rotate(angle, sb.nrand(self.rocketInaccuracy or 0, 0))
	end
	
	local params = {
		power = self.rocketDamage * config.getParameter("damageLevelMultiplier"),
		powerMultiplier = activeItem.ownerPowerMultiplier()
	}
	
	world.spawnProjectile(self.projectiles.rocket, pos, self.ownerId, angle, false, params)
	world.sendEntityMessage(self.portalId, "timeToLive", self.rocketSpawnTimer * 2)
end

function PortalSword:fireBeam(startPos, endPos)
	local aimVector = vec2.norm(world.distance(endPos, startPos))
	startPos = vec2.add(startPos, vec2.mul(aimVector, -self.beamCfg.segmentSize / 2))
	
	--collision
	local collidePoint = world.lineCollision(startPos, endPos)
	if collidePoint then
		endPos = collidePoint
		
		local params = {}
		if self.impactSoundTimer == 0 then
			self.impactSoundTimer = 0.1
			params.periodicActions = {{time = 0, ["repeat"] = false, action = "sound", options = self.beamImpactSound}}
		end
		
		world.spawnProjectile(self.projectiles.explosion, endPos, self.ownerId, self:randomVector(), false, params)
	end
	
	--draw
  local newChain = copy(self.beamCfg)
  newChain.startPosition = startPos
  newChain.endPosition = endPos
  activeItem.setScriptedAnimationParameter("chains", {newChain})
	
	self:beamDamage(startPos, endPos, aimVector)
end

function PortalSword:beamDamage(startPos, endPos, aimVector)
	local mpos = mcontroller.position()
	local angle = vec2.rotate(aimVector, math.pi / 2)
	local damageStart = world.distance(startPos, mpos)
	local damageEnd = world.distance(endPos, mpos)
	local damagePoly = {
		vec2.add(damageStart, vec2.mul(angle, self.beamWidth)),
		vec2.add(damageStart, vec2.mul(angle, -self.beamWidth)),
		vec2.add(damageEnd, vec2.mul(angle, -self.beamWidth)),
		vec2.add(damageEnd, vec2.mul(angle, self.beamWidth))
	}
	self.weapon:setOwnerDamage(self.beamDamageCfg, damagePoly)
end

function PortalSword:randomVector()
	return vec2.rotate({1, 0}, math.pi * 2 * math.random())
end

function PortalSword:randomAngle()
	return math.pi * 2 * math.random()
end

function PortalSword:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  activeItem.setCursor(self.cursors.idle)
  animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive("charge", false)
  util.wait(self.stances.cooldown.duration)
end

function PortalSword:updateLightningArcs()
	local lightning = {}
	
	-- translate line
	local arcLine = poly.rotate(self.arcCfg.line, self.weapon.relativeWeaponRotation)
	arcLine = poly.translate(arcLine, self.weapon.weaponOffset)
	arcLine = poly.handPosition(arcLine)
	arcLine = poly.translate(arcLine, mcontroller.position())
		world.debugPoly(arcLine, "yellow")
	
	local arcs = self.lightningArcs
	for i = 1, self.arcCfg.count do
		if not arcs[i] or arcs[i].timer == 0 then
			arcs[i] = {
				timer = 1,
				time = util.randomInRange(self.arcCfg.speedRange),
				distance = util.randomInRange(self.arcCfg.distanceRange),
				angle = self:randomAngle(),
				endAngle = util.randomInRange({-self.arcCfg.maxEndAngle, self.arcCfg.maxEndAngle}),
				positionLerp = {math.random(), math.random()}
			}
		end
		
		local arc = arcs[i]
		arc.timer = math.max(0, arc.timer - self.dt / arc.time)
		
		local posRatio = util.lerp(arc.timer, arc.positionLerp)
		local startPos = vec2.lerp(posRatio, arcLine[1], arcLine[2])
		
		local angle = arc.angle + ((1 - arc.timer) * arc.endAngle)
		local endPos = vec2.add(startPos, vec2.withAngle(angle, arc.distance))
		
		local collision = world.lineCollision(startPos, endPos)
			world.debugLine(startPos, collision or endPos, (collision and "green" or "red"))
		
		if collision then
			local bolt = sb.jsonMerge(self.arcCfg.params)
			bolt.width = util.lerp(arc.timer, 0, bolt.width)
			bolt.startPosition = startPos
			bolt.endPosition = collision
			table.insert(lightning, bolt)
		end
	end
	
  activeItem.setScriptedAnimationParameter("lightning", lightning)
end

function PortalSword:reset()
  self.weapon:setStance(self.stances.idle)
  activeItem.setCursor(self.cursors.idle)
  animator.stopAllSounds("chargedloop")
  animator.stopAllSounds("fullcharge")
  animator.stopAllSounds("beamLoop")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive("charge", false)
  activeItem.setScriptedAnimationParameter("chains", nil)
end

function PortalSword:canFire()
	return not world.lineTileCollision(mcontroller.position(), activeItem.ownerAimPosition())
end

function PortalSword:uninit()
	self:reset()
	
	if self.portalId then
		world.sendEntityMessage(self.portalId, "timeToLive", 0, true)
	end
end

local ballsqueeze = self.weapon.damageSource
function self.weapon:damageSource(cfg, ...)
	local d = ballsqueeze(self, cfg, ...)
	if d and cfg and cfg.rayCheck ~= nil then
		d.rayCheck = cfg.rayCheck
	end
	return d
end