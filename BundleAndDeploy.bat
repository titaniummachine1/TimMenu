@echo off

node bundle.js
move /Y "TimMenu.lua" "%localappdata%"
exit