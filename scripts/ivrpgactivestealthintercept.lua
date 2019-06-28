-- Overrides taken from Active Stealth Module by Wellbott

function performStealthFunctionOverrides()
	if iHaveStealthPatched then return nil end
	iHaveStealthPatched = true

	if type(world) == "table" then
		originalWorldQueries = {
			entityQuery = world.entityQuery,
			entityLineQuery = world.entityLineQuery,
			monsterQuery = world.monsterQuery,
			npcQuery = world.npcQuery,
			npcLineQuery = world.npcLineQuery,
			playerQuery = world.playerQuery,
			entityExists = world.entityExists,
			entityType = world.entityType
		}
		--sb.logInfo("world table altered")
		function world.entityQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["entityQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				--sb.logInfo("entity["..tostring(id).."]Stealthed: %s", tostring(world.getProperty("entity["..tostring(id).."]Stealthed")))
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				else
					--sb.logInfo("Stealthed target ignored: %s", id)
				end
			end
			return newReturns
		end

		function world.entityLineQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["entityLineQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				end
			end
			return newReturns
		end

		function world.npcQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["npcQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				end
			end
			return newReturns
		end

		function world.npcLineQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["npcLineQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				end
			end
			return newReturns
		end

		function world.playerQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["playerQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				else
					--sb.logInfo("Stealthed target ignored: %s", id)
				end
			end
			return newReturns
		end

		function world.monsterQuery(a1,a2,a3, ignoresStealth)
			local originalReturns = originalWorldQueries["monsterQuery"](a1, a2, a3)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if ignoresStealth or not world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				end
			end
			return newReturns
		end

		function world.entityExists(a1, ignoresStealth)
			local originalReturn = originalWorldQueries["entityExists"](a1)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturn = originalReturn and (ignoresStealth or not world.getProperty("entity["..tostring(a1).."]Stealthed"))
			return newReturn
		end
		
		function world.entityType(a1, ignoresStealth)
			local originalReturn = originalWorldQueries["entityType"](a1)
			if (entity and world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturn = originalReturn
			if world.getProperty("entity["..tostring(ai).."]Stealthed") and not ignoresStealth then
				newReturn = "none"
			end
			return newReturn
		end
		
		function world.stealthQuery(a1,a2,a3)
			local originalReturns = originalWorldQueries["entityQuery"](a1, a2, a3)
			local newReturns = {}
			for _,id in ipairs(originalReturns) do
				if world.getProperty("entity["..tostring(id).."]Stealthed") then
					table.insert(newReturns, id)
				end
			end
			return newReturns
		end

		function world.friendlyQuery(a1, a2, a3, a4, ignoresStealth)
			ignoresStealth = ignoresStealth == nil and true or ignoresStealth
			local targetIds = world.entityQuery(a1, a2, a3, ignoresStealth)
			local newTargets = {}
			for _,id in ipairs(targetIds) do
				if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(a4, id)) then
					table.insert(newTargets, id)
				end
			end
			return newTargets
		end
	end

	if type(entity) == "table" then
		originalEntityQueries = {
			isValidTarget = entity.isValidTarget,
			entityInSight = entity.entityInSight
		}
		--sb.logInfo("entity table altered")

		function entity.closestValidTarget(a1, ignoresStealth)
			if (world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local targetIds = world.entityQuery(entity.position(), a1, {
				withoutEntityId = entity.id()
			}, ignoresStealth)
			local distance = math.huge
			local closestTarget = nil
			if targetIds then
				for _,id in ipairs(targetIds) do
					if entity.isValidTarget(id) then
						local newD = world.magnitude(entity.position(), world.entityPosition(id))
						if newD < distance then
							distance = newD
							closestTarget = id
						end
					end
				end
			end
			return closestTarget
		end

		function entity.isValidTarget(a1, ignoresStealth)
			local originalReturn = originalEntityQueries["isValidTarget"](a1)
			if (world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturn = originalReturn and (ignoresStealth or not world.getProperty("entity["..tostring(a1).."]Stealthed"))
			return newReturn
		end
		function entity.entityInSight(a1, ignoresStealth)
			local originalReturn = originalEntityQueries["entityInSight"](a1)
			if (world.entityDamageTeam(entity.id()).type == "friendly") and ignoresStealth ~= false then ignoresStealth = true end
			local newReturn = originalReturn and (ignoresStealth or not world.getProperty("entity["..tostring(a1).."]Stealthed"))
			return newReturn
		end
	end
end