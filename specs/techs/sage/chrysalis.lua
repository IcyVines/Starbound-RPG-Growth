require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
	self.id = entity.id()
	self.active = false
	self.damageGivenUpdate = 5
	self.elements = {}
	self.balanced = {}
	self.elementConfig = {fire = 0, electric = 0, ice = 0}
	--animator.setSoundVolume("break", 0.5)
	Bind.create("f", toggle)
end

function toggle()
	if not self.active then
		self.active = true
		animator.setAnimationState("soul", "on")
		animator.playSound("soul")
	else
		self.active = false
		soulBurst()
	end
end

function soulBurst()
	local statusConfig = {regeneration4 = 0, energyregen = 0, rage = 0}
	for _,element in ipairs(self.elements) do
		if element == "ice" then
			statusConfig.regeneration4 = statusConfig.regeneration4 + 3
		elseif element == "electric" then
			statusConfig.energyregen = statusConfig.energyregen + 6
		elseif element == "fire" then
			statusConfig.rage = statusConfig.rage + 12
		end
	end

	local targets = friendlyQuery(mcontroller.position(), 30, {}, self.id, true)
	if targets then
		for _,id in ipairs(targets) do
			for effect,v in pairs(statusConfig) do
				if v > 0 then
					world.sendEntityMessage(id, "addEphemeralEffect", effect, v, self.id)
				end
			end
		end
	end

	animator.playSound("break")
	reset()
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  local elementIndex = #self.elements
  if self.active and notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 and #self.balanced < elementIndex and string.find(notification.damageSourceKind, "nova") then
      	animator.setGlobalTag("charged" .. (#self.balanced + 1), "balanced")
      	table.insert(self.balanced, true)
      	chargeElementConfig(#self.balanced)
      elseif notification.healthLost > 0 and elementIndex < 5 then
        --notification.damageDealt
        if string.find(notification.damageSourceKind, "fire") then
        	animator.setGlobalTag("element" .. (elementIndex + 1), "fire")
        	table.insert(self.elements, "fire")
        	addToElementConfig("fire")
        elseif string.find(notification.damageSourceKind, "ice") then
        	animator.setGlobalTag("element" .. (elementIndex + 1), "ice")
        	table.insert(self.elements, "ice")
        	addToElementConfig("ice")
        elseif string.find(notification.damageSourceKind, "electric") then
        	animator.setGlobalTag("element" .. (elementIndex + 1), "electric")
        	table.insert(self.elements, "electric")
        	addToElementConfig("electric")
        end
      end
    end
  end
end

function addToElementConfig(element)
	for k,v in pairs(self.elementConfig) do
		if element == k then
			self.elementConfig[k] = v + 0.2
		else
			self.elementConfig[k] = v - 0.1
		end
	end
end

function chargeElementConfig(index)
	local element = self.elements[index]
	for k,v in pairs(self.elementConfig) do
		if element ~= k then
			self.elementConfig[k] = v + 0.1
		end
	end
end

function reset()
  tech.setParentDirectives()
  animator.setAnimationState("soul", "off")
  for i=1,5 do
  	animator.setGlobalTag("element" .. i, "empty")
  	animator.setGlobalTag("charged" .. i, "")
	end
	self.elements = {}
	self.balanced = {}
	self.elementConfig = {fire = 0, electric = 0, ice = 0}
	status.clearPersistentEffects("ivrpgchrysalis")
end

function uninit()
  reset()
end

function update(args)
	updateDamageGiven()
	status.setPersistentEffects("ivrpgchrysalis", {
		{stat = "fireResistance", amount = self.elementConfig.fire},
		{stat = "electricResistance", amount = self.elementConfig.electric},
		{stat = "iceResistance", amount = self.elementConfig.ice},
		{stat = "physicalResistance", amount = 0.05 * #self.elements},
		{stat = "powerMultiplier", amount = -0.05 * (#self.elements - #self.balanced)}
	})
end