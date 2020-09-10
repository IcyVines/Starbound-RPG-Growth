local oldInit = init
local ignoreNpcs = {
  esther = true,
  frogmerchant = true,
  frogvillager = true,
  frogvisitor = true
}

local forceNpcs = {
  deadbeatscrounger = true
}

function init()
  oldInit()

  message.setHandler("makeRecruitable", simpleHandler(makeRecruitable))
  message.setHandler("saySomething", simpleHandler(saySomething)) 
end

function makeRecruitable(params)
  local offerType = params.offerType
  local messages = params.messages
  local npcTeam = entity.damageTeam().team


  if isRejected() then
    local message = false
    if npcTeam ~= 1 and npcTeam ~= 0 then
     message = messages.jobOfferEnemy[npc.species()] and messages.jobOfferEnemy[npc.species()] or messages.jobOfferEnemy.generic
    end
    if ignoreNpcs[npc.npcType()] then
      message = messages.jobOfferSpecial[npc.npcType()] and messages.jobOfferSpecial[npc.npcType()] or messages.jobOfferSpecial.generic
    end
    if recruitable.isRecruitable() or recruitable.ownerUuid() then
      message = messages.jobOfferRecruitable[npc.species()] and messages.jobOfferRecruitable[npc.species()] or messages.jobOfferRecruitable.generic
    end
    if not message then
      message = messages.jobOfferSpecial.generic
    end
    npc.say(message)
    return false
  else
    storage.itemSlots = storage.itemSlots or {}
    if not storage.itemSlots.headCosmetic and not storage.itemSlots.headCosmetic then
      storage.itemSlots.headCosmetic = npc.getItemSlot("headCosmetic")
    end
    if not storage.itemSlots.head then
      storage.itemSlots.head = npc.getItemSlot("head")
    end

    storage.itemSlots.primary = npc.getItemSlot("primary")
    storage.itemSlots.alt = npc.getItemSlot("alt")

    local newUniqueId = sb.makeUuid()
    local newEntityId = world.spawnNpc(entity.position(), npc.species(), sb.print(offerType), npc.level(), npc.seed(), {
        identity = npc.humanoidIdentity(),
        scriptConfig = {
            personality = personality(),
            initialStorage = preservedStorage(),
            crew = {
              defaultUniform = {
                chest = npc.getItemSlot("chest"),
                legs = npc.getItemSlot("legs")
              },
            },
            uniqueId = newUniqueId
          }
      })
    tenant.detachFromSpawner()
    tenant.despawn()
    return newUniqueId
  end
end

function isRejected()
  local npcTeam = entity.damageTeam().team
  if forceNpcs[npc.npcType()] then
    return false
  else
    return false
    --[[return npcTeam ~= 1 and npcTeam ~= 0
      or ignoreNpcs[npc.npcType()]
      or recruitable.isRecruitable()
      or recruitable.ownerUuid()]]
  end
end

function saySomething(params)
  local messages = params.messages
  local message = messages[params.message][npc.species()] and messages[params.message][npc.species()] or messages[params.message].generic
  npc.say(message)
end