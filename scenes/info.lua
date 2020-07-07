local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
-- Required libraries
local widget = require( "widget" )
local _g = require("lib.globalVariables")
local _ads = require("lib.ads")
local _iap = require("plugin.iap_badger")

function scene:onBackKey(event)
    composer.hideOverlay( "slideRight", 400 )
    return true
end

local function closeButtonEvent( event )
    if ( "ended" == event.phase ) then
        -- Hide the overlay and go to the menu
        composer.hideOverlay( "slideRight", 400 )
    end
end

--If this function is called, the app store never replied to the request
--for a restore (which probably means there were no products to restore)
local function restoreTimeout()

    --Tell user something went wrong
    hideMessage()
    showMessage("Restore failed")

end

--This function is called on a successful restore.
--If event.firstRestoreCallback is set to true, then this is the first time the function
--has been called.
local function restoreListener(productName, event)

    --If this is the first transaction...
    if (event.firstRestoreCallback) then
        --Tell user purchases have been restored
        hideMessage()
        showMessage("Purchase restored!")
    end

    --Remove ads
    if (productName == "removeAds") then 
        _ads:remove()
    end

    --Save any inventory changes
    _iap.saveInventory()

end

local function restorePurchaseButtonEvent( event )
    if ( "ended" == event.phase ) then
        showMessage("Attempting to restore purchase")
        _iap.restore(false, restoreListener, restoreTimeout)
    end
end

local function adSettingsButtonEvent( event )
    if ( "ended" == event.phase ) then
        composer.showOverlay( "scenes.gdpr", {isModal = true, effect = "fromLeft", time = 400})
    end
end

local function privacyPolicyButtonEvent( event )
    if ( "ended" == event.phase ) then
        system.openURL( "https://robbieelias.ca/ozone_privacy.html" )
    end
end

local function termsButtonEvent( event )
    if ( "ended" == event.phase ) then
        system.openURL( "https://robbieelias.ca/ozone_terms.html" )
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    local ratio = _g.screenHeight/_g.screenWidth
    local shortScreen = false
    if ratio <= 1.6 then shortScreen = true end
    
    local bg = display.newRect(sceneGroup, _g.centerX, _g.centerY, _g.screenWidth, _g.screenHeight)
    bg:setFillColor(0,0,0,0.9)
    
    local howToPlayText
    if shortScreen then
        howToPlayText = display.newText(sceneGroup, "HOW TO PLAY", _g.centerX, _g.safeScreenTop + 20, _g.fontMain, 38)
    else
        howToPlayText = display.newText(sceneGroup, "HOW TO PLAY", _g.centerX, _g.safeScreenTop + 30, _g.fontMain, 44)
    end
    howToPlayText:addEventListener("touch", closeButtonEvent)

    local tW = _g.screenWidth
    if ratio <= 1 then 
        tW = tW - 150
    elseif ratio < 1.2 then 
        tW = tW - 120
    elseif ratio < 1.4 then 
        tW = tW - 50
    elseif ratio < 1.6 then 
        tW = tW - 10
    end
    local tutorial = display.newImageRect(sceneGroup, "assets/tutorial.png", tW, tW)
    tutorial.x = _g.centerX
    if shortScreen then
        tutorial.y = howToPlayText.y + tW*0.5 + 15
    else
        tutorial.y = howToPlayText.y + tW*0.5 + 30
    end
    tutorial:addEventListener("touch", closeButtonEvent)

    local buttonsY = _g.screenBottom - (_g.screenBottom - (tutorial.y+tW*0.5))*0.5 - 20

    local restorePurchaseButton = widget.newButton(
        {
            label = "Restore Purchase",
            font = _g.fontRegular,
            fontSize = 14,
            onEvent = restorePurchaseButtonEvent,
            textOnly = true,
            x = _g.centerX - 75,
            y = buttonsY - 20,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(restorePurchaseButton)

    local adSettingsButton = widget.newButton(
        {
            label = "Ad Settings",
            font = _g.fontRegular,
            fontSize = 14,
            onEvent = adSettingsButtonEvent,
            textOnly = true,
            x = _g.centerX + 75,
            y = buttonsY - 20,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(adSettingsButton)

    local privacyPolicyButton = widget.newButton(
        {
            label = "Privacy Policy",
            font = _g.fontRegular,
            fontSize = 14,
            onEvent = privacyPolicyButtonEvent,
            textOnly = true,
            x = _g.centerX - 75,
            y = buttonsY + 20,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(privacyPolicyButton)

    local termsButton = widget.newButton(
        {
            label = "Terms of Use",
            font = _g.fontRegular,
            fontSize = 14,
            onEvent = termsButtonEvent,
            textOnly = true,
            x = _g.centerX + 75,
            y = buttonsY + 20,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(termsButton)

    local y
    if shortScreen then y = _g.screenBottom - 20 else y = _g.screenBottom - 30 end
    local closeButton = widget.newButton(
        {
            label = "CLOSE",
            font = _g.fontRegular,
            fontSize = 18,
            onEvent = closeButtonEvent,
            textOnly = true,
            x = _g.centerX,
            y = y,
            cornerRadius = 10,
            labelColor = { default={204/255,204/255,204/255}, over={163/255,163/255,163/255} },
        }
    )
    sceneGroup:insert(closeButton)
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

    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
    parent = event.parent  -- Reference to the parent scene object
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        composer.removeScene("scenes.info")
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