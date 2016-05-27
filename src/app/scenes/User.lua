--[[
    玩家信息类
        记录一些公共数据
--]]

User = {}

User.againCount = 0 -- 洗牌数,每过三关加1
User.tipCount   = 0 -- 提示数,每过一关加1
User.score      = 0 -- 分数
User.rankDatas  = {} -- 玩家的排行榜信息

User.initMode = function(mode)
    User.againCount = Const.MODE[mode].AGAIN_COUNT
    User.tipCount   = Const.MODE[mode].TIP_COUNT
    User.score      = 0
end

User.useAgainChance = function()
    User.againCount = User.againCount - 1
    EventMgr.triggerEvent(EventConst.REFRESH_BUTTON_LABEL)
end

User.addAgainChance = function()
    User.againCount = User.againCount + 1
end

User.getAgainChance = function()
    return User.againCount
end

User.useTipChance = function()
    User.tipCount = User.tipCount - 1
    EventMgr.triggerEvent(EventConst.REFRESH_BUTTON_LABEL)
end

User.addTipChance = function()
    User.tipCount = User.tipCount + 1
end

User.getTipChance = function()
    return User.tipCount
end

User.addScore = function(score)
    User.score = User.score + score
end

User.getScore = function()
    return User.score
end

User.getRankData = function(mode, level)
    return User.rankDatas[mode][level]
end

User.setRankData = function(mode, level, name, score)
    User.rankDatas[mode][level] = {name = name, score = score}
end

User.getRankLevelByScore = function(mode, score)
    for i = 1, 3 do
        if User.rankDatas[mode][i].score < score then
            table.insert(User.rankDatas[mode], i, {})
            return i
        end
    end

    return nil
end

-- 默认开始就初始化排行榜信息
for mode = 1, 3 do
    User.rankDatas[mode] = {}
    for level = 1, 3 do
        local rankData = {}
        rankData.name = cc.UserDefault:getInstance():getStringForKey(string.format("Rank%d_%d_Name", mode, level), "等你来战")
        rankData.score = cc.UserDefault:getInstance():getIntegerForKey(string.format("Rank%d_%d_Score", mode, level), 0)

        User.rankDatas[mode][level] = rankData
    end
end
