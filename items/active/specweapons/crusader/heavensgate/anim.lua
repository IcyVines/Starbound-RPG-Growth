require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	lightningRand = sb.makeRandomSource()
end

local function randomInRange(range)
  return lightningRand:randf(-range, range)
end

local function randomOffset(range)
  return {randomInRange(range), randomInRange(range)}
end

local function drawLightning(bolt, startPos, endPos, displacement)
  if displacement < bolt.minDisplacement then
    endPos = vec2.sub(endPos, startPos)
    localAnimator.addDrawable({position = startPos, line = {{0, 0}, endPos}, width = bolt.width, color = bolt.color, fullbright = true}, bolt.renderLayer)
  else
    local mid = vec2.div(vec2.add(startPos, endPos), 2)
    mid = vec2.add(mid, randomOffset(displacement))
		local d = displacement / 2
    drawLightning(bolt, startPos, mid, d)
    drawLightning(bolt, mid, endPos, d)
  end
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
	
	-- chains
  self.chains = animationConfig.animationParameter("chains") or {}
  for _, chain in pairs(self.chains) do
		local startPosition = chain.startPosition
		local endPosition = chain.endPosition
		
		local chainVec = world.distance(endPosition, startPosition)
		local chainDirection = chainVec[1] < 0 and -1 or 1
		local chainLength = vec2.mag(chainVec)
		
		local arcAngle = 0
		if chain.arcRadius then
			arcAngle = chainDirection * 2 * math.asin(chainLength / (2 * chain.arcRadius))
			chainLength = chainDirection * arcAngle * chain.arcRadius
		end
		
		local segmentCount = math.floor(((chainLength + (chain.overdrawLength or 0)) / chain.segmentSize) + 0.5)
		if segmentCount > 0 then
			local chainStartAngle = vec2.angle(chainVec) - arcAngle / 2
			if chainVec[1] < 0 then chainStartAngle = math.pi - chainStartAngle end
			
			local segmentOffset = vec2.mul(vec2.norm(chainVec), chain.segmentSize)
			segmentOffset = vec2.rotate(segmentOffset, -arcAngle / 2)
			local currentBaseOffset = vec2.add(startPosition, vec2.mul(segmentOffset, 0.5))
			local lastDrawnSegment = chain.drawPercentage and math.ceil(segmentCount * chain.drawPercentage) or segmentCount
			for i = 1, lastDrawnSegment do
				local image = chain.segmentImage
				if i == 1 and chain.startSegmentImage then
					image = chain.startSegmentImage
				elseif i == lastDrawnSegment and chain.endSegmentImage then
					image = chain.endSegmentImage
				end
				
				local thisOffset = {0, 0}
				if chain.jitter then
					thisOffset = vec2.add(thisOffset, {0, (math.random() - 0.5) * chain.jitter})
				end
				if chain.waveform then
					local angle = ((i * chain.segmentSize) - (os.clock() * (chain.waveform.movement or 0))) / (chain.waveform.frequency / math.pi)
					local sineVal = math.sin(angle) * chain.waveform.amplitude * 0.5
					thisOffset = vec2.add(thisOffset, {0, sineVal})
				end
				
				local segmentAngle = chainStartAngle + (i - 1) * chainDirection * (arcAngle / segmentCount)
				
				thisOffset = vec2.rotate(thisOffset, chainVec[1] >= 0 and segmentAngle or -segmentAngle)
				
				local segmentPos = vec2.add(currentBaseOffset, thisOffset)
				local drawable = {
					image = image,
					centered = true,
					mirrored = chainVec[1] < 0,
					rotation = segmentAngle,
					position = segmentPos,
					fullbright = chain.fullbright or false
				}
				
				localAnimator.addDrawable(drawable, chain.renderLayer)
				if chain.light then
					localAnimator.addLightSource({
						position = segmentPos,
						color = chain.light,
					})
				end
				
				segmentOffset = vec2.rotate(segmentOffset, arcAngle / segmentCount)
				currentBaseOffset = vec2.add(currentBaseOffset, segmentOffset)
			end
		end
  end
	
	-- lightning
  local tickRate = animationConfig.animationParameter("lightningTickRate") or 25
	
	local millis = math.floor((os.time() + (os.clock() % 1)) * 1000)
	local lightningSeed = math.floor(millis / tickRate)

  local lightningBolts = animationConfig.animationParameter("lightning")
  
  if lightningBolts then
    for _, bolt in pairs(lightningBolts) do
			lightningRand:init(bolt.seed or lightningSeed)
			
      if bolt.endPointDisplacement then
        bolt.endPosition = vec2.add(bolt.endPosition, randomOffset(bolt.endPointDisplacement))
      end
			
      drawLightning(bolt, bolt.startPosition, bolt.endPosition, bolt.displacement)
    end
  end
end
