local ivrpgoldInit = init
local ivrpgoldUpdate = update

function init()
  ivrpgoldInit()
end

function update(dt)
  ivrpgoldUpdate(dt)
  sb.logInfo("companions")
  local pets = playerCompanions.getCompanions("pet")
  if pets then
    for k,v in pairs(pets) do
      sb.logInfo(v)
    end
  end
end