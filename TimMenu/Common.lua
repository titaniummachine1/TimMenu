---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common

local Utils = require("TimMenu.Utils")

local Common = {}

--local Globals = require("TimMenu.Globals") -- Import the Globals module for Colors and Style.

--------------------------------------------------------------------------------------
--Library loading--
--------------------------------------------------------------------------------------

-- Function to download content from a URL
local function downloadFile(url)
	local body = http.Get(url)
	if body and body ~= "" then
		return body
	else
		error("Failed to download file from " .. url)
	end
end

local latestReleaseURL = "https://github.com/lnx00/Lmaobox-Library/releases/latest/download/lnxLib.lua"

-- Load and validate LNXlib
local function loadLNXlib()
	local libLoaded, Lib = pcall(require, "LNXlib")
	if not libLoaded or not Lib.GetVersion or Lib.GetVersion() < 1.0 then
		print("LNXlib not found or version is too old. Attempting to download the latest version...")

		-- Download and load lnxLib.lua
		local lnxLibContent = downloadFile(latestReleaseURL)
		local lnxLibFunction, loadError = load(lnxLibContent)
		if lnxLibFunction then
			lnxLibFunction()
			libLoaded, Lib = pcall(require, "LNXlib")
			if not libLoaded then
				error("Failed to load LNXlib after downloading: " .. loadError)
			end
		else
			error("Error loading lnxLib: " .. loadError)
		end
	end

	return Lib
end

-- Initialize library
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

-- Remove the direct nil assignment and package reloading from Refresh().
function Common.Refresh()
	package.loaded["TimMenu"] = nil
end

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

local function OnUnload() -- Called when a script using TimMenu is unloaded
	--ensure o leave mosue input enabled(api is inverted)
	input.SetMouseInputEnabled(false)
	engine.PlaySound("hl1/fvox/deactivated.wav") -- deactivated sound
	-- Prune windows from unloaded scripts
	Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)
	-- If no more scripts are using TimMenu, fully unload
	if next(TimMenuGlobal.loadOrder) == nil then
		print("Unloading TimMenu")
		-- Unload the TimMenu module so next require reinitializes it
		package.loaded["TimMenu"] = nil
	end
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

return Common
