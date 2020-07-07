local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
-- Required libraries
local physics = require("physics")
local objectsPhysics = require("assets.objects_physics")
local widget = require("widget")
local _gs = require("lib.gameServices")
local _g = require("lib.globalVariables")
local _data = require("lib.data")
local _ads = require("lib.ads")
local _fa = require("plugin.firebaseAnalytics")
local rand = math.random

-- Variables
local lastTouchX, lastTouchY = 0, 0
local objectsTable = {}
local gameLoopTimer
local scoreLoopTimer
local gameStarted = true
local gameResumed = false
local canRemoveObjects = false
local levelIsSetup = false
local isFirstLevel = true
local level = 1
local currentLevel = 1
local levels = {}
local levelIndexes
local lvlTmrs = {}
-- local lastLevelPlayed = _data:get("lastLevelPlayed")
local highestLevel = _data:get("highestLevel")
local highScore = _data:get("highScore")
local gamesPlayed = _data:get("gamesPlayed")
local firstGame = gamesPlayed == 0
local doFirstGameLevel = firstGame
local score = 0
local scoreCurrentLevel = 0
local bgHeight
local bgY
local bgAboveY

-- Display groups
local background -- main background group
local separator --this will overlay 'background'  
local foreground --and this will overlay 'separator'
local foregroundText --and this will overlay 'foreground'

-- UI elements
local screenTouchBox
local currentBackground
local nextBackground
local leftWall
local rightWall
local topWall
local bottomWall
local ozone
local scoreText
local scoreLabelText
local levelText
local levelLabelText
local levelIndicator
local levelsInfoText
-- local backArrow
-- local prevLevelButton
-- local forwardArrow
-- local nextLevelButton
local firstGameText
local firstGameFinger

-- Functions
local startGame

local function tableContains(tbl, val)
    for index, value in ipairs(tbl) do
        if value == val then
            return true
        end
    end

    return false
end

local function shuffle(t)
    local j
    
    for i = #t, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function shuffleTable( t, iter )
    local iter = iter or 1
    local n

    for i = 1, iter do
        n = #t 
        while n >= 2 do
            -- n is now the last pertinent index
            local k = math.random(n) -- 1 <= k <= n
            -- Quick swap
            t[n], t[k] = t[k], t[n]
            n = n - 1
        end
    end
 
    return t
end

local function getAngle(x1,y1,x2,y2)
    local PI = math.pi
    local deltaY = y2 - y1
    local deltaX = x2 - x1

    local angleInDegrees = (((math.atan2(deltaY, deltaX) * 180)/ PI)+90)%360

    local mult = 10^0

    return math.floor(angleInDegrees * mult + 0.5) / mult
end

local function lighten(color, factor)
    color[1] = color[1] + (255 - color[1]) * factor -- r
    color[2] = color[2] + (255 - color[2]) * factor -- g
    color[3] = color[3] + (255 - color[3]) * factor -- b
    return color
end

function scene:onBackKey(event)
    return true
end

local function animateFinger()
    local fingerMove = ((_g.screenRight-30) - (_g.centerX+earth.contentWidth*0.5+30))*0.5
    local middleToRight

    local function bottomToMiddle()
        firstGameFinger.transition = transition.to(firstGameFinger, {y = firstGameFinger.y-fingerMove, time = 500, onComplete = function()
            middleToRight()                
        end})
    end
    local function topToBottom()
        firstGameFinger.transition = transition.to(firstGameFinger, {y = firstGameFinger.y+fingerMove*2, time = 1000, onComplete = function()
            bottomToMiddle()
        end})
    end
    local function middleToTop()
        firstGameFinger.transition = transition.to(firstGameFinger, {y = firstGameFinger.y-fingerMove, time = 500, onComplete = function()
            topToBottom()
        end})
    end
    local function leftToMiddle()
        firstGameFinger.transition = transition.to(firstGameFinger, {x = firstGameFinger.x+fingerMove, time = 500, onComplete = function()
            middleToTop()
        end})
    end
    local function rightToLeft()
        firstGameFinger.transition = transition.to(firstGameFinger, {x = firstGameFinger.x-fingerMove*2, time = 1000, onComplete = function()
            leftToMiddle()
        end})
    end
    middleToRight = function()
        firstGameFinger.transition = transition.to(firstGameFinger, {x = firstGameFinger.x+fingerMove, time = 500, onComplete = function()
            rightToLeft()
        end})
    end
    middleToRight()
end

local function createMeteor()
    -- scale = scale or 1
    local name = "meteor"
    local meteor = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex(name)}})
    local physicsData = objectsPhysics.physicsData()
    physics.addBody( meteor, physicsData:get(name) )

    table.insert(objectsTable, meteor)

    return meteor
end

-- local function levelIndex()
--     return ((level-1) % #levelIndexes) + 1
-- end

-- local function currentLevel()
--     return levelIndexes[levelIndex()]
-- end

local function updateTextColors()
    local color = levels[currentLevel].textColor
    if color == 0 then
        transition.to( scoreText.fill, { r=0, g=0, b=0, time=300, transition=easing.inCubic })
        transition.to( scoreLabelText.fill, { r=0, g=0, b=0, time=300, transition=easing.inCubic })
        transition.to( levelText.fill, { r=0, g=0, b=0, time=300, transition=easing.inCubic })
        transition.to( levelLabelText.fill, { r=0, g=0, b=0, time=300, transition=easing.inCubic })
        levelIndicator:setFillColor(0)
        levelIndicator.alpha = 0.5
    else
        transition.to( scoreText.fill, { r=1, g=1, b=1, time=300, transition=easing.inCubic })
        transition.to( scoreLabelText.fill, { r=1, g=1, b=1, time=300, transition=easing.inCubic })
        transition.to( levelText.fill, { r=1, g=1, b=1, time=300, transition=easing.inCubic })
        transition.to( levelLabelText.fill, { r=1, g=1, b=1, time=300, transition=easing.inCubic })
        levelIndicator:setFillColor(1)
        levelIndicator.alpha = 0.7
    end
end

local function cancelLevelTimers()
    for i = 1, #lvlTmrs do
        if lvlTmrs[i] then
            timer.cancel(lvlTmrs[i])
            lvlTmrs[i] = nil
        end
    end
    lvlTmrs = {}
end

local function nextLevel()
    print("nextLevel()")
    levels[currentLevel].create()
end

local function setupNextLevel(incrementLevel)
    print("setupNextLevel()")
    -- cleanup previous level
    cancelLevelTimers()
    canRemoveObjects = false
    levelIsSetup = false

    -- Print the score from the previous level and reset
    print("Score level " .. level .. ": " .. scoreCurrentLevel)
    scoreCurrentLevel = 0

    -- Get the background from the previous level
    local prevBg
    if isFirstLevel then
        prevBg = _g.mainBgColor
    else
        prevBg = levels[currentLevel].background
    end

    -- Increment the level if needed
    if incrementLevel then
        level = level + 1
        currentLevel = levelIndexes:get()
        -- for i = 1, 100 do
        --     print(levelIndexes:get())
        -- end
    end

    local bg = levels[currentLevel].background
    levelText.text = "#" .. level
    levelIndicator.text = "LEVEL " .. level
    levelsInfoText.text = "Cur: " .. currentLevel

    -- lastLevelPlayed = currentLevel
    -- _data:update("lastLevelPlayed", lastLevelPlayed)

    -- background stuff for new level
    local color = {prevBg[1],prevBg[2],prevBg[3]}
    local factor = 0
    for i = separator.numChildren, 1, -1 do
        if separator[i].myName == "separator" then
            factor = factor + 0.2
            color = lighten(color, factor)
            separator[i]:setFillColor(color[1]/255,color[2]/255,color[3]/255)
            if i%2==1 then
                separator[i].xScale = -1
            end
        end
    end

    separator.y = _g.screenTop - separator.contentHeight/2
    local separatorNewY = _g.screenBottom + separator.contentHeight/2 + 40
    transition.to(separator, {time=getScrollDuration(separatorNewY-separator.y), y=separatorNewY})

    currentBackground:toBack()
    nextBackground.y = bgAboveY
    nextBackground:setFillColor(bg[1]/255,bg[2]/255,bg[3]/255)
    local bgNewY = _g.centerY
    transition.to(nextBackground, {time=getScrollDuration(bgNewY-nextBackground.y), y=bgNewY})
    currentBackground, nextBackground = nextBackground, currentBackground
    local nextLevelDelay = getScrollDuration((earth.y+separator.contentHeight*0.5)-separator.y)
    timer.performWithDelay( nextLevelDelay, nextLevel, 1 )

    local updateColorsDelay = getScrollDuration(scoreText.y-separator.y)
    timer.performWithDelay( updateColorsDelay, updateTextColors, 1 )

    isFirstLevel = false
end

function dragOzone( event )
    local phase = event.phase
 
    if ( "began" == phase ) then
        -- Set touch focus on the ozone
        -- display.currentStage:setFocus( ozone )

        lastTouchX = event.x
        lastTouchY = event.y

        if ozone.x < _g.screenLeft or ozone.x > _g.screenRight 
            or ozone.y < _g.screenTop or ozone.y > _g.screenBottom then
            ozone.x = _g.centerX
            ozone.y = earth.y - 120
        end
    elseif ( "moved" == phase ) then
        if firstGame then
            -- Remove tutorial
            firstGameText:removeSelf()
            firstGameText = nil
            if firstGameFinger.transition then
                transition.cancel(firstGameFinger.transition)
                firstGameFinger.transition = nil
            end
            firstGameFinger:removeSelf()
            firstGameFinger = nil

            -- Start the game
            firstGame = false
            startGame()
        end

        -- Move the ozone to the new touch position
        local tX, tY = ozone.touchJoint:getTarget()
        local transitionX = event.x - lastTouchX
        local transitionY = event.y - lastTouchY

        if transitionX > 0 then
            transitionX = transitionX + 0.5
        elseif transitionX < 0 then
            transitionX = transitionX - 0.5
        end

        if transitionY > 0 then
            transitionY = transitionY + 0.5
        elseif transitionY < 0 then
            transitionY = transitionY - 0.5
        end

        local newX = tX + transitionX
        local newY = tY + transitionY

        if newX < _g.screenLeft or newX > _g.screenRight then
            newX = tX
        end
        if newY < _g.screenTop or newY > _g.screenBottom then
            newY = tY
        end

        -- Update the joint to track the touch
        ozone.touchJoint:setTarget( newX, newY )

        lastTouchX = event.x
        lastTouchY = event.y
 
    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Release touch focus on the ozone
        -- display.currentStage:setFocus( nil )
    end
 
    return true  -- Prevents touch propagation to underlying objects
end

local function resetGravity(obj)
    if obj.collisionGravityScale then
        obj.gravityScale = obj.collisionGravityScale
    else
        obj.gravityScale = 1
    end
end

local function removeObj(obj, tableIndex)
    table.remove(objectsTable, tableIndex)
    if obj.tmr then
        timer.cancel(obj.tmr)
        obj.tmr = nil
    end
    display.remove( obj )
    obj = nil
end

local function gameLoop()
    -- Remove objects which have drifted off screen
    if canRemoveObjects and gameStarted then
        for i = #objectsTable, 1, -1 do
            local obj = objectsTable[i]
            
            if obj.removeSelf == nil then
                removeObj(obj, i)
            else
                local x = math.max(obj.contentWidth*0.5, obj.contentHeight*0.5)
                if ( obj.x < _g.screenLeft - x or
                     obj.x > _g.screenRight + x or
                     obj.y < _g.screenTop - 500 or
                     obj.y > _g.screenBottom + x)
                then
                    removeObj(obj, i)
                end
            end
        end

        if levelIsSetup and #objectsTable == 0 then
            setupNextLevel(true)
        end
    end
end

local function scoreLoop()
    if scoreCurrentLevel >= levels[currentLevel].maxScore then return end
    score = score + 1
    scoreCurrentLevel = scoreCurrentLevel + 1
    scoreText.text = score
end

function scene:gameOver(fromOverlay)
    -- Submit score to game services
    _gs:submitScore(score)

    local isHighScore = false
    if score > highScore then
        highScore = score
        _data:update("highScore", highScore)
        isHighScore = true
    end
    if level > highestLevel then
        highestLevel = level
        _data:update("highestLevel", highestLevel)
    end

    -- Log event in firebase
    _fa.logEvent("post_score", {level=level, score=score, character="normal"})
    print("event logged")

    local params = { score=score, level=level, isHighScore=isHighScore }

    if fromOverlay then
        composer.hideOverlay( "fade", 400 )
        composer.gotoScene("scenes.menu", {params = params})
    else
        composer.gotoScene("scenes.menu", {effect = "crossFade", time = 500, params = params})
    end
end

local function explodeEarth(x, y, obj)
    local starSpeed = 20
    local starTime = 1000
    physics.setTimeStep(1/800)
    transition.cancel(earth.transition)
    timer.performWithDelay(1, function()
        -- obj.isBodyActive = false
        obj.bodyType = "static"
    end)

    transition.to(ozone, {time=1500, alpha=0})
    transition.to(earth, {time=1500, alpha=0})
    timer.performWithDelay(1000, function()
        earth.isBodyActive = false
        -- ozone.isBodyActive = false
    end)

    local bg = {unpack(levels[currentLevel].background)}
    -- Get the complement of the color
    bg[1], bg[2], bg[3] = 255-bg[1], 255-bg[2], 255-bg[3]
    timer.performWithDelay(2, function()
        for i = 1, 2 do
            local starDown = display.newRect(foreground, x,y,10,10)
            starDown:setFillColor(bg[1]/255,bg[2]/255,bg[3]/255)
            transition.to(starDown, {time=starTime, alpha=0, x=x+4*(rand(starSpeed*-1,starSpeed)), y=y+3*(rand(starSpeed*-1,starSpeed)), onComplete = function()
                starDown:removeSelf()
                starDown = nil
            end})
        end
    end, 30)

    timer.performWithDelay(3000, function()
        -- physics.setTimeStep(-1)
        -- while #objectsTable > 0 do
        --     removeObj(objectsTable[1], 1)
        -- end
        -- gameStarted = true
        -- setupNextLevel()
        -- composer.gotoScene("scenes.menu", {effect = "crossFade", time = 500})
        -- gameLoopTimer = timer.performWithDelay( 1000, gameLoop, 0 )
        -- scoreLoopTimer = timer.performWithDelay( 100, scoreLoop, 0 )
        -- earth.isBodyActive = true
        -- earth.alpha = 1
        -- ozone.isBodyActive = true
        -- ozone.alpha = 1

        physics.pause()
        -- Show the game over overlay
        if (_g.debug and gameResumed) or (not _g.debug and (gameResumed or level == 1)) or (not _ads:canShowReward()) then
            scene:gameOver(false)
        else
            composer.showOverlay( "scenes.gameOver", {isModal = true, effect = "fade", time = 400})
        end
    end)
end

local function endGame(x, y, obj)
    if not gameStarted then return end
    gameStarted = false

    -- Stop movement of object that hit earth
    -- obj:setLinearVelocity(0)
    -- obj.angularVelocity = 0

    cancelLevelTimers()
    transition.cancel() -- cancel all transitions
    if gameLoopTimer ~= nil then timer.cancel(gameLoopTimer) end
    if scoreLoopTimer ~= nil then timer.cancel(scoreLoopTimer) end
    explodeEarth(x, y, obj)
    screenTouchBox:removeEventListener("touch", dragOzone)
end

local function onGlobalCollision( event )
 
    if ( event.phase == "began" ) then
        if event.object1.myName == "earth" and event.object2.myName ~= "ozone" then
            print("Collided with earth")
            event.contact.bounce = 0
            endGame(event.x, event.y, event.object2)
        elseif event.object2.myName == "earth" and event.object1.myName ~= "ozone" then
            print("Collided with earth")
            event.contact.bounce = 0
            endGame(event.x, event.y, event.object1)
        end
    elseif ( event.phase == "ended" ) then
        if event.object1.myName ~= "ozone" then
            resetGravity(event.object1)
        end
        if event.object2.myName ~= "ozone" then
            resetGravity(event.object2)
        end
    end

end

local function resetGame()
    separator.y = _g.screenTop - separator.contentHeight/2

    currentBackground.y = bgY
    currentBackground:setFillColor(_g.mainBgColor[1]/255,_g.mainBgColor[2]/255,_g.mainBgColor[3]/255)
    currentBackground:toBack()

    nextBackground.y = bgAboveY
    nextBackground:setFillColor(_g.mainBgColor[1]/255,_g.mainBgColor[2]/255,_g.mainBgColor[3]/255)
    nextBackground:toBack()

    while #objectsTable > 0 do
        removeObj(objectsTable[1], 1)
    end

    ozone.x, ozone.y = _g.centerX, earth.y - 120
    ozone.touchJoint:setTarget( _g.centerX, earth.y - 120 )
    ozone.alpha = 1

    -- Set text colors back to white
    scoreText:setFillColor(1)
    scoreLabelText:setFillColor(1)
    levelText:setFillColor(1)
    levelLabelText:setFillColor(1)
end

startGame = function()
    -- add touch listener for ozone
    screenTouchBox:removeEventListener("touch", dragOzone) -- remove just in case
    screenTouchBox:addEventListener("touch", dragOzone)

    if firstGame then
        return
    end
    -- reset some game stuff
    physics.start()
    physics.setTimeStep(-1)
    physics.setGravity( 0, 3 )
    physics.setReportCollisionsInContentCoordinates( true )
    -- physics.setDrawMode( "hybrid" )
    gameStarted = true
    isFirstLevel = true

    if gameResumed then
        score = score - scoreCurrentLevel
    else
        level = 1
        score = 0
        currentLevel = levelIndexes:get()

        -- If the level is the same as the last level played, pick a different one
        -- while lastLevelPlayed == currentLevel do
        --     currentLevel = levelIndexes:get()
        -- end
        -- currentLevel = 45 -- ###

        -- Increment the games played data
        gamesPlayed = gamesPlayed + 1
        _data:update("gamesPlayed", gamesPlayed)
    end

    if (_g.debug) then
        local m = "Levels Remaining:"
        for i = 1, #levelIndexes.unused do
            m = m .. " " .. levelIndexes.unused[i]
        end
        print(m)

        m = "Levels Used:"
        for i = 1, #levelIndexes.used do
            m = m .. " " .. levelIndexes.used[i]
        end
        print(m)
    end

    -- levelIndexes[1] = 25 -- ###
    scoreCurrentLevel = 0
    earth.isBodyActive = true
    earth.alpha = 1
    transition.cancel(earth.transition)
    earth.transition = transition.to( earth, { time = 20000, rotation = earth.rotation+360, iterations = 0 } )
    ozone.isBodyActive = true
    ozone.alpha = 1
    -- setupTouchJoint()

    -- start timers
    gameLoopTimer = timer.performWithDelay( 1000, gameLoop, 0 )
    scoreLoopTimer = timer.performWithDelay( 100, scoreLoop, 0 )

    setupNextLevel(false)
end

-- Custom function for resuming the game (from game over state)
function scene:resumeGame()
    gameResumed = true
    resetGame()
    startGame()
end

function scene:onResized(event)
    screenTouchBox.x, screenTouchBox.y = _g.centerX, _g.centerY
    screenTouchBox.width, screenTouchBox.height = _g.screenWidth*4, _g.screenHeight*4

    local widthScale = _g.screenWidth / 320
    local h = widthScale*67
    for i = separator.numChildren, 1, -1 do
        if separator[i].myName == "separator" then
            separator[i].width = _g.screenWidth
            separator[i].height = h
        end
    end

    separator.y = _g.screenTop - separator.contentHeight/2

    bgHeight = _g.screenHeight + separator.contentHeight/2
    bgY = _g.centerY - ((bgHeight-_g.screenHeight)/2)
    bgAboveY = bgY - bgHeight

    currentBackground.width, currentBackground.height = _g.screenWidth, bgHeight
    nextBackground.width, nextBackground.height = _g.screenWidth, bgHeight

    leftWall.height = _g.screenHeight
    leftWall.x, leftWall.y = _g.screenLeft, _g.centerY

    rightWall.height = _g.screenHeight
    rightWall.x, rightWall.y = _g.screenRight, _g.centerY

    topWall.width = _g.screenWidth
    topWall.x, topWall.y = _g.centerX, _g.screenTop

    bottomWall.width = _g.screenWidth
    bottomWall.x, bottomWall.y = _g.centerX, _g.screenBottom

    ozone.x, ozone.y = _g.centerX, earth.y - 120

    scoreText.x, scoreText.y = _g.screenLeft+25, _g.safeScreenTop+15
    scoreLabelText.x, scoreLabelText.y = _g.screenLeft+25, scoreText.y+15

    levelText.x, levelText.y = _g.screenRight-25, _g.safeScreenTop+15
    levelLabelText.x, levelLabelText.y = _g.screenRight-24, scoreText.y+15

    levelsInfoText.y = _g.screenBottom-15
    -- backArrow.y = _g.screenBottom - 15
    -- forwardArrow.y = _g.screenBottom - 15
    -- prevLevelButton.y = _g.screenBottom - 25
    -- nextLevelButton.y = _g.screenBottom - 25

    if firstGame and firstGameText ~= nil and firstGameFinger ~= nil then
        firstGameText.x, firstGameText.y = _g.centerX, ozone.y - 100
        if firstGameFinger.transition ~= nil then
            transition.cancel(firstGameFinger.transition)
        end
        firstGameFinger.x, firstGameFinger.y = _g.centerX + (_g.screenRight - (_g.centerX+earth.contentWidth*0.5)), earth.y
        animateFinger()
    end 
end

local function setupLevelIndexes()
    levelIndexes = {}
    levelIndexes.used = {}
    levelIndexes.unused = {}
    
    levelIndexes.insert = function(entry)
        levelIndexes.unused[#levelIndexes.unused+1] = entry
    end

    levelIndexes.remove = function(entry)
        for i = 1, #levelIndexes.unused do
           if levelIndexes.unused[i] == entry then
              levelIndexes.used[#levelIndexes.used+1] = levelIndexes.unused[i]
              table.remove(levelIndexes.unused, i)
              _data:update("levelIndexes", levelIndexes)
              return true
           end
        end
        
        return false    
    end

    levelIndexes.shuffle = function()
        for i = 1, #levelIndexes.unused do
           levelIndexes.used[#levelIndexes.used+1] = levelIndexes.unused[i]
        end
        levelIndexes.unused = shuffleTable( levelIndexes.used, 100 )
        levelIndexes.used = {} 
    end

    levelIndexes.get = function()
        if( #levelIndexes.unused == 0 ) then      
           levelIndexes:shuffle()
        end
        while true do
            for i = #levelIndexes.unused, 1, -1 do
                -- print("i: " .. i)
                if level >= levels[levelIndexes.unused[i]].difficulty then
                    levelIndexes.used[#levelIndexes.used+1] = levelIndexes.unused[i]
                    table.remove(levelIndexes.unused, i)
                    _data:update("levelIndexes", levelIndexes)
                    return levelIndexes.used[#levelIndexes.used]
                end
            end
            levelIndexes:shuffle()
        end

        return nil
    end

    -- Check if level indexes have already been saved
    local temp = _data:get("levelIndexes")
    if temp == nil then
        if doFirstGameLevel then
            for i = 2, #levels do
                levelIndexes.insert(i)
            end
            levelIndexes.shuffle()
            levelIndexes.insert(1)
            doFirstGameLevel = false
        else
            for i = 1, #levels do
                levelIndexes.insert(i)
            end
            levelIndexes.shuffle()
        end
        _data:update("levelIndexes", levelIndexes)
    else
        levelIndexes.unused = temp.unused
        levelIndexes.used = temp.used

        -- Make sure all levels are in either used or unused
        if #levelIndexes.unused + #levelIndexes.used < #levels then
            for i = 1, #levels do
                if not tableContains(levelIndexes.unused, i) and not tableContains(levelIndexes.used, i) then
                    levelIndexes.insert(i)
                end
            end
        end
    end
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    physics.start()
    physics.setGravity( 0, 3 )
    physics.setReportCollisionsInContentCoordinates( true )

    -- Initialize the display groups and add them to the scene group
    background = display.newGroup()
    sceneGroup:insert(background)
    separator = display.newGroup()
    sceneGroup:insert(separator)
    foreground = display.newGroup()
    sceneGroup:insert(foreground)
    foregroundText = display.newGroup()
    sceneGroup:insert(foregroundText)

    -- Create the background level separator and move it to the top
    local widthScale = _g.screenWidth / 320
    local h = widthScale*67
    local y = 60
    for i = 1, 4 do
        local bgSeparator = display.newSprite(separator, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("bg-separator")}})
        bgSeparator.width = _g.screenWidth
        bgSeparator.height = h
        -- local bgSeparator = display.newImageRect(separator, "bg-separator8.png", _g.screenWidth, h)
        bgSeparator.x = _g.centerX
        bgSeparator.y = y
        bgSeparator.myName = "separator"
        bgSeparator:toBack()

        y = y - 40
    end
    levelIndicator = display.newText(separator, "LEVEL 1", _g.centerX, y-50, _g.fontMain, 44)
    levelIndicator.alpha = 0.7
    levelIndicator.myName = "levelIndicator"
    separator.y = _g.screenTop - separator.contentHeight/2

    -- Create main backgrounds
    bgHeight = _g.screenHeight + separator.contentHeight/2
    bgY = _g.centerY - ((bgHeight-_g.screenHeight)/2)
    bgAboveY = bgY - bgHeight

    currentBackground = display.newRect(background, _g.centerX, bgY, _g.screenWidth, bgHeight)
    currentBackground:setFillColor(_g.mainBgColor[1]/255,_g.mainBgColor[2]/255,_g.mainBgColor[3]/255)
    currentBackground:toBack()

    nextBackground = display.newRect(background, _g.centerX, bgAboveY, _g.screenWidth, bgHeight)
    nextBackground:setFillColor(_g.mainBgColor[1]/255,_g.mainBgColor[2]/255,_g.mainBgColor[3]/255)
    nextBackground:toBack()

    -- Create clouds in the background
    -- bgClouds = display.newImageRect(background, "bg-main.png", _g.screenWidth, _g.screenWidth/2)
    -- bgClouds.x = _g.centerX
    -- bgClouds.y = _g.screenBottom - bgClouds.contentHeight/2

    -- Create invisible walls to block the ozone
    leftWall = display.newRect(foreground,_g.screenLeft,_g.centerY,0,_g.screenHeight)
    leftWall.myName = "leftWall"
    rightWall = display.newRect(foreground,_g.screenRight,_g.centerY,0,_g.screenHeight)
    rightWall.myName = "rightWall"
    topWall = display.newRect(foreground,_g.centerX,_g.screenTop,_g.screenWidth,0)
    topWall.myName = "topWall"
    bottomWall = display.newRect(foreground,_g.centerX,_g.screenBottom,_g.screenWidth,0)
    bottomWall.myName = "bottomWall"
    physics.addBody (leftWall, "static", { friction=0, bounce = 0, filter = { categoryBits=2, maskBits=4 }} )
    physics.addBody (rightWall, "static", { friction=0, bounce = 0, filter = { categoryBits=2, maskBits=4 }} )
    physics.addBody (topWall, "static", { friction=0, bounce = 0, filter = { categoryBits=2, maskBits=4 }} )
    physics.addBody (bottomWall, "static", { friction=0, bounce = 0, filter = { categoryBits=2, maskBits=4 }} )
 
    -- Create earth and ozone above it
    -- earth = display.newSprite(foreground, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("earth")}})
    -- earth.x = _g.centerX
    -- local earthY = _g.safeScreenTop + 480
    -- if earthY+45 > _g.screenBottom then
    --     earthY = _g.screenBottom - 65
    -- end
    -- earth.y = earthY
    -- physics.addBody( earth, "static", { radius=45, filter = { categoryBits=1, maskBits=12+32 } } )
    -- earth.myName = "earth"
    -- earth.transition = transition.to( earth, { time = 20000, rotation = 360, iterations = 0 } )
    physics.addBody( earth, "static", { radius=45, filter = { categoryBits=1, maskBits=12+32 } } )

    ozone = display.newSprite(foreground, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("ozone")}})
    ozone.x = _g.centerX
    ozone.y = earth.y - 120
    ozone.myName = "ozone"
    physics.addBody( ozone, { radius=21, density=1, bounce=0, filter = { categoryBits = 4 } } )
    ozone.gravityScale = 0
    ozone.isBullet = true
    ozone.isFixedRotation = true
    ozone.touchJoint = physics.newJoint( "touch", ozone, ozone.x, ozone.y )
    ozone.touchJoint.dampingRatio = 1
    ozone.touchJoint.maxForce = 5000
    ozone.touchJoint.frequency = 20

    -- Create score and level texts
    -- Score and level
    scoreText = display.newText(foregroundText, score, _g.screenLeft+25, _g.safeScreenTop+15, _g.fontMain, 14)
    scoreLabelText = display.newText(foregroundText, "SCORE", _g.screenLeft+25, scoreText.y+15, _g.fontRegular, 10)
    levelText = display.newText(foregroundText, "#" .. level, _g.screenRight-25, _g.safeScreenTop+15, _g.fontMain, 14)
    levelLabelText = display.newText(foregroundText, "LEVEL", _g.screenRight-25, scoreText.y+15, _g.fontRegular, 10)

    -- Show level stuff for debug
    levelsInfoText = display.newText(foregroundText, "Cur: ", _g.centerX, _g.screenBottom-15, native.systemFont, 16)
    if not _g.debug then
        levelsInfoText.isVisible = false
    end

    -- Create invisble full screen object for touch events
    screenTouchBox = display.newRect(foregroundText, _g.centerX, _g.centerY, _g.screenWidth*4, _g.screenHeight*4)
    screenTouchBox.isVisible = false
    screenTouchBox.isHitTestable = true

    -- local function prevLevelEvent( event )
    --     if ( "ended" == event.phase ) then
    --         -- nextLevelIndex = nextLevelIndex - 1
    --         -- if nextLevelIndex <= 1 then nextLevelIndex = #levels end
    --         -- levelsInfoText.text = "Cur: " .. currentLevel
    --     end
    -- end

    -- local function nextLevelEvent( event )
    --     if ( "ended" == event.phase ) then
    --         -- nextLevelIndex = nextLevelIndex + 1
    --         -- if nextLevelIndex > #levels then nextLevelIndex = 1 end
    --         -- levelsInfoText.text = "Cur: " .. currentLevel
    --     end
    -- end

    -- backArrow = display.newPolygon(foregroundText, _g.screenLeft + 15, _g.screenBottom - 15, { -8,0, 8,-10, 8,10 })
    -- backArrow:setFillColor(1)
    -- prevLevelButton = widget.newButton(
    --     {
    --         x = _g.screenLeft + 25, 
    --         y = _g.screenBottom - 25,
    --         onEvent = prevLevelEvent,
    --         shape = "rect",
    --         width = 50,
    --         height = 50,
    --         fillColor = { default={0,0,0,0.01}, over={0,0,0,0} }
    --     }
    -- )
    -- foregroundText:insert(prevLevelButton)
    -- forwardArrow = display.newPolygon(foregroundText, _g.screenRight - 15, _g.screenBottom - 15, { 8,0, -8,-10, -8,10 })
    -- forwardArrow:setFillColor(1)
    -- nextLevelButton = widget.newButton(
    --     {
    --         x = _g.screenRight - 25, 
    --         y = _g.screenBottom - 25,
    --         onEvent = nextLevelEvent,
    --         shape = "rect",
    --         width = 50,
    --         height = 50,
    --         fillColor = { default={0,0,0,0.01}, over={0,0,0,0} }
    --     }
    -- )
    -- foregroundText:insert(nextLevelButton)

    if firstGame then
        firstGameText = display.newText(foregroundText, "PROTECT THE EARTH", _g.centerX, ozone.y - 100, _g.fontMain, 22)
        firstGameText:setFillColor(54/255,85/255,102/255)
        firstGameFinger = display.newSprite(foregroundText, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("finger")}})
        firstGameFinger.x, firstGameFinger.y = _g.centerX + (_g.screenRight - (_g.centerX+earth.contentWidth*0.5)), earth.y
        animateFinger()
    end

    levels = { -- ###
        {
            level = 1,
            difficulty = 1,
            maxScore = 250,
            desc = "Asteroids aligned",
            background = {66,13,51},
            textColor = 1,
            create = function()
                local y = 0
                local rowCount = 5
                local velocityY = _g.scrollSpeed * display.fps

                for i = 1, rowCount, 1 do
                    local randMeteor1 = createMeteor()
                    local randMeteor2 = createMeteor()
                    local randMeteor3 = createMeteor()

                    if i == 1 then
                        y = _g.screenTop - (randMeteor1.contentHeight/2) - 5
                    end

                    local y2 = y - randMeteor1.contentHeight/2
                    randMeteor1.y, randMeteor2.y, randMeteor3.y = y, y2, y2
                    y = y - (randMeteor1.contentHeight * 1.5)
                   
                    randMeteor1.x = _g.centerX
                    randMeteor2.x = randMeteor1.x - (randMeteor1.contentWidth * 1.5)
                    randMeteor3.x = randMeteor1.x + (randMeteor1.contentWidth * 1.5)
                    randMeteor1:setLinearVelocity(0, velocityY)
                    randMeteor2:setLinearVelocity(0, velocityY)
                    randMeteor3:setLinearVelocity(0, velocityY)
                    randMeteor1:applyTorque(rand(-200, 200))
                    randMeteor2:applyTorque(rand(-200, 200))
                    randMeteor3:applyTorque(rand(-200, 200))

                    randMeteor1.gravityScale = 0
                    randMeteor2.gravityScale = 0
                    randMeteor3.gravityScale = 0
                end

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 2,
            difficulty = 1,
            maxScore = 250,
            desc = "Asteroids random",
            background = {35,26,61},
            textColor = 1,
            create = function()
                local meteorCount = 20
                local i = 1

                local func = function()
                    local meteor = createMeteor()
                    local x = rand(_g.screenLeft + meteor.contentWidth, _g.screenRight - meteor.contentWidth)
                    meteor.x = x
                    meteor.y = _g.screenTop - (meteor.contentHeight/2) - 5

                    local xVelocity = 0
                    if x < _g.centerX then
                        xVelocity = rand(0, 75)
                    else
                        xVelocity = rand(-75, 0)
                    end

                    meteor:setLinearVelocity(xVelocity, rand(200, 375))
                    meteor:applyTorque(rand(-200, 200))
                    meteor.gravityScale = 0

                    if i == meteorCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 600, func, meteorCount-1 )

                canRemoveObjects = true
            end
        },
        {
            level = 3,
            difficulty = 2,
            maxScore = 230,
            desc = "Satellites spinning",
            background = {89,29,28},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 2
                local satelliteCount = 8
                local moveTime = 1000
                local n = 1

                local function onSatelliteCollision( self, event )
                    if ( event.phase == "began" ) then
                        transition.cancel(self.anim1)
                        transition.cancel(self.anim2)
                        transition.cancel(self.anim3)
                        self:removeEventListener("collision", onSatelliteCollision)
                    end
                end
                
                local i = 1
                local func = function()
                    local x, name
                    x = _g.centerX + rand(-100, 100)
                    if n == 1 then
                        name = "satellite1"
                    else
                        name = "satellite2"
                    end

                    local satellite = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex(name)}} )
                    satellite.x = x
                    satellite.y = _g.screenTop - satellite.contentHeight/2
                    table.insert(objectsTable, satellite)

                    local physicsData = objectsPhysics.physicsData()
                    physics.addBody( satellite, physicsData:get("satellite") )
                    satellite.bodyType = "kinematic"
                    satellite.gravityScale = 0
                    satellite:setLinearVelocity(0, velocityY)

                    local function animate( event )
                        satellite.bodyType = "dynamic"
                        satellite.anim1 = transition.to(satellite, {y = earth.y + rand(-20,20), time = moveTime})
                        satellite.anim2 = transition.to(satellite, {x = _g.centerX + rand(-100, 100), delay = 0, time = moveTime/2, transition = easing.outCirc})
                        satellite.anim3 = transition.to(satellite, {x = earth.x, delay = moveTime/2, time = moveTime/2, transition = easing.inCirc})
                        satellite:applyTorque(12000)
                         
                        satellite.collision = onSatelliteCollision
                        satellite:addEventListener( "collision" )
                    end

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(500, animate)

                    if n == 1 then n = 2 else n = 1 end

                    if i == satelliteCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 1250, func, satelliteCount )

                canRemoveObjects = true
            end
        },
        {
            level = 4,
            difficulty = 2,
            maxScore = 230,
            desc = "Stars aligned attacking",
            background = {4,53,123},
            textColor = 1,
            create = function()
                local i = 1
                local y = 0
                local rowCount = 5
                local velocityY = _g.scrollSpeed * display.fps
                local velocityXLeft = 0
                local velocityXRight = 0

                local func = function()
                    for n = 1, 3, 1 do
                        local star = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("star")}} )
                        if n == 1 then
                            star.x = _g.centerX
                        elseif n == 2 then
                            star.x = _g.centerX - 100
                        else
                            star.x = _g.centerX + 100
                        end

                        star.y = _g.screenTop - star.contentHeight/2 - 5

                        local physicsData = objectsPhysics.physicsData()
                        physics.addBody( star, physicsData:get("star") )
                        star:setLinearVelocity(0, velocityY)
                        star:applyTorque(rand(-200, 200))
                        star.gravityScale = 0

                        table.insert(objectsTable, star)

                        local animate = function()
                            if star.removeSelf == nil or star == nil then return end
                            if star.x < _g.centerX - 10 then
                                star:setLinearVelocity(velocityXLeft, velocityY*3)
                            elseif star.x > _g.centerX + 10 then
                                star:setLinearVelocity(velocityXRight, velocityY*3)
                            else
                                star:setLinearVelocity(0, velocityY*3)
                            end
                            velocityXLeft = velocityXLeft + 3
                            velocityXRight = velocityXRight - 3
                            star:applyTorque(1000)
                        end
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1000, animate)
                    end

                    if i == rowCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 1500, func, rowCount )

                canRemoveObjects = true
            end
        },
        {
            level = 5,
            difficulty = 3,
            maxScore = 275,
            desc = "Cannon shooters",
            background = {161,168,247},
            textColor = 1,
            create = function()
                local i = 1
                local cannonCount = 4
                local velocityY = _g.scrollSpeed * display.fps

                local func = function()
                    local cannon = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("cannon")}} )
                    local isEven = true
                    if (i % 2 == 0) then
                        isEven = false
                        cannon.x = _g.screenRight - cannon.contentWidth/4
                        cannon.rotation = 90
                    else
                        cannon.x = _g.screenLeft + cannon.contentWidth/4
                        cannon.rotation = 270
                    end

                    cannon.y = _g.screenTop - cannon.contentHeight/2 - 5

                    local physicsData = objectsPhysics.physicsData()
                    physics.addBody( cannon, physicsData:get("cannon") )
                    cannon.bodyType = "kinematic"
                    cannon:setLinearVelocity(0, velocityY)
                    cannon.gravityScale = 0
                    cannon:toFront()

                    table.insert(objectsTable, cannon)

                    local shoot = function()
                        if cannon.removeSelf == nil or cannon == nil then return end
                        
                        local bullet = display.newCircle(foreground, cannon.x, cannon.y, cannon.contentWidth/6 )
                        bullet:setFillColor(1)
                        physics.addBody( bullet, { radius=cannon.contentWidth/6, density=2, bounce=1, filter = { categoryBits = 8, maskBits = 13 } } )
                        bullet.gravityScale = 0
                        bullet.collisionGravityScale = 0
                        cannon:toFront()

                        if isEven then
                            bullet:setLinearVelocity(200, velocityY)
                        else
                            bullet:setLinearVelocity(-200, velocityY)
                        end

                        table.insert(objectsTable, bullet)
                    end

                    local tmr1, tmr2
                    local checkPosition = function()
                        if cannon.y > earth.y - earth.contentHeight*2 and tmr2 == nil then
                            tmr2 = timer.performWithDelay(400, shoot, 20)
                            lvlTmrs[#lvlTmrs + 1] = tmr2
                        end

                        if cannon.y > _g.screenBottom then
                            timer.cancel(tmr1)
                            timer.cancel(tmr2)
                        end
                    end
                    tmr1 = timer.performWithDelay(100, checkPosition, 0)
                    lvlTmrs[#lvlTmrs + 1] = tmr1

                    if i == cannonCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 3000, func, cannonCount-1 )

                canRemoveObjects = true
            end
        },
        {
            level = 6,
            difficulty = 1,
            maxScore = 150,
            desc = "Popping red ball",
            background = {124,248,245},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 2
                local ballRadius = 100
                local miniBallRadius = 8

                local ball = display.newCircle(foreground, _g.centerX, _g.screenTop - ballRadius, ballRadius )
                ball:setFillColor(unpack({237/255,56/255,51/255}))
                physics.addBody( ball, { radius=ballRadius, density=2, bounce=0, filter = { categoryBits = 8, maskBits = 5 } } )
                ball:setLinearVelocity(0, velocityY)
                table.insert(objectsTable, ball)

                local function onBallCollision( self, event )
                    if ( event.phase == "began" and event.other.myName == "ozone") then
                        self:removeEventListener("collision", onBallCollision)
                        
                        local x, y = self.x, self.y
                        local minX = self.x - ballRadius
                        local maxX = self.x + ballRadius
                        local minY = self.y - ballRadius
                        local maxY = self.y + ballRadius
                        local miniBallsXYs = {
                            -- top left
                            {-24,-24}, {-24,-48}, {-24,-72},
                            {-48,-24}, {-48,-48},
                            {-72,-24},
                            -- bottom left
                            {-24,0}, {-24,24}, {-24,48}, {-24,72},
                            {-48,0}, {-48,24}, {-48,48},
                            {-72,0}, {-72,24},
                            -- bottom right
                            {0,0}, {0,24}, {0,48}, {0,72}, 
                            {24,0}, {24,24}, {24,48}, {24,72},
                            {48,0}, {48,24}, {48,48},
                            {72,0}, {72,24},
                            -- top right
                            {0,-24}, {0,-48}, {0,-72},
                            {24,-24}, {24,-48}, {24,-72},
                            {48,-24}, {48,-48},
                            {72,-24},
                        }
                        local miniBallsTable = {}

                        for i = 1, #miniBallsXYs do
                            local miniBall = display.newCircle(foreground, x+miniBallsXYs[i][1], y+miniBallsXYs[i][2], miniBallRadius )
                            miniBall:setFillColor(unpack({237/255,56/255,51/255}))
                            -- physics.addBody( miniBall, { radius=ballRadius, density=4, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                            table.insert(objectsTable, miniBall)
                            table.insert(miniBallsTable, miniBall)
                        end

                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1, function() 
                            for i = 1, #miniBallsTable do
                                physics.addBody( miniBallsTable[i], { radius=miniBallRadius, density=10, bounce=0.5, filter = { categoryBits = 8, maskBits = 13 } } )
                                miniBallsTable[i].gravityScale = 2
                                miniBallsTable[i].collisionGravityScale = 2
                                miniBallsTable[i]:applyLinearImpulse( 0, -2, miniBallsTable[i].x, miniBallsTable[i].y )
                            end
                        end)

                        display.remove( self )

                        levelIsSetup = true
                    end
                end

                ball.collision = onBallCollision
                ball:addEventListener( "collision" )

                canRemoveObjects = true
            end
        },
        {
            level = 7,
            difficulty = 1,
            maxScore = 200,
            desc = "Triangle break up",
            background = {154,24,26},
            textColor = 1,
            create = function()
                local x = _g.centerX
                local y = _g.screenTop - 50
                local velocityY = _g.scrollSpeed * display.fps * 1.5
                local triangleShape = { 0,-30, 35,30, -35,30 }
                local bigTriangleShape = { 0,-92, 108,92, -108,92 }
                local trianglesTable = {}

                local function onTriangleCollision( self, event )
                    if ( event.phase == "began" and event.other.myName ~= self.myName) then
                        display.remove(self.bigTriangle)
                        for i = 1, #trianglesTable do
                            if trianglesTable[i].myName == self.myName then
                                if trianglesTable[i].removeEventListener then
                                    trianglesTable[i]:removeEventListener("collision", onTriangleCollision)
                                end
                            end
                        end
                    end
                end

                local function createTriangle(coords)
                    local triangle = display.newPolygon(foreground, x + coords[1], y + coords[2], triangleShape)
                    triangle.rotation = coords[3]
                    triangle:setFillColor(unpack({165/255,155/255,131/255}))
                    physics.addBody( triangle, { density=20, bounce=0.1, shape=triangleShape, filter = { categoryBits = 8, maskBits = 13 } } )
                    triangle:setLinearVelocity(0, velocityY)
                    triangle.gravityScale = 0

                    triangle.collision = onTriangleCollision
                    triangle:addEventListener( "collision" )

                    table.insert(objectsTable, triangle)
                    table.insert(trianglesTable, triangle)

                    return triangle
                end

                local function createBigTriangle(r)
                    local triangle = display.newPolygon(foreground, x, y-60.5, bigTriangleShape)
                    triangle.rotation = r
                    triangle:setFillColor(unpack({165/255,155/255,131/255}))
                    physics.addBody( triangle, { density=0, bounce=0, shape=bigTriangleShape, filter = { categoryBits = 8, maskBits = 5 } } )
                    triangle:setLinearVelocity(0, velocityY)
                    triangle.gravityScale = 0

                    table.insert(objectsTable, triangle)

                    return triangle
                end

                -- make the big triangle
                local triangleCoordinates = {
                    {0,-122,0},
                    {-36,-61,0},{0,-61,180},{36,-61,0},
                    {-72,0,0},{-36,0,180},{0,0,0},{36,0,180},{72,0,0}
                }
                local triangleCoordinates2 = {
                    {0,0,180},
                    {-36,-61,180},{0,-61,0},{36,-61,180},
                    {-72,-122,180},{-36,-122,0},{0,-122,180},{36,-122,0},{72,-122,180}
                }

                local bigTriangle = createBigTriangle(0)
                for i = 1, #triangleCoordinates do
                    local triangle = createTriangle(triangleCoordinates[i])
                    triangle.myName = "triangle1"
                    triangle.bigTriangle = bigTriangle
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2000, function() 
                    local bigTriangle = createBigTriangle(180)
                    for i = 1, #triangleCoordinates2 do
                        local triangle = createTriangle(triangleCoordinates2[i])
                        triangle.myName = "triangle2"
                        triangle.bigTriangle = bigTriangle
                    end

                    levelIsSetup = true
                end)

                canRemoveObjects = true
            end
        },
        {
            level = 8,
            difficulty = 2,
            maxScore = 225,
            desc = "Square break up",
            background = {16,58,127},
            textColor = 1,
            create = function()
                local x = _g.centerX
                local y = _g.screenTop - 50
                local velocityX = 0
                local velocityY = 250
                local squaresCount = 5
                local squaresTable = {}

                local function onSquareCollision( self, event )
                    if ( event.phase == "began" and event.other.myName ~= self.myName) then
                        display.remove( self.bigSquare )
                        for i = 1, #squaresTable do
                            if squaresTable[i].myName == self.myName then
                                if squaresTable[i].removeEventListener then
                                    squaresTable[i]:removeEventListener("collision", onSquareCollision)
                                end
                            end
                        end
                    end
                end

                local function createSquare(coords, velocityX, velocityY)
                    local square = display.newRect(foreground, x + coords[1], y + coords[2], 10, 10)
                    square:setFillColor(1)
                    physics.addBody( square, { density=40, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    square:setLinearVelocity(velocityX, velocityY)
                    square.gravityScale = 0

                    square.collision = onSquareCollision
                    square:addEventListener( "collision" )

                    table.insert(objectsTable, square)
                    table.insert(squaresTable, square)

                    return square
                end

                local function createBigSquare(coords, velocityX, velocityY, sides)
                    local xx = x
                    if (sides%2) == 0 then xx = xx - 10 end
                    local square = display.newRect(foreground, xx, y + coords[2] - ((sides-1)*10)/2 , sides*10.5+1, sides*10.5+1)
                    square:setFillColor(1)
                    physics.addBody( square, { density=0, bounce=0, filter = { categoryBits = 8, maskBits = 5 } } )
                    square:setLinearVelocity(velocityX, velocityY)
                    square.gravityScale = 0

                    table.insert(objectsTable, square)

                    return square
                end

                local smallSquareCoordinates = {{-5,-5},{5,-5},{-5,5},{5,5}}

                local i = 1
                local func = function()
                    if i % 2 == 0 then
                        x = _g.centerX + 100
                        velocityX = -30
                    else
                        x = _g.centerX - 100
                        velocityX = 30
                    end
                    -- if i == 6 then
                    --  x = _g.centerX
                    --  velocityX = 0
                    -- end

                    local initialX = 0
                    local initialY = 0
                    if i % 2 == 0 then 
                        initialX = -5
                        initialY = 5
                    end

                    local coords = {initialX,initialY}

                    local bigSquare = nil
                    if i > 1 then
                        bigSquare = createBigSquare(coords, velocityX, velocityY, i)
                        bigSquare.myName = "bigSquare" .. i
                    end

                    initialX = initialX - math.floor(i/2)*10
                    coords = {initialX,initialY}


                    for n = 1, i do
                        for p = 1, i do
                            local square = createSquare(coords, velocityX, velocityY)
                            square.myName = "square" .. i
                            square.bigSquare = bigSquare
                            coords[1] = coords[1] + 10.5
                        end

                        coords[1] = initialX
                        coords[2] = coords[2] - 10.5
                    end

                    if i == squaresCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 1600, func, squaresCount-1 )

                canRemoveObjects = true
            end
        },
        {
            level = 9,
            difficulty = 3,
            maxScore = 300,
            desc = "Tunnel thin rectangles",
            background = {223,170,193},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rectangleCount = 16
                local wallWidth = 40 -- double this
                local leftWallShape = { -wallWidth,-400, wallWidth,-400, wallWidth,300, -wallWidth,400 }
                local rightWallShape = { -wallWidth,-400, wallWidth,-400, wallWidth,400, -wallWidth,300 }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0.4, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0.4, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local y = _g.screenTop - 120
                for i = 1, rectangleCount do
                    local rect = display.newRect(foreground, _g.centerX, y, 75, 3)
                    rect:setFillColor(1)
                    physics.addBody( rect, { density=80, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect:setLinearVelocity(velocityX, velocityY)
                    rect.gravityScale = 0

                    table.insert(objectsTable, rect)

                    y = y - 40
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 15000, function()
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 10,
            difficulty = 3,
            maxScore = 320,
            desc = "Tunnel ball",
            background = {9,48,73},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local ballRadius = 25
                local wallHeight = 600 -- it will be double this
                -- local wallWidth = 40 -- it will be double this
                local wallWidth = (_g.screenWidth-160) * 0.25 -- it will be double this
                local leftWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,(wallHeight-100), -wallWidth,wallHeight }
                local rightWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,wallHeight, -wallWidth,(wallHeight-100) }
                local obstacleCount = 4

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, friction=0, shape=leftWallShape, filter = { categoryBits = 16, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, friction=0, shape=rightWallShape, filter = { categoryBits = 16, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local ball = display.newCircle(foreground, _g.centerX, _g.screenTop - 300, ballRadius )
                ball:setFillColor(unpack({237/255,56/255,51/255}))
                physics.addBody( ball, { radius=ballRadius, density=15, bounce=0.6, friction=0, filter = { categoryBits = 8, maskBits = 29 } } )
                ball:setLinearVelocity(0, velocityY)
                ball.isBullet = true
                ball.gravityScale = 0
                ball.collisionGravityScale = 2
                table.insert(objectsTable, ball)

                local y = _g.screenTop - 450
                for i = 1, obstacleCount do
                    local obstacle = display.newRect(foreground, _g.centerX, y, 60, 10)
                    if i % 2 == 0 then
                        obstacle.x = wallLeft.x + wallLeft.contentWidth/2 + obstacle.contentWidth/2
                    else
                        obstacle.x = wallRight.x - wallLeft.contentWidth/2 - obstacle.contentWidth/2
                    end
                    obstacle:setFillColor(0)
                    physics.addBody( obstacle, "kinematic", { bounce=0.1, filter = { categoryBits = 16, maskBits = 9 } } )
                    obstacle:setLinearVelocity(0, velocityY)
                    obstacle.gravityScale = 0
                    obstacle.collisionGravityScale = 0

                    table.insert(objectsTable, obstacle)

                    if i == obstacleCount then
                        obstacle.x = _g.centerX
                        obstacle.angularVelocity = 90
                    end

                    y = y - 200
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(10000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 11,
            difficulty = 2,
            maxScore = 250,
            desc = "Rockets from sides",
            background = {173,229,246},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rocketCount = 8
                local i = 1
                local launchVelocityX = 80
                local launchVelocityY = 200

                local func = function()
                    local rocket = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("rocket")}} )
                    rocket.y = earth.y - 420 + rand(-40, 40)
                    table.insert(objectsTable, rocket)

                    local physicsData = objectsPhysics.physicsData()
                    physics.addBody( rocket, physicsData:get("rocket") )
                    rocket.bodyType = "kinematic"
                    rocket.gravityScale = 0

                    local dir = rand(1,2)
                    if dir == 1 then
                        rocket.x = _g.screenLeft - rocket.contentWidth
                        rocket:setLinearVelocity(velocityY, velocityY)
                        rocket.rotation = getAngle(rocket.x, rocket.y, earth.x, earth.y) - 5
                    else
                        rocket.x = _g.screenRight + rocket.contentWidth
                        rocket:setLinearVelocity(-velocityY, velocityY)
                        rocket.rotation = getAngle(rocket.x, rocket.y, earth.x, earth.y) + 5
                    end

                    local function animate( event )
                        rocket:setLinearVelocity(0, velocityY)

                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(500, function() 
                            rocket.bodyType = "dynamic"
                            if dir == 1 then
                                rocket:setLinearVelocity(launchVelocityX, launchVelocityY)
                            else
                                rocket:setLinearVelocity(-launchVelocityX, launchVelocityY)
                            end
                            launchVelocityX = launchVelocityX + 10
                            launchVelocityY = launchVelocityY + 10
                        end)
                    end

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(600, animate)

                    if i == rocketCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 1400, func, rocketCount )

                canRemoveObjects = true
            end
        },
        {
            level = 12,
            difficulty = 3,
            maxScore = 250,
            desc = "Rainbow",
            background = {176,244,252},
            textColor = 0,
            create = function()
                local lvX = 90
                local lvY = -120
                local colors = {{166/255,126/255,255/255},{82/255,219/255,255/255},{0/255,220/255,171/255}
                    ,{255/255,221/255,0/255},{255/255,133/255,34/255},{250/255,73/255,110/255}}
                local Ys = {earth.y-172,0,0,0,0,0}
                local countPerColor = 20
                local count = 0
                local tmr

                for i=2, #Ys do
                    Ys[i] = Ys[i-1] - 20
                end

                local func2 = function()
                    if #objectsTable > 0 then 
                        return 
                    end
                    timer.cancel(tmr)
                    local x = _g.centerX - 75
                    for i=1, #colors do
                        local circle = display.newCircle(foreground, x, _g.screenTop - 10, 10)
                        table.insert(objectsTable, circle)
                        circle:setFillColor(unpack(colors[i]))
                        physics.addBody( circle, { density=10, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        circle.gravityScale = 0
                        circle.collisionGravityScale = 1
                        circle:setLinearVelocity(0, 250)

                        x = x + 30
                    end

                    levelIsSetup = true
                end

                local func = function()
                    for i=1, #Ys do
                        local circle = display.newCircle(foreground, _g.screenLeft-5, Ys[i], 5)
                        table.insert(objectsTable, circle)
                        circle:setFillColor(unpack(colors[i]))
                        physics.addBody( circle, { density=10, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        circle.gravityScale = 1
                        circle.collisionGravityScale = 1
                        circle:setLinearVelocity(lvX, lvY)
                        lvX = lvX - 0.4
                    end

                    count = count + 1
                    if count == countPerColor then
                        canRemoveObjects = true
                        tmr = timer.performWithDelay( 500, func2, -1 )
                        lvlTmrs[#lvlTmrs + 1] = tmr
                    end
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 250, func, countPerColor )
            end
        },
        {
            level = 13,
            difficulty = 3,
            maxScore = 250,
            desc = "Lightning",
            background = {33,11,101},
            textColor = 1,
            create = function()
                local lightningCount = 8
                local i = 1

                local function onRectCollision( self, event )
                    if ( event.phase == "began" ) then
                        if self.tmr then
                            timer.cancel(self.tmr)
                            self.tmr = nil
                        end
                        self:removeEventListener("collision", onRectCollision)
                        self.angularDamping = 1
                    end
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1250, function()
                    local n = 1
                    local x = rand(_g.screenLeft + 80, _g.screenRight - 80)
                    local moveTime = rand(200, 600)
                    if i == lightningCount+1 then
                        n = 3
                        x = _g.centerX - 120
                        moveTime = 300
                        levelIsSetup = true
                    end

                    for m = 1, n do
                        local rect = display.newRect(foreground, x, _g.screenTop - 20, 4, 40)
                        table.insert(objectsTable, rect)
                        rect:setFillColor(unpack({238/255,146/255,7/255}))
                        physics.addBody( rect, { density=45, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        rect.angularDamping = 20
                        rect.gravityScale = 0
                        local lvX = 210
                        local lvY = 160
                        local aI = -800
                        if (x > _g.centerX) then
                            lvX = -lvX
                            aI = -aI
                        end
                        rect:setLinearVelocity(lvX, lvY)
                        rect:applyAngularImpulse(aI)
                        aI = aI*2

                        rect.tmr = timer.performWithDelay(moveTime, function()
                            lvX = -lvX
                            aI = -aI
                            rect:applyAngularImpulse(aI)
                            rect:setLinearVelocity(0, lvY)

                            lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(100, function()
                                if rect.removeSelf ~= nil and rect.tmr then
                                    rect:setLinearVelocity(lvX, lvY)
                                end
                            end)    
                        end, -1)
                        lvlTmrs[#lvlTmrs + 1] = rect.tmr

                        rect.collision = onRectCollision
                        rect:addEventListener( "collision" )

                        x = x + 50
                    end

                    i = i + 1

                end, lightningCount+1)

                canRemoveObjects = true
            end
        },
        {
            level = 14,
            difficulty = 2,
            maxScore = 300,
            desc = "Flowers random",
            background = {161,237,166},
            textColor = 0,
            create = function()
                local flowerCount = 8
                local i = 1

                local func = function()
                    local radius = rand(5, 20)
                    local x = rand(_g.screenLeft + radius*3, _g.screenRight - radius*3)

                    local flower = display.newCircle(foreground, x, _g.screenTop - radius*4, radius )
                    table.insert(objectsTable, flower)
                    flower:setFillColor(unpack({240/255,232/255,31/255}))
                    physics.addBody( flower, { radius=radius, density=15, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    flower.gravityScale = 0
                    local petals = {}
                    for p = 1, 6 do
                        local petal = display.newCircle(foreground, flower.x-flower.contentWidth, flower.y, radius )
                        petal.myName = "petal" .. i
                        table.insert(objectsTable, petal)
                        table.insert(petals, petal)
                        petal:setFillColor(unpack({255/255,120/255,185/255}))
                        physics.addBody( petal, { radius=radius, density=15, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        petal.gravityScale = 0

                        local joint = physics.newJoint("distance", flower, petal, flower.x, flower.y, petal.x, petal.y)
                        joint.length = flower.contentWidth
                        petal.joint = joint

                        local function onFlowerCollision( self, event )
                            if ( event.phase == "began" and event.other.myName ~= self.myName) then
                                for n = 1, #petals do
                                    if petals[n].removeEventListener then
                                        petals[n]:removeEventListener("collision", onFlowerCollision)
                                    end
                                end
                                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1, function() 
                                    for n = 1, #petals do
                                        if petals[n].joint.removeSelf ~= nil then
                                            petals[n].joint:removeSelf()
                                        end
                                    end
                                end)
                            end
                        end
                        
                        petal.collision = onFlowerCollision
                        petal:addEventListener( "collision" )
                    end

                    local xVelocity = 0
                    if x < _g.centerX then
                        xVelocity = rand(25, 100)
                    else
                        xVelocity = rand(-100, 25)
                    end

                    flower:setLinearVelocity(xVelocity, rand(200, 400))
                    flower:applyTorque(rand(-200, 200))

                    if i == flowerCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 2000, func, flowerCount-1 )

                canRemoveObjects = true
            end
        },
        {
            level = 15,
            difficulty = 3,
            maxScore = 300,
            desc = "Space ship shooting",
            background = {157,216,194},
            textColor = 0,
            create = function()
                local bulletCount = 20
                local i = 1
                local yStart = 50
                local yTop = 10
                local yBottom = 140
                local dirX, dirY = 1, 1
                local complete = false
                local ship = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("ship")}} )
                table.insert(objectsTable, ship)
                ship.x = _g.centerX
                ship.y = _g.screenTop-ship.contentHeight*0.5
                local physicsData = objectsPhysics.physicsData()
                physics.addBody( ship, physicsData:get("ship") )
                ship.bodyType = "kinematic"
                ship.gravityScale = 0

                local function moveX(obj)
                    if complete then
                        transition.to(ship, {x = _g.centerX, rotation = 0, time = 1500, transition = easing.inOutQuad, onComplete = function()
                            ship.bodyType = "dynamic"
                            ship:setLinearVelocity(0, 400)
                        end})
                        return
                    end

                    local newX
                    if dirX == 1 then
                        newX = rand(_g.centerX+20, _g.screenRight-10)
                        dirX = 2
                    else
                        newX = rand(_g.screenLeft+10, _g.centerX-20)
                        dirX = 1
                    end
                    transition.to(ship, {x = newX, time = 1250, transition = easing.inOutQuad, onComplete=moveX})
                end

                local function moveY(obj)
                    if complete then
                        transition.to(ship, {y = yStart, time = 750, transition = easing.inOutQuad})
                        return
                    end

                    local newY
                    if dirY == 1 then
                        newY = rand(yStart, yBottom)
                        dirY = 2
                    else
                        newY = rand(yTop, yStart)
                        dirY = 1
                    end
                    transition.to(ship, {y = newY, time = 750, transition = easing.inOutQuad, onComplete=moveY})
                end

                transition.to(ship, {y = yStart, time = 750, transition = easing.inOutQuad, onComplete=moveY})
                transition.to(ship, {x = _g.centerX, time = 750, transition = easing.inOutQuad, onComplete=moveX})

                local tmr
                local shouldShoot = true
                local shoot = function()
                    if ship.removeSelf == nil or ship == nil then return end
                    
                    local x, y = 0, ship.contentHeight*0.5
                    local a = getAngle(ship.x, ship.y, earth.x, earth.y) - 180
                    ship.rotation = a

                    if not shouldShoot or rand(1,5) ~= 1 then
                        shouldShoot = true
                        return
                    end
                    shouldShoot = false

                    a = a * math.pi / 180
                    local bullet = display.newCircle(foreground, ship.x + (x*math.cos(a) - y*math.sin(a)), ship.y + (y*math.cos(a) + x*math.sin(a)), 5 )
                    bullet:setFillColor(1)
                    physics.addBody( bullet, { radius=5, density=2, bounce=1, filter = { categoryBits = 8, maskBits = 13 } } )
                    bullet.gravityScale = 0
                    bullet.collisionGravityScale = 0
                    ship:toFront()

                    local velocityX = earth.x - bullet.x --+ rand(-25,25)
                    local velocityY = earth.y - bullet.y
                    bullet:setLinearVelocity(velocityX, velocityY)

                    table.insert(objectsTable, bullet)

                    if i == bulletCount then
                        complete = true
                        timer.cancel(tmr)
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1000, function() 
                    tmr = timer.performWithDelay(100, shoot, -1)
                    lvlTmrs[#lvlTmrs + 1] = tmr
                end)
                canRemoveObjects = true
            end
        },
        {
            level = 16,
            difficulty = 3,
            maxScore = 350,
            desc = "Ball bouncing off walls",
            background = {5,160,90},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local ballCount = 4
                local wallHeight = 800 -- it will be double this
                local wallWidth = 10 -- it will be double this
                local leftWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,(wallHeight-100), -wallWidth,wallHeight }
                local rightWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,wallHeight, -wallWidth,(wallHeight-100) }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local i = 1
                local func
                func = function()
                    local ballRadius = rand(10, 20)
                    if i > ballCount then
                        ballRadius = 15
                    end
                    local x
                    if i%2 == 0 then
                        x = _g.centerX + ballRadius*2 + 1
                    else
                        x = _g.centerX - ballRadius*2 - 1
                    end
                    local ball = display.newCircle(foreground, x, _g.screenTop - ballRadius, ballRadius )
                    ball:setFillColor(1)
                    physics.addBody( ball, { radius=ballRadius, density=10, bounce=0.8, friction=0, filter = { categoryBits = 8, maskBits = 29 } } )
                    ball.gravityScale = 1
                    ball.collisionGravityScale = 1
                    table.insert(objectsTable, ball)

                    if i%2 == 0 then
                        ball:setLinearVelocity(rand(250,350), velocityY)
                    else
                        ball:setLinearVelocity(rand(-350,-250), velocityY)
                    end

                    if i == ballCount then
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(3000, function() 
                            func()
                            func()
                            levelIsSetup = true
                            canRemoveObjects = true
                        end)
                    end

                    i = i + 1
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 3000, func, ballCount )
            end
        },
        {
            level = 17,
            difficulty = 1,
            maxScore = 250,
            desc = "Small squares from sides",
            background = {203,1,159},
            textColor = 1,
            create = function()
                local squareCount = 8
                local velocityX = 45

                local i = 1
                local func = function()
                    local square1 = display.newRect(foreground, _g.screenLeft - 3, earth.y - 200, 6, 6)
                    table.insert(objectsTable, square1)
                    square1:setFillColor(1)
                    physics.addBody( square1, { density=15, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    square1:setLinearVelocity(velocityX, -200)
                    square1.gravityScale = 3

                    local square2 = display.newRect(foreground, _g.screenRight + 3, earth.y - 200, 6, 6)
                    table.insert(objectsTable, square2)
                    square2:setFillColor(1)
                    physics.addBody( square2, { density=15, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    square2:setLinearVelocity(-velocityX, -200)
                    square2.gravityScale = 3

                    velocityX = velocityX + 4

                    if i == squareCount then
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(200, function() 
                            levelIsSetup = true
                            canRemoveObjects = true
                        end)
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 1500, func, squareCount-1 )
            end
        },
        {
            level = 18,
            difficulty = 3,
            maxScore = 300,
            desc = "Tunnel rectangle and balls",
            background = {203,103,200},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rectangleCount = 16
                local wallWidth = 30 -- double this
                local leftWallShape = { -wallWidth,-400, wallWidth,-400, wallWidth,300, -wallWidth,400 }
                local rightWallShape = { -wallWidth,-400, wallWidth,-400, wallWidth,400, -wallWidth,300 }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local rect = display.newRect(foreground, _g.centerX, _g.screenTop - 104, 120, 4)
                rect:setFillColor(1)
                physics.addBody( rect, { density=70, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                rect.isBullet = true
                rect.gravityScale = 0
                rect.angularDamping = 2
                rect:setLinearVelocity(0, velocityY)

                table.insert(objectsTable, rect)

                local ballRadius = 5
                local columns = 1
                local maxColumns = 4
                local inc = true
                local y = _g.screenTop - 200
                for i = 1, 19 do
                    local x = _g.centerX - (columns-1)*0.5*30
                    for n = 1, columns do
                        local ball = display.newCircle(foreground, x, y, ballRadius)
                        ball:setFillColor(1)
                        physics.addBody( ball, { radius=ballRadius, density=5, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        ball:setLinearVelocity(0, velocityY)
                        ball.gravityScale = 0
                        table.insert(objectsTable, ball)
                        x = x + 30
                    end

                    if inc then
                        columns = columns + 1
                        if columns == maxColumns then inc = false end
                    else
                        columns = columns - 1
                        if columns == 1 then inc = true end
                    end

                    y = y - 30
                end

                local tmr
                local func = function()
                    if canRemoveObjects then print("canRemoveObjects") end
                    if wallLeft.y - wallLeft.contentHeight*0.5 > _g.screenBottom then
                        canRemoveObjects = true
                        levelIsSetup = true
                        timer.cancel(tmr)
                    end     
                end

                tmr = timer.performWithDelay( 500, func, -1 )
                lvlTmrs[#lvlTmrs + 1] = tmr
            end
        },
        {
            level = 19,
            difficulty = 2,
            maxScore = 275,
            desc = "Balls rolling off rectangles",
            background = {97,105,240},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local ballRadius = 8
                local rectCount = 5
                local ballCount = 4

                local i = 1
                local createRect = function()

                    local y = _g.screenTop - 80
                    local x, r, ballX
                    if i%2 == 0 then
                        x = _g.screenRight
                        r = -25
                        ballX = _g.screenRight + ballRadius
                    else
                        x = _g.screenLeft
                        r = 25
                        ballX = _g.screenLeft - ballRadius
                    end
                    local rect = display.newRect(foreground, x, y, 160, 10)
                    table.insert(objectsTable, rect)
                    rect:setFillColor(0)
                    rect.rotation = r
                    physics.addBody( rect, "kinematic", { bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect.gravityScale = 0
                    rect:setLinearVelocity(0, velocityY)

                    local n = 1
                    local p = i
                    local createBall = function()
                        local ball = display.newCircle(foreground, ballX, rect.y-ballRadius*2, ballRadius)
                        ball:setFillColor(1)
                        physics.addBody( ball, { radius=ballRadius, density=15, bounce=0.4, filter = { categoryBits = 8, maskBits = 13 } } )
                        ball:setLinearVelocity(0, velocityY)
                        ball.gravityScale = 1.5
                        table.insert(objectsTable, ball)
                        
                        if p == rectCount and n == ballCount then
                            lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1000, function() 
                                canRemoveObjects = true
                                levelIsSetup = true
                            end)
                        end

                        n = n + 1
                    end

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 850, createBall, ballCount )
                    i = i + 1
                end

                createRect()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 2200, createRect, rectCount-1 )
            end
        },
        {
            level = 20,
            difficulty = 4,
            maxScore = 200,
            desc = "Big rectangles split",
            background = {222,69,86},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local w = _g.screenWidth
                local rect1 = display.newRect(foreground, _g.screenLeft-15, _g.screenTop - w, w, w*2)
                rect1:setFillColor(1)
                physics.addBody( rect1, { density=45, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                rect1:setLinearVelocity(0, velocityY)
                rect1.gravityScale = 0
                rect1.collisionGravityScale = 0.2

                local rect2 = display.newRect(foreground, _g.screenRight+15, _g.screenTop - w, w, w*2)
                rect2:setFillColor(1)
                physics.addBody( rect2, { density=45, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                rect2:setLinearVelocity(0, velocityY)
                rect2.gravityScale = 0
                rect2.collisionGravityScale = 0.2

                table.insert(objectsTable, rect1)
                table.insert(objectsTable, rect2)

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 21,
            difficulty = 4,
            maxScore = 200,
            desc = "Falling rectangles",
            background = {151,22,12},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 1.5
                local gravityDelay = 1
                local rectWidth = 70
                local leftX = _g.centerX - 140
                local RightX = _g.centerX + 140
                local y = _g.screenTop - 1.5

                for i = 1, 50 do
                    local rect1 = display.newRect(foreground, leftX, y, rectWidth, 3)
                    table.insert(objectsTable, rect1)
                    rect1:setFillColor(1)
                    physics.addBody( rect1, { density=25, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect1.gravityScale = 0
                    rect1:setLinearVelocity(0, velocityY)

                    local rect2 = display.newRect(foreground, RightX, y, rectWidth, 3)
                    table.insert(objectsTable, rect2)
                    rect2:setFillColor(1)
                    physics.addBody( rect2, { density=25, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect2.gravityScale = 0
                    rect2:setLinearVelocity(0, velocityY)

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( gravityDelay, function()
                        rect1.gravityScale = 0.7
                        rect2.gravityScale = 0.7
                    end, 0 )

                    gravityDelay = gravityDelay + 50
                    if i >= 20 and i <= 36 then
                        leftX = leftX + 6
                        RightX = RightX - 6
                    end
                    y = y - 8

                    if i == 50 then
                        canRemoveObjects = true
                        levelIsSetup = true
                    end
                end
            end
        },
        {
            level = 22,
            difficulty = 3,
            maxScore = 325,
            desc = "Sun shooting rays",
            background = {134,213,248},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps

                local sun = display.newCircle(foreground, _g.centerX, _g.screenTop - 500, 500 )
                table.insert(objectsTable, sun)
                sun:setFillColor(unpack({249/255,215/255,28/255}))
                physics.addBody( sun, "kinematic", { radius=500, density=1, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                sun.gravityScale = 0

                local shootRays = function()
                    local x = _g.centerX
                    local y = _g.screenTop + 80
                    local coordsOutside = {{x-120,y-13},{x-105,y-10},{x-90,y-7},{x-75,y-4},{x-60,y-2},{x+60,y-2},{x+75,y-4},{x+90,y-7},{x+105,y-10},{x+120,y-13}}
                    local coordsInside = {{x-45,y-0.5},{x-30,y+1},{x-15,y+1.5},{x,y+2},{x+15,y+1.5},{x+30,y+1},{x+45,y-0.5}}
                    local coord = nil
                    local rayCount = 16
                    local i = 1
                    local insideLast = true

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(600, function() 
                        -- local tmp = coord
                        -- while tmp == coord do
                        if insideLast then
                            tmp = coordsOutside[rand(1,#coordsOutside)]
                            insideLast = false
                        else
                            tmp = coordsInside[rand(1,#coordsInside)]
                            insideLast = true
                        end
                        -- end
                        coord = tmp

                        local triangleShape = { 0,8.66025, 10,-8.66025, -10,-8.66025 }
                        local ray = display.newPolygon(foreground, coord[1], coord[2], triangleShape)
                        -- local ray = display.newRect(foreground, coord[1], coord[2], 3, 40)
                        table.insert(objectsTable, ray)
                        ray:setFillColor(unpack({249/255,215/255,28/255}))
                        physics.addBody( ray, "kinematic", { shape=triangleShape, density=20, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        ray.gravityScale = 0
                        -- ray:setLinearVelocity(0, velocityY)
                        transition.to(ray, {y = coord[2]+40, time = 200})
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(600, function()
                            -- physics.removeBody(ray)
                            -- physics.addBody( ray, { density=20, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                            ray.bodyType = "dynamic"
                            ray:setLinearVelocity(0, velocityY*3)
                        end)


                        if i == rayCount then
                            lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1500, function()
                                sun.bodyType = "dynamic"
                                sun.gravityScale = 1
                                levelIsSetup = true
                            end)
                        end

                        i = i + 1

                    end, rayCount)

                    canRemoveObjects = true
                end

                transition.to(sun, {y = _g.screenTop-400, time = 2500, transition = easing.inOutQuad, onComplete = shootRays})
            end
        },
        {
            level = 23,
            difficulty = 4,
            maxScore = 275,
            desc = "Falling squares",
            background = {127,118,188},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 0.2
                local count = 9
                local mid = math.ceil(count*0.5)
                local squareSize = 10
                local gap = 10
                local x
                local y = _g.screenTop - squareSize
                local startDelay = 500

                for i = 1, 9 do
                    x = _g.centerX - (math.floor(count*0.5)*(squareSize+gap))
                    for n = 1, count do
                        local square = display.newRect(foreground, x, y, squareSize, squareSize)
                        table.insert(objectsTable, square)
                        square:setFillColor(1)
                        physics.addBody( square, "kinematic", { density=40, bounce=0.3, filter = { categoryBits = 8, maskBits = 13 } } )
                        square:setLinearVelocity(0, velocityY)
                        square.gravityScale = 0
                        square.collisionGravityScale = 0
                        x = x + squareSize + gap

                        local delay = startDelay + math.abs(n - mid)*2500 + i*50

                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(delay, function() 
                            square.gravityScale = 0.7
                            square.collisionGravityScale = 0.7
                            square.bodyType = "dynamic"
                        end)
                    end
                    y = y - squareSize - gap
                end

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 24,
            difficulty = 2,
            maxScore = 275,
            desc = "Falling shapes with blocker",
            background = {248,232,73},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local itemsCount = 32
                local colors = {{166/255,126/255,255/255},{58/255,124/255,253/255},{0/255,176/255,136/255},{255/255,133/255,34/255},{250/255,73/255,110/255}}
                local x = _g.centerX
                local y = _g.screenTop - 100
                local wallShape = { -100,-30, -90,-30, -90,20, 90,20, 90,-30, 100,-30, 100,30, -100,30 }
                local triangleShape = { 0,-5, 5.7735,5, -5.7735,5 }

                local wall = display.newPolygon(foreground, _g.centerX, _g.screenTop-25, wallShape)
                wall:setFillColor(1)

                local leftShape = { -100,-30, -90,-30, -90,20, -100,20 }
                local rightShape = { 100,-30, 90,-30, 90,20, 100,20 }
                local middleShape = { -100,20, 100,20, 100,30, -100,30 } 
                physics.addBody( wall, "dynamic",
                    { density=60, bounce=0, shape=leftShape, filter = { categoryBits = 8, maskBits = 13 } },
                    { density=60, bounce=0, shape=rightShape, filter = { categoryBits = 8, maskBits = 13 } },
                    { density=60, bounce=0, shape=middleShape, filter = { categoryBits = 8, maskBits = 13 } }
                )
                wall.isBullet = true
                wall.angularDamping = 1
                wall:setLinearVelocity(0, velocityY)
                wall.gravityScale = 0
                wall.collisionGravityScale = 1
                table.insert(objectsTable, wall)

                local i = 1
                local func = function()
                    local item
                    x = rand(_g.screenLeft + 90, _g.screenRight - 90)
                    local n = rand(1,3)
                    if n == 1 then -- circle
                        item = display.newCircle(foreground, x, y, 5 )
                        physics.addBody( item, { radius=5, density=5, bounce=0.2, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    elseif n == 2 then -- square
                        item = display.newRect(foreground, x, y, 10, 10)
                        physics.addBody( item, { density=5, bounce=0.2, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    else -- triangle
                        item = display.newPolygon(foreground, x, y, triangleShape)
                        physics.addBody( item, { shape=triangleShape, density=5, bounce=0.2, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    end

                    item:setFillColor(unpack(colors[rand(1,5)]))
                    item:setLinearVelocity(0, velocityY)
                    item.gravityScale = 0
                    table.insert(objectsTable, item)

                    if i > 4 and i < 24 then
                        velocityY = velocityY + 25
                    end

                    if i == itemsCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1000, func, 4)
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(4000, function() 
                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(350, func, itemsCount-4)
                end)

                canRemoveObjects = true
            end
        },
        {
            level = 25,
            difficulty = 4,
            maxScore = 260,
            desc = "Falling shapes with crosses",
            background = {144,232,179},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 1.5
                local crossCount = 2
                local crossShape = { -8,-200, 8,-200, 8,-8, 250,-8, 250,8, 8,8, 8,200, -8,200, -8,8, -250,8, -250,-8, -8,-8 }
                local leftShape = { -250,-8, -8,-8, -8,8, -250,8 }
                local rightShape = { 8,-8, 250,-8, 250,8, 8,8 }
                local topShape = { -8,-8, -8,-200, 8,-200, 8,-8 }
                local bottomShape = { -8,8, 8,8, 8,200, -8,200 }
                local itemsCount = 20
                local colors = {{166/255,126/255,255/255},{58/255,124/255,253/255},{0/255,176/255,136/255},{255/255,133/255,34/255},{250/255,73/255,110/255}}
                local triangleShape = { 0,-5, 5.7735,5, -5.7735,5 }

                local i = 1
                local createItem = function()
                    local item
                    local x = rand(_g.screenLeft + 90, _g.screenRight - 90)
                    local n = rand(1,3)
                    if n == 1 then -- circle
                        item = display.newCircle(foreground, x, _g.screenTop - 250, 5 )
                        physics.addBody( item, { radius=5, density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    elseif n == 2 then -- square
                        item = display.newRect(foreground, x, _g.screenTop - 250, 10, 10)
                        physics.addBody( item, { density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    else -- triangle
                        item = display.newPolygon(foreground, x, _g.screenTop - 250, triangleShape)
                        physics.addBody( item, { shape=triangleShape, density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    end

                    item:setFillColor(unpack(colors[rand(1,5)]))
                    item:setLinearVelocity(0, velocityY)
                    item.gravityScale = 1
                    table.insert(objectsTable, item)

                    if i == itemsCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                local n = 1
                local createCross = function()
                    local x = _g.centerX - 130
                    if n == 2 then x = _g.centerX + 130 end

                    local cross = display.newPolygon(foreground, x, _g.screenTop - 200, crossShape)
                    cross:setFillColor(1)

                    physics.addBody( cross, "dynamic",
                        { density=50, bounce=0, shape=leftShape, filter = { categoryBits = 8, maskBits = 13 } },
                        { density=50, bounce=0, shape=rightShape, filter = { categoryBits = 8, maskBits = 13 } },
                        { density=50, bounce=0, shape=topShape, filter = { categoryBits = 8, maskBits = 13 } },
                        { density=50, bounce=0, shape=bottomShape, filter = { categoryBits = 8, maskBits = 13 } }
                    )
                    cross.angularDamping = 0.5
                    cross.gravityScale = 0
                    cross.collisionGravityScale = 0

                    local shadow = display.newCircle(foreground, x, _g.screenTop - 200, 4)
                    shadow:setFillColor(0)
                    physics.addBody( shadow, "kinematic", { density=1, bounce=0, filter = { categoryBits = 8, maskBits = 5 } } )
                    shadow.gravityScale = 0
                    shadow.collisionGravityScale = 0

                    local pivotJoint = physics.newJoint( "pivot", shadow, cross, shadow.x, shadow.y )
                    shadow:setLinearVelocity(0, velocityY)

                    table.insert(objectsTable, shadow)
                    table.insert(objectsTable, cross)

                    i = 1
                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(125, createItem, itemsCount)

                    if n == crossCount and i == itemsCount then
                        levelIsSetup = true
                    end

                    n = n + 1   
                end

                createCross()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, createCross, crossCount-1)

                canRemoveObjects = true
            end
        },
        {
            level = 26,
            difficulty = 4,
            maxScore = 300,
            desc = "Bunch of balls between walls",
            background = {237,110,184},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local wallHeight = 400 -- it will be double this
                local wallWidth = 10 -- it will be double this
                local leftWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,(wallHeight-100), -wallWidth,wallHeight }
                local rightWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,wallHeight, -wallWidth,(wallHeight-100) }
                local x
                local y = _g.screenTop - 180
                local ballsTable = {}

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0.1, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0
                wallLeft.isBullet = true

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0.1, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0
                wallRight.isBullet = true

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                for i = 1, 12 do
                    x = _g.screenLeft + 25 + rand(15, 25)

                    while x + 25 < _g.screenRight do
                        local ball = display.newCircle(foreground, x + rand(-8,8), y + rand(-8,8), 5 )
                        ball:setFillColor(1)
                        physics.addBody( ball, { density=10, bounce=0.1, friction=0, filter = { categoryBits = 8, maskBits = 29 } } )
                        ball.gravityScale = 0
                        ball.collisionGravityScale = 0.5
                        ball:setLinearVelocity(0, velocityY)
                        table.insert(objectsTable, ball)

                        x = x + 45
                    end

                    y = y - 45
                end


                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(10000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 27,
            difficulty = 1,
            maxScore = 250,
            desc = "Birds from sides",
            background = {87,164,234},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local velocityX = 70
                local x, y = _g.screenLeft-30, earth.y - 380
                local birdCount = 10

                local function onCollision( self, event )
                    if ( event.phase == "began" ) then
                        self:removeEventListener("collision", onCollision)
                        if self.tmr then
                            timer.cancel(self.tmr)
                            self.tmr = nil
                        end
                    end
                end

                local i = 1
                local func = function()
                    local rect1 = display.newRect(foreground, x-16, y, 30, 4)
                    rect1:setFillColor(1)
                    physics.addBody( rect1, { density=20, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect1.gravityScale = 3
                    rect1:setLinearVelocity(velocityX, -100)
                    local rect2 = display.newRect(foreground, x+16, y, 30, 4)
                    rect2:setFillColor(1)
                    physics.addBody( rect2, { density=20, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect2.gravityScale = 3
                    rect2:setLinearVelocity(velocityX, -100)

                    rect1:applyAngularImpulse(18)
                    rect2:applyAngularImpulse(-18)
                    local rot1 = false
                    local rot2 = false

                    rect1.tmr = timer.performWithDelay(350, function() 
                        if rot1 then
                            rect1:applyAngularImpulse(36)
                            rot1 = false
                        else
                            rect1:applyAngularImpulse(-36)
                            rot1 = true
                        end 
                    end, -1)
                    lvlTmrs[#lvlTmrs + 1] = rect1.tmr
                    rect2.tmr = timer.performWithDelay(350, function() 
                        if rot2 then
                            rect2:applyAngularImpulse(-36)
                            rot2 = false
                        else
                            rect2:applyAngularImpulse(36)
                            rot2 = true
                        end 
                    end, -1)
                    lvlTmrs[#lvlTmrs + 1] = rect2.tmr

                    rect1.collision = onCollision
                    rect1:addEventListener( "collision" )
                    rect2.collision = onCollision
                    rect2:addEventListener( "collision" )

                    table.insert(objectsTable, rect1)
                    table.insert(objectsTable, rect2)

                    if rand(1,2) == 1 then
                        velocityX = -velocityX
                    end
                    if velocityX > 0 then 
                        velocityX = velocityX + 5
                        x = _g.screenLeft-30
                    else
                        velocityX = velocityX - 5
                        x = _g.screenRight+30
                    end

                    -- if x < _g.screenLeft then
                    --  x = _g.screenRight+30
                    -- else
                    --  x = _g.screenLeft-30
                    -- end

                    if i == birdCount then
                        levelIsSetup = true
                        canRemoveObjects = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1200, func, birdCount-1)
            end
        },
        {
            level = 28,
            difficulty = 2,
            maxScore = 250,
            desc = "UFOs rotating",
            background = {35,61,99},
            textColor = 1,
            create = function()
                local ufoCount = 8

                local function onCollision( self, event )
                    if ( event.phase == "began" ) then
                        self:removeEventListener("collision", onCollision)
                        self.isFixedRotation = false
                        if self.joint.removeSelf ~= nil then
                            self.joint:removeSelf()
                        end
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(100, function()
                            if self.shadow ~= nil and self.shadow.removeSelf ~= nil then
                                self.shadow:setLinearVelocity(0, 1000)
                                self.shadow = nil
                            end
                        end)
                    end
                end

                local i = 1
                local func = function()
                    local offset = rand(-50, 50)
                    local shadow = display.newRect(foreground, _g.centerX + offset, _g.screenTop, 0, 0)
                    table.insert(objectsTable, shadow)
                    physics.addBody( shadow, "kinematic", { density=1, bounce=0, friction=0, filter = { categoryBits = 8, maskBits = 0 } } )

                    local ufo = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("ufo")}} )
                    table.insert(objectsTable, ufo)
                    ufo.x = _g.centerX + offset
                    ufo.y = _g.screenTop - rand(50, 100)
                    local physicsData = objectsPhysics.physicsData()
                    physics.addBody( ufo, physicsData:get("ufo") )
                    ufo.isFixedRotation = true
                    ufo.gravityScale = 0
                    ufo.collisionGravityScale = 2
                    ufo.shadow = shadow

                    local pivot = physics.newJoint("distance", shadow, ufo, shadow.x, shadow.y, ufo.x, ufo.y)

                    shadow:setLinearVelocity(0, rand(100,200))
                    ufo:setLinearVelocity(rand(250,400), 0)

                    ufo.joint = pivot
                    ufo.collision = onCollision
                    ufo:addEventListener( "collision" )

                    if i == ufoCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1700, func, ufoCount-1)
                canRemoveObjects = true
            end
        },
        {
            level = 29,
            difficulty = 2,
            maxScore = 250,
            desc = "Triangle blocker",
            background = {228,135,48},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local ballCount = 5

                local triangleShape = { 0,-50, 100,50, 40,50, 40,0, -40,0, -40,50, -100,50 }
                blocker = display.newPolygon(foreground, _g.centerX, _g.screenTop-50, triangleShape)

                local leftShape = { -100,50, -40,0, -40,50 }
                local middleShape = { 0,-50, 50,0, -50,0 }
                local rightShape = { 100,50, 40,0, 40,50 }
                physics.addBody( blocker, "dynamic",
                    { density=30, bounce=0, shape=leftShape, filter = { categoryBits = 8, maskBits = 13 } },
                    { density=30, bounce=0, shape=middleShape, filter = { categoryBits = 8, maskBits = 13 } },
                    { density=30, bounce=0, shape=rightShape, filter = { categoryBits = 8, maskBits = 13 } }
                )
                blocker.angularDamping = 0.5
                blocker.gravityScale = 0
                blocker:setLinearVelocity(0, velocityY)
                table.insert(objectsTable, blocker)

                local y = earth.y - 450
                local i = 1
                local func = function()
                    local ball1 = display.newCircle(foreground, _g.screenLeft-4, y, 4 )
                    local ball2 = display.newCircle(foreground, _g.screenRight+4, y, 4 )
                    ball1:setFillColor(1)
                    ball2:setFillColor(1)
                    physics.addBody( ball1, { radius=4, density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    physics.addBody( ball2, { radius=4, density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    ball1.gravityScale = 0
                    ball2.gravityScale = 0
                    ball1:setLinearVelocity(60, 200)
                    ball2:setLinearVelocity(-60, 200)
                    ball1.isBullet = true
                    ball2.isBullet = true

                    table.insert(objectsTable, ball1)
                    table.insert(objectsTable, ball2)

                    if i == ballCount then
                        local y = _g.screenTop - 70

                        for n = 8, 2, -2 do
                            local r = (_g.screenRight - _g.screenLeft)/n * 0.5
                            local x = _g.screenLeft+r
                            for p = 1, n do
                                local circle = display.newCircle(foreground, x, y, r )
                                physics.addBody( circle, { radius=r, density=5, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                                circle.gravityScale = 0.1
                                circle:setLinearVelocity(0, velocityY)

                                table.insert(objectsTable, circle)

                                if n == 4 and p == n then
                                    levelIsSetup = true
                                end

                                x = x + r*2
                            end

                            y = y - r*4
                        end
                    end

                    i = i + 1
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(3000, function()
                    func()
                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(500, func, ballCount-1)
                end)

                canRemoveObjects = true
            end
        },
        {
            level = 30,
            difficulty = 3,
            maxScore = 250,
            desc = "Gates open, dropping balls",
            background = {174,20,124},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local w = _g.screenWidth*0.5+10

                local gate1 = display.newRect(foreground, _g.screenLeft-10, _g.screenTop-50, w, 20)
                local gate2 = display.newRect(foreground, _g.screenRight+10, _g.screenTop-50, w, 20)
                table.insert(objectsTable, gate1)
                table.insert(objectsTable, gate2)
                gate1:setFillColor(0)
                gate2:setFillColor(0)
                gate1.anchorX = 0
                gate2.anchorX = 1
                physics.addBody( gate1, "kinematic", { density=20, bounce=0, filter = { categoryBits = 8, maskBits = 12 } } )
                physics.addBody( gate2, "kinematic", { density=20, bounce=0, filter = { categoryBits = 8, maskBits = 12 } } )
                gate1.gravityScale = 0
                gate2.gravityScale = 0
                gate1.collisionGravityScale = 1
                gate2.collisionGravityScale = 1
                gate1.rotation = 10
                gate2.rotation = -10
                gate1:setLinearVelocity(0, velocityY*0.5)
                gate2:setLinearVelocity(0, velocityY*0.5)

                -- local delay = ((earth.y-350)-gate1.y) / (velocityY*0.5) * 1000
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(3000, function() 
                    gate1:setLinearVelocity(-200, velocityY*0.25)
                    gate2:setLinearVelocity(200, velocityY*0.25)

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2000, function()
                        canRemoveObjects = true
                        levelIsSetup = true
                    end)
                end)

                for i = 1, rand(35,45) do
                    local ball = display.newCircle(foreground, rand(_g.screenLeft+10,_g.screenRight-10), rand(_g.screenTop-200,_g.screenTop-90), 5 )
                    table.insert(objectsTable, ball)
                    ball:setFillColor(1)
                    physics.addBody( ball, { radius=5, density=30, bounce=0.6, friction=0, filter = { categoryBits = 8, maskBits = 29 } } )
                    ball.gravityScale = 0.9
                    ball.collisionGravityScale = 0.9
                end
            end
        },
        {
            level = 31,
            difficulty = 2,
            maxScore = 320,
            desc = "Spinning ropes",
            background = {135,228,232},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local ropeCount = 8
                local xS = {_g.screenLeft, _g.screenLeft+(_g.centerX-_g.screenLeft)*0.5, _g.centerX, _g.screenRight-(_g.centerX-_g.screenLeft)*0.5, _g.screenRight}
                local xVs1 = {600, 300, 200, -300, -600}
                local xVs2 = {-200, -100, -200, 100, 200}
                local i = 1

                local func = function()
                    local ballCount = rand(5,15)
                    local ballRadius = rand(5,15)
                    local p = rand(1,#xS)
                    local x = xS[p]
                    local y = _g.screenTop - ballRadius
                    local lastBall
                    local balls = {}

                    -- local function onCollision( self, event )
                    --     if ( event.phase == "began" ) then
                    --         for i=1, #balls do
                    --             if balls[i].removeSelf ~= nil then
                    --                 balls[i]:removeEventListener("collision", onCollision)
                    --                 if balls[i].joint.removeSelf ~= nil then
                    --                     balls[i].joint:removeSelf()
                    --                 end
                    --             end
                    --         end
                    --     end
                    -- end

                    for n=1, ballCount do
                        local ball = display.newCircle(foreground, x, y, ballRadius )
                        table.insert(objectsTable, ball)
                        ball:setFillColor(1)
                        physics.addBody( ball, { radius=ballRadius, density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        ball.gravityScale = 1
                        ball.collisionGravityScale = 1

                        if n > 1 then
                            local ropeJoint = physics.newJoint( "rope", lastBall, ball )
                            ropeJoint.maxLength = ballRadius*2+2
                            ball.joint = ropeJoint

                            -- ball.collision = onCollision
                            -- ball:addEventListener( "collision" )
                            table.insert(balls, ball)

                            if n == ballCount then
                                ball:setLinearVelocity(xVs2[p], velocityY)  
                            else
                                ball:setLinearVelocity(0, velocityY)
                            end
                        else
                            ball:setLinearVelocity(xVs1[p], velocityY)
                        end

                        y = y - ballRadius*2-2
                        lastBall = ball
                    end

                    if i == ropeCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2250, func, ropeCount-1)
                canRemoveObjects = true
            end
        },
        {
            level = 32,
            difficulty = 3,
            maxScore = 225,
            desc = "Balls pushed from side by spinning black rectangles",
            background = {224,51,106},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local count = 3

                local rectLeft = display.newRect(foreground, _g.screenLeft, _g.screenTop-200, 150, 10 )
                local rectRight = display.newRect(foreground, _g.screenRight, _g.screenTop-10, 150, 10 )
                table.insert(objectsTable, rectLeft)
                table.insert(objectsTable, rectRight)
                rectLeft:setFillColor(0)
                rectRight:setFillColor(0)
                physics.addBody( rectLeft, "kinematic", { density=10, bounce=0, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                physics.addBody( rectRight, "kinematic", { density=10, bounce=0, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                rectLeft.gravityScale = 0
                rectRight.gravityScale = 0

                rectLeft.collisionGravityScale = 0
                rectRight.collisionGravityScale = 0
                rectRight.angularVelocity = -100
                rectRight:setLinearVelocity(2, velocityY)

                local i = 1
                local isRight = true
                local func
                func = function()
                    local x, y
                    if isRight then
                        x = rectRight.x + 15
                        y = rectRight.y - 5
                    else
                        x = rectLeft.x - 15
                        y = rectLeft.y - 5
                    end
                    for n = 1, 5 do
                        local ball = display.newCircle(foreground, x, y, 5 )
                        table.insert(objectsTable, ball)
                        ball:setFillColor(1)
                        physics.addBody( ball, { radius=5, density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        ball.gravityScale = 1
                        ball.collisionGravityScale = 1
                        if isRight then
                            ball:setLinearVelocity(-5, velocityY*1.5)
                        else
                            ball:setLinearVelocity(5, velocityY*1.5)
                        end

                        y = y - 15
                    end

                    if i == count then
                        if isRight then
                            rectLeft.angularVelocity = 100
                            rectLeft:setLinearVelocity(-2, velocityY)
                            i = 1
                            isRight = false

                            lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(1800, function()
                                func()
                                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(rand(1800,2000), func, count-1)
                            end)
                        else
                            lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2000, function()
                                canRemoveObjects = true
                                levelIsSetup = true
                            end)
                        end

                        return
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(rand(1800,2000), func, count-1)
            end
        },
        {
            level = 33,
            difficulty = 3,
            maxScore = 250,
            desc = "Diamonds, then tunnel with big circle blocker",
            background = {18,88,130},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local diagonal = 40*math.sqrt(2)+0.5
                local x
                local y = _g.screenTop-diagonal

                for i = 1, 3 do
                    x = _g.centerX - 1.5*diagonal
                    for n = 1, 4 do
                        local square = display.newRect(foreground, x, y, 40, 40 )
                        table.insert(objectsTable, square)
                        square.rotation = 45
                        square:setFillColor(1)
                        physics.addBody( square, { density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        square.gravityScale = 0
                        square:setLinearVelocity(0, velocityY)

                        x = x + diagonal
                    end
                    y = y - diagonal
                end

                local wallWidth = (_g.screenWidth-110) * 0.25 -- double this
                local leftWallShape = { -wallWidth,-200, wallWidth,100, -wallWidth,200 }
                local rightWallShape = { wallWidth,-200, -wallWidth,100, wallWidth,200 }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - 500
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.isBullet = true
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - 500
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.isBullet = true
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local circ = display.newCircle(foreground, _g.centerX, wallLeft.y + 35, 70 )
                table.insert(objectsTable, circ)
                circ:setFillColor(1)
                physics.addBody( circ, { radius=70, density=5, bounce=0, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                circ.gravityScale = 1
                circ:setLinearVelocity(0, velocityY)

                local y = circ.y-circ.contentHeight*0.5-30
                local rect1 = display.newRect(foreground, _g.centerX-51, y, 100, 6 )
                local rect2 = display.newRect(foreground, _g.centerX+51, y, 100, 6 )
                table.insert(objectsTable, rect1)
                table.insert(objectsTable, rect2)
                rect1:setFillColor(1)
                rect2:setFillColor(1)
                physics.addBody( rect1, { density=20, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                physics.addBody( rect2, { density=20, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                rect1.gravityScale = 0
                rect2.gravityScale = 0
                rect1:setLinearVelocity(0, velocityY)
                rect2:setLinearVelocity(0, velocityY)

                local w = 10
                local x1, x2
                y = y - 9
                for i = 5, 1, -1 do
                    x1 = rect1.x - ((i-1)*0.5)*(w+1)
                    x2 = rect2.x - ((i-1)*0.5)*(w+1)
                    for n = 1, i do
                        local square1 = display.newRect(foreground, x1, y, w, w )
                        local square2 = display.newRect(foreground, x2, y, w, w )
                        table.insert(objectsTable, square1)
                        table.insert(objectsTable, square2)
                        square1:setFillColor(1)
                        square2:setFillColor(1)
                        physics.addBody( square1, { density=20, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        physics.addBody( square2, { density=20, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        square1.gravityScale = 0
                        square2.gravityScale = 0
                        square1:setLinearVelocity(0, velocityY)
                        square2:setLinearVelocity(0, velocityY)
                        x1 = x1 + w + 1
                        x2 = x2 + w + 1
                    end

                    y = y - w - 1
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 34,
            difficulty = 2,
            maxScore = 300,
            desc = "Kites",
            background = {143,201,255},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 0.9
                local kiteCount = 5
                local rectCount = 10
                local kiteShape = { 0,-40, 22,8, 0,40, -22,8 }
                local colors = {{230/255,96/255,0/255},{253/255,106/255,0/255},{255/255,115/255,0/255},{255/255,125/255,0/255},
                                {255/255,134/255,0/255},{255/255,144/255,0/255},{255/255,154/255,0/255},{255/255,163/255,0/255},
                                {255/255,173/255,0/255},{255/255,182/255,0/255},{255/255,192/255,0/255}}

                local i = 1
                local func = function()
                    local p = 1
                    if i%2 == 0 then p = -1 end

                    local kite = display.newPolygon(foreground, _g.centerX-(rand(20,120)*p), _g.screenTop-40, kiteShape)
                    table.insert(objectsTable, kite)
                    kite:setFillColor(unpack(colors[1]))
                    physics.addBody( kite, { shape=kiteShape, density=10, bounce=0.1, friction = 0, filter = { categoryBits = 8, maskBits = 13 } } )
                    kite.gravityScale = 0
                    kite:setLinearVelocity(0, velocityY*2)

                    local x = kite.x
                    local y = kite.y - kite.contentHeight*0.5 - 6
                    local w = 10
                    local rects = {kite}
                    local tmr

                    local function onCollision( self, event )
                        if ( event.phase == "began" and event.other.myName == "ozone" ) then
                            for i=1, #rects do
                                if rects[i].removeSelf ~= nil then
                                    rects[i]:removeEventListener("collision", onCollision)
                                    rects[i].isFixedRotation = false
                                    rects[i].collisionGravityScale = 1
                                    if rects[i].joint and rects[i].joint.removeSelf ~= nil then
                                        rects[i].joint:removeSelf()
                                    end
                                end
                                if rects[i].tmr then
                                    timer.cancel(rects[i].tmr)
                                end
                                timer.cancel(tmr)
                            end
                        end
                    end

                    kite.collision = onCollision
                    kite:addEventListener( "collision" )

                    for n=1, rectCount do
                        local rect = display.newRect(foreground, x, y, w, w )
                        table.insert(objectsTable, rect)
                        table.insert(rects, rect)
                        rect:setFillColor(unpack(colors[n+1]))
                        physics.addBody( rect, { density=30, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        rect.isFixedRotation = true
                        rect.gravityScale = 0
                        rect.collisionGravityScale = 1

                        if n > 1 then
                            local joint = physics.newJoint( "distance", lastBall, rect, lastBall.x, lastBall.y, rect.x, rect.y )
                            joint.length = w
                            rect.joint = joint

                            rect.collision = onCollision
                            rect:addEventListener( "collision" )
                        else
                            local joint = physics.newJoint( "distance", kite, rect, kite.x, kite.y-kite.contentHeight*0.5, rect.x, rect.y+w*0.5 )
                            joint.length = 0
                            rect.joint = joint
                        end
                        rect:setLinearVelocity(0, velocityY*2)

                        y = y - w
                        lastBall = rect
                    end

                    local vX = 40
                    local pushedRight = true
                    tmr = timer.performWithDelay(500, function() 
                        local delay = 0
                        for i = 1, #rects do
                            rects[i]:setLinearVelocity(0, velocityY*3)
                            rects[i].tmr = timer.performWithDelay(delay, function() 
                                rects[i]:setLinearVelocity(50*p, velocityY*3)
                            end)
                            lvlTmrs[#lvlTmrs + 1] = rects[i].tmr
                            delay = delay + 100
                        end
                    end)
                    lvlTmrs[#lvlTmrs + 1] = tmr

                    if i == kiteCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2500, func, kiteCount-1)
                canRemoveObjects = true
            end
        },
        {
            level = 35,
            difficulty = 1,
            maxScore = 180,
            desc = "Triangles hitting each other horizontally",
            background = {136,0,220},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local y = _g.screenTop - 20
                for i = 1, 20 do
                    local triangleShape = { 0,-8.66025, 10,8.66025, -10,8.66025 }
                    local triangle1 = display.newPolygon(foreground, _g.centerX-100, y-10.5, triangleShape)
                    table.insert(objectsTable, triangle1)
                    local triangle2 = display.newPolygon(foreground, _g.centerX+100, y, triangleShape)
                    table.insert(objectsTable, triangle2)
                    triangle1.rotation = 90
                    triangle2.rotation = -90
                    triangle1:setFillColor(1)
                    triangle2:setFillColor(1)
                    physics.addBody( triangle1, { density=20, bounce=0.1, shape=triangleShape, filter = { categoryBits = 8, maskBits = 13 } } )
                    physics.addBody( triangle2, { density=20, bounce=0.1, shape=triangleShape, filter = { categoryBits = 8, maskBits = 13 } } )
                    triangle1.gravityScale = 0
                    triangle1.collisionGravityScale = 1.6
                    triangle2.gravityScale = 0
                    triangle2.collisionGravityScale = 1.6
                    triangle1:setLinearVelocity(0, velocityY)
                    triangle2:setLinearVelocity(0, velocityY)

                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(2000, function() 
                        if triangle1.removeSelf ~= nil then
                            triangle1:setLinearVelocity(100, velocityY)
                        end
                        if triangle2.removeSelf ~= nil then
                            triangle2:setLinearVelocity(-100, velocityY)
                        end
                    end)

                    y = y - 21
                end

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 36,
            difficulty = 2,
            maxScore = 250,
            desc = "Ball in tunnel with diamonds surrounding",
            background = {6,48,90},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rectangleCount = 19
                local wallHeight = 340 -- it will be double this
                -- local wallWidth = 35 -- it will be double this
                local wallWidth = (_g.screenWidth-185) * 0.25 -- it will be double this
                local leftWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,(wallHeight-100), -wallWidth,wallHeight }
                local rightWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,wallHeight, -wallWidth,(wallHeight-100) }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local x1, x2 = wallLeft.x + 50, wallRight.x - 50
                local y = _g.screenTop - 120

                for i = 1, rectangleCount do
                    local rect1 = display.newRect(foreground, x1, y, 20, 20 )
                    local rect2 = display.newRect(foreground, x2, y, 20, 20 )
                    table.insert(objectsTable, rect1)
                    table.insert(objectsTable, rect2)
                    rect1:setFillColor(1)
                    rect2:setFillColor(1)
                    rect1.rotation = 45
                    rect2.rotation = 45
                    physics.addBody( rect1, { density=10, bounce=0.1, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    physics.addBody( rect2, { density=10, bounce=0.1, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect1.gravityScale = 0
                    rect2.gravityScale = 0
                    rect1.isBullet = true
                    rect2.isBullet = true
                    rect1.collisionGravityScale = 1
                    rect2.collisionGravityScale = 1
                    rect1:setLinearVelocity(0, velocityY)
                    rect2:setLinearVelocity(0, velocityY)

                    y = y - 30
                end

                local ball = display.newCircle(foreground, _g.centerX, _g.screenTop - 200, 50 )
                table.insert(objectsTable, ball)
                ball:setFillColor(1)
                physics.addBody( ball, { radius=50, density=5, bounce=0.1, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                ball.gravityScale = 0
                ball.collisionGravityScale = 1
                ball:setLinearVelocity(0, velocityY)

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(6000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 37,
            difficulty = 1,
            maxScore = 250,
            desc = "Leaves falling",
            background = {69,56,48},
            textColor = 1,
            create = function()
                local function onCollision( self, event )
                    if ( event.phase == "began" ) then
                        self:removeEventListener("collision", onCollision)
                        if self.joint.removeSelf ~= nil then
                            self.joint:removeSelf()
                        end
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(100, function()
                            if self.shadow ~= nil and self.shadow.removeSelf ~= nil then
                                self.shadow:setLinearVelocity(0, 1000)
                                self.shadow = nil
                            end
                        end)
                    end
                end

                local y = _g.screenTop - 20
                for i = 1, 10 do
                    local diff = rand(20,35)
                    local x = _g.screenLeft + diff
                    if i%2 == 0 then
                        x = _g.screenRight - diff
                    end

                    local leaf = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("leaf")}} )
                    leaf.x, leaf.y = x, y
                    table.insert(objectsTable, leaf)
                    leaf:setFillColor(1)
                    leaf.rotation = rand(0,360)
                    local physicsData = objectsPhysics.physicsData()
                    physics.addBody( leaf, physicsData:get("leaf") )
                    leaf.gravityScale = rand(8, 12)
                    leaf.collisionGravityScale = 2
                    leaf:setLinearVelocity(0, 0)

                    local shadow = display.newRect(foreground, _g.centerX, y, 0, 0 )
                    table.insert(objectsTable, shadow)
                    shadow:setFillColor(1)
                    physics.addBody( shadow, "kinematic", { density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 0 } } )
                    shadow.gravityScale = 0
                    shadow:setLinearVelocity(0, 100)

                    local pivotJoint = physics.newJoint( "pivot", shadow, leaf, shadow.x, shadow.y )
                    leaf.joint = pivotJoint
                    leaf.shadow = shadow

                    leaf.collision = onCollision
                    leaf:addEventListener( "collision" )

                    y = y - rand(100, 140)
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 38,
            difficulty = 1,
            maxScore = 225,
            desc = "Rectangles followed by stacked circles",
            background = {118,126,107},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local x, y = _g.centerX, _g.screenTop-10
                local rects = {{x,y,150},{x-75,y-30,125},{x+75,y-30,125},{x-120,y-60,100},{x+120,y-60,100}}
                y = y - 300
                local circles = {{x,y,59},{x,y-60,49},{x,y-110,39},{x,y-150,29},{x,y-180,19}}

                for i = 1, #rects do
                    local rect = display.newRect(foreground, rects[i][1], rects[i][2], rects[i][3], 20)
                    rect:setFillColor(1)
                    physics.addBody( rect, { density=30, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect:setLinearVelocity(0, velocityY)
                    rect.gravityScale = 0
                    table.insert(objectsTable, rect)
                end

                for i = 1, #circles do
                    local circ = display.newCircle(foreground, circles[i][1], circles[i][2], circles[i][3])
                    circ:setFillColor(1)
                    physics.addBody( circ, { radius=circles[i][3], density=10, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    circ:setLinearVelocity(0, velocityY)
                    circ.gravityScale = 0
                    table.insert(objectsTable, circ)
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 39,
            difficulty = 4,
            maxScore = 200,
            desc = "Big balls with small balls in diamond shape in between",
            background = {198,37,65},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local y

                for i = 1, 2 do
                    local r = _g.screenWidth*0.25
                    local x = _g.centerX
                    y = _g.screenTop - r
                    if i == 1 then x = x - r else x = x + r end
                    local ball = display.newCircle(foreground, x, y, r )
                    table.insert(objectsTable, ball)
                    ball:setFillColor(1)
                    physics.addBody( ball, { radius=r, density=5, bounce=0.2, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    ball.gravityScale = 0
                    ball:setLinearVelocity(0, velocityY*1.1)
                end

                local w = 10
                local r = 5
                y = y - _g.screenWidth*0.25 + 30
                for i = 1, 20 do
                    local p = i
                    if i > 10 then
                        p = 20 - i
                    end
                    local x = _g.centerX - ((p-1)*0.5)*(r*3)
                    for n = 1, p do
                        local ball = display.newCircle(foreground, x, y, r )
                        table.insert(objectsTable, ball)
                        ball:setFillColor(1)
                        physics.addBody( ball, { radius=r, density=5, bounce=0.2, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        ball.gravityScale = 0
                        ball:setLinearVelocity(0, velocityY*1.1)

                        x = x + r*3
                    end

                    y = y - r*3
                end

                y = y - 18
                for i = 1, 2 do
                    local r = _g.screenWidth*0.25
                    local x = _g.centerX
                    if i == 1 then x = x - r else x = x + r end
                    local ball = display.newCircle(foreground, x, y, r )
                    table.insert(objectsTable, ball)
                    ball:setFillColor(1)
                    physics.addBody( ball, { radius=r, density=5, bounce=0.2, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    ball.gravityScale = 0
                    ball:setLinearVelocity(0, velocityY*1.1)
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 40,
            difficulty = 3,
            maxScore = 275,
            desc = "Ship shooters from screen edges",
            background = {152,215,226},
            textColor = 0,
            create = function()
                local shipCount = 8
                local ship = display.newSprite(foreground, _g.objectsImageSheet , {frames={_g.objectsSheetInfo:getFrameIndex("ship")}} )
                table.insert(objectsTable, ship)
                ship.x = _g.centerX
                ship.y = _g.centerY
                local physicsData = objectsPhysics.physicsData()
                physics.addBody( ship, physicsData:get("ship") )
                ship.bodyType = "kinematic"
                ship.gravityScale = 0

                local shoot = function(x, y)
                    local bullet = display.newCircle(foreground, x, y, 5 )
                    bullet:setFillColor(1)
                    physics.addBody( bullet, { radius=5, density=2, bounce=1, filter = { categoryBits = 8, maskBits = 13 } } )
                    bullet.gravityScale = 0
                    bullet.collisionGravityScale = 0
                    ship:toFront()

                    local velocityX = earth.x - bullet.x + rand(-40,40)
                    local velocityY = earth.y - bullet.y
                    bullet:setLinearVelocity(velocityX, velocityY)

                    table.insert(objectsTable, bullet)
                end

                local i = 1
                local func
                func = function()
                    local dir = rand(1,3) -- 1:top, 2:left, 3:right
                    if i == 1 then dir = 1 end
                    local x,y
                    local move = 50

                    if dir == 1 then
                        x = rand(_g.screenLeft, _g.screenRight)
                        y = _g.screenTop - ship.contentHeight*0.5
                        move = 50 + (_g.safeScreenTop-_g.screenTop)
                    elseif dir == 2 then
                        x = _g.screenLeft - ship.contentWidth*0.5
                        y = rand(_g.screenTop-60, _g.screenTop+80)
                        move = 100
                    else
                        x = _g.screenRight + ship.contentWidth*0.5
                        y = rand(_g.screenTop-60, _g.screenTop+80)
                        move = 100
                    end

                    ship.x, ship.y = x, y
                    local a = getAngle(ship.x, ship.y, earth.x, earth.y) - 180
                    ship.rotation = a

                    local rad = (a+90) * math.pi/180
                    local xDiff, yDiff = move*math.cos(rad), move*math.sin(rad)

                    transition.to(ship, {x = ship.x + xDiff, y = ship.y + yDiff, time = 500, transition = easing.inOutQuad, onComplete = function()
                        if ship.removeSelf == nil or ship == nil then return end
                        
                        local bulletCount = rand(2,5)
                        local x, y = 0, ship.contentHeight*0.5
                        local a = getAngle(ship.x, ship.y, earth.x, earth.y) - 180
                        a = a * math.pi / 180
                        x, y = ship.x + (x*math.cos(a) - y*math.sin(a)), ship.y + (y*math.cos(a) + x*math.sin(a))
                        
                        local n = 1
                        shoot(x, y)
                        lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(350, function() 
                            n = n + 1
                            shoot(x, y)

                            if n == bulletCount then
                                transition.to(ship, {x = ship.x - xDiff, y = ship.y - yDiff, time = 500, transition = easing.inOutQuad, onComplete = function()
                                    if i == shipCount then
                                        canRemoveObjects = true
                                        levelIsSetup = true
                                        ship:setLinearVelocity(-(xDiff*50), -(yDiff*50))
                                        return
                                    end

                                    func()

                                    i = i + 1
                                end})
                            end
                        end, bulletCount-1)
                    end})
                end

                func()
            end
        },
        {
            level = 41,
            difficulty = 3,
            maxScore = 250,
            desc = "All shapes in four sections",
            background = {112,115,230},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local obstacleCount = 4

                local wallHeight = 400 -- it will be double this
                local wallWidth = 5 -- it will be double this
                local leftWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,(wallHeight-50), -wallWidth,wallHeight }
                local rightWallShape = { -wallWidth,-wallHeight, wallWidth,-wallHeight, wallWidth,wallHeight, -wallWidth,(wallHeight-50) }

                local wallLeft = display.newPolygon(foreground, _g.screenLeft + wallWidth, _g.centerY, leftWallShape)
                wallLeft.y = _g.screenTop - wallLeft.contentHeight/2
                wallLeft:setFillColor(0)
                physics.addBody( wallLeft, "kinematic", { bounce=0, shape=leftWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallLeft:setLinearVelocity(0, velocityY)
                wallLeft.gravityScale = 0
                wallLeft.collisionGravityScale = 0

                local wallRight = display.newPolygon(foreground, _g.screenRight - wallWidth, _g.centerY, rightWallShape)
                wallRight.y = _g.screenTop - wallRight.contentHeight/2
                wallRight:setFillColor(0)
                physics.addBody( wallRight, "kinematic", { bounce=0, shape=rightWallShape, filter = { categoryBits = 8, maskBits = 13 } } )
                wallRight:setLinearVelocity(0, velocityY)
                wallRight.gravityScale = 0
                wallRight.collisionGravityScale = 0

                table.insert(objectsTable, wallLeft)
                table.insert(objectsTable, wallRight)

                local y = _g.screenTop - 200
                local w = ((_g.screenWidth - earth.contentWidth) * 0.5) - 20
                for i = 1, obstacleCount do
                    local obstacleLeft = display.newRect(foreground, _g.screenLeft+(w*0.5), y, w, 10)
                    local obstacleRight = display.newRect(foreground, _g.screenRight-(w*0.5), y, w, 10)
                    obstacleLeft:setFillColor(0)
                    obstacleRight:setFillColor(0)
                    physics.addBody( obstacleLeft, "kinematic", { bounce=0, filter = { categoryBits = 16, maskBits = 9 } } )
                    physics.addBody( obstacleRight, "kinematic", { bounce=0, filter = { categoryBits = 16, maskBits = 9 } } )
                    obstacleLeft:setLinearVelocity(0, velocityY)
                    obstacleRight:setLinearVelocity(0, velocityY)
                    obstacleLeft.gravityScale = 0
                    obstacleRight.gravityScale = 0
                    obstacleLeft.collisionGravityScale = 0
                    obstacleRight.collisionGravityScale = 0

                    table.insert(objectsTable, obstacleLeft)
                    table.insert(objectsTable, obstacleRight)

                    y = y - 200
                end

                local bigShapeSize = 35
                local smallShapeSize = 15
                local bigTriangleShape = { 0,-15, 17.5,15, -17.5,15 }
                local smallTriangleShape = { 0,-6.5, 7.5,6.5, -7.5,6.5 }
                local triangleShape = bigTriangleShape
                local x
                x = _g.centerX - 3*(bigShapeSize + 2)
                y = _g.screenTop - 100

                for i = 1, 4 do
                    x = _g.centerX - 3*(bigShapeSize + 2)

                    for n = 1, 7 do
                        local w, triangleShape
                        if n%2 == 0 then 
                            w = smallShapeSize 
                            triangleShape = smallTriangleShape
                        else
                            w = bigShapeSize
                            triangleShape = bigTriangleShape
                        end
                        local shape
                        if i == 1 or i == 2 then
                            shape = display.newRect(foreground, x, y, w, w)
                            physics.addBody( shape, { density=5, bounce=0.1, filter = { categoryBits = 8, maskBits = 29 } } )
                        elseif i == 3 then
                            shape = display.newCircle(foreground, x, y, w*0.5)
                            physics.addBody( shape, { density=5, bounce=0.1, filter = { categoryBits = 8, maskBits = 29 } } )
                        else
                            shape = display.newPolygon(foreground, x, y, triangleShape)
                            physics.addBody( shape, { density=5, shape=triangleShape, bounce=0.1, filter = { categoryBits = 8, maskBits = 29 } } )
                        end
                        if i == 2 then shape.rotation = 45 end
                        if i == 4 and n%2==0 then shape.rotation = 180 end
                        shape:setFillColor(1)
                        shape:setLinearVelocity(0, velocityY)
                        shape.gravityScale = 0

                        table.insert(objectsTable, shape)

                        x = x + bigShapeSize + 2
                    end

                    y = y - 200
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(5000, function() 
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 42,
            difficulty = 2,
            maxScore = 180,
            desc = "Falling squares in succession",
            background = {247,133,34},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local x, y = _g.screenLeft + 4, _g.screenTop - 50
                local goRight = true
                local delay = 0
                while x > _g.screenLeft do
                    local shape = display.newRect(foreground, x, y, 8, 8)
                    physics.addBody( shape, { density=5, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                    shape:setFillColor(1)
                    shape:setLinearVelocity(0, velocityY*0.1)
                    shape.gravityScale = 0
                    table.insert(objectsTable, shape)

                    local d = delay
                    lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(d, function() 
                        shape.gravityScale = 1
                    end)
                    delay = delay + 50

                    if goRight then
                        x = x + 9
                    else
                        x = x - 9
                    end

                    if x > _g.screenRight then
                        goRight = false
                        x = x - 9
                        y = y - 9
                    end
                end

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 43,
            difficulty = 3,
            maxScore = 250,
            desc = "Squares moving side to side",
            background = {144,45,113},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 1.5
                local squareCount, w, x
                local spacing = 20
                local rowCount = 6
                local y = _g.screenTop
                local squares = {}

                local function onCollision( self, event )
                    if ( event.phase == "began" ) then
                        self:removeEventListener("collision", onCollision)
                        if self.tmr then
                            timer.cancel(self.tmr)
                            self.tmr = nil
                        end
                    end
                end

                for i = 1, rowCount do

                    squareCount = rand(3,6)
                    w = (_g.screenWidth - ((squareCount+1)*spacing))/squareCount
                    x = _g.screenLeft + w*0.5 + spacing

                    y = y - w*0.5 - 5

                    for n = 1, squareCount do
                        local square = display.newRect(foreground, x, y, w, w)
                        table.insert(objectsTable, square)
                        table.insert(squares, square)
                        square:setFillColor(1)
                        physics.addBody( square, { density=10, bounce=0.4, friction=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        square.gravityScale = 0
                        local vX = 200
                        if i%2 == 0 then
                            vX = -vX
                        end
                        square:setLinearVelocity(vX, velocityY)
                        square.tmr = timer.performWithDelay(1000, function() 
                            vX = -vX
                            square:setLinearVelocity(vX, velocityY)
                        end, 12+i)
                        lvlTmrs[#lvlTmrs + 1] = square.tmr

                        square.collision = onCollision
                        square:addEventListener( "collision" )

                        x = x + w + spacing
                    end

                    if i < rowCount then
                        y = y - w*3 - spacing - 100
                    end
                end

                -- local tmr
                -- tmr = timer.performWithDelay(1000, function() 
                --     for i = 1, #squares do
                --         if squares[i].tmr ~= nil then
                --             return
                --         end

                --         local x = math.max(squares[i].contentWidth/2, squares[i].contentHeight/2)
                --         if ( squares[i].x < _g.screenLeft - x or
                --              squares[i].x > _g.screenRight + x or
                --              squares[i].y < _g.screenTop - x or
                --              squares[i].y > _g.screenBottom + x)
                --         then
                --             return
                --         end
                --     end

                --     timer.cancel(tmr)
                --     tmr = nil
                --     canRemoveObjects = true
                --     levelIsSetup = true
                -- end, -1)
                -- lvlTmrs[#lvlTmrs + 1] = tmr

                local delay = (earth.y+(earth.contentHeight*0.5)+(w*0.5) - y) / velocityY * 1000
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(delay, function() 
                    -- if tmr == nil then return end

                    -- timer.cancel(tmr)
                    -- tmr = nil
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 44,
            difficulty = 1,
            maxScore = 275,
            desc = "Rectangles lined up on an angle",
            background = {200,130,99},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rectanglesPerRow = 16

                local x
                local y = _g.screenTop - 120
                local xMove = -(_g.screenWidth/rectanglesPerRow)
                local r = -60
                for i = 1, 4 do
                    xMove, r = -xMove, -r
                    if i%2 == 0 then x = _g.screenRight else x = _g.screenLeft end
                    for n = 1, rectanglesPerRow+1 do
                        local rect = display.newRect(foreground, x, y, 75, 4)
                        rect:setFillColor(1)
                        rect.rotation = r
                        physics.addBody( rect, { density=50, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        rect:setLinearVelocity(0, velocityY)
                        rect.gravityScale = 0

                        table.insert(objectsTable, rect)

                        x = x + xMove
                    end

                    y = y - 200
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 8000, function()
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 45,
            difficulty = 2,
            maxScore = 300,
            desc = "Rectangles used to block circles",
            background = {229,121,111},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local circlesPerRow = 12

                local startX, x
                local y = _g.screenTop - 20
                local w = _g.screenWidth*0.70
                local xMove = w/circlesPerRow
                local yMove = xMove
                
                for i = 1, 3 do
                    if i == 1 then
                        startX = _g.screenLeft+10
                    elseif i == 2 then
                        xMove = -xMove
                        startX = _g.screenRight-10
                    else
                        xMove = -xMove
                        startX = _g.centerX - w*0.5 + 10
                    end
                    
                    -- if i == 3 then circlesPerRow = 6 end
                    for j = 1, circlesPerRow do
                        if (i ~= 3 and j > 2 and j <= circlesPerRow-2) or (i == 3 and j <= 4) then
                            x = startX
                            for n = 1, circlesPerRow do
                                if (i == 3 and n > 2 and n <= circlesPerRow-2) or i ~= 3 then 
                                    local circ = display.newCircle(foreground, x, y, 5)
                                    circ:setFillColor(1)
                                    physics.addBody( circ, { density=20, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                                    circ:setLinearVelocity(0, velocityY)
                                    circ.gravityScale = 0

                                    table.insert(objectsTable, circ)
                                end

                                x = x + xMove
                            end
                        end

                        y = y - yMove
                    end

                    local rect
                    if i == 3 then -- center below circles
                        rect = display.newRect(foreground, _g.centerX, y+w+15, w, 8)
                    else
                        rect = display.newRect(foreground, x, y+w*0.5+10, 8, w)
                    end
                    rect:setFillColor(1)
                    physics.addBody( rect, { density=50, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect:setLinearVelocity(0, velocityY)
                    rect.gravityScale = 0

                    table.insert(objectsTable, rect)

                    y = y - 120
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 12000, function()
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 46,
            difficulty = 1,
            maxScore = 275,
            desc = "Big circles trapped inside rectangles",
            background = {54,54,54},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local circleCount = 6
                local circleRadius = 30
                local x, y = _g.centerX, _g.screenTop - 50
                
                for i = 1, circleCount do
                    local circ = display.newCircle(foreground, x, y, circleRadius)
                    circ:setFillColor(1)
                    physics.addBody( circ, { radius=circleRadius, density=15, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                    circ:setLinearVelocity(0, velocityY)
                    circ.gravityScale = 0

                    table.insert(objectsTable, circ)

                    local rects = {
                        {circ.x+circleRadius,circ.y+circleRadius,-45},
                        {circ.x-circleRadius,circ.y+circleRadius,45},
                        {circ.x+circleRadius,circ.y-circleRadius,45},
                        {circ.x-circleRadius,circ.y-circleRadius,-45},
                    }
                    if x >= _g.centerX then
                        rects[1][1], rects[1][2] = rects[1][1] - 5, rects[1][2] - 5
                        rects[4][1], rects[4][2] = rects[4][1] + 5, rects[4][2] + 5
                    else
                        rects[2][1], rects[2][2] = rects[2][1] + 5, rects[2][2] - 5
                        rects[3][1], rects[3][2] = rects[3][1] - 5, rects[3][2] + 5
                    end
                    for n = 1, #rects do
                        local rect = display.newRect(foreground, rects[n][1], rects[n][2], circleRadius*2+15, 5)
                        rect:setFillColor(1)
                        rect.rotation = rects[n][3]
                        physics.addBody( rect, { density=40, bounce=0, filter = { categoryBits = 8, maskBits = 13 } } )
                        rect:setLinearVelocity(0, velocityY)
                        rect.gravityScale = 0

                        table.insert(objectsTable, rect)
                    end

                    if i < circleCount then
                        if x == _g.centerX then
                            x = rand(_g.centerX+40, _g.screenRight-40)
                        elseif x > _g.centerX then
                            x = rand(_g.screenLeft+40, _g.centerX)
                        else
                            x = rand(_g.centerX, _g.screenRight-40)
                        end
                        y = y - 180
                    end
                end

                local delay = (_g.screenTop - y) / velocityY * 1000
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( delay, function()
                    canRemoveObjects = true
                    levelIsSetup = true
                end)
            end
        },
        {
            level = 47,
            difficulty = 1,
            maxScore = 200,
            desc = "Pyramid made of squares",
            background = {107,118,126},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local rowCount = 7
                local spacing = 5
                local w = (_g.screenWidth - (spacing * (rowCount+1))) / rowCount
                local y = _g.screenTop - w*0.5
                
                for i = 1, rowCount do
                    local squareCount = rowCount - i + 1
                    local x = _g.centerX - ((squareCount-1)*0.5)*(w+spacing)

                    for n = 1, squareCount do
                        local rect = display.newRect(foreground, x, y, w, w)
                        rect:setFillColor(1)
                        physics.addBody( rect, { density=15, bounce=0.1, filter = { categoryBits = 8, maskBits = 13 } } )
                        rect:setLinearVelocity(0, velocityY)
                        rect.gravityScale = 0
                        table.insert(objectsTable, rect)

                        x = x + w + spacing
                    end

                    y = y - w - spacing
                end

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
        {
            level = 48,
            difficulty = 4,
            maxScore = 160,
            desc = "Splitting rectangle with falling objects",
            background = {253,196,231},
            textColor = 0,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local itemsCount = 20
                local colors = {{166/255,126/255,255/255},{58/255,124/255,253/255},{0/255,176/255,136/255},{140/255,112/255,95/255},{250/255,73/255,110/255}}
                local triangleShape = { 0,-5, 5.7735,5, -5.7735,5 }

                local i = 1
                local createItem = function()
                    local item
                    local x = rand(_g.centerX - 150, _g.centerX + 150)
                    local n = rand(1,3)
                    if n == 1 then -- circle
                        item = display.newCircle(foreground, x, _g.screenTop - 100, 5 )
                        physics.addBody( item, { radius=5, density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13+32 } } )
                    elseif n == 2 then -- square
                        item = display.newRect(foreground, x, _g.screenTop - 100, 10, 10)
                        physics.addBody( item, { density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13+32 } } )
                    else -- triangle
                        item = display.newPolygon(foreground, x, _g.screenTop - 100, triangleShape)
                        physics.addBody( item, { shape=triangleShape, density=5, bounce=0.5, friction = 0, filter = { categoryBits = 8, maskBits = 13+32 } } )
                    end

                    item:setFillColor(unpack(colors[rand(1,5)]))
                    item:setLinearVelocity(0, velocityY)
                    item.gravityScale = 1
                    table.insert(objectsTable, item)

                    if i == itemsCount then
                        levelIsSetup = true
                    end

                    i = i + 1
                end

                local n = 1
                for n = 1, 2 do
                    local x = _g.centerX - 75
                    if n == 2 then x = _g.centerX + 75 end

                    local cross = display.newRect(foreground, x, _g.screenTop - 15, 150, 15)
                    cross:setFillColor(1)

                    physics.addBody( cross, { density=150, bounce=0, filter = { categoryBits = 32, maskBits = 13 } })
                    cross.angularDamping = 1
                    cross.gravityScale = 0
                    cross.collisionGravityScale = 0

                    local shadow = display.newCircle(foreground, x, _g.screenTop - 15, 3)
                    shadow:setFillColor(0)
                    physics.addBody( shadow, "kinematic", { density=1, bounce=0, filter = { categoryBits = 8, maskBits = 5 } } )
                    shadow.gravityScale = 0
                    shadow.collisionGravityScale = 0

                    local pivotJoint = physics.newJoint( "pivot", shadow, cross, shadow.x, shadow.y )
                    shadow:setLinearVelocity(0, velocityY)

                    table.insert(objectsTable, shadow)
                    table.insert(objectsTable, cross)
                end

                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay(125, createItem, itemsCount)
                canRemoveObjects = true
            end
        },
        {
            level = 49,
            difficulty = 1,
            maxScore = 300,
            desc = "Different shapes in the form of circles",
            background = {204,163,122},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps
                local cos, sin, pi = math.cos, math.sin, math.pi
                local triangleShape = { 0,-8.66025, 10,8.66025, -10,8.66025 }
                local i = 1

                local func = function()
                    local y = _g.screenTop-80
                    local x

                    if i%2 == 1 then
                        x = rand(_g.centerX-80,_g.centerX+80)    
                    else
                        if rand(1,2) == 1 then
                            x = rand(_g.screenLeft+50,_g.screenLeft+80)
                        else
                            x = rand(_g.screenRight-80, _g.screenRight-50)
                        end
                    end
                    local s = rand(1,2)
                    if s == 1 then -- rects
                        for n = 0, 359, 20 do
                            local x2 = x + 50*math.cos(n*pi/180)
                            local y2 = y + 50*math.sin(n*pi/180)
                            local rect = display.newRect(foreground, x2, y2, 28, 8)
                            rect.rotation = n
                            physics.addBody( rect, { density=20, bounce=0.2, filter = { categoryBits = 8, maskBits = 13 } } )
                            rect.gravityScale = 0
                            rect:setLinearVelocity(0,velocityY)

                            table.insert(objectsTable, rect)
                        end
                    else -- triangles
                        for n = 0, 359, 24 do
                            local x2 = x + 50*math.cos(n*pi/180)
                            local y2 = y + 50*math.sin(n*pi/180)
                            local triangle = display.newPolygon(foreground, x2, y2, triangleShape)
                            triangle.rotation = n
                            physics.addBody( triangle, { shape=triangleShape, density=20, bounce=0.2, filter = { categoryBits = 8, maskBits = 13 } } )
                            triangle.gravityScale = 0
                            triangle:setLinearVelocity(0,velocityY)

                            table.insert(objectsTable, triangle)
                        end
                    end

                    if i == 4 then
                        canRemoveObjects = true
                        levelIsSetup = true
                    end

                    i = i + 1

                end

                func()
                lvlTmrs[#lvlTmrs + 1] = timer.performWithDelay( 3500, func, 4 )
            end
        },
        {
            level = 50,
            difficulty = 1,
            maxScore = 200,
            desc = "Rectangles that sandwich triangles",
            background = {244,29,29},
            textColor = 1,
            create = function()
                local velocityY = _g.scrollSpeed * display.fps * 1.2
                local spacing = 4
                local w = 20
                local h = 17.3205
                local triangleShape = { 0,-(h*0.5), (w*0.5),(h*0.5), -(w*0.5),(h*0.5) }
                local rows = {8,7,7,6}
                local y = _g.screenTop - 4

                for p = 1, 2 do
                    local rect = display.newRect(foreground, _g.centerX, y, rows[1]*(w+spacing)-spacing, 8)
                    rect:setFillColor(1)
                    physics.addBody( rect, { density=50, bounce=0.2, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect:setLinearVelocity(0, velocityY)
                    rect.gravityScale = 0
                    table.insert(objectsTable, rect)
                    y = y - 8 - spacing*2

                    for i = 1, #rows do

                        local x = _g.centerX - ((rows[i]-1)*0.5)*(w+spacing)

                        for n = 1, rows[i] do
                            local triangle = display.newPolygon(foreground, x, y, triangleShape)
                            triangle:setFillColor(1)
                            physics.addBody( triangle, { shape=triangleShape, density=10, bounce=0.2, filter = { categoryBits = 8, maskBits = 13 } } )
                            triangle.gravityScale = 0
                            if i%2 == 0 then
                                triangle.rotation = 180
                            end
                            triangle:setLinearVelocity(0, velocityY)
                            table.insert(objectsTable, triangle)
                            x = x + w + spacing
                        end

                        if i < #rows then
                            if i%2 == 0 then
                                y = y - h - spacing
                            else
                                y = y - spacing
                            end
                        end
                    end


                    y = y - 8 - spacing*2
                    local rect = display.newRect(foreground, _g.centerX, y, rows[#rows]*(w+spacing)-spacing, 8)
                    rect:setFillColor(1)
                    physics.addBody( rect, { density=50, bounce=0.2, filter = { categoryBits = 8, maskBits = 13 } } )
                    rect:setLinearVelocity(0, velocityY)
                    table.insert(objectsTable, rect)
                    rect.gravityScale = 0

                    r = 5
                    y = y - 4 - r - spacing
                    local circleCount = 10
                    local x = _g.centerX - ((circleCount-1)*0.5)*((r*2)+spacing)
                    for n = 1, circleCount do
                        local circle = display.newCircle(foreground, x, y, r)
                        circle:setFillColor(1)
                        physics.addBody( circle, { radius=r, density=10, bounce=0.4, filter = { categoryBits = 8, maskBits = 13 } } )
                        circle.gravityScale = 0
                        circle:setLinearVelocity(0, velocityY)
                        table.insert(objectsTable, circle)
                        x = x + r*2 + spacing
                    end

                    y = y - 100
                end

                local circle = display.newCircle(foreground, _g.centerX, y, 60)
                circle:setFillColor(1)
                physics.addBody( circle, { radius=60, density=10, bounce=0.4, filter = { categoryBits = 8, maskBits = 13 } } )
                circle.gravityScale = 0
                circle:setLinearVelocity(0, velocityY)
                table.insert(objectsTable, circle)

                canRemoveObjects = true
                levelIsSetup = true
            end
        },
    }

    -- Setup level indexes
    setupLevelIndexes()
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        -- Runtime:addEventListener("touch", dragOzone)
        Runtime:addEventListener("collision", onGlobalCollision)

        foreground:insert(earth)
        foreground:insert(bgClouds)

        -- Move earth to where it should be
        transition.to(earth, { y = earth.gameY, time = 1500, transition = easing.inOutQuad })

        gameResumed = false
        startGame()
        -- timer.performWithDelay( 2250, startGame, 1 )
        -- timer.performWithDelay( 1, startGame, 1 )
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        
        -- Save data
        _data:save()

        -- Move these to the display stage so they aren't removed by the sceneGroup
        display.getCurrentStage():insert(earth)
        display.getCurrentStage():insert(bgClouds)
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        resetGame()
        scoreText.text = 0
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene