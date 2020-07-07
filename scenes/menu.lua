local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
-- Required libraries
local widget = require( "widget" )
local confetti = require("lib.confetti")
local _ads = require("lib.ads")
local _gdpr = require("lib.gdprutil")
local _gs = require("lib.gameServices")
local _g = require("lib.globalVariables")
local _data = require("lib.data")
local _iap = require("plugin.iap_badger")

-- Display groups
local confettiGroup
local gameOverGroup
local buttonsGroup

-- Variables
local logoText
local gameOverText
local scoreText
local scoreLabelText
local levelText
local levelLabelText
local gamesPlayedText
local gamesPlayedLabelText
local highestLevelText
local highestLevelLabelText
local crown
local highScoreText
local backPressed = false
local score = nil

function scene:onResized(event)
    logoText.x, logoText.y = _g.centerX, _g.centerY - (_g.centerY-_g.screenTop)*0.5 - 10
    buttonsGroup.x, buttonsGroup.y = _g.centerX, _g.centerY

    local y = _g.centerY+(_g.safeScreenTop-_g.centerY)*0.5 + 20
    gameOverText.y = y - 55
    scoreText.y = y
    scoreLabelText.y = y+35
    levelText.y = y
    levelLabelText.y = y+35
    gamesPlayedText.y = _g.safeScreenTop+15
    gamesPlayedLabelText.y = gamesPlayedText.y+15
    highestLevelText.y = _g.safeScreenTop+15
    highestLevelLabelText.y = gamesPlayedText.y+15
    crown.y = _g.safeScreenTop+18
    highScoreText.y = crown.y+25
end

function scene:onBackKey(event)
    if backPressed then
        return false
    end

    showMessage("Back again to exit game", 3000)
    backPressed = true
    timer.performWithDelay(3000, function()
        backPressed = false
    end)

    return true
end

local function showConfetti()
    physics.start()
    physics.setTimeStep(-1)
    physics.setGravity(0, 9.8)
    confetti.show({
        x1 = _g.screenLeft,
        x2 = _g.screenRight, 
        y = bgClouds.y,
        num = 80,
        verticalForce = 70,
        horizontalForce = 0,
        xDispersion = 10,
        yDispersion = 5,
        scaleDispersion = 0.2,
        colors = {{166/255,126/255,255/255},{82/255,219/255,255/255},{0/255,220/255,171/255}
                ,{255/255,221/255,0/255},{255/255,133/255,34/255},{250/255,73/255,110/255}},
        particlesGroup = confettiGroup,
    })
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    confettiGroup = display.newGroup()
    sceneGroup:insert(confettiGroup)

    gameOverGroup = display.newGroup()
    sceneGroup:insert(gameOverGroup)
    gameOverGroup.isVisible = false

    buttonsGroup = display.newGroup()
    buttonsGroup.x, buttonsGroup.y = _g.centerX, _g.centerY
    sceneGroup:insert(buttonsGroup)
    
    -- local logoOW, logoOH = 1024, 274
    -- local ratio = _g.screenWidth / 1024
    -- local logoW, logoH = ratio*logoOW, ratio*logoOH
    -- logoText = display.newImageRect(sceneGroup, "logo-text.png", logoW, logoH)
    logoText = display.newSprite(sceneGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("logo-text")}})
    logoText.x, logoText.y = _g.centerX, _g.centerY - (_g.centerY-_g.screenTop)*0.5 - 10

    -- Setup score stuff after game is over
    local y = _g.centerY+(_g.safeScreenTop-_g.centerY)*0.5 + 20
    local leftX = _g.centerX-(_g.centerX-_g.screenLeft)*0.5 + 20
    local rightX = _g.centerX+(_g.screenRight-_g.centerX)*0.5 - 20
    gameOverText = display.newText(gameOverGroup, "GAME OVER", _g.centerX, y - 55, _g.fontMain, 44)
    gameOverText:setFillColor(54/255,85/255,102/255)
    scoreText = display.newText(gameOverGroup, "0", leftX, y, _g.fontMain, 44)
    scoreLabelText = display.newText(gameOverGroup, "SCORE", leftX, y+35, _g.fontRegular, 22)
    levelText = display.newText(gameOverGroup, "#1", rightX, y, _g.fontMain, 44)
    levelLabelText = display.newText(gameOverGroup, "LEVEL", rightX, y+35, _g.fontRegular, 22)
    gamesPlayedText = display.newText(gameOverGroup, "0", _g.screenLeft+25, _g.safeScreenTop+15, _g.fontMain, 14)
    gamesPlayedLabelText = display.newText(gameOverGroup, "# GAMES", _g.screenLeft+25, gamesPlayedText.y+15, _g.fontRegular, 10)
    highestLevelText = display.newText(gameOverGroup, "#1", _g.screenRight-25, _g.safeScreenTop+15, _g.fontMain, 14)
    highestLevelLabelText = display.newText(gameOverGroup, "MAX LVL", _g.screenRight-25, gamesPlayedText.y+15, _g.fontRegular, 10)
    crown = display.newSprite(gameOverGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("crown")}})
    crown.x, crown.y = _g.centerX, _g.safeScreenTop+18
    highScoreText = display.newText(gameOverGroup, "0", _g.centerX, crown.y+25, _g.fontMain, 20)

    local function playButtonEvent( event )
        if ( "ended" == event.phase ) then
            local bgCloudsNewY = _g.screenBottom + bgClouds.contentHeight/2
            transition.to(bgClouds, {time=getScrollDuration(bgCloudsNewY-bgClouds.y), y=bgCloudsNewY, onComplete=function()
                bgClouds.isVisible = false
            end})
            composer.gotoScene("scenes.game", {effect = "crossFade", time = 500})
        end
    end
     
    local shadow = display.newRoundedRect(buttonsGroup, 0, 4, 80, 80, 20)
    shadow:setFillColor(144/255,215/255,244/255)
    local playButton = widget.newButton(
        {
            onEvent = playButtonEvent,
            shape = "roundedRect",
            x = 0,
            y = 0,
            width = 80,
            height = 80,
            cornerRadius = 20,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    buttonsGroup:insert(playButton)
    local play = display.newSprite(buttonsGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("play")}})
    -- local play = display.newImageRect(buttonsGroup, "play.png", 60, 60)
    play.x, play.y = 1, 0

    local function leaderboardButtonEvent( event )
        if ( "ended" == event.phase ) then
            if _gs:isLoggedIn() then
                _gs:showLeaderboard()
            else
                if score ~= nil then
                    _gs:setCallback(function()
                        _gs:submitScore(score)
                        _gs:showLeaderboard()
                    end)
                end
                _gs:login(true)
            end
        end
    end

    local leaderboardButton = widget.newButton(
        {
            onEvent = leaderboardButtonEvent,
            shape = "roundedRect",
            x = -75,
            y = 0,
            width = 40,
            height = 40,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    buttonsGroup:insert(leaderboardButton)
    local shadow = display.newRoundedRect(buttonsGroup, leaderboardButton.x, leaderboardButton.y+3, 40, 40, 10)
    shadow:setFillColor(144/255,215/255,244/255)
    leaderboardButton:toFront()
    local leaderboard = display.newSprite(buttonsGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("leaderboard")}})
    -- local leaderboard = display.newImageRect(buttonsGroup, "leaderboard.png", 30, 30)
    leaderboard.x, leaderboard.y = leaderboardButton.x, leaderboardButton.y

    local function purchaseListener(product, transaction)
        if (product=="removeAds") then
            --Remove the ads
            _ads:remove()
            --Save the inventory
            _iap.saveInventory()
            --Tell the user the ads have been removed
            showMessage("Purchase complete. Ads removed!", 5000)
            -- Show confetti
            showConfetti()
            -- Hide the nav bar
            setImmersive()
        end
    end

    local function removeAdsButtonEvent( event )
        if ( "ended" == event.phase ) then
            if _ads:areRemoved() then
                showMessage("Ads are already removed!")
            else
                --Make the purchase
                _iap.purchase("removeAds", purchaseListener)
            end
        end
    end

    local removeAdsButton = widget.newButton(
        {
            onEvent = removeAdsButtonEvent,
            shape = "roundedRect",
            x = 75,
            y = 0,
            width = 40,
            height = 40,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    buttonsGroup:insert(removeAdsButton)
    local shadow = display.newRoundedRect(buttonsGroup, removeAdsButton.x, removeAdsButton.y+3, 40, 40, 10)
    shadow:setFillColor(144/255,215/255,244/255)
    removeAdsButton:toFront()
    local removeAds = display.newSprite(buttonsGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("remove-ads")}})
    -- local removeAds = display.newImageRect(buttonsGroup, "remove-ads.png", 28, 28)
    removeAds.x, removeAds.y = removeAdsButton.x, removeAdsButton.y

    local function rateButtonEvent( event )
        if ( "ended" == event.phase ) then
            local platform = system.getInfo("platform")
            if (platform == "android") then  -- Android
                system.openURL( "https://play.google.com/store/apps/details?id=com.robbieelias.ozone" )
            elseif (platform == "ios" ) then  --iOS
                system.openURL( "https://apps.apple.com/app/id1477671851" ) -- TODO
            end
        end
    end

    local rateButton = widget.newButton(
        {
            onEvent = rateButtonEvent,
            shape = "roundedRect",
            x = 130,
            y = 0,
            width = 40,
            height = 40,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    buttonsGroup:insert(rateButton)
    local shadow = display.newRoundedRect(buttonsGroup, rateButton.x, rateButton.y+3, 40, 40, 10)
    shadow:setFillColor(144/255,215/255,244/255)
    rateButton:toFront()
    local rate = display.newSprite(buttonsGroup, _g.objectsImageSheet, {frames={_g.objectsSheetInfo:getFrameIndex("rate")}})
    -- local rate = display.newImageRect(buttonsGroup, "rate.png", 28, 28)
    rate.x, rate.y = rateButton.x, rateButton.y

    local function infoButtonEvent( event )
        if ( "ended" == event.phase ) then
            composer.showOverlay( "scenes.info", {isModal = true, effect = "fromLeft", time = 400})
        end
    end

    local infoButton = widget.newButton(
        {
            label = "?",
            font = _g.fontMain,
            fontSize = 32,
            labelColor = { default={1,1,1}, over={1,1,1} },
            onEvent = infoButtonEvent,
            shape = "roundedRect",
            x = -130,
            y = 0,
            width = 40,
            height = 40,
            cornerRadius = 10,
            fillColor = { default={_g.buttonColor[1],_g.buttonColor[2],_g.buttonColor[3]}, over={_g.buttonColorPressed[1],_g.buttonColorPressed[2],_g.buttonColorPressed[3]} },
        }
    )
    buttonsGroup:insert(infoButton)
    local shadow = display.newRoundedRect(buttonsGroup, infoButton.x, infoButton.y+3, 40, 40, 10)
    shadow:setFillColor(144/255,215/255,244/255)
    infoButton:toFront()
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

        bgClouds.isVisible = true
        earth.alpha = 1
        -- transition.to( earth, { alpha = 1, time = 500 } )
        earth.transition = transition.to( earth, { time = 20000, rotation = earth.rotation+360, iterations = 0 } )
        -- bgClouds.transition = transition.to( bgClouds, { alpha = 1, time = 500 } )
        -- Move earth to where it should be
        earth.y = earth.menuY
        bgClouds.y = bgClouds.menuY

        sceneGroup:insert(earth)
        sceneGroup:insert(bgClouds)

        -- If there are any params, that means it's game over, and we need to show the game stats
        if event.params ~= nil then
            score = event.params.score
            scoreText.text = score
            levelText.text = "#" .. event.params.level
            highScoreText.text = _data:get("highScore")
            gamesPlayedText.text = _data:get("gamesPlayed")
            highestLevelText.text = "#" .. _data:get("highestLevel")
            gameOverGroup.isVisible = true
            logoText.isVisible = false

            if event.params.isHighScore then
                gameOverText.text = "HIGH SCORE"
            else
                gameOverText.text = "GAME OVER"
            end
        else
            score = nil
            gameOverGroup.isVisible = false
            logoText.isVisible = true

            if not _gdpr.hasResponded() then
                composer.showOverlay( "scenes.gdpr", {isModal = true, effect = "fromLeft", time = 400})
            end
        end
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        
        -- Show confetti
        if event.params ~= nil then
            -- Show ad
            -- Show confetti if high score
            local callback = nil
            if event.params.isHighScore then
                callback = function()
                    showConfetti()
                end
            end

            if _ads:showInterstitial() then
                if callback ~= nil then
                    _ads:setInterstitialCallback(callback)
                end
            else
                if callback ~= nil then
                    callback()
                end
            end
        end
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

        if backPressed then
            hideMessage()
            backPressed = false
        end
 
        display.getCurrentStage():insert(earth)
        display.getCurrentStage():insert(bgClouds)
        if _g.messageGroup then
            _g.messageGroup:toFront()
        end
    elseif ( phase == "did" ) then
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