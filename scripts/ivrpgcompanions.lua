require "/scripts/util.lua"

local ivrpgoldInit = init
local ivrpgoldUpdate = update
local ivrpgoldUninit = uninit

function init()
  ivrpgoldInit()
end

function update(args)
  ivrpgoldUpdate(args)
  local rpgPets = playerCompanions.getCompanions("pets")
  local rpgCrew = playerCompanions.getCompanions("crew")
  local crewReadable = {}
  for _,v in ipairs(rpgCrew) do
  	if v.uniqueId then crewReadable[v.uniqueId] = {name = v.name, type = v.config.type, status = v.status, persistent = v.persistent, hasDied = v.hasDied} end
  end
  status.setStatusProperty("ivrpg-crew", crewReadable)
end

function uninit()
	ivrpgoldUninit()
end