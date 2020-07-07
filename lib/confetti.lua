local confetti = {}

local physics = require('physics')
local rand = math.random

function confetti.show(params)
	physics.start()
	local x1 = params.x1 or display.actualContentWidth / 2
	local x2 = params.x2 or display.actualContentWidth / 2
	local y = params.y or display.actualContentHeight / 2
	local num = params.num or 100
	local deltaTime = 20
	local verticalForce = params.verticalForce or 5
	local horizontalForce = params.horizontalForce or 0
	local xDispersion = params.xDispersion or 0.5
	local yDispersion = params.yDispersion or 0.5
	local colors = params.colors or false
	local scaleDispersion = params.scaleDispersion or 0
	local particlesGroup = params.particlesGroup or false
	for i=1,num do
		timer.performWithDelay( deltaTime * i, function()
				local item
				local n = rand(1,3)
				if n == 1 then
					item = display.newRect(rand(x1,x2), y, 5, 9) -- rect
				elseif n == 2 then
					item = display.newRect(rand(x1,x2), y, 7, 7) -- square
				elseif n == 3 then
					item = display.newCircle(rand(x1,x2), y, 3.5) -- circ
				end

				if (particlesGroup) then
					particlesGroup:insert(item)
				end
				if (colors) then
					local color = colors[rand(1,#colors)]
					item:setFillColor(color[1],color[2],color[3])
				end
				if (scaleDispersion) then
					local dScale = rand(-scaleDispersion * 1000, scaleDispersion * 1000 ) / 1000
					item.xScale = 1 + dScale
					item.yScale = 1 + dScale
				end
				physics.addBody( item, {density = 1, isSensor = true} )
				item.gravityScale = 2
				local dX = rand(-xDispersion * 1000, xDispersion * 1000  )
				dX = dX / 1000
				local dY = rand(-yDispersion * 1000, yDispersion * 1000 )
				dY = dY / 1000
				local currentVerticalForce = verticalForce + dY
				local currentHorizontalForce = horizontalForce + dX
				item:applyForce( currentHorizontalForce, -currentVerticalForce, item.x, item.y )
				item.angularVelocity = rand(-20, 20)
				transition.to(item, {alpha = 0, xScale = 0.1, yScale = 0.1, time = 3000, delay = 500, onComplete=function()
					physics.removeBody( item )
					item:removeSelf()
				end})
			end, 1 )
		
	end
end
return confetti