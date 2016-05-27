--[[
    事件管理器
--]]

EventConst = {}

EventConst.SCENE_EXIT           = "sceneExit"
EventConst.SCENE_ENTER          = "sceneEnter"
EventConst.GAME_OVER            = "gameOver"
EventConst.GAME_WIN             = "gameWin"
EventConst.GAME_RESTART         = "gameRestart"
EventConst.LEVEL_NEXT           = "levelNext"
EventConst.REFRESH_BUTTON_LABEL = "refreshButtonLabel"
EventConst.BACK_TO_MAINMENU     = "backToMainmenu"

EventMgr = {}

EventMgr.registerEvent = function(eventType, callback, priority, ...)
    if not eventType then
        Logger.error("事件类型为空！！！")
    end

    if type(callback) ~= "function" then
        Logger.error("没有对应的事件触发回调处理！！！")
        return
    end

    local eventCallback = {
        callback = callback,
        priority = priority or EventConst.PRIO_MIDDLE,
        params = {...},
    }

    EventMgr.events = EventMgr.events or {}
    EventMgr.events[eventType] = EventMgr.events[eventType] or {}
    
    EventMgr.events[eventType][#EventMgr.events[eventType] + 1] = eventCallback
    table.sort(EventMgr.events[eventType], function(left, right)
        return left.priority > right.priority
    end)
end

EventMgr.unregisterEvent = function(eventType, callback)
    EventMgr.events = EventMgr.events or {}
    local eventCallbacks = EventMgr.events[eventType]
    if not eventCallbacks or #eventCallbacks == 0 then
        Logger.warn(string.format("事件：没有对应的回调函数", eventType))
        return
    end

    for k, v in pairs(eventCallbacks) do
        if v.callback == callback then
            table.remove(eventCallbacks, k)
            return
        end
    end
end

EventMgr.triggerEvent = function(eventType, ...)
    -- clone，防止回调函数时，调用unRegisterEvent，把数据清空了
    EventMgr.events = EventMgr.events or {}
    local eventCallbacks = clone(EventMgr.events[eventType])
    if not eventCallbacks or #eventCallbacks == 0 then
        -- 这里的打印造成了mac上的明显卡顿，暂时屏蔽
        printInfo(string.format("事件：没有对应的回调函数", eventType))
        return
    end

    for k, v in pairs(eventCallbacks) do
        if EventMgr.hasRegisterEvent(eventType, v.callback) then
            if #{...} == 0 then
                v.callback(unpack(v.params))
            else
                for _, param in ipairs({...}) do
                    table.insert(v.params, param)
                end

                v.callback(unpack(v.params))
            end
        end
    end
end

EventMgr.hasRegisterEvent = function(eventType, callback)
    EventMgr.events = EventMgr.events or {}
    local eventCallbacks = EventMgr.events[eventType]
    if not eventCallbacks or #eventCallbacks == 0 then
        return false
    end

    for k, v in pairs(eventCallbacks) do
        if v.callback == callback then
            return true
        end
    end

    return false
end

EventMgr.clearEvent = function(eventType)
    Logger.debug("\n\n clearEvent:", eventType)

    EventMgr.events = EventMgr.events or {}
    local eventCallbacks = EventMgr.events[eventType]
    if eventCallbacks then
        EventMgr.events[eventType] = {}
    end
end

EventMgr.clearEvents = function()
    EventMgr.events = {}
end