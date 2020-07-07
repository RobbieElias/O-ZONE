-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Removes status bar on iOS and tries to hide home indicator
display.setStatusBar( display.HiddenStatusBar )
native.setProperty( "prefersHomeIndicatorAutoHidden", true )
native.setProperty( "preferredScreenEdgesDeferringSystemGestures", true )
 
-- Seed the random number generator
math.randomseed( os.time() )
math.random() -- calling math.random() fixes bug

-- Required libraries
local composer = require("composer")
local loadsave = require("lib.loadsave")
local _ads = require("lib.ads")
local _gs = require("lib.gameServices")
local _g = require("lib.globalVariables")
local _iap = require("plugin.iap_badger")
local _fa = require("plugin.firebaseAnalytics")
local _data = require("lib.data")


-- Initialize global variables
_g:init()

-- Preload fonts
local text = display.newText( "", 0, 0, _g.fontMain, 24 )
display.remove(text)
local text = display.newText( "", 0, 0, _g.fontRegular, 24 )
display.remove(text)

-- Create earth
earth = display.newSprite(_g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("earth")}})
earth.gameY = _g.safeScreenTop + 480
if earth.gameY+45 > _g.screenBottom then
    earth.gameY = _g.screenBottom - 65
end
earth.menuY = earth.gameY
if earth.menuY < _g.centerY+160 then earth.menuY = _g.centerY+160 end
earth.x, earth.y = _g.centerX, earth.menuY
earth.myName = "earth"

-- Create clouds background and set default background color
bgClouds = display.newSprite(_g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("bg-clouds")}})
local widthScale = _g.screenWidth / 320
local h = widthScale*119
bgClouds.width = _g.screenWidth
bgClouds.height = h
bgClouds.x = _g.centerX
local bgCloudsY = earth.y + 70
if bgCloudsY > _g.screenBottom then bgCloudsY = _g.screenBottom-10 end
bgClouds.y = bgCloudsY
bgClouds.menuY = bgCloudsY
display.setDefault( "background", _g.mainBgColor[1]/255, _g.mainBgColor[2]/255, _g.mainBgColor[3]/255 )

-- Wipe data (if in debug mode)
if _g.debug then
    -- _data:wipe()
end

-- Load saved data
_data:load()

local messageQueue = {}

function hideMessage()
    if _g.messageGroup then
        _g.messageGroup.transition = transition.to(_g.messageGroup, {y=_g.screenBottom+_g.messageGroup.contentHeight*0.5, time=300, onComplete=function()
            _g.messageGroup:removeSelf()
            _g.messageGroup = nil
            if #messageQueue > 0 then
                local m = table.remove(messageQueue, 1)
                showMessage(m[1], m[2])
            end
        end})
    end
end

function showMessage(txt, duration)
    local d = duration or 4000
    if _g.messageGroup then
        messageQueue[#messageQueue + 1] = {txt, d}
        return
    end

    _g.messageGroup = display.newGroup()
    _g.messageGroup.x, _g.messageGroup.y = _g.centerX, _g.screenBottom+23
    local w = _g.screenWidth-20
    local textSize = 24
    local fontSizeIncrement = 4
    local text = display.newText(_g.messageGroup, txt, 0, 0, _g.fontRegular, textSize)
    while text.width > w * 0.95 and text.size > fontSizeIncrement do
        text.size = text.size - fontSizeIncrement
    end

    local shadow = display.newRoundedRect(_g.messageGroup, 0, 3, w, text.contentHeight + 10, 10/textSize * text.size)
    shadow:setFillColor(54/255,85/255,102/255,0.2)
    local rect = display.newRoundedRect(_g.messageGroup, 0, 0, w, text.contentHeight + 10, 10/textSize * text.size)
    rect:setFillColor(54/255,85/255,102/255)
    text:toFront()

    _g.messageGroup.transition = transition.to(_g.messageGroup, {y=_g.screenBottom-_g.messageGroup.contentHeight*0.5-10, time=300})

    timer.performWithDelay(d, function()
        if _g.messageGroup then
            _g.messageGroup.transition = transition.to(_g.messageGroup, {y=_g.screenBottom+_g.messageGroup.contentHeight*0.5, time=300, onComplete=function()
                _g.messageGroup:removeSelf()
                _g.messageGroup = nil
                if #messageQueue > 0 then
                    local m = table.remove(messageQueue, 1)
                    showMessage(m[1], m[2])
                end
            end})
        end
    end)
end

function getScrollDuration(distance)
    return distance / (_g.bgScrollSpeed * display.fps) * 1000
end

-- Removes bottom bar on Android 
function setImmersive()
	if (system.getInfo("platform") == "android") then
		if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
		    native.setProperty( "androidSystemUiVisibility", "lowProfile" )
		else
		    native.setProperty( "androidSystemUiVisibility", "immersiveSticky" ) 
		end
	end
end

-- Called when the window has been resized. Re-layouts the app display objects to fit.
local function onResized(event)
	    _g:updateScreenVariables()
        setImmersive()

        earth.gameY = _g.safeScreenTop + 480
        if earth.gameY+45 > _g.screenBottom then
            earth.gameY = _g.screenBottom - 65
        end
        earth.menuY = earth.gameY
        if earth.menuY < _g.centerY+160 then earth.menuY = _g.centerY+160 end
        earth.x = _g.centerX

        local widthScale = _g.screenWidth / 320
        local h = widthScale*119
        bgClouds.width = _g.screenWidth
        bgClouds.height = h
        bgClouds.x = _g.centerX
        local bgCloudsY = earth.menuY + 70
        if bgCloudsY > _g.screenBottom then bgCloudsY = _g.screenBottom-10 end
        bgClouds.menuY = bgCloudsY

        local currentSceneName = composer.getSceneName("current")
        local currentOverlayName = composer.getSceneName("overlay")

        if currentSceneName == "scenes.game" then
            earth.y = earth.gameY
            bgClouds.y = _g.screenBottom + bgClouds.contentHeight/2
            bgClouds.isVisible = false
        else
            earth.y = earth.menuY
            bgClouds.y = bgClouds.menuY
        end

        if currentSceneName ~= nil then
            print("The current scene is: " .. currentSceneName)
            local currentScene = composer.getScene(currentSceneName)

            if (currentScene ~= nil and currentScene.onResized and type(currentScene.onResized)=="function") then
                print("Calling the scene's onResized method...")
                currentScene:onResized(event)
            end
        end

        if currentOverlayName ~= nil then
            print("The active overlay scene is: " .. currentOverlayName)
            local currentOverlay = composer.getScene(currentOverlayName)

            if (currentOverlay ~= nil and currentOverlay.onResized and type(currentOverlay.onResized)=="function") then
                print("Calling the scene's onResized method...")
                currentOverlay:onResized(event)
            end
        end
end

local function systemEvents( event )
   print("systemEvent " .. event.type)
   if ( event.type == "applicationSuspend" ) then
      _data:save()
      print( "suspending..........................." )
   elseif ( event.type == "applicationResume" ) then
      print( "resuming............................." )
      setImmersive()
   elseif ( event.type == "applicationExit" ) then
      print( "exiting.............................." )
   elseif ( event.type == "applicationStart" ) then
      setImmersive()
   end
   return true
end

-- setup hardware back key listener
local function onKeyEvent( event )
    -- Print which key was pressed down/up to the log.
    print("Key '" .. event.keyName .. "' was pressed " .. event.phase)

    -- if event.keyName == 's' and event.phase == 'down' then
    --     local screenBounds =
    --     {
    --         xMin = _g.screenLeft,
    --         xMax = _g.screenRight,
    --         yMin = _g.screenTop,
    --         yMax = _g.screenBottom,
    --     }
    --     local screenCap = display.captureBounds( screenBounds )
    --     screenCap.x = _g.screenWidth/2
    --     screenCap.y = _g.screenHeight/2

    --     local w = screenCap.width
    --     local w2 = display.pixelWidth
    --     local h2 = display.pixelHeight

    --     screenCap.height = w*h2/w2

    --     local function save()
    --         display.save( screenCap, { filename=display.pixelWidth .. 'x' .. display.pixelHeight .. '_' .. math.floor(system.getTimer()) .. '.png', baseDir=system.DocumentsDirectory, isFullResolution=true } )    
    --         screenCap:removeSelf()
    --         screenCap = nil
    --     end
    --     timer.performWithDelay( 100, save, 1)
    --     return false
    -- end

    -- Handle back key
    if (event.keyName == "back") and (event.phase == "up") and (system.getInfo("platform") == "android") then
        local currentSceneName = composer.getSceneName("current")
        local currentOverlayName = composer.getSceneName("overlay")

        local currentScene
        if currentOverlayName ~= nil then
            print("The active overlay scene is: " .. currentOverlayName)
            currentScene = composer.getScene(currentOverlayName)
        elseif currentSceneName ~= nil then
            print("The current scene is: " .. currentSceneName)
            currentScene = composer.getScene(currentSceneName)
        else
            print("Couldn't get the current scene object!")
            return false
        end

        if currentScene == nil then
            print("Couldn't get the scene object!")
            return false
        end

        if (currentScene.onBackKey and type(currentScene.onBackKey)=="function") then
            print("Calling the scene's onBackKey method...")
            return currentScene:onBackKey(event)
        else
            print("No scene onBackKey() handler, returning true without doing anything.")
            return true
        end
    end

    -- Return false to indicate that this app is *not* overriding the received key.
    -- This lets the operating system execute its default handling of this key.
    print("Default key handler: returning false")
    return false
end

Runtime:addEventListener("resize", onResized)
Runtime:addEventListener("system", systemEvents)
Runtime:addEventListener("key", onKeyEvent)

function checkMemory()
   collectgarbage( "collect" )
   local memUsage_str = string.format( "MEMORY = %.3f KB", collectgarbage( "count" ) )
   print( memUsage_str, "TEXTURE = "..(system.getInfo("textureMemoryUsed") / (1024 * 1024) ) )
end
if (_g.debug) then timer.performWithDelay( 1000, checkMemory, 0 ) end

-- Init ads (check GDPR first)
local _gdpr = require("lib.gdprutil")
if _gdpr.hasResponded() then
    _ads:init(_gdpr.hasUserConsent())
end

-- IAP Stuff
local catalogue = {
    --Information about the product on the app stores
    products = {
        --removeAds is the product identifier.
        --Always use this identifier to talk to IAP Badger about the purchase.
        removeAds = {
            --A list of product names or identifiers specific to apple's App Store or Google Play.
            productNames = { apple="com.robbieelias.ozone.remove_ads", google="remove_ads" },
            --The product type
            productType = "non-consumable",
            --This function is called when a purchase is complete.
            onPurchase=function() _iap.setInventoryValue("removeAds", true) end,
            --The function is called when a refund is made
            onRefund=function() _iap.removeFromInventory("removeAds", true) end,
        }
    },
    --Information about how to handle the inventory item
    inventoryItems = {
        removeAds = { productType="non-consumable" }
    }
}

local function failedListener(product, transaction)
    showMessage("Transaction failed.")
    setImmersive()
end

local function cancelledListener(product, transaction)
    showMessage("Transaction cancelled.")
    setImmersive()
end

local iapOptions = {
    --The catalogue generated above
    catalogue=catalogue,
    --The filename in which to save the inventory
    filename="inventory.txt",
    --Salt for the hashing algorithm
    salt = "***REMOVED***",
    -- Called when an in-app purchase fails
    failedListener = failedListener,
    -- Called when the user cancels an in-app purchase
    cancelledListener = cancelledListener,
    debugMode=_g.debug,
}
--Initialise IAP
_iap.init(iapOptions)

if _iap.isInInventory("removeAds") then
    print("Remove Ads purchased already")
    -- Since remove ads has already been purchased, remove all ads
    _ads:remove()

    if _g.debug then
        _iap.emptyInventoryOfNonConsumableItems()
        _iap.saveInventory()
    end
end

-- Login to google play games services or ios game center
_gs:login(false)

-- Initialize Firebase Analytics
_fa.init()

-- Go to initial scene
composer.gotoScene("scenes.menu")