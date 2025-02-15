---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common

local Common = {}

local Globals = require("TimMenu.Globals") -- Import the Globals module for Colors and Style.

-- Attempt to unload any existing LNXlib instance
local function safeUnload()
    local success = pcall(UnloadLib)
    if not success then
        -- Library wasn't loaded, which is fine
    end
end

-- Load and validate LNXlib
local function loadLNXlib()
    local libLoaded, Lib = pcall(require, "LNXlib")
    if not libLoaded then
        error("Failed to load LNXlib. Please ensure it is installed correctly.")
    end
    
    if not Lib.GetVersion or Lib.GetVersion() < 1.0 then
        error("LNXlib version is too old. Please update to version 1.0 or newer.")
    end
    
    return Lib
end

-- Initialize library
safeUnload()
local Lib = loadLNXlib()

-- Expose required functionality
Common.Lib = Lib
Common.Fonts = Lib.UI.Fonts
Common.KeyHelper = Lib.Utils.KeyHelper
Common.Input = Lib.Utils.Input
Common.Timer = Lib.Utils.Timer
Common.Log = Lib.Utils.Logger.new("TimMenu")
Common.Notify = Lib.UI.Notify
Common.Math = Lib.Utils.Math
Common.Conversion = Lib.Utils.Conversion

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
    UnloadLib() --unloading lualib
    input.SetMouseInputEnabled(true) --enable mouse input(hopefuly prevent soft lock on load)
    engine.PlaySound("hl1/fvox/deactivated.wav") --deactivated
    package.loaded["TimMenu"] = nil
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

--[[ Play sound when loaded ]]--
engine.PlaySound("hl1/fvox/activated.wav")

return Common
