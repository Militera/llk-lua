
require("config")
require("cocos.init")
require("framework.init")
require("app.scenes.Const")
require("app.scenes.EventMgr")
require("app.scenes.TipBox")
require("app.scenes.User")

if DEBUG ~= 2 then
	printInfo = function() end
end

local MyApp = class("MyApp", cc.mvc.AppBase)

MyApp.ctor = function(self)
	MyApp.super.ctor(self)

end

MyApp.run = function(self)
	cc.FileUtils:getInstance():addSearchPath("res/")
	
	-- 直接加载所有资源
	display.addSpriteFrames("majiang.plist", "majiang.png")

	-- self:enterScene("GameScene")
	self:enterScene("MainmenuScene")
end

return MyApp
