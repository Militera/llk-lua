scheduler       = require("framework.scheduler")
NumberScroller  = require("app.ui.NumberScrollerReverse")
LoseLayer       = require("app.scenes.LoseLayer")
WinLayer        = require("app.scenes.WinLayer")
RecordLayer     = require("app.scenes.RecordLayer")
MainmenuScene   = require("app.scenes.MainmenuScene")

local GameScene = class("GameScene", function()
    return display.newScene("GameScene")
end)

GameScene.ctor = function(self, mode, level)
    -- 添加一个纯色背景
    display.newColorLayer(cc.c4b(0x24, 0x2c, 0x3c, 255)):addTo(self)

    self.level          = level or 1
    self.mode           = mode or 1
    
    self.ROWS           = Const.MODE[self.mode].ROWS
    self.COLS           = Const.MODE[self.mode].COLS
    self.BLOCK_WIDTH    = Const.MODE[self.mode].BLOCK_WIDTH
    self.BLOCK_HEIGHT   = Const.MODE[self.mode].BLOCK_HEIGHT
    self.LEFT_PADDING   = Const.MODE[self.mode].LEFT_PADDING
    self.BOTTOM_PADDING = Const.MODE[self.mode].BOTTOM_PADDING
    self.TOP_PADDING    = Const.MODE[self.mode].TOP_PADDING
    self.RIGHT_PADDING  = Const.MODE[self.mode].RIGHT_PADDING

    if self.level == 1 then
        User.initMode(self.mode)
    end

    self:initGameData()
    self:initGameEffect()
    self:initTopLayer()
end

GameScene.onEnter = function(self)
    printInfo("进入GameScene，准备注册事件")

    self.handlers = {
        [EventConst.GAME_OVER]              = handler(self, self.gameOver),
        [EventConst.GAME_WIN]               = handler(self, self.gameWin),
        [EventConst.GAME_RESTART]           = handler(self, self.gameRestart),
        [EventConst.REFRESH_BUTTON_LABEL]   = handler(self, self.refreshButtonLabel),
        [EventConst.LEVEL_NEXT]             = handler(self, self.levelNext),
        [EventConst.BACK_TO_MAINMENU]       = handler(self, self.backToMainmenu),
    }

    for k, v in pairs(self.handlers) do
        EventMgr.registerEvent(k, v)
    end

    EventMgr.triggerEvent(EventConst.SCENE_ENTER)
end

GameScene.onExit = function(self)
    printInfo("离开GameScene，准备反注册事件")

    for k, v in pairs(self.handlers) do
        EventMgr.unregisterEvent(k, v)
    end

    self.handlers = nil

    if self.timerHandler then
        scheduler.unscheduleGlobal(self.timerHandler)
        self.timerHandler = nil
    end

    EventMgr.triggerEvent(EventConst.SCENE_EXIT)
end

GameScene.initGameData = function(self)
    -- 设置随机种子
    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()
    math.random()

    self.totalBlockCounts = self.ROWS * self.COLS

    local blockNums = {}
    for i = 1, self.ROWS * self.COLS / 2 do
        local random = math.random(39)
        table.insert(blockNums, random)
        table.insert(blockNums, random)
    end

    local newBlockNums = {}
    for row = 1, self.ROWS do
        for col = 1, self.COLS do
            local newIndex = math.random(#blockNums)
            table.insert(newBlockNums, blockNums[newIndex])
            table.remove(blockNums, newIndex)
        end
    end

    if DEBUG == 1 then
        -- 测试数据
        -- self.ROWS = 6
        -- self.COLS = 12
        -- newBlockNums = {
        --  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        --  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        --  -1, -1, -1, -1, 3,  2,  -1, -1, -1, -1, -1, -1,
        --  -1, -1, -1, -1, 3,  2,  -1, -1, -1, -1, -1, -1,
        --  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        --  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -- }
        -- self.totalBlockCounts = 4
    end

    -- 为了获取缩放比例
    local node0 = display.newSprite("#majiang_0.png")
    local size = node0:getContentSize()
    local xScale = self.BLOCK_WIDTH / size.width
    local yScale = self.BLOCK_HEIGHT / size.height

    self.nodes = {}
    for row = 1, self.ROWS do
        self.nodes[row] = {}

        for col = 1, self.COLS do
            local x = (col - 0.5) * self.BLOCK_WIDTH + self.LEFT_PADDING
            local y = (row - 0.5) * self.BLOCK_HEIGHT + self.BOTTOM_PADDING

            local index = (row - 1) * self.COLS + col
            local num = newBlockNums[index]
            local node
            if num == -1 then
                -- 以后就可以设计地图了
                node = display.newSprite()
                node:hide()
            else
                node = display.newSprite(string.format("#majiang_%d.png", num))
            end

            node.num, node.row, node.col = num, row, col
            node:pos(x, y)
            node:setScale(xScale, yScale)
            node:addTo(self)
            self.nodes[row][col] = node
            
            node.highlight = function()
                local touchSprite = display.newSprite("#majiang_touched.png")
                touchSprite:align(display.LEFT_BOTTOM)
                touchSprite:addTo(node)
                touchSprite:setName("touched")
            end

            node.removeHighlight = function()
                node:removeChildByName("touched")
            end

            node.reset = function()
                printInfo("方块(%d, %d), 取消高亮，同时重置为－1，设置为不可见", node.row, node.col)
                node.removeHighlight()
                node:hide()
                node.num = -1
            end

            node:setTouchEnabled(true)
            node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
                if self.isPlayingEffect then
                    printInfo("播放动画，本次点击无效，直接返回")
                    return
                end

                printInfo("[row:%d, col:%d] is pressed, the clicked index is :%d", node.row, node.col, index)

                if not self.preClickedNode then
                    printInfo("点击的第一个方块")

                    node.highlight()
                    self.preClickedNode = node
                elseif self.preClickedNode == node then
                    printInfo("点击的是同一个方块，消去黄色边框")

                    self.preClickedNode.removeHighlight()
                    self.preClickedNode = nil
                else
                    printInfo("点击的第二个方块")

                    node.highlight()

                    if self.preClickedNode.num ~= node.num then
                        printInfo("不可以消去，以当前点中方块作为第一个方块")

                        self.preClickedNode.removeHighlight()
                        self.preClickedNode = node

                        return
                    end

                    self.linkLines = {}
                    if self:hasPath(self.preClickedNode.row, self.preClickedNode.col, node.row, node.col) then
                        table.insert(self.linkLines, 1, cc.p(self.preClickedNode:getPosition()))
                        table.insert(self.linkLines, cc.p(node:getPosition()))

                        printInfo("可以消去, 播放消去动画，0.2秒以后，删除两个黄色边框")

                        self.isPlayingEffect = true

                        self:showLinkLine(function()
                            node.reset()
                            self.preClickedNode.reset()
                            self.preClickedNode = nil

                            -- 这里需要清除，因为启动的游戏特效有可能会导致这里面的匹配对无效
                            self.foundTipPairs = {}

                            self.isPlayingEffect = false

                            -- 增加游戏分数，默认消除一对＋100分
                            User.addScore(100)
                            self.scoreLabel:setString(User.getScore())
                            self.scoreLabel:runAction(transition.sequence({cca.scaleTo(0.2, 1.2), cca.scaleTo(0.2, 1)}))

                            -- 1、检查好游戏是否胜利
                            self.totalBlockCounts = self.totalBlockCounts - 2
                            if self.totalBlockCounts <= 0 then
                                EventMgr.triggerEvent(EventConst.GAME_WIN)
                                return
                            end

                            -- 2、检查游戏是否还有方块可以消除，没有则重置地图
                            local isFind = self:findTip(nil, false, true)
                            if not isFind then
                                if User.getAgainChance() <= 0 then
                                    showTip("找不到可以消去的方块对, 没有洗牌机会", cc.c3b(0xff, 0x14, 0x93))
                                    showTip("1秒后游戏结束", cc.c3b(0xff, 0x14, 0x93))
                                    self:performWithDelay(function()
                                        EventMgr.triggerEvent(EventConst.GAME_OVER)
                                    end, 1)
                                else
                                    self:performWithDelay(function()
                                        self:resetMap()
                                    end, 2)
                                end
                            else
                                -- 启动关卡游戏特效
                                self.gameEffect(self.nodes, self.ROWS, self.COLS)
                            end
                        end)
                    else
                        printInfo("不可以消去, 播放消去动画，0.2秒以后，删除两个黄色边框")

                        self.isPlayingEffect = true
                        node:performWithDelay(function()
                            node.removeHighlight()
                            self.preClickedNode.removeHighlight()
                            self.preClickedNode = nil

                            self.isPlayingEffect = false
                        end, 0.2)
                    end
                end
            end)
        end
    end

    for row = 0, self.ROWS + 1 do
        self.nodes[row] = self.nodes[row] or {}
        for col = 0, self.COLS + 1 do
            if not self.nodes[row][col] then
                printInfo(string.format("生成外围看不到的那一圈方块,(%d, %d)", row, col))
                local node = {}
                node.num = -1
                node.getPosition = function(node)
                    local x = (col - 0.5) * self.BLOCK_WIDTH + self.LEFT_PADDING
                    local y = (row - 0.5) * self.BLOCK_HEIGHT + self.BOTTOM_PADDING
                    -- 上下坐标修正，让上下的中心点内聚，以容纳其他内容（下方广告条，上方的进度条和各种按钮）
                    if row == self.ROWS + 1 then
                        y = y - 20
                    elseif row == 0 then
                        y = y + 20
                    end

                    return x, y
                end

                self.nodes[row][col] = node
            end
        end
    end
end

GameScene.initGameEffect = function(self)
    self.gameEffect = Const.LEVEL_GAME_EFFECTS[self.level]
end

GameScene.initTopLayer = function(self)
    local topLayer = display.newNode()
    topLayer:align(display.CENTER, display.cx, display.height - self.TOP_PADDING / 2)
    topLayer:addTo(self)
    self.topLayer = topLayer

    local buttonFontSize = 24
    local buttonSize = self.BLOCK_WIDTH * 0.7
    local buttonIsPressed = false
    local createButton = function(image, x, callback, labelText)
        local button = cc.ui.UIPushButton.new({normal = image})
        button:setButtonSize(buttonSize, buttonSize)
        button:align(display.CENTER, x, 0)
        button:addTo(topLayer)

        button:onButtonClicked(function()
            if buttonIsPressed then
                printInfo("有按钮正在响应，此次点击无效")
                return
            end

            buttonIsPressed = true
            button:setButtonEnabled(false)

            button:runAction(transition.sequence({cca.scaleTo(0.2, 1.2), cca.scaleTo(0.2, 1), cca.cb(function()
                callback(function()
                    buttonIsPressed = false
                    button:setButtonEnabled(true)
                end)
            end)}))
        end)
        
        if labelText then
            button:setButtonLabel(cc.ui.UILabel.new({text = labelText, size = buttonFontSize, color = cc.c3b(0xb3, 0xee, 0x3a)}))
            button:setButtonLabelOffset(buttonFontSize * 1.3, 0)
        end

        return button
    end

    -- 都是一些坐标计算，烦~
    local buttonX, buttonOffset = display.width / 3, buttonSize * 1.5
    self.resetMapButton = createButton("resetMap.png", buttonX + buttonOffset, handler(self, self.resetMap), User.getAgainChance() .. "")
    
    local tipCallback = function(callback)
        self:findTip(function(isFind)
            if not isFind then
                if User.getAgainChance() <= 0 then
                    showTip("找不到可以消去的方块对, 没有洗牌机会", cc.c3b(0xff, 0x14, 0x93))
                    showTip("1秒后游戏结束", cc.c3b(0xff, 0x14, 0x93))
                    self:performWithDelay(function()
                        EventMgr.triggerEvent(EventConst.GAME_OVER)
                    end, 1)
                else
                    self:performWithDelay(function()
                        self:resetMap(callback)
                    end, 2)
                end
            else
                callback()
            end
        end)
    end
    self.tipButton = createButton("tip.png", buttonX, tipCallback, User.getTipChance() .. "")

    if DEBUG == 1 then
        self.autoPairButton = createButton("autoPair.png", buttonX - buttonOffset, handler(self, self.autoPair))
    end

    local fontSize = 24
    local labelY = fontSize / 2
    local modeLabel = cc.ui.UILabel.new({text = "难度：" .. string.rep("I", self.mode), size = fontSize})--, font = Const.FONT})
    modeLabel:align(display.LEFT_CENTER, display.c_left + self.LEFT_PADDING, labelY)
    modeLabel:addTo(topLayer)
    
    local levelLabel = cc.ui.UILabel.new({text = "关卡：" .. self.level, size = fontSize, font = Const.FONT})
    levelLabel:align(display.LEFT_CENTER, modeLabel:getPositionX() + modeLabel:getContentSize().width * 1.2, labelY)
    levelLabel:addTo(topLayer)

    local gameEffectLabel = cc.ui.UILabel.new({text = Const.LEVEL_DESCS[self.level], size = fontSize, font = Const.FONT, color = cc.c3b(153, 204, 255)})
    gameEffectLabel:align(display.LEFT_CENTER, levelLabel:getPositionX() + levelLabel:getContentSize().width * 1.2, labelY)
    gameEffectLabel:addTo(topLayer)
    
    local totalTime = Const.TOTAL_TIME
    local timeCounterLabel = cc.ui.UILabel.new({text = string.format("%03d", totalTime), font = Const.FONT, size = fontSize * 2, color = display.COLOR_RED})
    timeCounterLabel:align(display.CENTER, 0, 0)
    timeCounterLabel:addTo(topLayer)
    self.timeCounterLabel = timeCounterLabel

    self.timerHandler = scheduler.scheduleGlobal(function(dt)
        if self.pauseFlag then
            return
        end

        totalTime = totalTime - 1
        timeCounterLabel:setString(string.format("%03d", totalTime))

        if totalTime <= Const.WARNING_TIME then
            -- 最后20秒，时间抖动警示
            timeCounterLabel:runAction(transition.sequence({cca.scaleTo(0.2, 1.2), cca.scaleTo(0.2, 1)}))
        end

        if totalTime <= 0 then
            timeCounterLabel:stop()
            EventMgr.triggerEvent(EventConst.GAME_OVER)
        end
    end, 1)

    local scoreDescLabel = cc.ui.UILabel.new({text = "分数：", size = fontSize * 1.2, font = Const.FONT}):align(display.RIGHT_TOP, -display.width / 4, -fontSize / 2):addTo(topLayer)
    local scoreLabel = cc.ui.UILabel.new({text = User.getScore(), size = fontSize * 1.2, color = cc.c3b(0xff, 0xf6, 0x8f)})
    scoreLabel:align(display.LEFT_TOP, scoreDescLabel:getPositionX(), -fontSize / 2)
    scoreLabel:addTo(topLayer)
    self.scoreLabel = scoreLabel

    topLayer.setDisabled = function()
        self.resetMapButton:setButtonEnabled(false)
        self.tipButton:setButtonEnabled(false)
        if DEBUG == 1 then
            self.autoPairButton:setButtonEnabled(false)
        end

        self.pauseFlag = true

        if self.timerHandler then
            scheduler.unscheduleGlobal(self.timerHandler)
            self.timerHandler = nil
        end
    end
end

GameScene.hasPath = function(self, row1, col1, row2, col2)
    printInfo("进行水平直连消除测试")
    if self:hasHorizontalPath(row1, col1, row2, col2) then
        printInfo("水平直连成功：(%d, %d) -> (%d, %d)", row1, col1, row2, col2)
        return true
    end

    printInfo("进行竖直直连消除测试")
    if self:hasVerticalPath(row1, col1, row2, col2) then
        printInfo("竖直直连成功：(%d, %d) -> (%d, %d)", row1, col1, row2, col2)
        return true
    end

    printInfo("进行一个拐角消除测试")
    if self:hasOneCornerPath(row1, col1, row2, col2) then
        printInfo("一个拐角成功：(%d, %d) -> (%d, %d)", row1, col1, row2, col2)
        return true
    end

    printInfo("进行两个拐角消除测试")
    if self:hasTwoCornerPath(row1, col1, row2, col2) then
        printInfo("两个拐角成功：(%d, %d) -> (%d, %d)", row1, col1, row2, col2)
        return true
    end 

    return false
end

GameScene.hasHorizontalPath = function(self, row1, col1, row2, col2)
    if row1 ~= row2 or col1 == col2 then
        printInfo("不位于同一行，或者就是同一个方块，后者是在一个拐角或者两个拐角情况下出现的")
        return false
    end

    if row1 == 0 or row1 == (self.ROWS + 1) then
        printInfo("外围的那一行一律视作可以匹配")
        return true
    end

    if col1 > col2 then
        for col = col2 + 1, col1 - 1 do
            if self.nodes[row1][col].num ~= -1 then
                return false
            end
        end
    else
        for col = col1 + 1, col2 - 1 do
            if self.nodes[row1][col].num ~= -1 then
                return false
            end
        end
    end

    return true
end

GameScene.hasVerticalPath = function(self, row1, col1, row2, col2)
    if col1 ~= col2 or row1 == row2 then
        printInfo("不位于同一列，或者就是同一个方块，后者是在一个拐角或者两个拐角情况下出现的")
        return false
    end

    if col1 == 0 or col1 == (self.COLS + 1) then
        printInfo("外围的那一列一律视作可以匹配")
        return true
    end

    if row1 > row2 then
        for row = row2 + 1, row1 - 1 do
            if self.nodes[row][col1].num ~= -1 then
                return false
            end
        end
    else
        for row = row1 + 1, row2 - 1 do
            if self.nodes[row][col1].num ~= -1 then
                return false
            end
        end
    end

    return true
end

GameScene.hasOneCornerPath = function(self, row1, col1, row2, col2)
    local cornerNode = self.nodes[row1][col2]
    printInfo("尝试第一个拐角(%d, %d):%d", row1, col2, cornerNode.num)
    if cornerNode.num == -1 and self:hasHorizontalPath(row1, col1, row1, col2) and self:hasVerticalPath(row1, col2, row2, col2) then
        table.insert(self.linkLines, cc.p(cornerNode:getPosition()))
        printInfo("第一个拐角即可进行联通，测试成功")
        return true
    end

    cornerNode = self.nodes[row2][col1]
    printInfo("尝试第二个拐角(%d, %d):%d", row2, col1, cornerNode.num)
    if cornerNode.num == -1 and self:hasHorizontalPath(row2, col2, row2, col1) and self:hasVerticalPath(row2, col1, row1, col1) then
        table.insert(self.linkLines, cc.p(cornerNode:getPosition()))
        printInfo("第二个拐角即可进行联通，测试成功")
        return true
    end

    return false
end

GameScene.hasTwoCornerPath = function(self, row1, col1, row2, col2)
    printInfo("进行向上两拐角测试")
    for row = row1 + 1, self.ROWS + 1 do
        if self.nodes[row][col1].num ~= -1 then
            break
        elseif self:hasOneCornerPath(row, col1, row2, col2) then
            table.insert(self.linkLines, 1, cc.p(self.nodes[row][col1]:getPosition()))
            printInfo("向上两拐角测试成功(%d, %d) -> (%d, %d)", row, col1, row2, col2)
            return true
        end
    end

    printInfo("进行向下两拐角测试")
    for row = row1 - 1, 0, -1 do
        if self.nodes[row][col1].num ~= -1 then
            break
        elseif self:hasOneCornerPath(row, col1, row2, col2) then
            table.insert(self.linkLines, 1, cc.p(self.nodes[row][col1]:getPosition()))
            printInfo("向下两拐角测试成功(%d, %d) -> (%d, %d)", row, col1, row2, col2)
            return true
        end
    end

    printInfo("进行向左两拐角测试")
    for col = col1 - 1, 0, -1 do
        if self.nodes[row1][col].num ~= -1 then
            break
        elseif self:hasOneCornerPath(row1, col, row2, col2) then
            table.insert(self.linkLines, 1, cc.p(self.nodes[row1][col]:getPosition()))
            printInfo("向左两拐角测试成功(%d, %d) -> (%d, %d)", row1, col, row2, col2)
            return true
        end
    end

    printInfo("进行向右两拐角测试")
    for col = col1 + 1, self.COLS + 1 do
        if self.nodes[row1][col].num ~= -1 then
            break
        elseif self:hasOneCornerPath(row1, col, row2, col2) then
            table.insert(self.linkLines, 1, cc.p(self.nodes[row1][col]:getPosition()))
            printInfo("向右两拐角测试成功(%d, %d) -> (%d, %d)", row1, col, row2, col2)
            return true
        end
    end

    return false
end

GameScene.showLinkLine = function(self, callback)
    local drawNodes = {}
    for i = 1, #self.linkLines - 1 do
        local drawNode = cc.NVGDrawNode:create()
        drawNode:setLineWidth(10)
        drawNode:addTo(self)
        drawNode:drawLine(self.linkLines[i], self.linkLines[i + 1], cc.c4f(0.92, 0.84, 0, 1))
        table.insert(drawNodes, drawNode)
    end

    self:performWithDelay(function()
        callback()

        table.walk(drawNodes, function(v)
            v:removeSelf()
        end)

        self.linkLines = nil
    end, 0.2)
end

GameScene.resetMap = function(self, callback, isNotUseAgainChance)
    if self.preClickedNode then
        self.preClickedNode.removeHighlight()
        self.preClickedNode = nil
    end

    local newPos = {}
    for i = 1, self.ROWS * self.COLS do
        newPos[i] = i
    end

    local moveDone = 0 -- 用来记录已经完成了多少个方块的move行为
    local newNodes = {}
    for row = 1, self.ROWS do
        for col = 1, self.COLS do
            local newIndex = math.random(#newPos)
            local newRow = math.ceil(newPos[newIndex] / self.COLS)
            local newCol = newPos[newIndex] % self.COLS + 1
            table.remove(newPos, newIndex)

            printInfo("新位置产生(%d, %d) -> (%d, %d)", row, col, newRow, newCol)

            local node = self.nodes[row][col]
            transition.execute(node, cca.moveTo(0.3, cc.p(self.nodes[newRow][newCol]:getPosition())), {
                onComplete = function()
                    moveDone = moveDone + 1
                    if moveDone >= self.ROWS * self.COLS then
                        printInfo("所有的方块已经移动完成，可以继续开启本关的移动效果")
                        self.gameEffect(self.nodes, self.ROWS, self.COLS, function()
                            if callback then
                                callback()
                            end

                            if not isNotUseAgainChance then
                                -- 主要用于自动消去时不减少次数
                                User.useAgainChance()
                            end

                            self.foundTipPairs = {} -- 地图重置，清空已经找到过的方块对
                        end)
                    end
                end
            })

            newNodes[newRow] = newNodes[newRow] or {}
            newNodes[newRow][newCol] = node
        end
    end

    for row = 1, self.ROWS do
        for col = 1, self.COLS do
            self.nodes[row][col] = newNodes[row][col]
            self.nodes[row][col].row = row
            self.nodes[row][col].col = col
        end
    end
end

--[[
    找到一对可以消去的方块
        成功返回true和匹配节点对
        失败返回false
    callback表示找到以后，动画播放结束时的回调
    isNotUseTipChance，表示不减少提示次数，用于debug中的自动匹配
    noAnimation，表示不要动画，这个会导致匹配成功时，callback不执行，不过这里无碍，因为主动消去一对方块时，不会传递callback
--]]
GameScene.findTip = function(self, callback, isNotUseTipChance, noAnimation)
    if self.preClickedNode then
        self.preClickedNode:removeChildByName("touched")
        self.preClickedNode = nil
    end

    -- 用来缓存已经找到过的匹配对，来保证每次tip的都不是相同的块，在地图重置的时候清空
    self.foundTipPairs = self.foundTipPairs or {}
    -- 这里需要初始化下着玩意，中间有用到
    self.linkLines = {}

    -- 这个用来播放匹配对动画
    local runPairAnimation = function(pairNode)
        local tintDone = 0 -- 用于记录是否两个匹配节点都闪动结束

        for _, v in ipairs(pairNode) do
            local tint = cca.tintBy(0.3, -200, -200, -200)
            local tintBack = tint:reverse()
            v:runAction(transition.sequence({tint, tintBack, cca.callFunc(function()
                tintDone = tintDone + 1
                if tintDone == #pairNode and callback then
                    callback(true, pairNode)

                    if not isNotUseTipChance then
                        -- 主要为了兼容自动消去，不使用提示
                        User.useTipChance()
                    end
                end
            end)}))
        end
    end

    -- local tintDone = 0 -- 用于记录是否两个匹配节点都闪动结束
    local pairNodes = {}
    for i = 1, self.ROWS * self.COLS do
        pairNodes[1] = self.nodes[math.ceil(i / self.COLS)][i % self.COLS + 1]
        if pairNodes[1].num ~= -1 then
            for j = 1, self.ROWS * self.COLS do
                pairNodes[2] = self.nodes[math.ceil(j / self.COLS)][j % self.COLS + 1]

                -- 判断是否为已经找到过的方块对
                local isHadFound = false
                for _, v in ipairs(self.foundTipPairs) do
                    if (v[1] == pairNodes[1] and v[2] == pairNodes[2]) or (v[1] == pairNodes[2] or v[2] == pairNodes[1]) then
                        isHadFound = true
                        break
                    end
                end

                -- 需要忽略同一个节点的情况
                if not isHadFound and pairNodes[1] ~= pairNodes[2] and pairNodes[2].num == pairNodes[1].num then
                    printInfo("尝试tip节点：(%d, %d):%d & (%d, %d):%d", pairNodes[1].row, pairNodes[1].col, pairNodes[1].num, pairNodes[2].row, pairNodes[2].col, pairNodes[2].num)

                    if self:hasPath(pairNodes[1].row, pairNodes[1].col, pairNodes[2].row, pairNodes[2].col) then
                        -- 缓存已经找到的块
                        table.insert(self.foundTipPairs, {pairNodes[1], pairNodes[2]})

                        -- 仅用于主动点击之后，查找是否还有匹配对，用于游戏检查是否结束，所以不需要动画
                        if not noAnimation then
                            runPairAnimation(pairNodes)
                        end

                        printInfo("找到了可以消去的方块对了")
                        return true, pairNodes
                    end

                end
            end
        end
    end

    local tipPairsLen = table.nums(self.foundTipPairs)
    if tipPairsLen ~= 0 then
        printInfo("其实还是有提示匹配对的，只是全部被缓存起来了~")
        printInfo("这里随机返回一对匹配对")
        
        local randomPairs = self.foundTipPairs[math.random(tipPairsLen)]
        runPairAnimation(randomPairs)

        return
    end
    
    printInfo("找不到可以消去的方块对")

    showTip("找不到可以消去的方块对, 2秒后重置地图", cc.c3b(0xff, 0x14, 0x93))

    if callback then
        callback(false)

        if not isNotUseTipChance then
            -- 主要为了兼容自动消去，不使用提示
            User.useTipChance()
        end
    end

    return false
end

-- 自动消去一对方块
GameScene.autoPair = function(self, callback)
    -- 自动消去属于调试状态，不需要缓存这玩意
    self.foundTipPairs = {}

    self:findTip(function(isFind, pairNodes)
        if isFind then
            table.insert(self.linkLines, 1, cc.p(pairNodes[1]:getPosition()))
            table.insert(self.linkLines, cc.p(pairNodes[2]:getPosition()))

            self:showLinkLine(function()
                for _, v in ipairs(pairNodes) do
                    v:hide()
                    v.num = -1
                end

                self.linkLines = nil

                printInfo("启动关卡游戏特效")
                self.gameEffect(self.nodes, self.ROWS, self.COLS, callback)

                self.totalBlockCounts = self.totalBlockCounts - 2
                if self.totalBlockCounts <= 0 then
                    EventMgr.triggerEvent(EventConst.GAME_WIN)
                end
            end)
        else
            printInfo("自动消去失败，没有可消去的方块了，直接重置方块")
            self:performWithDelay(function()
                self:resetMap(callback, true)
            end, 2)
        end
    end, true)
end

GameScene.gameOver = function(self)
    printInfo("游戏结束")

    for row = 1, self.ROWS do
        for col = 1, self.COLS do
            self.nodes[row][col]:setTouchEnabled(false)
        end
    end

    self.topLayer.setDisabled()
    LoseLayer.new()
end

GameScene.gameWin = function(self)
    printInfo("游戏胜利")

    -- 每关过后增加的固定分数
    User.addScore(self.level + 100)
    -- 时间换算分数，每秒20分
    User.addScore(tonumber(self.timeCounterLabel:getString()) * 20)
    self.scoreLabel:setString(User.getScore())
    self.scoreLabel:runAction(transition.sequence({cca.scaleTo(0.2, 1.2), cca.scaleTo(0.2, 1)}))

    self.topLayer.setDisabled()
    WinLayer.new()
end

GameScene.gameRestart = function(self)
    printInfo("重新开始，继续第一关")

    local newScene = GameScene.new(self.mode, 1)
    display.replaceScene(newScene)
end

-- 主要用来刷新洗牌次数和提示次数的
GameScene.refreshButtonLabel = function(self)
    self.resetMapButton:setButtonLabelString(User.getAgainChance() .. "")
    if User.getAgainChance() <= 0 then
        self.resetMapButton:setButtonEnabled(false)
    end

    if User.getAgainChance() < 0 then
        EventMgr.triggerEvent(EventConst.GAME_OVER)
    end

    self.tipButton:setButtonLabelString(User.getTipChance() .. "")
    if User.getTipChance() <= 0 then
        self.tipButton:setButtonEnabled(false)
    end
end

GameScene.levelNext = function(self)
    printInfo("进入到下一关，%d", self.level + 1)

    if self.level + 1 > Const.MAX_LEVEL then
        showTip("厉害啊，全部通关")

        local level = User.getRankLevelByScore(self.mode, User.getScore())
        if level then
            printInfo("弹出输入框，准备记录下名字，列入排行榜，然后切入到主菜单中去")
            RecordLayer.new(self.mode, level, function()
                local newScene = MainmenuScene.new()
                display.replaceScene(newScene)
            end)
        else
            showTip("未创新高，再接再厉！！！")
            self:performWithDelay(function()
                local newScene = MainmenuScene.new()
                display.replaceScene(newScene)
            end, 1)
        end

        return
    end

    printInfo("提示数,每过一关加1")
    User.addTipChance()

    if self.level % 3 == 0 then
        printInfo("洗牌数,每过三关加1")
        User.addAgainChance()
    end

    local newScene = GameScene.new(self.mode, self.level + 1)
    display.replaceScene(newScene)
end

GameScene.backToMainmenu = function(self)
    printInfo("这里需要直接切入到主菜单场景")

    local newScene = MainmenuScene.new()
    display.replaceScene(newScene)
end

return GameScene