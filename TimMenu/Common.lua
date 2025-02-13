---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common

local Common = {}

local Globals = require("TimMenu.Globals") -- Import the Globals module for Colors and Style.

pcall(UnloadLib) -- if it fails then forget about it it means it wasnt loaded in first place and were clean

local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 1.0, "LNXlib version is too old, please update it!")

Common.Lib        = Lib

Common.Fonts      = Lib.UI.Fonts
Common.KeyHelper  = Lib.Utils.KeyHelper
Common.Input      = Lib.Utils.Input
Common.Timer      = Lib.Utils.Timer

Common.Log        = Lib.Utils.Logger.new("TimMenu")
Common.Notify     = Lib.UI.Notify
Common.Math       = Common.Lib.Utils.Math
Common.Conversion = Common.Lib.Utils.Conversion

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

--- Clamps a floating-point value to the closest integer.
---@param value number
---@return number
function Common.Clamp(value)
    return math.floor(value + 0.5)
end

-- Track button state globally
local wasPressed = false

-- New: Helper function for mouse interaction within a rectangle.
function Common.GetInteraction(x, y, w, h)
    local mX, mY = table.unpack(input.GetMousePos())
    local hovered = (mX >= x) and (mX <= x + w) and (mY >= y) and (mY <= y + h)
    local isPressed = input.IsButtonDown(MOUSE_LEFT)

    -- Only trigger click when button is pressed and wasn't pressed last frame
    local clicked = hovered and isPressed and not wasPressed

    -- Update state for next frame
    wasPressed = isPressed
    
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