--[[
    游戏失败界面
--]]

local START_Y           = -100
local END_Y             = display.height / 3
local ACTION_DURATION   = 0.4
local BUTTON_SIZE       = 160

local LoseLayer = class("LoseLayer", function()
    return display.newColorLayer(cc.c4b(0, 0, 0, 100))
end)

LoseLayer.ctor = function(self)
    local curScene = display.getRunningScene()
    curScene:addChild(self)

    local loseSprite = display.newSprite("lose.png")
    local loseSpriteSize = loseSprite:getContentSize()
    loseSprite:setScale(500 / loseSpriteSize.width, 150 / loseSpriteSize.height)
    loseSprite:align(display.CENTER, display.cx, display.height * 0.7)
    loseSprite:opacity(0)
    loseSprite:addTo(self)
    self.loseSprite = loseSprite

    local restartButton = cc.ui.UIPushButton.new({normal = "again.png"}, {scale9 = true})
    restartButton:setButtonSize(BUTTON_SIZE, BUTTON_SIZE)
    restartButton:align(display.CENTER, display.cx - 100, START_Y)
    restartButton:onButtonClicked(function(event)
        self:onLayerLeave(EventConst.GAME_RESTART)
    end)
    restartButton:addTo(self)
    self.restartButton = restartButton

    local backToMainMenuButton = cc.ui.UIPushButton.new({normal = "levelSelect.png"}, {scale9 = true})
    backToMainMenuButton:setButtonSize(BUTTON_SIZE, BUTTON_SIZE)
    backToMainMenuButton:align(display.CENTER, display.cx + 100, START_Y)
    backToMainMenuButton:onButtonClicked(function(event)
        self:onLayerLeave(EventConst.BACK_TO_MAINMENU)
    end)
    backToMainMenuButton:addTo(self)
    self.backToMainMenuButton = backToMainMenuButton

    self:onLayerEnter()
end

LoseLayer.onLayerEnter = function(self)
    self.restartButton:setButtonEnabled(false)
    self.backToMainMenuButton:setButtonEnabled(false)

    self.restartButton:moveTo(ACTION_DURATION, display.cx - 100, END_Y)
    self.backToMainMenuButton:moveTo(ACTION_DURATION, display.cx + 100, END_Y)

    self.loseSprite:fadeIn(ACTION_DURATION)

    self:performWithDelay(function()
        self.restartButton:setButtonEnabled(true)
        self.backToMainMenuButton:setButtonEnabled(true)
    end, ACTION_DURATION)
end

LoseLayer.onLayerLeave = function(self, eventType)
    self.restartButton:setButtonEnabled(false)
    self.backToMainMenuButton:setButtonEnabled(false)

    self.restartButton:moveTo(ACTION_DURATION, display.cx - 100, START_Y)
    self.backToMainMenuButton:moveTo(ACTION_DURATION, display.cx + 100, START_Y)

    self.loseSprite:fadeOut(ACTION_DURATION)

    self:performWithDelay(function()
        self:removeSelf()

        EventMgr.triggerEvent(eventType)
    end, ACTION_DURATION)
end

return LoseLayer