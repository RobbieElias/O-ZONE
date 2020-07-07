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
            y=512,
            width=640,
            height=240,

        },
        {
            -- bg-separator
            x=0,
            y=180,
            width=640,
            height=134,

        },
        {
            -- cannon
            x=120,
            y=58,
            width=34,
            height=66,

        },
        {
            -- continue
            x=340,
            y=0,
            width=322,
            height=44,

        },
        {
            -- crown
            x=664,
            y=0,
            width=80,
            height=52,

        },
        {
            -- earth
            x=642,
            y=330,
            width=180,
            height=180,

        },
        {
            -- finger
            x=592,
            y=58,
            width=100,
            height=100,

        },
        {
            -- leaderboard
            x=58,
            y=58,
            width=60,
            height=60,

        },
        {
            -- leaf
            x=156,
            y=58,
            width=72,
            height=76,

        },
        {
            -- logo-text
            x=0,
            y=330,
            width=640,
            height=172,

        },
        {
            -- meteor
            x=402,
            y=58,
            width=86,
            height=92,

        },
        {
            -- ozone
            x=230,
            y=58,
            width=84,
            height=84,

        },
        {
            -- play
            x=694,
            y=58,
            width=120,
            height=120,

        },
        {
            -- rate
            x=0,
            y=58,
            width=56,
            height=56,

        },
        {
            -- remove-ads
            x=746,
            y=0,
            width=56,
            height=56,

        },
        {
            -- rocket
            x=642,
            y=512,
            width=126,
            height=248,

        },
        {
            -- satellite1
            x=0,
            y=0,
            width=168,
            height=40,

        },
        {
            -- satellite2
            x=170,
            y=0,
            width=168,
            height=40,

        },
        {
            -- ship
            x=642,
            y=180,
            width=94,
            height=148,

        },
        {
            -- star
            x=316,
            y=58,
            width=84,
            height=84,

        },
        {
            -- ufo
            x=490,
            y=58,
            width=100,
            height=98,

        },
    },

    sheetContentWidth = 822,
    sheetContentHeight = 760
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
