function init()
  object.setInteractive(true)
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId,"ivrpgExtractRemoval", entity.id(), "/professions/alchemist/inserter/portable.config")
end