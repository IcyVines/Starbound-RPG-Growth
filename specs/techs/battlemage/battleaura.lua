require "/scripts/keybinds.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.oldStance =  3
  self.stance = 0
  self.id = entity.id()
  self.timer = 0
  Bind.create("f", switch)
  animator.setAnimationState("blood_aura", "front")
  animator.setAnimationState("ionic_aura", "front2")
  animator.setAnimationState("iron_aura", "back")
end

function switch()
  self.oldStance = self.stance
  if self.shiftHeld then
    self.stance = (self.stance - 1) % 4
  else
    self.stance = (self.stance + 1) % 4
  end
  animator.playSound(self.stance == 0 and "deactivate" or "activate")
end

function uninit()
  tech.setParentDirectives()
  for i=0,3 do
    status.removeEphemeralEffect("ivrpgbattleaura" .. i)
  end
end

function update(args)
  self.shiftHeld = not args.moves["run"]
  --status.addEphemeralEffect("ivrpgbattleaura" .. self.stance, 2)
  --status.removeEphemeralEffect("ivrpgbattleaura" .. self.oldStance)
  nearbyAllies()

  self.timer = self.timer + args.dt
  if self.timer > 5 then
    self.timer = 0
  end
  local alpha = math.floor(self.timer / 5 * 255)
  animator.setGlobalTag("blood", string.format("?multiply=FFFFFF%02x", alpha))

  animator.resetTransformationGroup("aura")
  if mcontroller.crouching() then
    animator.translateTransformationGroup("aura", {0, -0.875})
  end
end


function nearbyAllies()
  local targetIds = friendlyQuery(mcontroller.position(), 30, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  }, self.id)

  for i,id in ipairs(targetIds) do
    world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgbattleaura" .. self.stance, 2, self.id)
    world.sendEntityMessage(id, "removeEphemeralEffect", "ivrpgbattleaura" .. self.oldStance)
  end
end