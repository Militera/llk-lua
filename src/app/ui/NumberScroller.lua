--[[
	滚动计时器
		参考：http://cn.cocos2d-x.org/tutorial/show?id=2322
--]]

local NumberColumn = class("NumberColumn", function()
	return display.newNode()
end)

NumberColumn.ctor = function(self, fontSize)
	self.curNumber = 0
	self.toNumber = 0
	self.time = 1
	self.updateMoveSum = 0
	self.fontSize = fontSize

	self.numbersNode = display.newNode()
	self.numbersNode:addTo(self)
	self.numberLabels = {}
	for i = 0, 10 do
		local numberLabel = cc.ui.UILabel.new({text = (i % 10) .. "", size = fontSize, color = display.COLOR_RED})
		numberLabel:align(display.CENTER, 0, i * fontSize)
		numberLabel:addTo(self.numbersNode)
		table.insert(self.numberLabels, numberLabel)
	end

	self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.onEnterFrame))
	self:scheduleUpdate()
end

NumberColumn.onEnterFrame = function(self, dt)
	if self.curNumber ~= self.toNumber then
		local distance = self.updateSpeed * dt
		self.numbersNode:setPositionY(self.numbersNode:getPositionY() - distance)
		self.updateMoveSum = self.updateMoveSum + distance

		if self.updateMoveSum >= self.fontSize then
			self.curNumber = self.curNumber + 1
			self.numbersNode:setPositionY(-(self.curNumber % 10 * self.fontSize))

			self.updateMoveSum = 0
		end
	end
end

NumberColumn.setNumber = function(self, number)
	self.toNumber = number
	local delta = self.toNumber - self.curNumber
	self.updateSpeed = delta * self.fontSize / self.time
end

NumberColumn.setTime = function(self, time)
	self.time = time
end

--------------------------------------------------------

NumberScroller = class("NumberScroller", function()
	return display.newNode()
end)

NumberScroller.ctor = function(self, length, fontSize)
	self.time = 1
	self.curNumber = 0

	local rect = cc.rect(0, -fontSize / 2, length * fontSize + 40, fontSize)
	self.columnsNode = display.newClippingRegionNode(rect)
	self.columnsNode:addTo(self)
	self.columns = {}

	for i = 1, length do
		local column = NumberColumn.new(fontSize)
		column:align(display.CENTER, i * fontSize, 0)
		column:addTo(self.columnsNode)
		table.insert(self.columns, column)
	end

end

NumberScroller.setNumber = function(self, number)
	if number > self.curNumber then
		self.curNumber = number

		for i = #self.columns, 1, -1 do
			self.columns[i]:setNumber(number, false)
			number = math.floor(number / 10)
		end
	end
end

NumberScroller.getNumber = function(self)
	return self.curNumber
end

-- 有顺序要求，需要先设置number，再来设置time才可以
NumberScroller.setTime = function(self, time)
	self.time = time
	for _, v in ipairs(self.columns) do
		v:setTime(time)
	end
end

return NumberScroller