---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common

local Common = {}

local Static = require("TimMenu.Static") -- Import the static module for Colors and Style.

pcall(UnloadLib) -- if it fails then forget about it it means it wasnt loaded in first place and were clean

-- Unload the module if it's already loaded
if package.loaded["ImMenu"] then
    package.loaded["ImMenu"] = nil
end

local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 1.0, "LNXlib version is too old, please update it!")

Common.Lib        = Lib

Common.Fonts      = Lib.UI.Fonts
Common.KeyHelper  = Lib.Utils.KeyHelper
Common.Input      = Lib.Utils.Input
Common.Timer      = Lib.Utils.Timer

Common.Log        = Lib.Utils.Logger.new("Cheater Detection")
Common.Notify     = Lib.UI.Notify
Common.Math       = Common.Lib.Utils.Math
Common.Conversion = Common.Lib.Utils.Conversion

--------------------------------------------------------------------------------
-- Updating Static Fonts
--------------------------------------------------------------------------------
Static.Style.Font = Common.Fonts.Verdana

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

--- Clamps a floating-point value to the closest integer.
---@param value number
---@return number
function Common.Clamp(value)
    return math.floor(value + 0.5)
end

-- Modified: Helper function to handle window dragging logic with rigid offset
function Common.HandleWindowDrag(window, titleHeight, screenWidth, screenHeight)
    local winX = window.X or 0
    local winY = window.Y or 0
    local winW = window.W or 100
    local winH = window.H or 100
    if not window.DragPos then window.DragPos = { X = 0, Y = 0 } end

    local mX, mY = table.unpack(input.GetMousePos())
    if not window.IsDragging and input.IsButtonDown(MOUSE_LEFT) then
        if mX >= winX and mX <= winX + winW and mY >= winY and mY <= winY + titleHeight then
            window.DragPos = { X = mX - winX, Y = mY - winY }
            window.IsDragging = true
        end
    end

    if window.IsDragging then
        local newX = mX - window.DragPos.X
        local newY = mY - window.DragPos.Y
        window.X = math.max(0, math.min(newX, screenWidth - winW))
        window.Y = math.max(0, math.min(newY, screenHeight - winH - titleHeight))
    end

    if not input.IsButtonDown(MOUSE_LEFT) then
        window.IsDragging = false
    end
end

-- New: Helper function for mouse interaction within a rectangle.
function Common.GetInteraction(x, y, w, h)
    local mX, mY = table.unpack(input.GetMousePos())
    local hovered = (mX >= x) and (mX <= x + w) and (mY >= y) and (mY <= y + h)
    -- Simple click detection: detect click only when button is pressed now and wasn't in the previous frame.
    if Common._PrevMouseDown == nil then Common._PrevMouseDown = false end
    local currentlyDown = input.IsButtonDown(MOUSE_LEFT)
    local clicked = hovered and currentlyDown and (not Common._PrevMouseDown)
    Common._PrevMouseDown = currentlyDown
    return hovered, clicked
end

--------------------------------------------------------------------------------
-- Unload Callback: Clean up the module on unload.
--------------------------------------------------------------------------------

local function OnUnload() -- Called when the script is unloaded
    package.loaded["TimMenu"] = nil
    UnloadLib() --unloading lualib
    engine.PlaySound("hl1/fvox/deactivated.wav") --deactivated
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

--[[ Play sound when loaded ]]--
engine.PlaySound("hl1/fvox/activated.wav")

return Common