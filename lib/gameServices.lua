local gs = {}

-- Required libraries
local json = require( "json" )
local _g = require("lib.globalVariables")

local platform = system.getInfo( "platform" )
local env = system.getInfo( "environment" )
local userInitiated = false
local callback = nil

local leaderboardId
 
if ( platform == "android" and env ~= "simulator" ) then
    gs.gpgs = require( "plugin.gpgs.v2" )
    gs.gameCenter = nil
    leaderboardId = "CgkIntj3kaALEAIQAQ"
elseif ( platform == "ios" and env ~= "simulator" ) then
    gs.gameCenter = require( "gameNetwork" )
    gs.gpgs = nil
    leaderboardId = "high_score_ozone"
end

-- Google Play Games Services initialization/login listener
local function gpgsInitListener( event )
    if event.isError then
        if userInitiated then
            showMessage("Error logging in to Google Play Games")
        end
    else
        if ( event.name == "login" ) then  -- Successful login event
            print( json.prettify(event) )
            if callback then
                callback()
            end
        end
    end

    callback = nil
end
 
-- Apple Game Center initialization/login listener
local function gcInitListener( event )
    if event.data then  -- Successful login event
        print( json.prettify(event) )
        if callback then
            callback()
        end
    else
        if userInitiated then
            showMessage("Error logging in to Game Center")
        end
    end

    callback = nil
end

local function submitScoreListener( event )
    print("Game Services: New High Score")
    -- -- Google Play Games Services score submission
    -- if ( gs.gpgs ) then
 
    --     if not event.isError then
    --         local isBest = nil
    --         if ( event.scores["daily"].isNewBest ) then
    --             isBest = "a daily"
    --         elseif ( event.scores["weekly"].isNewBest ) then
    --             isBest = "a weekly"
    --         elseif ( event.scores["all time"].isNewBest ) then
    --             isBest = "an all time"
    --         end
    --         if isBest then
    --             -- Congratulate player on a high score
    --             local message = "You set " .. isBest .. " high score!"
    --             -- native.showAlert( "Congratulations", message, { "OK" } )
    --         else
    --             -- Encourage the player to do better
    --             -- native.showAlert( "Sorry...", "Better luck next time!", { "OK" } )
    --         end
    --     end
 
    -- -- Apple Game Center score submission
    -- elseif ( gs.gameCenter ) then
 
    --     if ( event.type == "setHighScore" ) then
    --         -- Congratulate player on a high score
    --         native.showAlert( "Congratulations", "You set a high score!", { "OK" } )
    --     else
    --         -- Encourage the player to do better
    --         native.showAlert( "Sorry...", "Better luck next time!", { "OK" } )
    --     end
    -- end
end

function gs:login(byUser)
    userInitiated = byUser or false
	-- Initialize game network based on platform
	if ( gs.gpgs ) then
        -- Initialize Google Play Games Services
        if _g.debug then
            gs.gpgs.enableDebug()
        end
        gs.gpgs.login( { userInitiated=userInitiated, listener=gpgsInitListener } )
	elseif ( gs.gameCenter ) then
        -- Initialize Apple Game Center
        gs.gameCenter.init( "gamecenter", gcInitListener )
	else
		print("Can't login to games services on this platform")
	end
end

function gs:logout()
    if ( gs.gpgs ) then
        gs.gpgs.logout()
    elseif ( gs.gameCenter ) then
        
    else
        print("Can't login to games services on this platform")
    end
end

function gs:isLoggedIn()
    if ( gs.gpgs ) then
        return gs.gpgs.isConnected()
    elseif ( gs.gameCenter ) then
        return true
    end

    return false
end

function gs:showLeaderboard()
    if ( gs.gpgs ) then
        gs.gpgs.leaderboards.show(leaderboardId)
    elseif ( gs.gameCenter ) then
        gs.gameCenter.show( "leaderboards",
        {
            leaderboard = {
                category = leaderboardId
            }
        })
    end
end

function gs:submitScore(score)
 
    if ( gs.gpgs ) then
        -- Submit a score to Google Play Games Services
        gs.gpgs.leaderboards.submit(
        {
            leaderboardId = leaderboardId,
            score = score,
            listener = submitScoreListener
        })
 
    elseif ( gs.gameCenter ) then
        -- Submit a score to Apple Game Center
        gs.gameCenter.request( "setHighScore",
        {
            localPlayerScore = {
                category = leaderboardId,
                value = score
            },
            listener = submitScoreListener
        })
    end
end

function gs:setCallback(func)
    callback = func
end

return gs