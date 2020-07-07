local composer = require( "composer" )

local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

-- Required libraries
local widget = require( "widget" )
local _g = require("lib.globalVariables")
local _gdpr = require("lib.gdprutil")
local _ads = require("lib.ads")

-- Variables
local bg
local group

function scene:onResized(event)
    bg.x, bg.y = _g.centerX, _g.centerY
    bg.width, bg.height = _g.screenWidth, _g.screenHeight
    group.y = _g.centerY - group.contentHeight*0.5 + 10
end

function scene:onBackKey(event)
    -- block back key
    return true
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    bg = display.newRect(sceneGroup, _g.centerX, _g.centerY, _g.screenWidth, _g.screenHeight)
    bg:setFillColor(0,0,0,0.9)

    group = display.newGroup()
    group.x, group.y = _g.centerX, 0
    sceneGroup:insert(group)

    local textOptions = 
    {
        text = "Personalize your Ads",
        x = 0,
        y = 0,
        font = _g.fontMain,   
        fontSize = 24,
        parent = group
    }
     
    local text = display.newText(textOptions)
    text:setFillColor( 1, 1, 1, 0.9 )

    local textOptions = 
    {
        text = "O-ZONE personalizes your advertising experience. Our ad provider and its partners may collect and process personal data such as device identifiers, location data, and other demographic and interest data to provide you with a tailored experience. By consenting, you'll see ads that our ad provider and its partners believe are more relevant to you.",
        x = 0,
        y = 110,
        width = _g.screenWidth-20,
        font = _g.fontRegular,   
        fontSize = 14,
        align = "left",
        parent = group
    }
     
    local text = display.newText(textOptions)
    text:setFillColor( 1, 1, 1, 0.9 )

    local function learnMoreButtonEvent( event )
        if ( "ended" == event.phase ) then
            system.openURL( "https://robbieelias.ca/ozone_privacy.html" )
        end
    end

    local learnMoreButton = widget.newButton(
        {
            label = "LEARN MORE",
            font = _g.fontRegular,
            fontSize = 14,
            onEvent = learnMoreButtonEvent,
            textOnly = true,
            labelAlign = "left",
            x = 0,
            y = 200,
            labelColor = { default=_g.buttonColor, over=_g.buttonColorPressed },
        }
    )
    learnMoreButton.x = -_g.screenWidth*0.5 + learnMoreButton.contentWidth*0.5 + 10
    group:insert(learnMoreButton)

    local textOptions = 
    {
        text = "By agreeing, you confirm that you are over the age of 16 and would like a personalized ad experience.",
        x = 0,
        y = 250,
        width = _g.screenWidth-20,
        font = _g.fontRegular,   
        fontSize = 14,
        align = "left",
        parent = group
    }
     
    local text = display.newText(textOptions)
    text:setFillColor( 1, 1, 1, 0.9 )

    local function agreeButtonEvent( event )
        if ( "ended" == event.phase ) then
            _gdpr.setConsent(true)
            _ads:init(true)
            composer.hideOverlay( "slideRight", 400 )
        end
    end

    local shadow = display.newRoundedRect(group, 0, 324, 250, 50, 10)
    shadow:setFillColor(54/255,85/255,102/255)
    local agreeButton = widget.newButton(
        {
            label = "YES, I AGREE",
            labelColor = { default={1,1,1}, over={1,1,1} },
            font = _g.fontMain,
            fontSize = 26,
            onEvent = agreeButtonEvent,
            shape = "roundedRect",
            x = 0,
            y = 320,
            width = 250,
            height = 50,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    group:insert(agreeButton)

    local function noButtonEvent( event )
        if ( "ended" == event.phase ) then
            _gdpr.setConsent(false)
            _ads:init(false)
            composer.hideOverlay( "slideRight", 400 )
        end
    end

    local noButton = widget.newButton(
        {
            label = "NO, THANK YOU",
            font = _g.fontRegular,
            fontSize = 18,
            onEvent = noButtonEvent,
            textOnly = true,
            x = 0,
            y = 380,
            labelColor = { default=_g.buttonColor, over=_g.buttonColorPressed },
        }
    )
    group:insert(noButton)

    local textOptions = 
    {
        text = "I understand that I will still see ads, but they may not be relevant to me.",
        x = 0,
        y = 415,
        width = _g.screenWidth-100,
        align = "center",
        font = _g.fontRegular,   
        fontSize = 12,
        parent = group
    }
     
    local text = display.newText(textOptions)
    text:setFillColor( 1, 1, 1, 0.9 )

    group.y = _g.centerY - group.contentHeight*0.5 + 10

end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        composer.removeScene( "scenes.gdpr" )
        -- Code here runs immediately after the scene goes entirely off screen
 
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