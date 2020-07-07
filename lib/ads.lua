--Static instances of the ads class
local ads = {}

-- Lib
local appodeal
local _g = require("lib.globalVariables")

-- Variables
local isSetup = false
local isValidDevice = true
if ( system.getInfo( "environment" ) ~= "device" ) then isValidDevice = false end

local show = true
local timeBetweenAds = 120
local lastShowTime = os.time()
local interstitialCallback = nil
local rewardsCallback = nil
local rewardFinished = false

local appKey
local platform = system.getInfo("platform")
if (platform == "android") then  -- Android
	appKey = "***REMOVED***"
elseif (platform == "ios" ) then  --iOS
	appKey = "***REMOVED***"
end

--  app event handler 
local function adListener(event)
    print("ads: adListener:addDid trigger listener event")
   
  	-- Exit function if user hasn't set up testing parameters
	if (isValidDevice == false) then return end
	
	if ( event.phase == "init" ) then
		print( "Appodeal event: initialization successful" ) 
	    isSetup = true
	elseif ( event.phase == "loaded" ) then
		print( "Appodeal event: " .. tostring(event.type) .. " ad loaded successfully" )
	-- The ad was displayed/played
	elseif ( event.phase == "displayed" or event.phase == "playbackBegan" ) then
		print( "Appodeal event: " .. tostring(event.type) .. " ad displayed" )
	-- The ad was closed/hidden
	elseif ( event.phase == "hidden" or event.phase == "closed") then
		print( "Appodeal event: " .. tostring(event.type) .. " ad closed/hidden" )

		if event.type == "rewardedVideo" then
			if rewardsCallback then
				rewardsCallback(rewardFinished)
				rewardsCallback = nil
				rewardFinished = false
			end
		elseif event.type == "interstitial" then
			if interstitialCallback then
				interstitialCallback()
				interstitialCallback = nil
			end
		end

		lastShowTime = os.time()
	-- The ad was completed
	elseif ( event.phase == "playbackEnded" ) then
		print( "Appodeal event: " .. tostring(event.type) .. " ad completed" )
		rewardFinished = true
		lastShowTime = os.time()
	-- The user clicked/tapped an ad
	elseif ( event.phase == "clicked" ) then
		print( "Appodeal event: " .. tostring(event.type) .. " ad clicked/tapped" )
	-- The ad failed to load
	elseif ( event.phase == "failed" ) then
		print( "Appodeal event: " .. tostring(event.type) .. " ad failed to load" )
	end
end

--Check Test Mode before app submission
function ads:init(hasUserConsent)
	if hasUserConsent then
		print("ADS INIT CALLED: TRUE")
	else
		print("ADS INIT CALLED: FALSE")
	end
	if (isValidDevice == false) then return end

	appodeal = require("plugin.appodeal")

	appodeal.init(adListener, { 
	    appKey=appKey, 
	    testMode=_g.debug,
	    supportedAdTypes = {"interstitial", "rewardedVideo"},
	    hasUserConsent = hasUserConsent
	})
end

function ads:setRewardsCallback(func)
	rewardsCallback = func
end

function ads:setInterstitialCallback(func)
	interstitialCallback = func
end

function ads:showInterstitial()
	if (isValidDevice == false) then return false end

	local timeSinceLastShow = os.time() - lastShowTime

    if show and timeSinceLastShow >= timeBetweenAds and appodeal.canShow("interstitial") then
        appodeal.show("interstitial")
        lastShowTime = os.time()
        return true
    end

    return false
end

function ads:canShowReward()
	if (isValidDevice == false) then return false end
	if show then
		return appodeal.canShow("rewardedVideo")
	else
		return true
	end
end

function ads:showReward()
	if (isValidDevice == false) then return false end

	if show and appodeal.canShow("rewardedVideo") then
		appodeal.show("rewardedVideo")
		rewardFinished = false
		lastShowTime = os.time()
		return true
	end
	return false
end

function ads:remove()
	show = false
	appodeal = nil
end

function ads:areRemoved()
	return not show
end

return ads