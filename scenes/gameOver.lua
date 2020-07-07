local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
-- Required libraries
local widget = require("widget")
local _ads = require("lib.ads")
local _g = require("lib.globalVariables")

-- Variables
local bg
local countDown
local resume = false
local parent
 

-- Functions

local function goToMenu()
    parent:gameOver(true)
end

function scene:onResized(event)
    bg.x, bg.y = _g.centerX, _g.centerY
    bg.width, bg.height = _g.screenWidth, _g.screenHeight
end

function scene:onBackKey(event)
    -- Hide the overlay and go to the menu
    goToMenu()
    return true
end

local function continueButtonEvent( event )
    if ( "ended" == event.phase ) then
        local callback = function(finished)
            if finished then
                resume = true
                composer.hideOverlay( "fade", 400 )
            else
                if parent then
                    goToMenu()
                end
            end
        end

        if _ads:showReward() then
            _ads:setRewardsCallback(callback)
        else
            callback(true)
        end
    end
end

local function noThanksButtonEvent( event )
    if ( "ended" == event.phase ) then
        -- Hide the overlay and to the menu
        -- composer.hideOverlay( "fade", 400 )
        -- composer.gotoScene("scenes.menu")
        if parent then
            goToMenu()
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
    
    local bg = display.newRect(sceneGroup, _g.centerX, _g.centerY, _g.screenWidth, _g.screenHeight)
    bg:setFillColor(0,0,0,0.9)

    countDown = display.newText(sceneGroup, "5", _g.centerX, _g.centerY-18, _g.fontMain, 192)
    countDown:setFillColor(39/255,53/255,58/255)
    countDown.alpha=0
    countDown:scale( 0.1, 0.1 )

    keepPlayingText = display.newText(sceneGroup, "KEEP PLAYING?", _g.centerX, _g.centerY+(_g.safeScreenTop-_g.centerY)*0.5, _g.fontMain, 36)
     
    local shadow = display.newRoundedRect(sceneGroup, _g.centerX, _g.centerY+4, 188, 48, 10)
    shadow:setFillColor(54/255,85/255,102/255)
    local continueButton = widget.newButton(
        {
            onEvent = continueButtonEvent,
            shape = "roundedRect",
            x = _g.centerX,
            y = _g.centerY,
            width = 188,
            height = 48,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    sceneGroup:insert(continueButton)
    local continue = display.newSprite(sceneGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("continue")}})
    -- local continue = display.newImageRect(sceneGroup, "continue.png", 161, 22)
    continue.x, continue.y = _g.centerX, _g.centerY

    local noThanksButton = widget.newButton(
        {
            label = "NO THANKS",
            font = _g.fontRegular,
            fontSize = 18,
            onEvent = noThanksButtonEvent,
            textOnly = true,
            x = _g.centerX,
            y = _g.centerY+115,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(noThanksButton)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
    parent = event.parent  -- Reference to the parent scene object
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

        local animateCountDown
        local time = 5
        countDown.alpha = 1
        animateCountDown = function()
            countDown.text = time
            transition.to(countDown, {time=2500, delay=500, xScale=5, yScale=5, alpha=0, transition=easing.outInCirc, onComplete=function()
                countDown.xScale, countDown.yScale = 0.1, 0.1
                countDown.alpha = 1
                time = time - 1
                if time == 0 then
                    goToMenu()
                else
                    animateCountDown()
                end
            end})
        end
        animateCountDown()
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
    parent = event.parent  -- Reference to the parent scene object
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

        transition.cancel()
        transition.to(countDown, {time=100, alpha=0})
        if resume then
            parent:resumeGame()
        end
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        composer.removeScene("scenes.gameOver")
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