require "/scripts/keybinds.lua"

function init()
  self.oldStance =  3
  self.stance = 0
  self.id = entity.id()
  Bind.create("f", switch)
end

function switch()
  self.oldStance = self.stance
  self.stance = (self.stance + 1) % 4
  animator.playSound("activate")
end

function uninit()
  tech.setParentDirectives()
  for i=0,3 do
    status.removeEphemeralEffect("ivrpgallystance" .. i)
  end
end

function update(args)
  status.addEphemeralEffect("ivrpgallystance" .. self.stance, 2)
  status.removeEphemeralEffect("ivrpgallystance" .. self.oldStance)
  nearbyAllies()
end


function nearbyAllies()
  local targetIds = world.entityQuery(mcontroller.position(), 30, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgallystance" .. self.stance, 2, self.id)
      world.sendEntityMessage(id, "removeEphemeralEffect", "ivrpgallystance" .. self.oldStance)
    end
  end
end