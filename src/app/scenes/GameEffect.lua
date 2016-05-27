--[[
    每一关的不同变化
    目前是固定的
        第0关  不变化     NoneGameEffect
        第1关  向下       MoveDownEffect
        第2关  向左       MoveLeftEffect
        第3关  上下分离   UpDownOutEffect
        第4关  左右分离   LeftRightOutEffect
        第5关  上下集中   UpDownInEffect
        第6关  左右集中   LeftRightInEffect
        第7关  上左下右   UpToLeftDownToRightEffect
        第8关  左下右上   LeftToDownRightToUpEffect
        第9关  向外扩散   MoveOutEffect
        第10关 向内集中   MoveInEffect
--]]

-- 负责方块的真实move行为
local makeRealChange = function(changeNodeCount, nodes, ROWS, COLS, callback)
    if changeNodeCount == 0 and callback then
        callback()
        return
    end

    for row = 1, ROWS do
        for col = 1, COLS do
            if nodes[row][col].toPosition then
                transition.execute(nodes[row][col], cca.moveTo(0.3, nodes[row][col].toPosition), {
                    onComplete = function()
                        nodes[row][col].toPosition = nil
                        changeNodeCount = changeNodeCount - 1
                        if changeNodeCount <= 0 then
                            printInfo("所有的方块已经完成了移动变化")
                            if callback then
                                callback()
                            end
                        end
                    end
                })
            end
        end
    end
end

--[[
    node交换
        1、目的坐标交换，不能在这里，因为moveTo还需要时间执行，坐标在运行中可能不对
        2、需要交换位置之前，更新好行列坐标
        3、交换在nodes表中的真正位置
--]]
local swapNode = function(nodes, row1, col1, row2, col2)
    printInfo(string.format("发生了交换,(%d, %d) <-> (%d, %d)", row1, col1, row2, col2))
    
    local toPos1 = nodes[row2][col2].toPosition or cc.p(nodes[row2][col2]:getPosition())
    local toPos2 = nodes[row1][col1].toPosition or cc.p(nodes[row1][col1]:getPosition())
    
    nodes[row1][col1].toPosition, nodes[row2][col2].toPosition = toPos1, toPos2
    nodes[row1][col1].row, nodes[row1][col1].col = row2, col2
    nodes[row2][col2].row, nodes[row2][col2].col = row1, col1

    nodes[row1][col1], nodes[row2][col2] = nodes[row2][col2], nodes[row1][col1]
end

-- 不变化
NoneGameEffect = function(nodes, ROWS, COLS, callback)
    if callback then
        callback()
    end
end

-- 向下变化
MoveDownEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    for col = 1, COLS do
        for row = 1, ROWS do
            if nodes[row][col].num == -1 then
                local nextRow = row + 1
                while nextRow <= ROWS do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end
                    
                    nextRow = nextRow + 1
                end

                if nextRow == ROWS + 1 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 向左变化
MoveLeftEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    for row = 1, ROWS do
        for col = 1, COLS do
            if nodes[row][col].num == -1 then
                local nextCol = col + 1
                while nextCol <= COLS do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol + 1
                end

                if nextCol == COLS + 1 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove  then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 上下分离
UpDownOutEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    local HALF_ROWS = math.ceil(ROWS / 2)

    -- 上分离
    for col = 1, COLS do
        for row = ROWS, HALF_ROWS + 1, -1 do
            if nodes[row][col].num == -1 then
                local nextRow = row - 1
                while nextRow > HALF_ROWS do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow - 1
                end

                if nextRow == HALF_ROWS then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 下分离
    for col = 1, COLS do
        for row = 1, HALF_ROWS do
            if nodes[row][col].num == -1 then
                local nextRow = row + 1
                while nextRow <= HALF_ROWS do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow + 1
                end

                if nextRow == HALF_ROWS + 1 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 左右分离
LeftRightOutEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    local HALF_COLS = math.ceil(COLS / 2)

    -- 左分离
    for row = 1, ROWS do
        for col = 1, HALF_COLS do
            if nodes[row][col].num == -1 then
                local nextCol = col + 1
                while nextCol <= HALF_COLS do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol + 1
                end

                if nextCol == HALF_COLS + 1 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 右分离
    for row = 1, ROWS do
        for col = COLS, HALF_COLS + 1, -1 do
            if nodes[row][col].num == -1 then
                local nextCol = col - 1
                while nextCol > HALF_COLS do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol - 1
                end

                if nextCol == HALF_COLS then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 上下集中
UpDownInEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = 0
    local HALF_ROWS = math.ceil(ROWS / 2)

    -- 上集中
    for col = 1, COLS do
        for row = HALF_ROWS + 1, ROWS do
            if nodes[row][col].num == -1 then
                local nextRow = row + 1
                while nextRow <= ROWS do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow + 1
                end

                if nextRow == ROWS + 1 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 下集中
    for col = 1, COLS do
        for row = HALF_ROWS, 1, -1 do
            if nodes[row][col].num == -1 then
                local nextRow = row - 1
                while nextRow >= 1 do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow - 1
                end

                if nextRow == 0 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 左右集中
LeftRightInEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    local HALF_COLS = math.ceil(COLS / 2)

    -- 左集中
    for row = 1, ROWS do
        for col = HALF_COLS, 1, -1 do
            if nodes[row][col].num == -1 then
                local nextCol = col - 1
                while nextCol >= 1 do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol - 1
                end

                if nextCol == 0 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 右集中
    for row = 1, ROWS do
        for col = HALF_COLS + 1, COLS do
            if nodes[row][col].num == -1 then
                local nextCol = col + 1
                while nextCol <= COLS do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol + 1
                end

                if nextCol == COLS + 1 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 上左下右
UpToLeftDownToRightEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    local HALF_ROWS = math.ceil(ROWS / 2)

    -- 上左
    for row = 1, HALF_ROWS do
        for col = COLS, 1, -1 do
            if nodes[row][col].num == -1 then
                local nextCol = col - 1
                while nextCol >= 1 do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol - 1
                end

                if nextCol == 0 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 下右
    for row = HALF_ROWS + 1, ROWS do
        for col = 1, COLS do
            if nodes[row][col].num == -1 then
                local nextCol = col + 1
                while nextCol <= COLS do
                    if nodes[row][nextCol].num ~= -1 then
                        break
                    end
                    
                    nextCol = nextCol + 1
                end

                if nextCol == COLS + 1 then
                    break
                end

                swapNode(nodes, row, col, row, nextCol)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 左下右上
LeftToDownRightToUpEffect = function(nodes, ROWS, COLS, callback, dontMove, changeNodeCount)
    local changeNodeCount = changeNodeCount or 0
    local HALF_COLS = math.ceil(COLS / 2)

    -- 左下
    for col = 1, HALF_COLS do
        for row = 1, ROWS do
            if nodes[row][col].num == -1 then
                local nextRow = row + 1
                while nextRow <= ROWS do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow + 1
                end

                if nextRow == ROWS + 1 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    -- 右上
    for col = HALF_COLS + 1, COLS do
        for row = ROWS, 1, -1 do
            if nodes[row][col].num == -1 then
                local nextRow = row - 1
                while nextRow >= 1 do
                    if nodes[nextRow][col].num ~= -1 then
                        break
                    end

                    nextRow = nextRow - 1
                end

                if nextRow == 0 then
                    break
                end

                swapNode(nodes, row, col, nextRow, col)
                changeNodeCount = changeNodeCount + 1
            end
        end
    end

    if not dontMove then
        makeRealChange(changeNodeCount, nodes, ROWS, COLS, callback)
    end

    return changeNodeCount
end

-- 向外扩散
MoveOutEffect = function(nodes, ROWS, COLS, callback)
    local changeNodeCount = UpDownOutEffect(nodes, ROWS, COLS, nil, true)
    LeftRightOutEffect(nodes, ROWS, COLS, callback, false, changeNodeCount)
end

-- 向内集中
MoveInEffect = function(nodes, ROWS, COLS, callback)
    local changeNodeCount = UpDownInEffect(nodes, ROWS, COLS, nil, true)
    LeftRightInEffect(nodes, ROWS, COLS, callback, false, changeNodeCount)
end