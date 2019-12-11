require "/scripts/ivrpgutil.lua"

function init()
	self.initialBurst = true
	self.id = projectile.sourceEntity()
	self.shareDamage = {}
	mcontroller.setRotation(0)
	message.setHandler("shareTetherDamage", function(_, _, damage, targetEntity, sourceEntity)
		if sourceEntity and sourceEntity ~= entity.id() then
	    	self.shareDamage[targetEntity] = math.ceil(damage/2)
	    end
	end)
end

function update(dt)
	local targetIds = enemyQuery(mcontroller.position(), 15, {withoutEntityId = self.id}, self.id)
	if targetIds then
		for _,id in ipairs(targetIds) do
			world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgtethered", 1, entity.id())
			for shareId,shareDamage in pairs(self.shareDamage) do
				if id ~= shareId then world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "nova", shareDamage, entity.id()) end
			end
		end
		self.shareDamage = {}
	end
end

function uninit()
  
end