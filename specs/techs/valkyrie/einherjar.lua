require "/scripts/keybinds.lua"

function init()
  self.active = false
  self.target = false
  self.id = entity.id()
  self.rechargeTime = 0.1
  self.rechargeTimer = 0
  self.rechargeDirectives = "?fade=AAAA55=0.15"
  Bind.create("f", attemptActivation)
end

function attemptActivation()
  if self.target or self.active then return end

  local aimPosition = tech.aimPosition()
  local magnitude = 11
  local targetIds = world.entityQuery(aimPosition, 10, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  if targetIds then
    for _,id in ipairs(targetIds) do
      if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.sourceId, id)) then
        local position = world.entityPosition(id)
        if not world.lineTileCollision(mcontroller.position(), position) then
          local newMagnitude = position and world.magnitude(position, aimPosition) or 11
          if newMagnitude < magnitude then
            self.target = id
            magnitude = newMagnitude
          end
        end
      end
    end
  end

  if self.target then
    world.sendEntityMessage(self.target, "addEphemeralEffect", "ivrpgeinherjar", 5, self.id)
  end
end

function uninit()
  tech.setParentDirectives()
end

function update(args)
  if status.statusProperty("ivrpgeinherjarcooldown", false) then
    self.active = true
  elseif self.active == true then
    self.active = false
    self.target = false
    self.rechargeTimer = self.rechargeTime
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(self.rechargeTimer - args.dt, 0)
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
      animator.playSound("recharge")
    else
      tech.setParentDirectives(self.rechargeDirectives)
    end
  end
end
