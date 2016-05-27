--[[
    游戏胜利界面
--]]

local START_Y           = -100
local END_Y             = display.height / 3
local ACTION_DURATION   = 0.4
local BUTTON_SIZE       = 160

local WinLayer = class("WinLayer", function()
    return display.newColorLayer(cc.c4b(0, 0, 0, 100))
end)

WinLayer.ctor = function(self)
    local curScene = display.getRunningScene()
    curScene:addChild(self)

    local winSprite = display.newSprite("win.png")
    local winSpriteSize = winSprite:getContentSize()
    winSprite:setScale(500 / winSpriteSize.width, 150 / winSpriteSize.height)
    winSprite:align(display.CENTER, display.cx, display.height * 0.7)
    winSprite:opacity(0)
    winSprite:addTo(self)
    self.winSprite = winSprite

    local levelNextButton = cc.ui.UIPushButton.new({normal = "again.png"}, {scale9 = true})
    levelNextButton:setButtonSize(BUTTON_SIZE, BUTTON_SIZE)
    levelNextButton:align(display.CENTER, display.cx, START_Y)
    levelNextButton:onButtonClicked(function(event)
        self:onLayerLeave(EventConst.LEVEL_NEXT)
    end)
    levelNextButton:addTo(self)
    self.levelNextButton = levelNextButton

    local backToMainMenuButton = cc.ui.UIPushButton.new({normal = "levelSelect.png"}, {scale9 = true})
    backToMainMenuButton:setButtonSize(BUTTON_SIZE, BUTTON_SIZE)
    backToMainMenuButton:align(display.CENTER, display.cx + 200, START_Y)
    backToMainMenuButton:onButtonClicked(function(event)
        self:onLayerLeave(EventConst.BACK_TO_MAINMENU)
    end)
    backToMainMenuButton:addTo(self)
    self.backToMainMenuButton = backToMainMenuButton

    self:onLayerEnter()
end

WinLayer.onLayerEnter = function(self)
    self.levelNextButton:setButtonEnabled(false)
    self.backToMainMenuButton:setButtonEnabled(false)

    self.levelNextButton:moveTo(ACTION_DURATION, display.cx - 100, END_Y)
    self.backToMainMenuButton:moveTo(ACTION_DURATION, display.cx + 100, END_Y)

    self.winSprite:fadeIn(ACTION_DURATION)

    self:performWithDelay(function()
        self.levelNextButton:setButtonEnabled(true)
        self.backToMainMenuButton:setButtonEnabled(true)
    end, ACTION_DURATION)
end

WinLayer.onLayerLeave = function(self, eventType)
    self.levelNextButton:setButtonEnabled(false)
    self.backToMainMenuButton:setButtonEnabled(false)

    self.levelNextButton:moveTo(ACTION_DURATION, display.cx - 100, START_Y)
    self.backToMainMenuButton:moveTo(ACTION_DURATION, display.cx + 100, START_Y)

    self.winSprite:fadeOut(ACTION_DURATION)

    self:performWithDelay(function()
        self:removeSelf()

        EventMgr.triggerEvent(eventType)
    end, ACTION_DURATION)
end

return WinLayer