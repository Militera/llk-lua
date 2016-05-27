--[[
    主菜单
--]]
WinLayer = import(".WinLayer")
MainmenuScene = class("MainmenuScene", function()
    return display.newScene("MainmenuScene")
end)

MainmenuScene.ctor = function(self)
    -- 添加一个纯色背景
    display.newColorLayer(cc.c4b(0x24, 0x2c, 0x3c, 255)):addTo(self)

    self:initTitle()
    self:initMenu()
    self:initRankPages()
end

MainmenuScene.initTitle = function(self)
    local titleFontSize = 60
    local titleColors = {cc.c3b(0xff, 0x30, 0x30), cc.c3b(0xff, 0x82, 0x47), cc.c3b(0xee, 0xc9, 0x0), cc.c3b(0xb4, 0x52, 0xcd), cc.c3b(0x71, 0xc6, 0x71)}
    local titlePositions = {cc.p(50, 50), cc.p(150, 50), cc.p(250, 50), cc.p(350, 50), cc.p(450, 50)}
    local titleLabel = {"精", "灵", "连", "连", "看"}
    local titleNode = display.newNode()
    titleNode:size(500, 100)
    titleNode:align(display.CENTER, display.cx, display.height * 0.85)
    titleNode:addTo(self)

    for i, v in ipairs(titleLabel) do
        local label = cc.ui.UILabel.new({text = v, size = titleFontSize, color = titleColors[i], font = Const.FONT})
        label:align(display.CENTER, titlePositions[i].x, titlePositions[i].y)
        label:addTo(titleNode)
        label.index = i

        label:runAction(cca.loop(transition.sequence({cca.delay(0.7), cca.cb(function()
            label.index = label.index + 1
            if label.index > 5 then
                label.index = 1
            end

            label:setColor(titleColors[label.index])
        end)})))

    end
end

MainmenuScene.initMenu = function(self)
    local menuNode = display.newNode()
    menuNode:align(display.CENTER, display.cx / 2, display.cy)
    menuNode:size(220, 300)
    menuNode:addTo(self)

    local buttonFontSize = 36
    local buttonSize = {w = 200, h = 60}
    local createButton = function(x, y, text, mode, parent)
        local button = cc.ui.UIPushButton.new({normal = "buttonNormal.png"})
        button:setButtonSize(buttonSize.w, buttonSize.h)
        button:align(display.CENTER, x, y)
        button:addTo(parent)

        button:onButtonClicked(function()
            button:runAction(transition.sequence({cca.scaleTo(0.2, 1.2), cca.scaleTo(0.2, 1), cca.cb(function()
                local newScene = require("app.scenes.GameScene").new(mode)
                display.replaceScene(newScene)
            end)}))
        end)

        button:setButtonLabel(cc.ui.UILabel.new({text = text, size = buttonFontSize, font = Const.FONT, color = cc.c3b(0xb3, 0xee, 0x3a)}))
    end

    createButton(100, 210, "初级难度", 1, menuNode)
    createButton(100, 130, "中级难度", 2, menuNode)
    createButton(100, 50, "高级难度", 3, menuNode)
end

MainmenuScene.initRankPages = function(self)
    local rankNode = display.newNode()
    rankNode:align(display.CENTER, display.cx * 1.3, display.cy)
    rankNode:size(400, 300)
    rankNode:addTo(self)

    local rankTitleSprite = display.newSprite("rank.png")
    rankTitleSprite:align(display.LEFT_CENTER, 0, 150)
    rankTitleSprite:addTo(rankNode)

    local rankPages = cc.ui.UIListView.new({
        -- bgColor = cc.c4b(200, 200, 200, 120),
        viewRect = cc.rect(0, 0, 400, 300),
        direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
    })

    rankPages:addTo(rankNode)
    rankPages:align(display.LEFT_CENTER, 60, 0)

    for i = 1, 3 do
        local pageNode = self:createRankPage(i)
        local item = rankPages:newItem()
        item:addContent(pageNode)
        item:setItemSize(300, 300)
        rankPages:addItem(item)
    end

    rankPages:reload()
end

MainmenuScene.createRankPage = function(self, mode)
    local rankPageNode = display.newNode()
    rankPageNode:setContentSize(280, 280)

    local titleLabel = cc.ui.UILabel.new({text = Const.MODE[mode].NAME, size = 36, font = Const.FONT, color = cc.c3b(0x43, 0x7e, 0x3a)})
    titleLabel:align(display.CENTER, 140, 240)
    titleLabel:addTo(rankPageNode)

    local createRank = function(level, x, y)
        for i = 1, level do
            display.newSprite(string.format("star%d.png", mode)):pos(x, y):addTo(rankPageNode)
            x = x + 15
        end

        local rankData = User.getRankData(mode, 4 - level)
        local nameLabel = display.newTTFLabel({text = rankData.name, size = 24})
        nameLabel:align(display.CENTER, 120, y)
        nameLabel:addTo(rankPageNode)

        local scoreLabel = cc.ui.UILabel.new({text = rankData.score, size = 24, font = Const.FONT, color = cc.c3b(0xff, 0x7e, 0x3a)})
        scoreLabel:align(display.CENTER, 220, y)
        scoreLabel:addTo(rankPageNode)
    end

    createRank(3, 20, 190)
    createRank(2, 30, 120)
    createRank(1, 40, 50)
    return rankPageNode
end

MainmenuScene.onEnter = function(self)
    printInfo("进入MainmenuScene")
end

MainmenuScene.onExit = function(self)
    printInfo("离开MainmenuScene")
end

return MainmenuScene