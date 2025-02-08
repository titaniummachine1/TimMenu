local WidgetStack = {}
WidgetStack.stack = {}

function WidgetStack.push(x, y)
	WidgetStack.stack[#WidgetStack.stack + 1] = { x = x, y = y }
end

function WidgetStack.pop()
	return table.remove(WidgetStack.stack)
end

function WidgetStack.top()
	return WidgetStack.stack[#WidgetStack.stack] or { x = 0, y = 0 }
end

function WidgetStack.set(x, y)
	if WidgetStack.stack[#WidgetStack.stack] then
		WidgetStack.stack[#WidgetStack.stack] = { x = x, y = y }
	else
		WidgetStack.push(x, y)
	end
end

return WidgetStack
