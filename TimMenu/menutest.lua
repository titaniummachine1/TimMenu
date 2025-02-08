-- TestWindows.lua
local TimMenu = require("TimMenu")

local function OnDraw()
    -- Begin (or update) a window with just a title (ID defaults to title).
    if TimMenu.Begin("Window_One") then
        -- (Window drawing code can go here.)
        TimMenu.End()
    end

    -- Begin (or update) a window with a title and a custom unique ID.
    if TimMenu.Begin("Window_One", "Window_One_SecondInstance") then
        -- (Additional window drawing code can go here.)
        TimMenu.End()
    end

    -- Begin (or update) a window with a title and a custom unique ID.
    if TimMenu.Begin("Window_two", false, "window two") then
        -- (Additional window drawing code can go here.)
        TimMenu.End()
    end

    -- Show debug info.
    TimMenu.ShowDebug()
end

-- Generate a unique ID for the Draw callback.
local uniqueID = tostring(math.random(100000, 999999))
local drawCallbackID = "TestWindows_Draw_" .. uniqueID

callbacks.Unregister("Draw", drawCallbackID)
callbacks.Register("Draw", drawCallbackID, OnDraw)