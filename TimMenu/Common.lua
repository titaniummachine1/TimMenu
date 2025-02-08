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