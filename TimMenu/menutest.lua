-- TestWindows.lua
local TimMenu = require("TimMenu")

local function OnDraw()
    -- Create and draw the first window (ID defaults to title).
    local visible1, win1 = TimMenu.Begin("Window_One", true)
    if visible1 then
        -- (Place your drawing code for Window_One here)
        TimMenu.End()
    end

    -- Create and draw a second window with a custom unique ID.
    local visible2, win2 = TimMenu.Begin("Window_One", true, "Window_One_SecondInstance")
    if visible2 then
        -- (Place your drawing code for the second instance here)
        TimMenu.End()
    end

    -- Show debug information.
    TimMenu.ShowDebug()
end

-- Generate a unique ID for the Draw callback.
local uniqueID = tostring(math.random(100000, 999999))
local drawCallbackID = "TestWindows_Draw_" .. uniqueID

callbacks.Unregister("Draw", drawCallbackID)
callbacks.Register("Draw", drawCallbackID, OnDraw)
