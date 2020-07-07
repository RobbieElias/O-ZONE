-- Pseudo-global space
local M = {}

function M:updateScreenVariables()
	M.screenWidth = display.actualContentWidth
	M.screenHeight = display.actualContentHeight
	M.centerX = display.contentCenterX
	M.centerY = display.contentCenterY
	M.screenTop = display.screenOriginY
	M.safeScreenTop = display.safeScreenOriginY
	M.screenLeft = display.screenOriginX
	M.screenBottom = display.contentHeight - display.screenOriginY
	M.screenRight = display.contentWidth - display.screenOriginX
end

function M:init()
	M:updateScreenVariables()
	M.fontMain = "assets/Roboto-Black.ttf"
	M.fontRegular = "assets/Roboto-Regular.ttf"
	M.objectsSheetInfo = require("assets.objects")
	M.objectsImageSheet = graphics.newImageSheet( "assets/objects.png", M.objectsSheetInfo:getSheet() )
	M.mainBgColor = {151,225,255}
	M.buttonColor = {64/255,219/255,189/255}
	M.buttonColorPressed = {51/255,175/255,151/255}
	M.bgScrollSpeed = 1.8
	M.scrollSpeed = 1.4
	M.debug = false
end
 
return M