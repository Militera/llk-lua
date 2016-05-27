--[[
    游戏记录界面
--]]

local RecordLayer = class("RecordLayer", function()
    return display.newColorLayer(cc.c4b(0, 0, 0, 100))
end)

RecordLayer.ctor = function(self, mode, level, callback)
    local curScene = display.getRunningScene()
    curScene:addChild(self)

    local titleLabel = display.newTTFLabel({text = "记录您的大名吧！英雄", size = 72, color = cc.c3b(0x99, 0xf2, 0x4c)})
    titleLabel:align(display.CENTER, display.cx, display.height * 0.7)
    titleLabel:addTo(self)
    self.titleLabel = titleLabel

    local onEdit = function(event, editbox)
        if event == "began" then
        elseif event == "changed" then
        elseif event == "ended" then
        elseif event == "return" then
            User.setRankData(mode, level, editbox:getText(), User.getScore())
            cc.UserDefault:getInstance():setStringForKey(string.format("Rank%d_%d_Name", mode, level), editbox:getText())
            cc.UserDefault:getInstance():setIntegerForKey(string.format("Rank%d_%d_Score", mode, level), User.getScore())

            if callback then
                callback()
            end
        end
    end

    local editbox = cc.ui.UIInput.new({image = "buttonNormal.png", listener = onEdit, size = cc.size(300, 80)})
    editbox:align(display.CENTER, display.cx, display.cy)
    editbox:addTo(self)
end

return RecordLayer