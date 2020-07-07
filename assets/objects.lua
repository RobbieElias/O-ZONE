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
            y=256,
            width=320,
            height=120,

        },
        {
            -- bg-separator
            x=0,
            y=90,
            width=320,
            height=67,

        },
        {
            -- cannon
            x=60,
            y=29,
            width=17,
            height=33,

        },
        {
            -- continue
            x=170,
            y=0,
            width=161,
            height=22,

        },
        {
            -- crown
            x=332,
            y=0,
            width=40,
            height=26,

        },
        {
            -- earth
            x=321,
            y=165,
            width=90,
            height=90,

        },
        {
            -- finger
            x=296,
            y=29,
            width=50,
            height=50,

        },
        {
            -- leaderboard
            x=29,
            y=29,
            width=30,
            height=30,

        },
        {
            -- leaf
            x=78,
            y=29,
            width=36,
            height=38,

        },
        {
            -- logo-text
            x=0,
            y=165,
            width=320,
            height=86,

        },
        {
            -- meteor
            x=201,
            y=29,
            width=43,
            height=46,

        },
        {
            -- ozone
            x=115,
            y=29,
            width=42,
            height=42,

        },
        {
            -- play
            x=347,
            y=29,
            width=60,
            height=60,

        },
        {
            -- rate
            x=0,
            y=29,
            width=28,
            height=28,

        },
        {
            -- remove-ads
            x=373,
            y=0,
            width=28,
            height=28,

        },
        {
            -- rocket
            x=321,
            y=256,
            width=63,
            height=124,

        },
        {
            -- satellite1
            x=0,
            y=0,
            width=84,
            height=20,

        },
        {
            -- satellite2
            x=85,
            y=0,
            width=84,
            height=20,

        },
        {
            -- ship
            x=321,
            y=90,
            width=47,
            height=74,

        },
        {
            -- star
            x=158,
            y=29,
            width=42,
            height=42,

        },
        {
            -- ufo
            x=245,
            y=29,
            width=50,
            height=49,

        },
    },

    sheetContentWidth = 411,
    sheetContentHeight = 380
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
