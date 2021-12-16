function init()
  object.setInteractive(true)
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId,"interact", "ScriptPane", "/objects/ivrpg_crafting/grimoire_inscriber.config", entity.id())
end