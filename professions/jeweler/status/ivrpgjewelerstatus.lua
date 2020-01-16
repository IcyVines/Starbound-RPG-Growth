function init()
  script.setUpdateDelta(5)
  self.id = entity.id()
end

function update(dt)
  targetIds = world.playerQuery(mcontroller.position(), 30, {
    withoutEntityId = self.id
  })
end

function uninit()
  
end
