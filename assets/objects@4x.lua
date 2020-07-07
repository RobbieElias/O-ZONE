--
-- created with TexturePacker - https://www.codeandweb.com/texturepacker
--
-- $TexturePacker:SmartUpdate:cadcfe307a1eb19417de4d4c0dcda166:1e2a9027e60fc70d48b2e90cb500a164:1784b3470aad1b82bb9f03684bcf642d$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- bg-clouds
            x=0,
            y=1024,
            width=1280,
            height=480,

        },
        {
            -- bg-separator
            x=0,
            y=360,
            width=1280,
            height=268,

        },
        {
            -- cannon
            x=240,
            y=116,
            width=68,
            height=132,

        },
        {
            -- continue
            x=680,
            y=0,
            width=644,
            height=88,

        },
        {
            -- crown
            x=1328,
            y=0,
            width=160,
            height=104,

        },
        {
            -- earth
            x=1284,
            y=660,
            width=360,
            height=360,

        },
        {
            -- finger
            x=1184,
            y=116,
            width=200,
            height=200,

        },
        {
            -- leaderboard
            x=116,
            y=116,
            width=120,
            height=120,

        },
        {
            -- leaf
            x=312,
            y=116,
            width=144,
            height=152,

        },
        {
            -- logo-text
            x=0,
            y=660,
            width=1280,
            height=344,

        },
        {
            -- meteor
            x=804,
            y=116,
            width=172,
            height=184,

        },
        {
            -- ozone
            x=460,
            y=116,
            width=168,
            height=168,

        },
        {
            -- play
            x=1388,
            y=116,
            width=240,
            height=240,

        },
        {
            -- rate
            x=0,
            y=116,
            width=112,
            height=112,

        },
        {
            -- remove-ads
            x=1492,
            y=0,
            width=112,
            height=112,

        },
        {
            -- rocket
            x=1284,
            y=1024,
            width=252,
            height=496,

        },
        {
            -- satellite1
            x=0,
            y=0,
            width=336,
            height=80,

        },
        {
            -- satellite2
            x=340,
            y=0,
            width=336,
            height=80,

        },
        {
            -- ship
            x=1284,
            y=360,
            width=188,
            height=296,

        },
        {
            -- star
            x=632,
            y=116,
            width=168,
            height=168,

        },
        {
            -- ufo
            x=980,
            y=116,
            width=200,
            height=196,

        },
    },

    sheetContentWidth = 1644,
    sheetContentHeight = 1520
}

SheetInfo.frameIndex =
{

    ["bg-clouds"] = 1,
    ["bg-separator"] = 2,
    ["cannon"] = 3,
    ["continue"] = 4,
    ["crown"] = 5,
    ["earth"] = 6,
    ["finger"] = 7,
    ["leaderboard"] = 8,
    ["leaf"] = 9,
    ["logo-text"] = 10,
    ["meteor"] = 11,
    ["ozone"] = 12,
    ["play"] = 13,
    ["rate"] = 14,
    ["remove-ads"] = 15,
    ["rocket"] = 16,
    ["satellite1"] = 17,
    ["satellite2"] = 18,
    ["ship"] = 19,
    ["star"] = 20,
    ["ufo"] = 21,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
