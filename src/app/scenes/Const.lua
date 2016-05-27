--[[
    游戏中的全部常亮放在这里
--]]

require("app.scenes.GameEffect")

Const = {}

Const.MODE = {
    -- 初级, 1-11关, 7*12盘面, 洗牌数2, 提示4
    {
        NAME            = "初级",
        ROWS            = 7,
        COLS            = 12,
        AGAIN_COUNT     = 2,
        TIP_COUNT       = 4,
        BLOCK_WIDTH     = 0,
        BLOCK_HEIGHT    = 0,
        LEFT_PADDING    = 0,
        RIGHT_PADDING   = 0,
        TOP_PADDING     = 0,
        BOTTOM_PADDING  = 0,
    },
    -- 中级, 1-11关, 8*14盘面, 洗牌数3, 提示6
    {
        NAME            = "中级",
        ROWS            = 8,
        COLS            = 14,
        AGAIN_COUNT     = 3,
        TIP_COUNT       = 6,
        BLOCK_WIDTH     = 0,
        BLOCK_HEIGHT    = 0,
        LEFT_PADDING    = 0,
        RIGHT_PADDING   = 0,
        TOP_PADDING     = 0,
        BOTTOM_PADDING  = 0,
    },
    -- 高级, 1-11关, 9*16盘面, 洗牌数4, 提示8
    {
        NAME            = "高级",
        ROWS            = 9,
        COLS            = 16,
        AGAIN_COUNT     = 4,
        TIP_COUNT       = 7,
        BLOCK_WIDTH     = 0,
        BLOCK_HEIGHT    = 0,
        LEFT_PADDING    = 0,
        RIGHT_PADDING   = 0,
        TOP_PADDING     = 0,
        BOTTOM_PADDING  = 0,
    },
}

for _, v in ipairs(Const.MODE) do
    v.BLOCK_WIDTH       = math.floor(display.width / (v.COLS + 2))
    v.BLOCK_HEIGHT      = math.floor(display.height / (v.ROWS + 2))

    v.LEFT_PADDING      = v.BLOCK_WIDTH
    v.RIGHT_PADDING     = v.BLOCK_WIDTH
    v.TOP_PADDING       = v.BLOCK_HEIGHT
    v.BOTTOM_PADDING    = v.BLOCK_HEIGHT - 20
end

Const.LEVEL_DESCS = {
    "不变化",
    "向下变化",
    "向左变化",
    "上下分离",
    "左右分离",
    "上下集中",
    "左右集中",
    "上左下右",
    "左下右上",
    "向外扩散",
    "向内集中",
}

Const.LEVEL_GAME_EFFECTS = {
    NoneGameEffect,
    MoveDownEffect,
    MoveLeftEffect,
    UpDownOutEffect,
    LeftRightOutEffect,
    UpDownInEffect,
    LeftRightInEffect,
    UpToLeftDownToRightEffect,
    LeftToDownRightToUpEffect,
    MoveOutEffect,
    MoveInEffect,
}

Const.MAX_LEVEL     = #Const.LEVEL_GAME_EFFECTS
Const.TOTAL_TIME    = 240 -- 每关总时间
Const.WARNING_TIME  = 20 -- 临界时间，进入这个时间，就开始闪动提醒

Const.FONT          = "fonts/MYuppy-Bold-DDC.ttf"